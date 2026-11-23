'use strict';

const storyForm = document.querySelector('#story-form');
const storyInput = document.querySelector('#story');
const targetInput = document.querySelector('#target');
const targetHelp = document.querySelector('#target-help');
const generateButton = document.querySelector('#generate');
const testCaseFile = document.querySelector('#test-case-file');
const importButton = document.querySelector('#import-test-cases');
const answerForm = document.querySelector('#answers-form');
const answerButton = document.querySelector('#answer-button');
const runButton = document.querySelector('#run-button');
const statusBox = document.querySelector('#status');
const workspace = document.querySelector('#workspace');
const questionsCard = document.querySelector('#questions-card');
const questionsBox = document.querySelector('#questions');
const planCard = document.querySelector('#plan-card');
const criteriaBox = document.querySelector('#criteria');
const casesBox = document.querySelector('#test-cases');
const resultsCard = document.querySelector('#results-card');
const resultsBox = document.querySelector('#results');
const planActions = document.querySelector('#plan-actions');
const targetPill = document.querySelector('#target-pill');
const roundPill = document.querySelector('.round-pill');
const caseCount = document.querySelector('#case-count');
const resultCount = document.querySelector('#result-count');

let currentSession = null;
let busy = false;

targetInput.addEventListener('change', () => {
  targetHelp.textContent = targetInput.value === 'desktop'
    ? 'Drives the open MacOne app with Windows UI Automation. Sign in to the QA company first and keep the screen unlocked.'
    : 'Uses the configured HTTPS QA portal and QA credentials.';
});

function showStatus(message, kind = 'info') {
  statusBox.textContent = message;
  statusBox.dataset.kind = kind;
  statusBox.hidden = !message;
}

async function requestJson(url, payload, timeoutMs = 100_000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || 'The request failed.');
    return data;
  } catch (error) {
    if (error.name === 'AbortError') {
      throw new Error('This request took too long. No tests were run. You can try the import or plan generation again.');
    }
    throw error;
  } finally {
    clearTimeout(timeout);
  }
}

function appendText(parent, tag, className, value) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  element.textContent = value;
  element.dir = 'auto';   // Arabic text from Gemini renders right to left
  parent.append(element);
  return element;
}

function renderQuestions(session) {
  questionsBox.replaceChildren();
  session.plan.clarificationQuestions.forEach((question, index) => {
    const group = document.createElement('div');
    group.className = 'question';
    const label = appendText(group, 'label', '', `${index + 1}. ${question}`);
    const answer = document.createElement('textarea');
    answer.name = `answer-${index}`;
    answer.rows = 2;
    answer.maxLength = 2000;
    answer.required = true;
    answer.setAttribute('aria-label', question);
    label.htmlFor = answer.name;
    group.append(answer);
    questionsBox.append(group);
  });
  roundPill.textContent = `Round ${session.round} of ${session.source === 'markdown-import' ? 11 : 4}`;
  questionsCard.hidden = session.status !== 'needs_answers';
}

function describeStep(step) {
  if (step.action === 'open') return `Open ${step.path}`;
  if (step.action === 'expectText') return `Check for “${step.text}”`;
  if (step.action === 'screenshot') return `Take screenshot “${step.name}”`;
  if (step.action === 'readValue') return `Read the number next to “${step.target.name}” as {${step.as}}`;
  if (step.action === 'readCell') return `Read “${step.column}” in row “${step.row}” as {${step.as}}`;
  if (step.action === 'expectNumber') {
    return `Check ${step.expression} ${step.op || '='} ${step.value}${step.tolerance ? ` (± ${step.tolerance})` : ''}`;
  }
  if (step.action === 'expectValue') {
    return `Check {${step.var}} ${step.equals !== undefined ? `is “${step.equals}”` : `contains “${step.contains}”`}`;
  }
  if (!step.target) return `${step.action} step`;   // a step type this page does not know yet
  const target = step.target.name;
  if (step.action === 'fill') return `Enter “${step.value.replace('{RUN_ID}', 'unique run ID')}” in ${target}`;
  if (step.action === 'select') return `Select “${step.value}” in ${target}`;
  if (step.action === 'click') return `Click ${target}`;
  return `Check that ${target} is visible`;
}

