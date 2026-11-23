#!/usr/bin/env node
'use strict';

const fs = require('node:fs');
const path = require('node:path');
const readline = require('node:readline/promises');
const { stdin, stdout } = require('node:process');
const { GoogleGenAI } = require('@google/genai');
const { chromium } = require('@playwright/test');
const dotenv = require('dotenv');
const { parseMarkdownTestCases } = require('./test-case-import');
const { createUiaSession } = require('./desktop-session');
const {
  COMPARE_OPS,
  VARIABLE_NAME,
  compareNumbers,
  evaluateExpression,
  expressionVariables,
  formatNumber,
  parseNumber,
} = require('./calc');

const ROOT = path.resolve(__dirname, '..');
const RUN_ID = Date.now().toString(36).toUpperCase();
const DEFAULT_PORTAL_EXE = 'C:\\Users\\m.alshellah\\Downloads\\MacOne\\Minerets.Shop.MacOne.exe';
const MAX_CASES = 100;
const CASES_PER_IMPORT_BATCH = 8;
const MAX_IMPORT_BATCH_CLARIFICATION_QUESTIONS = 3;
const MAX_IMPORT_CLARIFICATION_QUESTIONS =
  Math.ceil(MAX_CASES / CASES_PER_IMPORT_BATCH) * MAX_IMPORT_BATCH_CLARIFICATION_QUESTIONS;
const MAX_STEPS_PER_CASE = 30;
const GEMINI_TIMEOUT_MS = 90_000;

dotenv.config({ path: path.join(__dirname, '.env'), quiet: true });
dotenv.config({ path: path.join(ROOT, '.env'), quiet: true });

const STEP_ACTIONS = new Set([
  'open', 'click', 'fill', 'select', 'expectVisible', 'expectText', 'screenshot',
  'readValue', 'readCell', 'expectNumber', 'expectValue',
]);
const SCREENSHOT_NAME = /^[A-Za-z0-9_-]{1,60}$/;
const LOCATOR_TYPES = new Set(['role', 'label', 'placeholder', 'text']);
// Sensitive clicks run only when the user's own request asks for that kind of action
// (the request text decides, never Gemini). On the desktop app "Cancel" also closes popups,
// so it is always allowed there; on the web portal a toolbar Cancel cancels a document.
const GUARDED_CLICKS = [
  { key: 'delete', name: /\b(delete|remove)\b/i, request: /delete|remove|حذف|احذف|امسح|مسح/i },
  { key: 'void', name: /\bvoid\b/i, request: /void|فويد|الغ|إلغ/i },
  { key: 'refund', name: /\brefund\b/i, request: /refund|return|ارجاع|إرجاع|مرتجع|رجّع|رجع/i },
  { key: 'cancel', name: /\bcancel\b/i, request: /cancel|كانسل|الغ|إلغ/i, desktop: true },
  { key: 'close', name: /\bclose (register|day)\b/i, request: /close (register|day)|تسكير|سكّر|سكر|اغلاق|إغلاق/i },
];

function allowedClicksFor(requestText, target) {
  const text = String(requestText || '');
  return GUARDED_CLICKS
    .filter((guard) => (guard.desktop && target === 'desktop') || guard.request.test(text))
    .map((guard) => guard.key);
}

function usage() {
  return [
    'Usage:',
    '  npm start -- --target web "As a user, I want to ... "',
    '  npm start -- --target web --execute "As a user, I want to ... "',
    '  npm start -- --target desktop --execute "As a user, I want to ... "',
    '  npm start -- --plan .\\MAC1-Desktop-QA-Assistant\\output\\qa-agent-<id>-plan.json --execute',
    '',
    'Options:',
    '  --target <web|desktop>  QA browser portal or the MacOne desktop app (default: web)',
    '  --plan <path>           Load a previously generated plan instead of calling Gemini',
    '  --execute               Run the generated test steps after showing the plan',
    '  --help                  Show this help',
    '',
    'Execution always asks for confirmation. Stories and reports stay in MAC1-Desktop-QA-Assistant/output/.',
  ].join('\n');
}

function parseArgs(argv) {
  const options = { target: null, planFile: null, execute: false, help: false, storyParts: [] };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--execute') {
      options.execute = true;
    } else if (arg === '--target') {
      const target = argv[index + 1];
      if (!target || !['web', 'desktop'].includes(target)) {
        throw new Error('--target must be either "web" or "desktop".');
      }
      options.target = target;
      index += 1;
    } else if (arg === '--plan') {
      const planFile = argv[index + 1];
      if (!planFile || planFile.startsWith('--')) {
        throw new Error('--plan requires a plan JSON path.');
      }
      options.planFile = planFile;
      index += 1;
    } else if (arg.startsWith('--')) {
      throw new Error(`Unknown option: ${arg}`);
    } else {
      options.storyParts.push(arg);
    }
  }
  options.story = options.storyParts.join(' ').trim();
  return options;
}

function isQaHostname(hostname) {
  const host = hostname.toLowerCase();
  return host === 'qa.minerets.com' ||
    host.endsWith('.qa.minerets.com') ||
    (host.startsWith('qa.') && host.endsWith('.minerets.com'));
}

function validateLocator(target, context) {
  if (!target || typeof target !== 'object' || !LOCATOR_TYPES.has(target.by)) {
    throw new Error(`${context} must use a supported locator: role, label, placeholder, or text.`);
  }
  if (typeof target.name !== 'string' || !target.name.trim() || target.name.length > 200) {
    throw new Error(`${context} needs a non-empty locator name (maximum 200 characters).`);
  }
  if (target.by === 'role' && (typeof target.role !== 'string' || !target.role.trim())) {
    throw new Error(`${context} using "role" must include a role name.`);
  }
}

