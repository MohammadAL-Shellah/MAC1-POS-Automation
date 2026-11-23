'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { runAgent } = require('./agent');
const {
  GUARDED_CLICKS,
  chatTurn,
  createDesktopSession,
  loadKnowledge,
  requestGeminiJson,
  executePlan,
  formatBugDraft,
  formatResultsForChat,
  generatePlan,
  generatePlanFromMarkdown,
  renderRunReportMarkdown,
  summarizeRun,
  validatePlan,
} = require('./qa-agent');

const HOST = '127.0.0.1';
const PORT = Number(process.env.QA_AGENT_UI_PORT || 4173);
const MAX_BODY_BYTES = 512 * 1024;
const MAX_MARKDOWN_BYTES = 128 * 1024;
const MAX_STORY_CHARS = 100_000;
const MAX_SESSIONS = 20;
const SESSION_TTL_MS = 60 * 60 * 1000;
const OUTPUT_DIR = path.join(__dirname, 'output');
const sessions = new Map();
const chats = new Map();
let runInProgress = false;   // one app can only be driven by one run at a time

function jsonResponse(response, status, payload) {
  response.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Cache-Control': 'no-store',
    'X-Content-Type-Options': 'nosniff',
  });
  response.end(JSON.stringify(payload));
}

function pruneSessions() {
  const now = Date.now();
  for (const [id, session] of sessions) {
    if (now - session.updatedAt > SESSION_TTL_MS || session.status === 'completed') {
      sessions.delete(id);
    }
  }
  while (sessions.size >= MAX_SESSIONS) {
    const firstId = sessions.keys().next().value;
    sessions.delete(firstId);
  }
}

async function readJson(request) {
  let size = 0;
  const chunks = [];
  for await (const chunk of request) {
    size += chunk.length;
    if (size > MAX_BODY_BYTES) throw Object.assign(new Error('Request is too large.'), { status: 413 });
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    throw Object.assign(new Error('Request must contain valid JSON.'), { status: 400 });
  }
}

function validateLocalRequest(request, response) {
  const host = request.headers.host;
  if (!host || !/^(127\.0\.0\.1|localhost)(:\d+)?$/i.test(host)) {
    jsonResponse(response, 403, { error: 'This local UI only accepts localhost connections.' });
    return false;
  }
  const origin = request.headers.origin;
  if (origin && origin !== `http://${host}`) {
    jsonResponse(response, 403, { error: 'Cross-origin requests are not allowed.' });
    return false;
  }
  return true;
}

function saveJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

function planView(session) {
  return {
    id: session.id,
    source: session.source || 'story',
    target: session.target,
    round: session.round,
    story: session.story,
    status: session.status,
    plan: session.plan,
  };
}