function renderPlan(session) {
  criteriaBox.replaceChildren();
  casesBox.replaceChildren();
  resultsCard.hidden = true;
  document.querySelector('#plan-title').textContent = session.plan.summary;
  targetPill.textContent = session.target === 'desktop' ? 'Minerets desktop app' : 'QA web portal';
  caseCount.textContent = `${session.plan.testCases.length} cases`;

  session.plan.acceptanceCriteria.forEach((criterion) => {
    const card = document.createElement('div');
    card.className = 'criterion';
    appendText(card, 'span', '', '✓');
    appendText(card, 'span', '', criterion);
    criteriaBox.append(card);
  });

  session.plan.testCases.forEach((testCase) => {
    const details = document.createElement('details');
    details.className = 'test-case';
    const summary = document.createElement('summary');
    appendText(summary, 'span', 'case-id', testCase.id);
    appendText(summary, 'span', 'case-title', testCase.title);
    details.append(summary);
    if (testCase.preconditions?.length) {
      const list = document.createElement('ul');
      list.className = 'preconditions';
      appendText(list, 'strong', '', 'Preconditions: ');
      testCase.preconditions.forEach((condition) => appendText(list, 'li', '', condition));
      details.append(list);
    }
    const steps = document.createElement('ol');
    steps.className = 'steps';
    testCase.steps.forEach((step) => appendText(steps, 'li', '', describeStep(step)));
    details.append(steps);
    casesBox.append(details);
  });

  const hasQuestions = session.plan.clarificationQuestions.length > 0;
  planActions.hidden = hasQuestions || session.status === 'running';
  runButton.disabled = busy || hasQuestions || session.status !== 'ready';
  planCard.hidden = false;
}

function showSession(session) {
  currentSession = session;
  workspace.hidden = false;
  renderQuestions(session);
  renderPlan(session);
}

function setBusy(value) {
  busy = value;
  generateButton.disabled = value;
  importButton.disabled = value;
  testCaseFile.disabled = value;
  answerButton.disabled = value;
  runButton.disabled = value || !currentSession ||
    currentSession.status !== 'ready' ||
    currentSession.plan.clarificationQuestions.length > 0;
}

importButton.addEventListener('click', async () => {
  if (busy) return;
  const file = testCaseFile.files[0];
  if (!file) {
    showStatus('Choose a Markdown test-case file first.', 'error');
    return;
  }
  if (!file.name.toLowerCase().endsWith('.md')) {
    showStatus('Choose a .md Markdown file.', 'error');
    return;
  }
  if (file.size === 0 || file.size > 128 * 1024) {
    showStatus('Choose a non-empty Markdown file no larger than 128 KB.', 'error');
    return;
  }

  setBusy(true);
  workspace.hidden = true;
  resultsCard.hidden = true;
  showStatus(
    `Reading ${file.name}. Gemini will convert the cases in batches; this may take a few minutes. Nothing runs until you review and confirm.`,
    'working',
  );
  try {
    const markdown = await file.text();
    const session = await requestJson('/api/import-test-cases', {
      markdown,
      target: targetInput.value,
    }, 30 * 60 * 1000);
    showSession(session);
    showStatus(
      `${session.plan.testCases.length} cases imported and prepared. Review every case; tests have not run.`,
      'success',
    );
    planCard.scrollIntoView({ block: 'start' });
  } catch (error) {
    showStatus(error.message, 'error');
  } finally {
    setBusy(false);
  }
});

storyForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (busy) return;
  if (testCaseFile.files.length) {
    showStatus('You selected a Markdown file. To import its test cases, click Import Markdown instead of Generate test plan.', 'error');
    return;
  }
  setBusy(true);
  workspace.hidden = true;
  resultsCard.hidden = true;
  showStatus('Gemini is reading your user story and preparing a test plan...', 'working');
  try {
    const session = await requestJson('/api/plan', {
      story: storyInput.value.trim(),
      target: targetInput.value,
    });
    showSession(session);
    if (session.status === 'needs_answers') {
      showStatus('Gemini has a few questions before it can finalize the test plan.', 'info');
      document.querySelector('#questions-card').scrollIntoView({ block: 'center' });
    } else {
      showStatus('Plan ready. Review the test cases before running them.', 'success');
      planCard.scrollIntoView({ block: 'start' });
    }
  } catch (error) {
    showStatus(error.message, 'error');
  } finally {
    setBusy(false);
  }
});

answerForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!currentSession || busy) return;
  const answers = [...questionsBox.querySelectorAll('textarea')].map((field) => field.value.trim());
  if (answers.some((answer) => !answer)) {
    showStatus('Please answer each clarification question.', 'error');
    return;
  }
  setBusy(true);
  showStatus('Gemini is updating the plan with your answers...', 'working');
  try {
    const session = await requestJson(`/api/clarify/${currentSession.id}`, { answers });
    showSession(session);
    if (session.status === 'needs_answers') {
      showStatus(
        session.source === 'markdown-import'
          ? 'Gemini needs clarification for some imported cases. Answer below; successfully converted batches will be kept.'
          : 'Gemini has a follow-up question. Please answer it to continue.',
        'info',
      );
      questionsCard.scrollIntoView({ block: 'center' });
    } else {
      showStatus('Clarifications complete. Review the final test plan before running it.', 'success');
      planCard.scrollIntoView({ block: 'start' });
    }
  } catch (error) {
    showStatus(error.message, 'error');
  } finally {
    setBusy(false);
  }
});

function renderRunSummary(report) {
  const box = document.createElement('section');
  box.className = 'run-summary';
  if (report.summary) {
    appendText(box, 'h4', '', 'الملخص');
    appendText(box, 'p', 'summary-line', report.summary.summary);
    report.summary.sections.forEach((section, index) => {
      appendText(box, 'h5', '', `${index + 1}. ${section.title}`);
      section.lines.forEach((line) => appendText(box, 'p', '', line));
    });
    if (report.summary.bugDrafts.length) {
      appendText(box, 'h4', '', 'Bug drafts (not opened in DevOps)');
      report.summary.bugDrafts.forEach((bug) => {
        const pre = appendText(box, 'pre', 'bug-draft', bug.text);
        pre.dir = 'ltr';
        const copyButton = appendText(box, 'button', 'button button-secondary copy-button', 'Copy');
        copyButton.type = 'button';
        copyButton.addEventListener('click', () => navigator.clipboard.writeText(bug.text));
      });
    }
  } else if (report.summaryError) {
    appendText(box, 'p', 'result-note', `The Arabic summary could not be written: ${report.summaryError}`);
  }
  resultsBox.append(box);
}