function validatePlan(plan, {
  maxClarificationQuestions = 3, allowedClicks: allowedOption, maxSteps = MAX_STEPS_PER_CASE,
} = {}) {
  if (!plan || typeof plan !== 'object' || Array.isArray(plan)) {
    throw new Error('Gemini returned an invalid test plan.');
  }
  // allowedClicks comes from our own code (computed from the user's request), never from Gemini.
  const allowedClicks = Array.isArray(allowedOption) ? allowedOption
    : (Array.isArray(plan.allowedClicks) ? plan.allowedClicks : []);
  if (typeof plan.summary !== 'string' || !plan.summary.trim()) {
    throw new Error('The plan is missing a summary.');
  }
  if (!Array.isArray(plan.acceptanceCriteria) || plan.acceptanceCriteria.length < 1 ||
      plan.acceptanceCriteria.some((item) => typeof item !== 'string' || !item.trim())) {
    throw new Error('The plan must contain non-empty acceptance criteria.');
  }
  if (plan.clarificationQuestions === undefined) plan.clarificationQuestions = [];
  if (!Array.isArray(plan.clarificationQuestions) ||
      plan.clarificationQuestions.length > maxClarificationQuestions ||
      plan.clarificationQuestions.some((item) => typeof item !== 'string' || !item.trim() || item.length > 500)) {
    throw new Error(`The plan can contain up to ${maxClarificationQuestions} non-empty clarification questions.`);
  }
  if (!Array.isArray(plan.testCases) || plan.testCases.length < 1 || plan.testCases.length > MAX_CASES) {
    throw new Error(`The plan must contain between 1 and ${MAX_CASES} test cases.`);
  }

  const ids = new Set();
  const qaNames = new Set();
  for (const [caseIndex, testCase] of plan.testCases.entries()) {
    const context = `Test case ${caseIndex + 1}`;
    if (!testCase || typeof testCase !== 'object' || Array.isArray(testCase)) {
      throw new Error(`${context} is invalid.`);
    }
    if (typeof testCase.id !== 'string' || !testCase.id.trim() || ids.has(testCase.id)) {
      throw new Error(`${context} needs a unique ID.`);
    }
    ids.add(testCase.id);
    if (typeof testCase.title !== 'string' || !testCase.title.trim()) {
      throw new Error(`${context} is missing a title.`);
    }
    if (!Array.isArray(testCase.steps) || testCase.steps.length < 1 || testCase.steps.length > maxSteps) {
      throw new Error(`${context} must have between 1 and ${maxSteps} steps.`);
    }
    if (testCase.preconditions !== undefined &&
        (!Array.isArray(testCase.preconditions) ||
          testCase.preconditions.some((item) => typeof item !== 'string'))) {
      throw new Error(`${context} has invalid preconditions.`);
    }

    const readNames = new Set();
    for (const [stepIndex, step] of testCase.steps.entries()) {
      const stepContext = `${context}, step ${stepIndex + 1}`;
      if (!step || typeof step !== 'object' || !STEP_ACTIONS.has(step.action)) {
        throw new Error(`${stepContext} (${testCase.id}) uses an unsupported action "${step?.action}".`);
      }
      if (step.action === 'readValue' || step.action === 'readCell') {
        if (typeof step.as !== 'string' || !VARIABLE_NAME.test(step.as)) {
          throw new Error(`${stepContext} needs "as": a value name of letters, digits and _ (starting with a letter).`);
        }
        if (step.action === 'readValue') {
          validateLocator(step.target, stepContext);
        } else {
          for (const key of ['row', 'column']) {
            if (typeof step[key] !== 'string' || !step[key].trim() || step[key].length > 200) {
              throw new Error(`${stepContext} needs a "${key}" text.`);
            }
          }
          if (step.rowAlso !== undefined && (typeof step.rowAlso !== 'string' || step.rowAlso.length > 200)) {
            throw new Error(`${stepContext} has an invalid "rowAlso".`);
          }
        }
        readNames.add(step.as);
        continue;
      }
      if (step.action === 'expectNumber') {
        const sides = [step.expression, step.value];
        if (typeof step.expression !== 'string' || !step.expression.trim() || step.expression.length > 300 ||
            !['string', 'number'].includes(typeof step.value) || String(step.value).length > 300) {
          throw new Error(`${stepContext} needs an "expression" and a "value" to compare.`);
        }
        if (!COMPARE_OPS.has(step.op ?? '=')) {
          throw new Error(`${stepContext} uses an unsupported comparison; use =, !=, <, <=, > or >=.`);
        }
        if (step.tolerance !== undefined &&
            (typeof step.tolerance !== 'number' || step.tolerance < 0 || step.tolerance > 1_000_000)) {
          throw new Error(`${stepContext} has an invalid tolerance.`);
        }
        for (const side of sides) {
          for (const name of expressionVariables(side)) {
            if (!readNames.has(name)) throw new Error(`${stepContext} uses {${name}} before it is read.`);
          }
          evaluateExpression(side, Object.fromEntries([...readNames].map((name) => [name, 1])));
        }
        continue;
      }
      if (step.action === 'expectValue') {
        if (typeof step.var !== 'string' || !readNames.has(step.var)) {
          throw new Error(`${stepContext} must name a value read earlier in "var".`);
        }
        const hasEquals = typeof step.equals === 'string';
        const hasContains = typeof step.contains === 'string';
        if (hasEquals === hasContains) {
          throw new Error(`${stepContext} needs exactly one of "equals" or "contains".`);
        }
        continue;
      }
      if (step.optional !== undefined && typeof step.optional !== 'boolean') {
        throw new Error(`${stepContext} has an invalid "optional" flag.`);
      }
      if (step.action === 'open') {
        if (typeof step.path !== 'string' || !step.path.trim() || step.path.length > 500) {
          throw new Error(`${stepContext} needs a relative page path.`);
        }
        if (/^[a-z][a-z\d+.-]*:/i.test(step.path) || step.path.startsWith('//')) {
          throw new Error(`${stepContext} must not navigate to another origin.`);
        }
      } else if (step.action === 'expectText') {
        if (typeof step.text !== 'string' || !step.text.trim() || step.text.length > 500) {
          throw new Error(`${stepContext} needs expected text.`);
        }
      } else if (step.action === 'screenshot') {
        if (typeof step.name !== 'string' || !SCREENSHOT_NAME.test(step.name)) {
          throw new Error(`${stepContext} needs a screenshot name of letters, digits, _ or - (maximum 60).`);
        }
      } else {
        validateLocator(step.target, stepContext);
        if (step.action === 'fill' || step.action === 'select') {
          if (typeof step.value !== 'string' || step.value.length > 500) {
            throw new Error(`${stepContext} needs a value of at most 500 characters.`);
          }
          if (step.value.startsWith('QA_AI_') && !step.value.includes('{RUN_ID}')) {
            throw new Error(`${stepContext} QA_AI_ data must include {RUN_ID} to avoid collisions.`);
          }
          if (step.newRecordName !== undefined && typeof step.newRecordName !== 'boolean') {
            throw new Error(`${stepContext} has an invalid newRecordName flag.`);
          }
          if (step.newRecordName) {
            if (step.action !== 'fill' || !/^QA_AI_\{RUN_ID\}_\S/.test(step.value)) {
              throw new Error(`${stepContext} new record names must use QA_AI_{RUN_ID}_...`);
            }
            if (qaNames.has(step.value)) {
              throw new Error(`${stepContext} reuses a QA record name from another test.`);
            }
            qaNames.add(step.value);
          }
        }
        if (step.action === 'click') {
          const guard = GUARDED_CLICKS.find((item) => item.name.test(step.target.name));
          if (guard && !allowedClicks.includes(guard.key)) {
            throw new Error(`${stepContext} targets a destructive action (${guard.key}) that the request did not ask for, so it is blocked.`);
          }
        }
      }
    }
  }
  return plan;
}

function parsePlanResponse(text, options) {
  if (typeof text !== 'string' || !text.trim()) {
    throw new Error('Gemini returned an empty response.');
  }
  const jsonText = text.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  let plan;
  try {
    plan = JSON.parse(jsonText);
  } catch (error) {
    throw new Error(`Gemini did not return valid JSON: ${error.message}`);
  }
  if (plan && typeof plan === 'object') delete plan.allowedClicks;   // only our code sets this
  // Gemini sometimes asks one question too many; keep the first ones instead of failing the whole plan.
  const maxQuestions = options?.maxClarificationQuestions ?? 3;
  if (plan && Array.isArray(plan.clarificationQuestions)) {
    plan.clarificationQuestions = plan.clarificationQuestions
      .filter((question) => typeof question === 'string' && question.trim())
      .slice(0, maxQuestions)
      .map((question) => (question.length > 500 ? `${question.slice(0, 497)}...` : question));
  }
  return validatePlan(plan, options);
}

function normalizeGeminiError(error) {
  const message = String(error?.message || error || '');
  const status = Number(error?.status || error?.statusCode || message.match(/\b(429|503)\b/)?.[1]);
  if (status === 503 || /currently experiencing high demand|spikes in demand/i.test(message)) {
    return Object.assign(
      new Error('Gemini is temporarily busy (HTTP 503). Your story is safe; wait a moment, then select Generate test plan to retry.'),
      { status: 503 },
    );
  }
  if (status === 429) {
    return Object.assign(
      new Error('Gemini is receiving too many requests (HTTP 429). Wait a moment, then select Generate test plan to retry.'),
      { status: 429 },
    );
  }
  if (/timed out|timeout|aborted/i.test(message) || /Timeout/i.test(error?.name || '')) {
    return Object.assign(
      new Error('Gemini took too long to respond. Your story is safe; select Generate test plan to try again.'),
      { status: 504 },
    );
  }
  return error instanceof Error ? error : new Error('Gemini request failed.');
}

async function askForStory() {
  const terminal = readline.createInterface({ input: stdin, output: stdout });
  try {
    return (await terminal.question('Paste the user story: ')).trim();
  } finally {
    terminal.close();
  }
}