// Chat: the agent answers, and when the message asks for work it runs the plan at once
// (autoRun) and adds the results to the conversation.
async function handleChat(body, response) {
  if (typeof body.message !== 'string' || !body.message.trim() || body.message.length > 20_000) {
    throw Object.assign(new Error('Write a message (maximum 20,000 characters).'), { status: 400 });
  }
  const target = body.target === 'web' ? 'web' : 'desktop';
  let chat = typeof body.chatId === 'string' ? chats.get(body.chatId) : null;
  if (!chat) {
    chat = { id: crypto.randomUUID(), history: [], target, updatedAt: Date.now() };
    chats.set(chat.id, chat);
  }
  chat.target = target;
  chat.updatedAt = Date.now();
  const message = body.message.trim();
  const answer = await chatTurn(chat.history, message, target);
  chat.history.push({ role: 'user', text: message }, { role: 'agent', text: answer.reply });
  const payload = { chatId: chat.id, reply: answer.reply, plan: answer.plan, task: answer.task || null };

  if (answer.task && body.autoRun !== false) {
    if (runInProgress) {
      payload.runError = 'A run is already in progress. Wait for it to finish, then ask again.';
    } else {
      runInProgress = true;
      let session = null;
      try {
        session = await createDesktopSession();
        const runId = Date.now().toString(36).toUpperCase();
        const result = await runAgent({
          desktop: session.desktop,
          goal: `${answer.task}\n\nThe user's own words: ${message}`,
          knowledge: loadKnowledge(),
          requestJson: requestGeminiJson,
          guards: GUARDED_CLICKS,
          allowedClicks: answer.allowedClicks,
          outputDir: OUTPUT_DIR,
          runId,
        });
        result.bugDrafts = result.bugDrafts.map((bug) => ({
          title: String(bug.title || 'MAC1 | Bug'),
          severity: String(bug.severity || 'Medium'),
          testCases: '',
          steps: Array.isArray(bug.steps) ? bug.steps.map(String) : [],
          actual: Array.isArray(bug.actual) ? bug.actual.map(String) : [],
          expected: String(bug.expected || ''),
          evidence: String(bug.evidence || ''),
        })).map((bug) => ({ ...bug, text: formatBugDraft(bug) }));
        result.evidence = result.evidence.map((file) => path.relative(path.dirname(__dirname), file));
        saveJson(path.join(OUTPUT_DIR, `qa-agent-${runId}-agent-run.json`), { task: answer.task, message, ...result });
        payload.agent = result;
        chat.history.push({
          role: 'system',
          text: [
            `Agent finished (${result.status}) in ${result.turns} turns.`,
            ...result.report,
            ...result.checks.map((check) => `check ${check.expression} = ${check.left} ${check.op} ${check.value} = ${check.right}: ${check.pass ? 'pass' : 'FAIL'}`),
            `Values: ${JSON.stringify(Object.fromEntries(Object.entries(result.values).map(([k, v]) => [k, v.text])))}`,
            `Last actions: ${JSON.stringify(result.log.slice(-8))}`,
          ].join('\n'),
        });
      } catch (error) {
        payload.runError = error.message;
        chat.history.push({ role: 'system', text: `The agent could not start or stopped: ${error.message}` });
      } finally {
        if (session?.desktop) await session.desktop.close();
        runInProgress = false;
      }
    }
  }

  if (answer.plan && body.autoRun !== false) {
    if (runInProgress) {
      payload.runError = 'A run is already in progress. Wait for it to finish, then ask again.';
    } else {
      runInProgress = true;
      try {
        const results = await executePlan(answer.plan, target, { goal: message });
        const report = { story: message, target, finishedAt: new Date().toISOString(), results };
        try {
          const summary = await summarizeRun(message, answer.plan, results, target);
          report.summary = {
            ...summary,
            bugDrafts: summary.bugDrafts.map((bug) => ({ ...bug, text: formatBugDraft(bug) })),
          };
          fs.writeFileSync(path.join(OUTPUT_DIR, `qa-chat-${chat.id}-${Date.now()}-report.md`),
            renderRunReportMarkdown(summary), 'utf8');
        } catch (error) {
          report.summaryError = error.message;
        }
        chat.history.push({ role: 'system', text: formatResultsForChat(results, report.summary) });
        payload.report = report;
      } catch (error) {
        payload.runError = error.message;
        chat.history.push({ role: 'system', text: `The run could not start or stopped: ${error.message}` });
      } finally {
        runInProgress = false;
      }
    }
  }
  saveJson(path.join(OUTPUT_DIR, `qa-chat-${chat.id}.json`), { target, history: chat.history });
  jsonResponse(response, 200, payload);
}