runButton.addEventListener('click', async () => {
  if (!currentSession || busy || currentSession.status !== 'ready') return;
  const targetName = currentSession.target === 'desktop' ? 'Minerets desktop app' : 'QA web portal';
  const confirmed = window.confirm(
    `Run ${currentSession.plan.testCases.length} test cases against the ${targetName}?\n\n` +
    'This is the QA environment. The tests may create or update QA test data. Review the plan before continuing.',
  );
  if (!confirmed) return;

  setBusy(true);
  currentSession.status = 'running';
  renderPlan(currentSession);
  showStatus('Playwright is running the reviewed test plan. Please keep this page open...', 'working');
  try {
    // Desktop runs take a few seconds per step, so allow long runs.
    const result = await requestJson(`/api/execute/${currentSession.id}`, { confirmed: true }, 60 * 60 * 1000);
    currentSession.status = 'completed';
    resultsBox.replaceChildren();
    const failures = result.report.results.filter((item) => item.status === 'failed').length;
    resultCount.textContent = `${result.report.results.length - failures} passed · ${failures} failed`;
    result.report.results.forEach((item) => {
      const row = document.createElement('div');
      row.className = 'result-row';
      appendText(row, 'span', `result-mark${item.status === 'failed' ? ' failed' : ''}`,
        item.status === 'passed' ? '✓' : '!');
      const copy = document.createElement('div');
      copy.className = 'result-copy';
      appendText(copy, 'strong', '', `${item.id} · ${item.title}`);
      if (item.error) appendText(copy, 'p', '', item.error);
      (item.notes || []).forEach((note) => appendText(copy, 'p', 'result-note', note));
      (item.checks || []).forEach((check) => {
        const line = check.expression
          ? `${check.pass ? '✓' : '✗'} ${check.expression} = ${check.left} ${check.op} ${check.value} = ${check.right}`
          : `${check.pass ? '✓' : '✗'} {${check.var}} = "${check.actual}"`;
        appendText(copy, 'p', 'result-note', line).dir = 'ltr';
      });
      const files = [...(item.evidence || []), ...(item.screenshot ? [item.screenshot] : [])];
      if (files.length) appendText(copy, 'p', 'result-note', `Evidence: ${files.join(', ')}`);
      row.append(copy);
      resultsBox.append(row);
    });
    renderRunSummary(result.report);
    resultsCard.hidden = false;
    showStatus('Test run finished. See the report below.', failures ? 'error' : 'success');
    resultsCard.scrollIntoView({ block: 'start' });
  } catch (error) {
    currentSession.status = 'failed';
    renderPlan(currentSession);
    showStatus(error.message, 'error');
  } finally {
    setBusy(false);
  }
});

// ---- Chat --------------------------------------------------------------------------------
const chatLog = document.querySelector('#chat-log');
const chatForm = document.querySelector('#chat-form');
const chatInput = document.querySelector('#chat-input');
const chatSend = document.querySelector('#chat-send');
const chatAutoRun = document.querySelector('#chat-autorun');
const chatTarget = document.querySelector('#chat-target');
let chatId = null;

function chatBubble(kind, text) {
  const bubble = appendText(chatLog, 'div', `chat-bubble chat-${kind}`, text);
  chatLog.scrollTop = chatLog.scrollHeight;
  return bubble;
}

function chatPlan(plan) {
  const details = document.createElement('details');
  details.className = 'chat-plan';
  appendText(details, 'summary', '', `${plan.summary} (${plan.testCases.length} cases)`);
  plan.testCases.forEach((testCase) => {
    appendText(details, 'strong', '', `${testCase.id} · ${testCase.title}`).dir = 'ltr';
    const steps = document.createElement('ol');
    testCase.steps.forEach((step) => appendText(steps, 'li', '', describeStep(step)));
    details.append(steps);
  });
  chatLog.append(details);
}

function chatReport(report) {
  const box = document.createElement('div');
  box.className = 'chat-bubble chat-agent chat-report';
  const failures = report.results.filter((item) => item.status === 'failed').length;
  appendText(box, 'strong', '', `${report.results.length - failures} passed · ${failures} failed`).dir = 'ltr';
  report.results.forEach((item) => {
    appendText(box, 'p', item.status === 'failed' ? 'chat-fail' : '', `${item.status === 'passed' ? '✓' : '✗'} ${item.id} · ${item.title}`).dir = 'ltr';
    if (item.error) appendText(box, 'p', 'chat-fail', item.error).dir = 'ltr';
    (item.checks || []).forEach((check) => {
      const line = check.expression
        ? `${check.pass ? '✓' : '✗'} ${check.expression} = ${check.left} ${check.op} ${check.value} = ${check.right}`
        : `${check.pass ? '✓' : '✗'} {${check.var}} = "${check.actual}"`;
      appendText(box, 'p', 'chat-check', line).dir = 'ltr';
    });
    const files = [...(item.evidence || []), ...(item.screenshot ? [item.screenshot] : [])];
    if (files.length) appendText(box, 'p', 'chat-check', `Evidence: ${files.join(', ')}`).dir = 'ltr';
  });
  if (report.summary) {
    appendText(box, 'p', 'summary-line', report.summary.summary);
    report.summary.sections.forEach((section, index) => {
      appendText(box, 'h5', '', `${index + 1}. ${section.title}`);
      section.lines.forEach((line) => appendText(box, 'p', '', line));
    });
    report.summary.bugDrafts.forEach((bug) => {
      appendText(box, 'pre', 'bug-draft', bug.text).dir = 'ltr';
      const copyButton = appendText(box, 'button', 'button button-secondary copy-button', 'Copy');
      copyButton.type = 'button';
      copyButton.addEventListener('click', () => navigator.clipboard.writeText(bug.text));
    });
  } else if (report.summaryError) {
    appendText(box, 'p', 'chat-fail', report.summaryError);
  }
  chatLog.append(box);
  chatLog.scrollTop = chatLog.scrollHeight;
}