async function askForClarification(questions) {
  const terminal = readline.createInterface({ input: stdin, output: stdout });
  try {
    const answers = [];
    for (const question of questions) {
      const answer = (await terminal.question(`\n${question}\nYour answer: `)).trim();
      if (!answer) throw new Error('Please answer all clarification questions before continuing.');
      answers.push({ question, answer });
    }
    return answers;
  } finally {
    terminal.close();
  }
}

async function confirmExecution(target) {
  if (!stdin.isTTY) {
    throw new Error('Interactive confirmation is required to execute tests. Run this command in a terminal.');
  }
  const terminal = readline.createInterface({ input: stdin, output: stdout });
  try {
    const answer = await terminal.question(
      `\nRun these generated steps against the ${target} QA portal? This may create or update QA test data. [y/N] `,
    );
    return /^y(es)?$/i.test(answer.trim());
  } finally {
    terminal.close();
  }
}

// The desktop app is native (no URLs, no DOM), so plans for it must navigate by visible labels only.
const DESKTOP_GUIDANCE = [
  'Target: the native Windows desktop app (MacOne POS). It has no URLs or page paths, so do not use the open action. The app is already open and signed in.',
  'Navigate only by clicking visible labels such as tabs, menu items, cards, and buttons. Prefer the text locator with the exact visible label; use role only for clear buttons, textboxes, and comboboxes.',
  'Every case starts on the dashboard Overview tab. Before reading or checking anything on another tab, click that tab first, and click it again in each case that needs it.',
];

function targetGuidance(target) {
  return target === 'desktop' ? DESKTOP_GUIDANCE : [];
}

// Team knowledge (working rules, app map, business rules, bug style) lives in knowledge/*.md.
// It is read on every request, so edits to those files apply without restarting the UI.
const KNOWLEDGE_DIR = path.join(__dirname, 'knowledge');

function loadKnowledge(dir = KNOWLEDGE_DIR) {
  let files;
  try {
    files = fs.readdirSync(dir).filter((name) => name.toLowerCase().endsWith('.md')).sort();
  } catch {
    return '';
  }
  return files.map((name) => fs.readFileSync(path.join(dir, name), 'utf8').trim()).join('\n\n');
}

function knowledgeBlock() {
  const knowledge = loadKnowledge();
  if (!knowledge) return [];
  return [
    'Team knowledge. Follow it exactly; it overrides general habits:',
    '<<<KNOWLEDGE',
    knowledge,
    'KNOWLEDGE>>>',
    '',
  ];
}

const OUTPUT_LANGUAGE_RULES = [
  'Write "summary", every "acceptanceCriteria" item, and every "clarificationQuestions" item in Arabic (Levantine dialect), following the language rules in the team knowledge: fully Arabic sentences, English names only on their own line or at the very end.',
  'Write test case titles and preconditions in English. Locator names and expected texts must be the exact English labels shown in the app.',
  'The user may write the request in Arabic. Understand it as the senior QA engineer would, using the team knowledge, before planning.',
];

const SCREENSHOT_RULE =
  'Use {"action":"screenshot","name":"short_name"} (letters, digits, _ or -) to keep evidence of an important screen, usually once at the end of a case. Add "optional":true to a click on a popup that only sometimes appears (for example "Skip" in the mileage popup); it is skipped when the popup does not show.';

// How Gemini checks numbers: read them from the screen into named values, then compare with arithmetic.
const CALCULATION_RULES = [
  'To check any number, KPI, total, count, rate, or formula, never compare numbers with expectText. Read the numbers, then calculate:',
  '{"action":"readValue","target":{"by":"text","name":"<exact label>"},"as":"name"} reads the number shown next to a label (to its right on the same row, or below it in a card). It also reads numbers inside the label text, such as "All (365)" (use the name "All") or "2 Pending" (use the name "Pending"). Percentages are read without the % sign (2.3 for 2.3%).',
  '{"action":"readCell","row":"<text in the row, for example INV - TO_11000093>","column":"<exact column header>","as":"name"} reads one cell of a list; add "rowAlso":"<second text in the same row>" when several rows share the first text. The row must be on screen: search for it first.',
  '{"action":"expectNumber","expression":"{a} + {b}","op":"=","value":"{total}","tolerance":0.01} computes both sides and compares them. Expressions use numbers, {names} read earlier in the same case, + - * / ( ), round(x, digits), abs, min, max. "op" is one of = != < <= > >=.',
  'Tolerance: 0.01 for amounts; for a percentage shown with one decimal use 0.05 and compute it with round(..., 1) or compare with that tolerance; for whole counts use 0.',
  '{"action":"expectValue","var":"name","contains":"Cash"} (or "equals") checks the text of a value read earlier, for example a Method or Status cell.',
  'Values belong to one test case and stay available after switching tabs, so one case can compare a number on Overview with the same number on another tab.',
  'Use the formulas in the team knowledge. Do not check formulas that are waiting for a business decision.',
];

function buildPrompt(story, answers = [], target = 'web') {
  return [
    'You are the senior QA engineer of this team. Turn the request below into an executable UI test plan.',
    ...knowledgeBlock(),
    ...targetGuidance(target),
    ...OUTPUT_LANGUAGE_RULES,
    `Cover every distinct requirement, business rule, KPI, calculation, tab, status, and navigation action the request asks about, as focused, non-duplicate cases (up to ${MAX_CASES}). For a short command, plan only what the command asks.`,
    'Include positive, negative, boundary, and empty or zero-data scenarios wherever expected behavior is defined. Keep behavior that is unspecified or waiting for a business decision out of executable tests.',
    'Return only valid JSON with this shape:',
    '{"summary":"...","clarificationQuestions":["..."],"acceptanceCriteria":["..."],"testCases":[{"id":"TC-01","title":"...","preconditions":["..."],"steps":[{"action":"open","path":"relative/path"},{"action":"click","target":{"by":"role","role":"button","name":"New"}},{"action":"fill","target":{"by":"label","name":"Name"},"value":"QA_AI_{RUN_ID}_example","newRecordName":true},{"action":"select","target":{"by":"label","name":"Kind"},"value":"General"},{"action":"expectVisible","target":{"by":"text","name":"..."}},{"action":"expectText","text":"..."},{"action":"screenshot","name":"overview_tab"}]}]}',
    `Include up to ${MAX_CASES} focused test cases and at most ${MAX_STEPS_PER_CASE} steps per case. Use separate cases for materially different scenarios; do not merge unrelated requirements into one case.`,
    'Ask up to 3 concise clarification questions only when the answer changes the intended behavior, test data, or safe execution. If answers below resolve the uncertainties, return an empty clarificationQuestions array. Do not ask questions already answered.',
    'Only use these actions: open, click, fill, select, expectVisible, expectText, screenshot, readValue, readCell, expectNumber, expectValue.',
    SCREENSHOT_RULE,
    ...CALCULATION_RULES,
    'Only use locator types role, label, placeholder, and text; never use CSS selectors, JavaScript, or code.',
    'Use relative paths only. Prefer checks supported by the story; do not invent URLs, APIs, or hidden selectors.',
    'Do exactly what the request asks on QA, including opening any screen, creating work orders, adding items, paying, syncing, and filling forms. Plan the full flow the user describes, step by step, using the app map labels.',
    'Click delete, remove, void, refund, close day, or close register only when the request asks for that action. On the desktop app, "Cancel" or "X" may be used to close a popup.',
    'For every newly created or edited QA record name, set newRecordName:true and use a unique value starting with QA_AI_{RUN_ID}_. Do not target existing records.',
    'Use empty values only when intentionally testing required-field validation.',
    'Do not include secrets, credentials, or personal data.',
    '',
    'User story:',
    story,
    '',
    'Clarification answers so far:',
    JSON.stringify(answers),
  ].join('\n');
}

async function generatePlan(story, answers = [], target = 'web') {
  const requestText = [story, ...answers.map((item) => item.answer)].join('\n');
  const allowedClicks = allowedClicksFor(requestText, target);
  const plan = await requestPlan(buildPrompt(story, answers, target), { allowedClicks });
  plan.allowedClicks = allowedClicks;
  return plan;
}