async function handleApi(request, response, pathname) {
  const body = await readJson(request);

  if (pathname === '/api/import-test-cases') {
    if (typeof body.markdown !== 'string' || !body.markdown.trim() ||
        Buffer.byteLength(body.markdown, 'utf8') > MAX_MARKDOWN_BYTES) {
      throw Object.assign(
        new Error(`Choose a non-empty Markdown file no larger than ${MAX_MARKDOWN_BYTES / 1024} KB.`),
        { status: 400 },
      );
    }
    if (!['web', 'desktop'].includes(body.target)) {
      throw Object.assign(new Error('Choose a supported portal target.'), { status: 400 });
    }
    if (body.target === 'web' && !process.env.QA_BASE_URL) {
      throw Object.assign(new Error('QA_BASE_URL is missing from the repository root .env.'), { status: 400 });
    }

    const markdown = body.markdown.trim();
    const imported = await generatePlanFromMarkdown(markdown, [], [], undefined, body.target);
    const plan = imported.plan;
    pruneSessions();
    const id = crypto.randomUUID();
    const session = {
      id,
      story: markdown,
      target: body.target,
      source: 'markdown-import',
      importConversions: imported.conversions,
      answers: [],
      plan,
      round: 1,
      status: plan.clarificationQuestions.length ? 'needs_answers' : 'ready',
      updatedAt: Date.now(),
    };
    sessions.set(id, session);
    saveJson(path.join(OUTPUT_DIR, `qa-agent-${id}-plan.json`), {
      story: session.story,
      target: session.target,
      source: 'markdown-import',
      generatedAt: new Date().toISOString(),
      ...plan,
    });
    jsonResponse(response, 200, planView(session));
    return;
  }

  if (pathname === '/api/plan') {
    if (typeof body.story !== 'string' || !body.story.trim() || body.story.length > MAX_STORY_CHARS) {
      throw Object.assign(
        new Error(`Enter a user story (maximum ${MAX_STORY_CHARS.toLocaleString()} characters).`),
        { status: 400 },
      );
    }
    if (!['web', 'desktop'].includes(body.target)) {
      throw Object.assign(new Error('Choose a supported portal target.'), { status: 400 });
    }
    if (body.target === 'web' && !process.env.QA_BASE_URL) {
      throw Object.assign(new Error('QA_BASE_URL is missing from the repository root .env.'), { status: 400 });
    }
    const plan = validatePlan(await generatePlan(body.story.trim(), [], body.target));
    pruneSessions();
    const id = crypto.randomUUID();
    const session = {
      id,
      story: body.story.trim(),
      target: body.target,
      answers: [],
      plan,
      round: 1,
      status: plan.clarificationQuestions.length ? 'needs_answers' : 'ready',
      updatedAt: Date.now(),
    };
    sessions.set(id, session);
    saveJson(path.join(OUTPUT_DIR, `qa-agent-${id}-plan.json`), {
      story: session.story,
      target: session.target,
      generatedAt: new Date().toISOString(),
      ...plan,
    });
    jsonResponse(response, 200, planView(session));
    return;
  }

  if (pathname === '/api/chat') {
    await handleChat(body, response);
    return;
  }

  const match = pathname.match(/^\/api\/(clarify|execute)\/([0-9a-f-]{36})$/i);
  if (!match) {
    jsonResponse(response, 404, { error: 'Not found.' });
    return;
  }
  const [, action, id] = match;
  const session = sessions.get(id);
  if (!session) {
    jsonResponse(response, 404, { error: 'This QA session expired. Start a new user story.' });
    return;
  }
  session.updatedAt = Date.now();

  if (action === 'clarify') {
    if (session.status !== 'needs_answers') {
      throw Object.assign(new Error('This plan has no unanswered questions.'), { status: 409 });
    }
    if (!Array.isArray(body.answers) || body.answers.length !== session.plan.clarificationQuestions.length) {
      throw Object.assign(new Error('Answer each question before continuing.'), { status: 400 });
    }
    const nextAnswers = body.answers.map((answer, index) => {
      if (typeof answer !== 'string' || !answer.trim() || answer.length > 2_000) {
        throw Object.assign(new Error(`Please provide a valid answer to question ${index + 1}.`), { status: 400 });
      }
      return { question: session.plan.clarificationQuestions[index], answer: answer.trim() };
    });
    const maxRounds = session.source === 'markdown-import' ? 11 : 4;
    if (session.round >= maxRounds) {
      throw Object.assign(
        new Error(
          session.source === 'markdown-import'
            ? 'Gemini still needs clarification after several rounds. Add the missing details to the source file and import it again.'
            : 'Gemini still needs clarification after several rounds. Add the missing details to the story and start again.',
        ),
        { status: 409 },
      );
    }
    session.status = 'thinking';
    try {
      const allAnswers = session.answers.concat(nextAnswers);
      if (session.source === 'markdown-import') {
        const imported = await generatePlanFromMarkdown(
          session.story,
          allAnswers,
          session.importConversions,
          undefined,
          session.target,
        );
        session.importConversions = imported.conversions;
        session.plan = imported.plan;
      } else {
        session.plan = validatePlan(await generatePlan(session.story, allAnswers, session.target));
      }
      session.answers = allAnswers;
      session.round += 1;
      session.status = session.plan.clarificationQuestions.length ? 'needs_answers' : 'ready';
      saveJson(path.join(OUTPUT_DIR, `qa-agent-${id}-plan.json`), {
        story: session.story,
        target: session.target,
        ...(session.source ? { source: session.source } : {}),
        generatedAt: new Date().toISOString(),
        ...session.plan,
      });
      jsonResponse(response, 200, planView(session));
    } catch (error) {
      session.status = 'needs_answers';
      throw error;
    }
    return;
  }

  if (session.status !== 'ready' || session.plan.clarificationQuestions.length) {
    throw Object.assign(new Error('Answer all clarification questions before running the plan.'), { status: 409 });
  }
  if (body.confirmed !== true) {
    throw Object.assign(new Error('Explicit confirmation is required to run tests.'), { status: 400 });
  }
  session.status = 'running';
  try {
    const results = await executePlan(session.plan, session.target, { goal: session.story });
    const report = {
      story: session.story,
      target: session.target,
      finishedAt: new Date().toISOString(),
      results,
    };
    saveJson(path.join(OUTPUT_DIR, `qa-agent-${id}-results.json`), report);
    // Arabic summary and English bug drafts, written the team's way. A Gemini failure here
    // must not hide the results, so it is reported separately.
    try {
      const summary = await summarizeRun(session.story, session.plan, results, session.target);
      report.summary = { ...summary, bugDrafts: summary.bugDrafts.map((bug) => ({ ...bug, text: formatBugDraft(bug) })) };
      fs.writeFileSync(path.join(OUTPUT_DIR, `qa-agent-${id}-report.md`), renderRunReportMarkdown(summary), 'utf8');
    } catch (error) {
      report.summaryError = error.message;
    }
    session.status = 'completed';
    session.updatedAt = Date.now();
    jsonResponse(response, 200, { status: 'completed', report });
  } catch (error) {
    session.status = 'failed';
    jsonResponse(response, 500, { error: error.message, status: 'failed' });
  }
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, `http://${HOST}:${PORT}`);
  if (!validateLocalRequest(request, response)) return;

  if (request.method === 'GET' && url.pathname === '/') {
    const page = fs.readFileSync(path.join(__dirname, 'ui.html'));
    response.writeHead(200, {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
      'Content-Security-Policy': "default-src 'self'; style-src 'self'; script-src 'self'; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'",
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
    });
    response.end(page);
    return;
  }

  if (request.method === 'GET' && ['/ui.css', '/ui.js'].includes(url.pathname)) {
    const extension = path.extname(url.pathname);
    const contentType = extension === '.css' ? 'text/css; charset=utf-8' : 'text/javascript; charset=utf-8';
    response.writeHead(200, {
      'Content-Type': contentType,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    response.end(fs.readFileSync(path.join(__dirname, url.pathname.slice(1))));
    return;
  }

  if (request.method === 'POST' && url.pathname.startsWith('/api/')) {
    const startedAt = Date.now();
    try {
      await handleApi(request, response, url.pathname);
    } catch (error) {
      const status = error.status || 500;
      console.error(
        `[${request.method} ${url.pathname}] HTTP ${status} in ${Date.now() - startedAt}ms (${error.name || 'Error'})`,
      );
      if (!response.headersSent) {
        jsonResponse(response, status, { error: error.message || 'The request failed.' });
      } else {
        jsonResponse(response, 500, { error: error.message || 'Test execution failed.', status: 'failed' });
      }
    }
    return;
  }

  jsonResponse(response, 404, { error: 'Not found.' });
});

server.on('error', (error) => {
  console.error(`Could not start the QA Agent UI: ${error.message}`);
  process.exitCode = 1;
});

server.listen(PORT, HOST, () => {
  console.log(`Gemini QA Agent UI is running at http://${HOST}:${PORT}`);
  console.log('The UI is bound to this computer only. Press Ctrl+C to stop.');
});