function chatAgent(result) {
  const box = document.createElement('div');
  box.className = 'chat-bubble chat-agent chat-report';
  const label = { passed: 'تمّ بنجاح', failed: 'فيه فشل', blocked: 'ما قدرت أكمّل' }[result.status] || result.status;
  appendText(box, 'strong', '', label);
  result.report.forEach((line) => appendText(box, 'p', '', line));
  result.checks.forEach((check) => {
    appendText(box, 'p', 'chat-check', `${check.pass ? '✓' : '✗'} ${check.expression} = ${check.left} ${check.op} ${check.value} = ${check.right}`).dir = 'ltr';
  });
  if (result.learned.length) appendText(box, 'p', 'chat-check', `Learned: ${result.learned.join(' | ')}`).dir = 'ltr';
  if (result.evidence.length) appendText(box, 'p', 'chat-check', `Evidence: ${result.evidence.join(', ')}`).dir = 'ltr';
  result.bugDrafts.forEach((bug) => {
    appendText(box, 'pre', 'bug-draft', bug.text).dir = 'ltr';
    const copyButton = appendText(box, 'button', 'button button-secondary copy-button', 'Copy');
    copyButton.type = 'button';
    copyButton.addEventListener('click', () => navigator.clipboard.writeText(bug.text));
  });
  const steps = document.createElement('details');
  appendText(steps, 'summary', '', `الخطوات اللي عملها (${result.log.length})`);
  const list = document.createElement('ol');
  result.log.forEach((entry) => {
    const text = entry.note || entry.error && !entry.action ? (entry.note || entry.error)
      : `${JSON.stringify(entry.action)} → ${entry.error ? 'ERROR: ' + entry.error : entry.result}`;
    appendText(list, 'li', entry.error ? 'chat-fail' : 'chat-check', text).dir = 'ltr';
  });
  steps.append(list);
  box.append(steps);
  chatLog.append(box);
  chatLog.scrollTop = chatLog.scrollHeight;
}

chatForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const message = chatInput.value.trim();
  if (!message || chatSend.disabled) return;
  chatBubble('user', message);
  chatInput.value = '';
  chatSend.disabled = true;
  const waiting = chatBubble('status', chatAutoRun.checked ? 'عم بفكّر، وإذا في شغل بنفّذه هلأ...' : 'عم بفكّر...');
  try {
    const answer = await requestJson('/api/chat', {
      chatId,
      message,
      target: chatTarget.value,
      autoRun: chatAutoRun.checked,
    }, 60 * 60 * 1000);
    chatId = answer.chatId;
    waiting.remove();
    chatBubble('agent', answer.reply);
    if (answer.plan) chatPlan(answer.plan);
    if (answer.report) chatReport(answer.report);
    if (answer.agent) chatAgent(answer.agent);
    if (answer.runError) chatBubble('status', answer.runError);
  } catch (error) {
    waiting.remove();
    chatBubble('status', error.message);
  } finally {
    chatSend.disabled = false;
    chatInput.focus();
  }
});

chatInput.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && !event.shiftKey) {
    event.preventDefault();
    chatForm.requestSubmit();
  }
});

document.querySelector('#chat-new').addEventListener('click', () => {
  chatId = null;
  chatLog.replaceChildren();
  chatInput.focus();
});