function buildImportedCasesPrompt(testCases, batchNumber, batchCount, answers = [], target = 'web') {
  return [
    'You are the senior QA engineer of this team, converting reviewed manual QA test cases into safe, executable UI steps.',
    ...knowledgeBlock(),
    ...targetGuidance(target),
    'Write "summary", every "acceptanceCriteria" item, and every "clarificationQuestions" item in Arabic (Levantine dialect), following the language rules in the team knowledge. Keep IDs, titles, preconditions, and locator names exactly as in the input or the app.',
    SCREENSHOT_RULE,
    ...CALCULATION_RULES,
    `This is batch ${batchNumber} of ${batchCount}. Convert every input case exactly once.`,
    'Preserve every case ID and title exactly. Do not add, remove, combine, split, or reorder cases.',
    'Return only valid JSON with this shape:',
    '{"summary":"...","clarificationQuestions":[],"acceptanceCriteria":["..."],"testCases":[{"id":"TC-POS-001","title":"...","preconditions":["..."],"steps":[{"action":"open","path":"relative/path"},{"action":"click","target":{"by":"role","role":"button","name":"..."}},{"action":"fill","target":{"by":"label","name":"..."},"value":"...","newRecordName":true},{"action":"select","target":{"by":"label","name":"..."},"value":"..."},{"action":"expectVisible","target":{"by":"text","name":"..."}},{"action":"expectText","text":"..."}]}]}',
    `Return exactly ${testCases.length} test cases in the same order as the input. Each case must have 1 to ${MAX_STEPS_PER_CASE} steps.`,
    'Use only actions: open, click, fill, select, expectVisible, expectText, screenshot, readValue, readCell, expectNumber, expectValue. Use only locators role, label, placeholder, and text.',
    'Never invent page paths, controls, test data, or behavior. Use only UI details explicitly supported by the input or the app map. When a manual step cannot be expressed safely with these actions or the necessary UI detail is missing, add a concise clarification question instead of guessing.',
    'When a case needs a new paid sale, create it inside the case with the work order flow in the app map (read the numbers before and after, then check the difference). When it needs data that flow cannot make (returns, deposits, a day with no sales, another user), do not ask about it; check what can be checked on the current data and add the precondition "Needs prepared data: <what>".',
    'Use the expected result as a visible assertion when its exact text is provided. Keep preconditions intact; do not pretend to create fixture data unless the manual steps explicitly do so.',
    'Follow the manual steps, including creating data, when the steps say so. Click delete, remove, void, refund, close day, or close register only when the manual steps ask for that action. On the desktop app, "Cancel" or "X" may be used to close a popup.',
    'Do not generate code, selectors, external navigation, or actions outside the current application.',
    `Ask at most ${MAX_IMPORT_BATCH_CLARIFICATION_QUESTIONS} concise clarification questions for this batch. Prioritize blockers that prevent safe conversion; combine related uncertainties when possible.`,
    '',
    'Clarification answers from the user:',
    JSON.stringify(answers),
    'Resolve only questions answered above. Retain clarificationQuestions only for genuine remaining blockers.',
    '',
    'Manual test cases:',
    JSON.stringify(testCases),
  ].join('\n');
}

async function generatePlanFromMarkdown(
  markdown,
  answers = [],
  previousConversions = [],
  requestGeneratedPlan = requestPlan,
  target = 'web',
) {
  const manualCases = parseMarkdownTestCases(markdown);
  const allowedClicks = allowedClicksFor([markdown, ...answers.map((item) => item.answer)].join('\n'), target);
  const convertedCases = [];
  const conversions = [];
  const questions = [];
  const batchCount = Math.ceil(manualCases.length / CASES_PER_IMPORT_BATCH);
  for (let offset = 0; offset < manualCases.length; offset += CASES_PER_IMPORT_BATCH) {
    const batch = manualCases.slice(offset, offset + CASES_PER_IMPORT_BATCH);
    const batchNumber = Math.floor(offset / CASES_PER_IMPORT_BATCH) + 1;
    const previous = previousConversions.find((conversion) =>
      conversion.batchNumber === batchNumber && conversion.plan.clarificationQuestions.length === 0);
    const plan = previous
      ? previous.plan
      : await requestGeneratedPlan(
        buildImportedCasesPrompt(batch, batchNumber, batchCount, answers, target),
        { maxClarificationQuestions: MAX_IMPORT_BATCH_CLARIFICATION_QUESTIONS, allowedClicks },
      );
    const expectedIds = batch.map((testCase) => testCase.id);
    const actualIds = plan.testCases.map((testCase) => testCase.id);
    if (JSON.stringify(actualIds) !== JSON.stringify(expectedIds)) {
      throw new Error(
        `Gemini did not preserve the IDs and order for imported cases ${expectedIds.join(', ')}. No plan was saved.`,
      );
    }
    for (let index = 0; index < batch.length; index += 1) {
      if (plan.testCases[index].title !== batch[index].title) {
        throw new Error(`Gemini changed the title for ${batch[index].id}. No plan was saved.`);
      }
    }
    convertedCases.push(...plan.testCases);
    conversions.push({ batchNumber, plan });
    questions.push(...plan.clarificationQuestions);
  }

  if (convertedCases.length !== manualCases.length) {
    throw new Error('Not all imported test cases were converted. No plan was saved.');
  }

  const convertedPlan = validatePlan({
    summary: `جهّزت الحالات من الملف وصارت جاهزة للمراجعة. عددها: ${convertedCases.length}`,
    clarificationQuestions: [...new Set(questions)],
    acceptanceCriteria: manualCases.map(({ id, title }) => `${id}: ${title}`),
    testCases: convertedCases,
    allowedClicks,
  }, { maxClarificationQuestions: MAX_IMPORT_CLARIFICATION_QUESTIONS });
  return { plan: convertedPlan, conversions };
}

// A plan that breaks the format (for example an unknown action) is sent back once with the reason,
// so one bad batch does not stop a whole import.
async function requestPlan(prompt, validationOptions, requestJson = requestGeminiJson) {
  const first = await requestJson(prompt);
  try {
    return parsePlanResponse(first, validationOptions);
  } catch (error) {
    const retryPrompt = [
      prompt,
      '',
      `Your previous answer was rejected: ${error.message}`,
      'Return the corrected JSON only, using only the allowed actions and fields.',
    ].join('\n');
    return parsePlanResponse(await requestJson(retryPrompt), validationOptions);
  }
}

async function requestGeminiJson(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is missing. Set it in MAC1-Desktop-QA-Assistant/.env.');
  }
  const ai = new GoogleGenAI({
    apiKey,
    apiVersion: 'v1beta',
    httpOptions: {
      timeout: GEMINI_TIMEOUT_MS,
      retryOptions: { attempts: 1 },
    },
  });
  let response;
  try {
    response = await ai.interactions.create({
      model: process.env.GEMINI_MODEL || 'gemini-flash-lite-latest',
      input: prompt,
      response_format: {
        type: 'text',
        mime_type: 'application/json',
      },
      generation_config: {
        temperature: 0.2,
        max_output_tokens: 16_384,
      },
    }, {
      timeout_ms: GEMINI_TIMEOUT_MS,
      retries: { strategy: 'none' },
    });
  } catch (error) {
    throw normalizeGeminiError(error);
  }
  if (response.status !== 'completed') {
    throw new Error(`Gemini interaction did not complete successfully (status: ${response.status}).`);
  }
  return response.output_text;
}

// After a run, Gemini writes the Arabic summary and English bug drafts the way the team does.
function buildRunReportPrompt(story, plan, results, target) {
  const cases = plan.testCases.map((testCase) => {
    const result = results.find((item) => item.id === testCase.id) || {};
    return {
      id: testCase.id,
      title: testCase.title,
      steps: testCase.steps,
      status: result.status,
      error: result.error,
      notes: result.notes,
      values: result.values,
      checks: result.checks,
      evidence: [...(result.evidence || []), ...(result.screenshot ? [result.screenshot] : [])]
        .map((file) => path.basename(file)),
    };
  });
  return [
    'You are the senior QA engineer of this team. A test run just finished. Report it to the user.',
    ...knowledgeBlock(),
    `Target: ${target === 'desktop' ? 'MacOne desktop app' : 'QA web portal'}.`,
    'Return only valid JSON with this shape:',
    '{"summary":"...","sections":[{"title":"...","lines":["..."]}],"bugDrafts":[{"title":"MAC1 - <Screen> | ...","severity":"Low|Medium|High","testCases":"TC-..","steps":["..."],"actual":["..."],"expected":"...","evidence":"..."}]}',
    'summary: one Arabic line with how many cases passed and failed.',
    'Each case lists the numbers read from the screen ("values") and every calculation check ("checks": expression, its result, the compared value, pass). Show the real numbers in the sections, for example the two sides of a failed check, each number on its own line.',
    'sections: numbered Arabic sections as in the run summary style (what passed, what failed and why, what needs a business decision, what needs a check of the test itself). Each line is a short Arabic sentence; put English names on their own line inside the lines array, never inside an Arabic sentence.',
    'bugDrafts: only for failures that are product defects according to the team knowledge. Do not draft bugs for automation problems (a label not found because the plan guessed it), for known open defects already listed, or for items waiting for a business decision. Write bug drafts in English in the team bug style, with steps taken from the case.',
    'Never claim a bug was opened in Azure DevOps; these are drafts for the user to review.',
    '',
    'Original request:',
    story,
    '',
    'Executed cases with results:',
    JSON.stringify(cases),
  ].join('\n');
}

function validateRunReport(report) {
  const isText = (value) => typeof value === 'string' && value.trim().length > 0;
  if (!report || typeof report !== 'object' || !isText(report.summary)) {
    throw new Error('Gemini returned an invalid run report.');
  }
  const sections = Array.isArray(report.sections) ? report.sections : [];
  const bugDrafts = Array.isArray(report.bugDrafts) ? report.bugDrafts : [];
  return {
    summary: report.summary.trim(),
    sections: sections
      .filter((section) => section && isText(section.title))
      .map((section) => ({
        title: section.title.trim(),
        lines: (Array.isArray(section.lines) ? section.lines : []).filter(isText).map((line) => line.trim()),
      })),
    bugDrafts: bugDrafts
      .filter((bug) => bug && isText(bug.title))
      .map((bug) => ({
        title: bug.title.trim(),
        severity: isText(bug.severity) ? bug.severity.trim() : 'Medium',
        testCases: isText(bug.testCases) ? bug.testCases.trim() : '',
        steps: (Array.isArray(bug.steps) ? bug.steps : []).filter(isText),
        actual: (Array.isArray(bug.actual) ? bug.actual : []).filter(isText),
        expected: isText(bug.expected) ? bug.expected.trim() : '',
        evidence: isText(bug.evidence) ? bug.evidence.trim() : '',
      })),
  };
}

function formatBugDraft(bug) {
  const lines = [`Title: ${bug.title}`, `Severity: ${bug.severity}`];
  if (bug.testCases) lines.push(`Test case: ${bug.testCases}`);
  lines.push('', 'Steps:', ...bug.steps.map((step, index) => `${index + 1}. ${step.replace(/^\d+\.\s*/, '')}`));
  if (bug.actual.length) lines.push('', 'Actual:', ...bug.actual);
  if (bug.expected) lines.push('', 'Expected:', bug.expected);
  if (bug.evidence) lines.push('', `Evidence: ${bug.evidence}`);
  return lines.join('\n');
}

function renderRunReportMarkdown(report) {
  const parts = [`# تقرير التشغيل`, '', report.summary, ''];
  report.sections.forEach((section, index) => {
    parts.push(`## ${index + 1}. ${section.title}`, '', ...section.lines.map((line) => `${line}  `), '');
  });
  if (report.bugDrafts.length) {
    parts.push('## Bug drafts (not opened in DevOps)', '');
    for (const bug of report.bugDrafts) parts.push('```', formatBugDraft(bug), '```', '');
  }
  return `${parts.join('\n').trim()}\n`;
}

// ---- Chat --------------------------------------------------------------------------------
// The user talks to the agent like a colleague. Each turn Gemini answers in Arabic and, when the
// message asks for work in the app, returns a plan that the server runs right away. Run results go
// back into the conversation, so follow-up questions ("why did it fail?") have the facts.

const MAX_CHAT_HISTORY = 24;

function formatResultsForChat(results, report) {
  const lines = ['Run results:'];
  for (const result of results) {
    lines.push(`${result.id} ${result.status}: ${result.title}${result.error ? ` | error: ${result.error}` : ''}`);
    for (const [name, value] of Object.entries(result.values || {})) lines.push(`  value ${name} = ${value.text} (${value.source})`);
    for (const check of result.checks || []) {
      lines.push(check.expression
        ? `  check ${check.expression} = ${check.left} ${check.op} ${check.value} = ${check.right}: ${check.pass ? 'pass' : 'FAIL'}`
        : `  check {${check.var}} = "${check.actual}": ${check.pass ? 'pass' : 'FAIL'}`);
    }
    for (const note of result.notes || []) lines.push(`  note: ${note}`);
  }
  if (report) {
    lines.push(`Report: ${report.summary}`);
    for (const section of report.sections) lines.push(`${section.title}: ${section.lines.join(' ')}`);
    for (const bug of report.bugDrafts) lines.push(`Bug draft: ${bug.title}`);
  }
  return lines.join('\n');
}

function buildChatPrompt(history, message, target) {
  const recent = history.slice(-MAX_CHAT_HISTORY).map((entry) => ({
    from: entry.role,
    text: String(entry.text).slice(0, 6_000),
  }));
  if (target === 'desktop') {
    // On the desktop app the work is done by the interactive agent, which looks at the screen as it goes.
    return [
      'You are the senior QA engineer of this team and the user\'s smart assistant, talking with the QA tester in a chat window, exactly the way the team knowledge describes.',
      ...knowledgeBlock(),
      'Return only valid JSON: {"reply":"...","task":null} or {"reply":"...","task":"<the full task for the app, in detail>"}',
      '"reply" is what you say to the user: Arabic (Levantine dialect), short, plain lines, numbered when listing, no markdown tables, no emojis, English names only on their own line.',
      'When the message asks you to do, test, check, explore, open, create, pay, fix, or retry anything in the app, put the whole job in "task" (include every detail from the user and from the conversation, for example earlier failures to avoid) and say in "reply" in one line what you are doing. Never refuse, never ask for permission, never reduce the job. A screen-reading agent does the task right after your answer and reports back in the conversation.',
      'When the message is a question or discussion, answer it from the team knowledge and the conversation (including earlier results) and set "task" to null.',
      'Ask a question (task null) only when nothing sensible can be done without the answer.',
      'Never claim that something was done unless the results in the conversation say so.',
      '',
      'Conversation so far (oldest first):',
      JSON.stringify(recent),
      '',
      'New message from the user:',
      message,
    ].join('\n');
  }
  return [
    'You are the senior QA engineer of this team, talking with the QA tester in a chat window, exactly the way the team knowledge describes.',
    ...knowledgeBlock(),
    ...targetGuidance(target),
    'Return only valid JSON: {"reply":"...","plan":null} or {"reply":"...","plan":{"summary":"...","acceptanceCriteria":["..."],"clarificationQuestions":[],"testCases":[{"id":"TC-01","title":"...","preconditions":["..."],"steps":[...]}]}}',
    '"reply" is what you say to the user: Arabic (Levantine dialect), short, plain lines, numbered when listing, no markdown tables, no emojis, English names only on their own line.',
    'When the message asks you to do, test, check, open, create, pay, or run anything in the app, return a "plan" that does the whole thing now, and say in "reply" in one or two lines what you are doing. Do not ask for permission; the system runs the plan right after your answer and adds the results to the conversation.',
    'When the message is a question or discussion, answer it from the team knowledge and the conversation (including earlier run results) and set "plan" to null.',
    'Ask numbered questions (plan null) only when something essential is missing and cannot be taken from the knowledge, the conversation, or a sensible default.',
    'Never claim that something ran or passed unless the run results in the conversation say so.',
    `Plan steps: at most ${MAX_STEPS_PER_CASE} per case; split long flows into several cases. Write test case titles in English and the plan summary and criteria in Arabic.`,
    'Allowed actions: open, click, fill, select, expectVisible, expectText, screenshot, readValue, readCell, expectNumber, expectValue. Locators: role, label, placeholder, text. Step shapes: {"action":"click","target":{"by":"text","name":"..."}}, {"action":"fill","target":{"by":"placeholder","name":"..."},"value":"..."}, {"action":"expectText","text":"..."}.',
    SCREENSHOT_RULE,
    ...CALCULATION_RULES,
    'Click delete, remove, void, refund, close day, or close register only when the user asked for that action. On the desktop app "Cancel" or "X" may close a popup.',
    '',
    'Conversation so far (oldest first):',
    JSON.stringify(recent),
    '',
    'New message from the user:',
    message,
  ].join('\n');
}

async function chatTurn(history, message, target = 'desktop', requestJson = requestGeminiJson) {
  const userText = [...history.filter((entry) => entry.role === 'user').map((entry) => entry.text), message].join('\n');
  const allowedClicks = allowedClicksFor(userText, target);
  const prompt = buildChatPrompt(history, message, target);
  const parse = (text) => {
    const jsonText = String(text || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
    const answer = JSON.parse(jsonText);
    if (!answer || typeof answer.reply !== 'string' || !answer.reply.trim()) {
      throw new Error('The answer needs a non-empty "reply".');
    }
    if (target === 'desktop') {
      const task = typeof answer.task === 'string' && answer.task.trim() ? answer.task.trim() : null;
      return { reply: answer.reply.trim(), task, plan: null, allowedClicks };
    }
    let plan = null;
    if (answer.plan) {
      delete answer.plan.allowedClicks;
      if (!Array.isArray(answer.plan.clarificationQuestions)) answer.plan.clarificationQuestions = [];
      answer.plan.clarificationQuestions = [];   // questions belong in the reply in chat mode
      plan = validatePlan(answer.plan, { allowedClicks });
      plan.allowedClicks = allowedClicks;
    }
    return { reply: answer.reply.trim(), plan };
  };
  const first = await requestJson(prompt);
  try {
    return parse(first);
  } catch (error) {
    const retry = await requestJson(`${prompt}\n\nYour previous answer was rejected: ${error.message}\nReturn the corrected JSON only.`);
    return parse(retry);
  }
}

async function summarizeRun(story, plan, results, target, requestJson = requestGeminiJson) {
  const text = await requestJson(buildRunReportPrompt(story, plan, results, target));
  const jsonText = String(text || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  let parsed;
  try {
    parsed = JSON.parse(jsonText);
  } catch (error) {
    throw new Error(`Gemini did not return a valid run report: ${error.message}`);
  }
  return validateRunReport(parsed);
}

function makeLocator(page, target) {
  switch (target.by) {
    case 'role':
      return page.getByRole(target.role, { name: target.name, exact: true });
    case 'label':
      return page.getByLabel(target.name, { exact: true });
    case 'placeholder':
      return page.getByPlaceholder(target.name, { exact: true });
    case 'text':
      return page.getByText(target.name, { exact: true });
    default:
      throw new Error(`Unsupported locator type: ${target.by}`);
  }
}

function interpolate(value) {
  return value.replaceAll('{RUN_ID}', RUN_ID);
}

async function executeStep(page, step, baseUrl) {
  if (step.action === 'open') {
    const currentUrl = new URL(page.url());
    const destination = new URL(step.path, baseUrl || currentUrl.origin + '/');
    if (destination.origin !== currentUrl.origin) {
      throw new Error(`Blocked navigation outside the current portal origin: ${destination.origin}`);
    }
    await page.goto(destination.href, { waitUntil: 'domcontentloaded' });
    return;
  }
  if (step.action === 'expectText') {
    await page.getByText(step.text, { exact: false }).first().waitFor({ state: 'visible', timeout: 15_000 });
    return;
  }

  const locator = makeLocator(page, step.target).first();
  if (step.action === 'click') {
    await locator.click({ timeout: 15_000 });
  } else if (step.action === 'fill') {
    await locator.fill(interpolate(step.value), { timeout: 15_000 });
  } else if (step.action === 'select') {
    await locator.selectOption({ label: interpolate(step.value) }, { timeout: 15_000 });
  } else if (step.action === 'expectVisible') {
    await locator.waitFor({ state: 'visible', timeout: 15_000 });
  }
}

async function logInIfNeeded(page) {
  const password = page.locator('input[type=password]');
  if (!(await password.isVisible())) return;
  if (!process.env.QA_USERNAME || !process.env.QA_PASSWORD) {
    throw new Error('The QA portal requires login, but QA_USERNAME or QA_PASSWORD is missing from the root .env.');
  }
  const user = page.locator('input[type=text]:not([readonly])').first();
  await user.fill(process.env.QA_USERNAME);
  await password.fill(process.env.QA_PASSWORD);
  await page.getByRole('button', { name: 'Log In', exact: true }).click();
  await password.waitFor({ state: 'hidden', timeout: 60_000 });
}

async function verifyQaPortal(page, target, baseUrl) {
  if (target === 'web' && !isQaHostname(new URL(baseUrl).hostname)) {
    throw new Error('Refusing to run against a non-QA host. QA_BASE_URL must use a QA hostname.');
  }
  const pageUrl = new URL(page.url());
  const content = await page.locator('body').innerText({ timeout: 10_000 }).catch(() => '');
  const qaLabelVisible = /\bQA\b/i.test(content);
  if (!isQaHostname(pageUrl.hostname) && !qaLabelVisible) {
    throw new Error('Could not verify that the open application is a QA environment. No tests were run.');
  }
}

async function guardTopLevelNavigations(context, allowedOrigin) {
  let blockedUrl = null;
  await context.route('**/*', async (route) => {
    const request = route.request();
    if (request.isNavigationRequest() && request.frame().parentFrame() === null &&
        new URL(request.url()).origin !== allowedOrigin) {
      blockedUrl = request.url();
      await route.abort('blockedbyclient');
      return;
    }
    await route.continue();
  });
  return {
    clear() {
      blockedUrl = null;
    },
    assertNoneBlocked() {
      if (blockedUrl) {
        const url = blockedUrl;
        blockedUrl = null;
        throw new Error(`Blocked navigation outside the portal origin: ${url}`);
      }
    },
  };
}

async function createWebSession() {
  const baseUrl = process.env.QA_BASE_URL;
  if (!baseUrl) throw new Error('QA_BASE_URL is missing from the root .env.');
  const parsedUrl = new URL(baseUrl);
  if (parsedUrl.protocol !== 'https:') {
    throw new Error('QA_BASE_URL must use HTTPS.');
  }
  if (!isQaHostname(parsedUrl.hostname)) {
    throw new Error('Refusing to open a non-QA host. QA_BASE_URL must use a QA hostname.');
  }

  const browser = await chromium.launch({ headless: false });
  try {
    const context = await browser.newContext();
    const navigationGuard = await guardTopLevelNavigations(context, parsedUrl.origin);
    const page = await context.newPage();
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 60_000 });
    await logInIfNeeded(page);
    await verifyQaPortal(page, 'web', baseUrl);
    return { browser, context, page, baseUrl, navigationGuard, closeBrowser: true };
  } catch (error) {
    await browser.close();
    throw error;
  }
}

async function createCdpDesktopSession(cdpUrl) {
  const endpoint = new URL(cdpUrl);
  if (!['http:', 'https:'].includes(endpoint.protocol) ||
      !['localhost', '127.0.0.1', '[::1]'].includes(endpoint.hostname)) {
    throw new Error('PORTAL_CDP_URL must point to a localhost WebView2 endpoint.');
  }
  const browser = await chromium.connectOverCDP(endpoint.toString());
  try {
    const context = browser.contexts()[0];
    if (!context) {
      throw new Error('The desktop WebView2 session has no browser context.');
    }
    const page = context.pages()[0];
    if (!page) {
      throw new Error('The desktop WebView2 session has no open portal page.');
    }
    await logInIfNeeded(page);
    await verifyQaPortal(page, 'desktop', process.env.QA_BASE_URL || '');
    const navigationGuard = await guardTopLevelNavigations(context, new URL(page.url()).origin);
    return { browser, context, page, baseUrl: process.env.QA_BASE_URL || '', navigationGuard, closeBrowser: true };
  } catch (error) {
    await browser.close();
    throw error;
  }
}

// The MacOne app is native MAUI / WinUI 3 without WebView2, so it is driven through Windows UI Automation.
// PORTAL_CDP_URL is kept for a future build that does expose a WebView2 debugging endpoint.
async function createDesktopSession() {
  if (process.env.PORTAL_CDP_URL) return createCdpDesktopSession(process.env.PORTAL_CDP_URL);
  if (process.platform !== 'win32') {
    throw new Error('The desktop target runs only on Windows.');
  }
  const exePath = process.env.PORTAL_EXE_PATH || DEFAULT_PORTAL_EXE;
  if (!fs.existsSync(exePath)) {
    throw new Error(`Desktop portal executable not found: ${exePath}. Set PORTAL_EXE_PATH in MAC1-Desktop-QA-Assistant/.env.`);
  }
  const desktop = await createUiaSession(exePath);
  return { desktop };
}

function evidencePath(outputDir, testCase, name) {
  return path.join(outputDir, `qa-agent-${RUN_ID}-${testCase.id.replace(/[^\w-]/g, '_')}-${name}.png`);
}

async function captureScreen(session, filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  if (session.desktop) await session.desktop.screenshot(filePath);
  else await session.page.screenshot({ path: filePath, fullPage: true });
  return path.relative(ROOT, filePath);
}

// readValue / readCell store what the screen shows; expectNumber / expectValue check it.
// Every value and check is kept in the result so the report can show the real numbers.
async function readScreenValue(session, step) {
  if (session.desktop) {
    return step.action === 'readValue'
      ? session.desktop.readValue(step.target)
      : session.desktop.readCell({ row: step.row, column: step.column, rowAlso: step.rowAlso });
  }
  if (step.action === 'readCell') throw new Error('readCell is supported only on the desktop target for now.');
  return normalizeSpace(await makeLocator(session.page, step.target).first().innerText({ timeout: 15_000 }));
}

function normalizeSpace(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}

async function runCalculationStep(session, step, context) {
  if (step.action === 'readValue' || step.action === 'readCell') {
    const text = await readScreenValue(session, step);
    const source = step.action === 'readValue' ? step.target.name : `${step.row} / ${step.column}`;
    context.values[step.as] = { text, value: parseNumber(text), source };
    return true;
  }
  if (step.action === 'expectNumber') {
    const op = step.op || '=';
    const tolerance = step.tolerance ?? 0.01;
    const left = evaluateExpression(step.expression, context.values);
    const right = evaluateExpression(String(step.value), context.values);
    const pass = compareNumbers(left, op, right, tolerance);
    const check = {
      expression: step.expression,
      value: String(step.value),
      op,
      tolerance,
      left: formatNumber(left),
      right: formatNumber(right),
      pass,
    };
    context.checks.push(check);
    if (!pass) {
      throw new Error(`Check failed: ${step.expression} = ${check.left}, expected ${op} ${step.value} = ${check.right} (tolerance ${tolerance}).`);
    }
    return true;
  }
  if (step.action === 'expectValue') {
    const actual = context.values[step.var]?.text ?? '';
    const pass = typeof step.equals === 'string'
      ? normalizeSpace(actual).toLowerCase() === normalizeSpace(step.equals).toLowerCase()
      : normalizeSpace(actual).toLowerCase().includes(normalizeSpace(step.contains).toLowerCase());
    context.checks.push({ var: step.var, actual, equals: step.equals, contains: step.contains, pass });
    if (!pass) {
      throw new Error(`Check failed: {${step.var}} is "${actual}", expected ${step.equals !== undefined ? `"${step.equals}"` : `to contain "${step.contains}"`}.`);
    }
    return true;
  }
  return false;
}

async function runCase(session, testCase, target, context) {
  if (session.desktop) await session.desktop.goHome();
  if (!session.desktop) {
    session.navigationGuard.clear();
    if (target === 'web') {
      await session.page.goto(session.baseUrl, { waitUntil: 'domcontentloaded', timeout: 60_000 });
      await logInIfNeeded(session.page);
    }
  }
  // Like a person: when a step cannot be done because the screen is not what the plan expected,
  // look at the screen and let Gemini adjust the rest of the steps (at most MAX_RECOVERIES times).
  let steps = [...testCase.steps];
  let recoveries = 0;
  for (let index = 0; index < steps.length; index += 1) {
    const step = steps[index];
    try {
      await runOneStep(session, testCase, step, context);
    } catch (error) {
      if (!session.desktop || !context.recover || !RECOVERABLE_ACTIONS.has(step.action) || recoveries >= MAX_RECOVERIES) {
        throw error;
      }
      recoveries += 1;
      const screen = await session.desktop.screenText();
      context.debug.push({ step, error: error.message, screen });
      const fix = await context.recover({
        testCase, done: steps.slice(0, index), failed: step, error: error.message, screen, values: context.values,
      });
      if (!fix.steps.length) throw new Error(`${error.message} The agent stopped: ${fix.reason}`);
      context.notes.push(`Adjusted the steps after "${error.message}": ${fix.reason}`);
      steps = [...steps.slice(0, index), ...fix.steps];
      index -= 1;
    }
  }
}

const RECOVERABLE_ACTIONS = new Set(['click', 'fill', 'select', 'readValue', 'readCell', 'expectVisible']);
const MAX_RECOVERIES = 3;

async function runOneStep(session, testCase, step, context) {
  if (step.action === 'screenshot') {
    context.evidence.push(await captureScreen(session, evidencePath(context.outputDir, testCase, step.name)));
    return;
  }
  if (await runCalculationStep(session, step, context)) return;
  if (session.desktop) {
    const note = await session.desktop.runStep(step, interpolate);
    if (note) context.notes.push(note);
  } else {
    await executeStep(session.page, step, session.baseUrl);
    session.navigationGuard.assertNoneBlocked();
  }
}

function buildRecoveryPrompt(goal, { testCase, done, failed, error, screen, values }) {
  return [
    'You are the senior QA engineer of this team, driving the app step by step. A step just failed. Look at what is on the screen now and continue toward the goal, as a person would.',
    ...knowledgeBlock(),
    ...DESKTOP_GUIDANCE,
    'Return only valid JSON: {"reason":"<one short Arabic line: what you saw and what you changed>","steps":[...the remaining steps from now on...]}',
    'If the screen shows that some planned steps are no longer needed (for example the work order screen is already open with its bay assigned, or a popup is gone), skip them. If a popup blocks the screen, close or answer it first. If the goal cannot be reached, return "steps": [] and say why in "reason".',
    'Use only the allowed actions and step shapes of the plan below, exact labels from the screen texts, and only {names} that were already read. Do not repeat steps that already succeeded unless the screen requires it.',
    SCREENSHOT_RULE,
    ...CALCULATION_RULES,
    '',
    `Goal (the user's request): ${goal}`,
    `Test case: ${testCase.id} ${testCase.title}`,
    `Steps already done: ${JSON.stringify(done)}`,
    `Failed step: ${JSON.stringify(failed)}`,
    `Error: ${error}`,
    `Remaining planned steps: ${JSON.stringify(testCase.steps.slice(done.length + 1))}`,
    `Values read so far: ${JSON.stringify(Object.fromEntries(Object.entries(values).map(([name, value]) => [name, value.text])))}`,
    `Screen now (automation texts, top to bottom): ${JSON.stringify(screen.automation)}`,
    `Screen now (read from the image, includes popups): ${JSON.stringify(screen.ocr)}`,
  ].join('\n');
}

function makeRecoverer(goal, allowedClicks, requestJson = requestGeminiJson) {
  return async (situation) => {
    const text = await requestJson(buildRecoveryPrompt(goal, situation));
    const answer = JSON.parse(String(text || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
    const steps = Array.isArray(answer.steps) ? answer.steps : [];
    const reason = typeof answer.reason === 'string' ? answer.reason.trim() : '';
    if (steps.length) {
      // Validate together with the reads already done, so {names} read earlier are known.
      const reads = situation.done.filter((step) => step.action === 'readValue' || step.action === 'readCell');
      validatePlan({
        summary: 'recovery',
        acceptanceCriteria: ['recovery'],
        testCases: [{ id: situation.testCase.id, title: situation.testCase.title, steps: [...reads, ...steps] }],
      }, { allowedClicks, maxSteps: MAX_STEPS_PER_CASE * 2 });
    }
    return { steps, reason: reason || 'continued from the current screen' };
  };
}

async function executePlan(plan, target, { outputDir = path.join(__dirname, 'output'), goal = plan.summary, recover } = {}) {
  const session = target === 'web' ? await createWebSession() : await createDesktopSession();
  const results = [];
  try {
    for (const testCase of plan.testCases) {
      const startedAt = new Date().toISOString();
      const context = {
        outputDir, notes: [], evidence: [], values: {}, checks: [], debug: [],
        recover: recover === false ? null : (recover || makeRecoverer(goal, plan.allowedClicks || [])),
      };
      const extras = () => ({
        ...(context.notes.length ? { notes: context.notes } : {}),
        ...(context.evidence.length ? { evidence: context.evidence } : {}),
        ...(Object.keys(context.values).length ? { values: context.values } : {}),
        ...(context.checks.length ? { checks: context.checks } : {}),
        ...(context.debug.length ? { debug: context.debug } : {}),
      });
      try {
        await runCase(session, testCase, target, context);
        results.push({ id: testCase.id, title: testCase.title, status: 'passed', startedAt, ...extras() });
      } catch (error) {
        const result = {
          id: testCase.id, title: testCase.title, status: 'failed', startedAt, error: error.message, ...extras(),
        };
        try {
          result.screenshot = await captureScreen(session, evidencePath(outputDir, testCase, 'failed'));
        } catch {
          // no screenshot when the app is not in the foreground or the page is gone
        }
        results.push(result);
      }
      const result = results.at(-1);
      console.log(`${result.status === 'passed' ? 'PASS' : 'FAIL'} ${result.id} — ${result.title}`);
      if (result.error) console.error(`  ${result.error}`);
    }
  } finally {
    if (session.desktop) await session.desktop.close();
    else if (session.closeBrowser) await session.browser.close();
  }
  return results;
}

function saveJson(filePath, data) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

async function main(argv = process.argv.slice(2)) {
  const options = parseArgs(argv);
  if (options.help) {
    console.log(usage());
    return;
  }
  const outputDir = path.join(__dirname, 'output');
  let target = options.target || 'web';
  let story;
  let plan;
  let basename = `qa-agent-${RUN_ID}`;
  let planPath = path.join(outputDir, `${basename}-plan.json`);
  if (options.planFile) {
    if (options.story) throw new Error('Pass either --plan or a user story, not both.');
    planPath = path.resolve(process.cwd(), options.planFile);
    const relativePlanPath = path.relative(outputDir, planPath);
    if (relativePlanPath.startsWith('..') || path.isAbsolute(relativePlanPath)) {
      throw new Error('Plan files must be inside MAC1-Desktop-QA-Assistant/output/.');
    }
    let savedPlan;
    try {
      savedPlan = JSON.parse(fs.readFileSync(planPath, 'utf8'));
    } catch (error) {
      throw new Error(`Could not read the saved plan: ${error.message}`);
    }
    if (typeof savedPlan.story !== 'string' || !savedPlan.story.trim()) {
      throw new Error('The saved plan does not include its user story.');
    }
    if (!options.target && ['web', 'desktop'].includes(savedPlan.target)) {
      target = savedPlan.target;
    }
    story = savedPlan.story;
    plan = validatePlan(savedPlan);
    basename = path.basename(planPath).replace(/-plan\.json$/i, '');
    if (basename === path.basename(planPath)) {
      throw new Error('Plan filename must end in "-plan.json".');
    }
  } else {
    story = options.story || await askForStory();
    if (!story) throw new Error('A user story is required.');
    console.log('Generating a QA plan with Gemini...');
    let answers = [];
    for (let round = 0; round < 4; round += 1) {
      plan = await generatePlan(story, answers, target);
      if (plan.clarificationQuestions.length === 0) break;
      if (round === 3) {
        throw new Error('Gemini still needs clarification. Run the local UI to answer follow-up questions.');
      }
      answers = answers.concat(await askForClarification(plan.clarificationQuestions));
    }
    saveJson(planPath, { story, target, generatedAt: new Date().toISOString(), ...plan });
  }
  console.log(`\n${plan.summary}\n`);
  for (const [index, criterion] of plan.acceptanceCriteria.entries()) {
    console.log(`${index + 1}. ${criterion}`);
  }
  for (const testCase of plan.testCases) {
    console.log(`\n${testCase.id}: ${testCase.title}`);
    for (const [index, step] of testCase.steps.entries()) {
      console.log(`  ${index + 1}. ${step.action}`);
    }
  }
  if (plan.clarificationQuestions.length) {
    console.log('\nClarifications are still required. Tests cannot run until you answer them.');
    for (const question of plan.clarificationQuestions) console.log(`- ${question}`);
  }
  console.log(`\nPlan saved to ${path.relative(ROOT, planPath)}.`);

  if (!options.execute) {
    console.log(`Review the plan, then run with --plan "${path.relative(ROOT, planPath)}" --execute.`);
    return;
  }
  if (plan.clarificationQuestions.length) {
    throw new Error('Cannot execute a plan with unanswered clarification questions.');
  }
  if (!(await confirmExecution(target))) {
    console.log('Execution cancelled; no portal actions were taken.');
    return;
  }

  const results = await executePlan(plan, target, { goal: story });
  const reportPath = path.join(outputDir, `${basename}-results.json`);
  saveJson(reportPath, {
    story,
    target,
    finishedAt: new Date().toISOString(),
    results,
  });
  const failed = results.filter((result) => result.status === 'failed').length;
  console.log(`\nResults: ${results.length - failed} passed, ${failed} failed.`);
  console.log(`Report saved to ${path.relative(ROOT, reportPath)}.`);
  if (failed) process.exitCode = 1;
}

if (require.main === module) {
  main().catch((error) => {
    console.error(`QA agent error: ${error.message}`);
    process.exitCode = 1;
  });
}

module.exports = {
  GUARDED_CLICKS,
  buildPrompt,
  createDesktopSession,
  requestGeminiJson,
  chatTurn,
  formatResultsForChat,
  executeStep,
  executePlan,
  formatBugDraft,
  generatePlan,
  generatePlanFromMarkdown,
  isQaHostname,
  loadKnowledge,
  normalizeGeminiError,
  parseArgs,
  parsePlanResponse,
  renderRunReportMarkdown,
  summarizeRun,
  validatePlan,
  validateRunReport,
};
