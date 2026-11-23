'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { chromium } = require('@playwright/test');
const {
  buildPrompt,
  executeStep,
  formatBugDraft,
  generatePlanFromMarkdown,
  isQaHostname,
  loadKnowledge,
  normalizeGeminiError,
  parseArgs,
  parsePlanResponse,
  renderRunReportMarkdown,
  summarizeRun,
  validatePlan,
} = require('./qa-agent');
const { escapeSendKeys, hasText, resolveLocator } = require('./desktop-session');

const validPlan = {
  summary: 'Create a QA group.',
  acceptanceCriteria: ['A named group can be created.'],
  testCases: [{
    id: 'TC-01',
    title: 'Create a group',
    preconditions: [],
    steps: [
      { action: 'open', path: 'Inventory/ServiceItemGroup_ListView' },
      { action: 'click', target: { by: 'role', role: 'button', name: 'New' } },
      { action: 'fill', target: { by: 'label', name: 'Group Name' }, value: 'QA_AI_{RUN_ID}_group', newRecordName: true },
      { action: 'expectVisible', target: { by: 'text', name: 'Saved' } },
    ],
  }],
};

test('parses target and story arguments', () => {
  assert.deepEqual(parseArgs(['--target', 'desktop', '--execute', 'As a user', 'I want a report']), {
    target: 'desktop',
    planFile: null,
    execute: true,
    help: false,
    storyParts: ['As a user', 'I want a report'],
    story: 'As a user I want a report',
  });
});

test('accepts a bounded test plan', () => {
  assert.equal(validatePlan(validPlan), validPlan);
  assert.deepEqual(validPlan.clarificationQuestions, []);
});

test('accepts more than 40 test cases up to the configured limit', () => {
  const plan = structuredClone(validPlan);
  plan.testCases = Array.from({ length: 100 }, (_, index) => ({
    ...structuredClone(validPlan.testCases[0]),
    id: `TC-${String(index + 1).padStart(2, '0')}`,
    steps: [{ action: 'expectText', text: `Ready ${index + 1}` }],
  }));
  assert.equal(validatePlan(plan).testCases.length, 100);

  plan.testCases.push({
    ...structuredClone(validPlan.testCases[0]),
    id: 'TC-101',
  });
  assert.throws(() => validatePlan(plan), /between 1 and 100 test cases/);
});

test('accepts limited clarification questions in the plan', () => {
  const plan = structuredClone(validPlan);
  plan.clarificationQuestions = ['Which vehicle should be used?'];
  assert.deepEqual(validatePlan(plan).clarificationQuestions, ['Which vehicle should be used?']);
});

test('rejects too many clarification questions', () => {
  const plan = structuredClone(validPlan);
  plan.clarificationQuestions = ['One?', 'Two?', 'Three?', 'Four?'];
  assert.throws(() => validatePlan(plan), /up to 3/);
});

test('allows additional clarification questions only when explicitly requested', () => {
  const plan = structuredClone(validPlan);
  plan.clarificationQuestions = ['One?', 'Two?', 'Three?', 'Four?'];
  assert.equal(validatePlan(plan, { maxClarificationQuestions: 10 }), plan);
  // A Gemini answer with too many questions keeps the first three instead of failing the whole plan.
  assert.deepEqual(parsePlanResponse(JSON.stringify(plan)).clarificationQuestions, ['One?', 'Two?', 'Three?']);
  assert.equal(
    parsePlanResponse(JSON.stringify(plan), { maxClarificationQuestions: 10 }).clarificationQuestions.length,
    4,
  );
});

test('Markdown import supports clarifications across batches and retries only unresolved batches', async () => {
  const markdown = Array.from({ length: 17 }, (_, index) => {
    const id = `TC-${String(index + 1).padStart(2, '0')}`;
    return [
      `#### ${id} — Case ${index + 1}`,
      '- **Category:** Positive',
      '- **Preconditions/data:** Ready.',
      `- **Steps:** 1. Check case ${index + 1}.`,
      `- **Expected:** Case ${index + 1} appears.`,
    ].join('\n');
  }).join('\n\n');
  const calls = [];
  const requestGeneratedPlan = async (prompt) => {
    const batchNumber = Number(prompt.match(/batch (\d+) of \d+/i)[1]);
    const hasAnswers = prompt.includes('"answer":"Answer');
    calls.push({ batchNumber, hasAnswers, prompt });
    const firstCase = (batchNumber - 1) * 8 + 1;
    const cases = Array.from(
      { length: Math.min(8, 18 - firstCase) },
      (_, index) => firstCase + index,
    );
    const clarificationQuestions = hasAnswers || batchNumber === 2
      ? []
      : [`Batch ${batchNumber} question one?`, `Batch ${batchNumber} question two?`, `Batch ${batchNumber} question three?`];
    return {
      summary: `Batch ${batchNumber}`,
      clarificationQuestions,
      acceptanceCriteria: [`Batch ${batchNumber} is covered.`],
      testCases: cases.map((number) => ({
        id: `TC-${String(number).padStart(2, '0')}`,
        title: `Case ${number}`,
        preconditions: [],
        steps: [{ action: 'expectText', text: `Case ${number} appears.` }],
      })),
    };
  };

  const firstImport = await generatePlanFromMarkdown(markdown, [], [], requestGeneratedPlan);
  assert.equal(firstImport.plan.clarificationQuestions.length, 6);
  assert.equal(firstImport.conversions.length, 3);

  const completedImport = await generatePlanFromMarkdown(
    markdown,
    firstImport.plan.clarificationQuestions.map((question) => ({ question, answer: 'Answer supplied' })),
    firstImport.conversions,
    requestGeneratedPlan,
  );
  assert.deepEqual(calls.map(({ batchNumber }) => batchNumber), [1, 2, 3, 1, 3]);
  assert.match(calls[3].prompt, /"answer":"Answer supplied"/);
  assert.deepEqual(completedImport.plan.clarificationQuestions, []);
  assert.deepEqual(
    completedImport.plan.testCases.map((testCase) => testCase.id),
    Array.from({ length: 17 }, (_, index) => `TC-${String(index + 1).padStart(2, '0')}`),
  );
});

test('rejects external navigation', () => {
  const plan = structuredClone(validPlan);
  plan.testCases[0].steps[0].path = 'https://example.com/';
  assert.throws(() => validatePlan(plan), /must not navigate to another origin/);
});

test('rejects destructive controls', () => {
  const plan = structuredClone(validPlan);
  plan.testCases[0].steps[1].target.name = 'Delete';
  assert.throws(() => validatePlan(plan), /destructive action/);
});

test('requires generated QA names to include the unique run ID', () => {
  const plan = structuredClone(validPlan);
  plan.testCases[0].steps[2].value = 'QA_AI_group';
  assert.throws(() => validatePlan(plan), /include \{RUN_ID\}/);
});

test('requires new QA records to use a run-specific name', () => {
  const plan = structuredClone(validPlan);
  plan.testCases[0].steps[2].value = 'Existing Group';
  assert.throws(() => validatePlan(plan), /new record names must use/);
});

test('parses and validates Gemini JSON responses', () => {
  assert.deepEqual(parsePlanResponse(`\`\`\`json\n${JSON.stringify(validPlan)}\n\`\`\``), validPlan);
  assert.throws(() => parsePlanResponse('not JSON'), /valid JSON/);
});

test('turns Gemini overload into a retryable user-facing error', () => {
  const error = normalizeGeminiError({
    name: 'InternalServerError',
    status: 503,
    message: 'gemini-3.8-flash is currently experiencing high demand.',
  });
  assert.equal(error.status, 503);
  assert.match(error.message, /temporarily busy/);
  assert.match(error.message, /Generate test plan to retry/);
});

test('turns Gemini timeouts into a bounded retry message', () => {
  const error = normalizeGeminiError({
    name: 'APIConnectionTimeoutError',
    message: 'Request timed out.',
  });
  assert.equal(error.status, 504);
  assert.match(error.message, /took too long/);
});

test('recognizes QA hostnames only', () => {
  assert.equal(isQaHostname('qa.minerets.com'), true);
  assert.equal(isQaHostname('portal.qa.minerets.com'), true);
  assert.equal(isQaHostname('minerets.com'), false);
  assert.equal(isQaHostname('qa.evil.com'), false);
  assert.equal(isQaHostname('qa.minerets.com.evil'), false);
});

const desktopElements = [
  { name: 'QA - Company', type: 'Text', help: '', x: 416, y: 105, w: 140, h: 36 },
  { name: 'Overview', type: 'Text', help: '', x: 30, y: 240, w: 62, h: 20 },
  { name: 'Microsoft.Maui.Controls.Platform.ItemTemplateContext', type: 'ListItem', help: '', x: 0, y: 600, w: 1900, h: 60 },
  { name: 'Export', type: 'Button', help: '', x: 1790, y: 535, w: 84, h: 40 },
  { name: 'Export', type: 'Text', help: '', x: 1800, y: 545, w: 60, h: 20 },
  { name: 'Search by WO #, Customer, Tech, Bay, VIN...', type: 'Edit', help: '', x: 570, y: 530, w: 1200, h: 50 },
  { name: 'Plate Number', type: 'Text', help: '', x: 100, y: 300, w: 120, h: 20 },
  { name: '', type: 'Edit', help: '', x: 240, y: 295, w: 300, h: 30 },
];

test('resolves desktop locators from UI Automation elements', () => {
  assert.equal(resolveLocator(desktopElements, { by: 'role', role: 'button', name: 'Export' }).type, 'Button');
  assert.equal(resolveLocator(desktopElements, { by: 'role', role: 'tab', name: 'Overview' }).name, 'Overview');
  assert.equal(resolveLocator(desktopElements, { by: 'text', name: 'overview' }).name, 'Overview');
  assert.equal(
    resolveLocator(desktopElements, { by: 'placeholder', name: 'Search by WO #, Customer, Tech, Bay, VIN...' }).type,
    'Edit',
  );
  assert.equal(resolveLocator(desktopElements, { by: 'label', name: 'Plate Number' }).x, 240);
  assert.equal(resolveLocator(desktopElements, { by: 'text', name: 'Missing' }), null);
  assert.equal(resolveLocator(desktopElements, { by: 'text', name: 'Microsoft.Maui.Controls.Platform.ItemTemplateContext' }), null);
});

test('checks visible desktop text and escapes typed values', () => {
  assert.equal(hasText(desktopElements, 'qa - company'), true);
  assert.equal(hasText(desktopElements, 'Fully Refunded'), false);
  assert.equal(escapeSendKeys('QA_AI_1 (50%) +{x}'), 'QA_AI_1 {(}50{%}{)} {+}{{}x{}}');
});

test('executes supported locator steps on a local page', async () => {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.setContent(
      '<label for="name">Name</label><input id="name">' +
      '<label for="kind">Kind</label><select id="kind"><option>General</option><option>Tire</option></select>' +
      '<button onclick="document.querySelector(\'#result\').textContent = \'Saved\'">Save</button>' +
      '<p id="result"></p>',
    );

    await executeStep(page, {
      action: 'fill',
      target: { by: 'label', name: 'Name' },
      value: 'QA_AI_{RUN_ID}_group',
    });
    await executeStep(page, {
      action: 'select',
      target: { by: 'label', name: 'Kind' },
      value: 'Tire',
    });
    await executeStep(page, {
      action: 'click',
      target: { by: 'role', role: 'button', name: 'Save' },
    });
    await executeStep(page, { action: 'expectText', text: 'Saved' });

    assert.match(await page.getByLabel('Name').inputValue(), /^QA_AI_[A-Z0-9]+_group$/);
    assert.equal(await page.getByLabel('Kind').inputValue(), 'Tire');
  } finally {
    await browser.close();
  }
});

test('loads team knowledge into every plan prompt', () => {
  const knowledge = loadKnowledge();
  assert.match(knowledge, /How we work/);
  assert.match(knowledge, /MacOne desktop app map/);
  const prompt = buildPrompt('افحص شاشة المبيعات', [], 'desktop');
  assert.match(prompt, /Team knowledge/);
  assert.match(prompt, /Levantine/);
  assert.match(prompt, /do not use the open action/);
});

test('accepts screenshot steps with safe names only', () => {
  const plan = structuredClone(validPlan);
  plan.testCases[0].steps.push({ action: 'screenshot', name: 'sales_tab' });
  assert.doesNotThrow(() => validatePlan(plan));
  plan.testCases[0].steps.at(-1).name = '../secret';
  assert.throws(() => validatePlan(plan), /screenshot name/);
});

test('matches desktop labels that carry a live count', () => {
  const elements = [{ name: 'All (21)', type: 'Text', help: '', x: 60, y: 540, w: 80, h: 30 }];
  assert.equal(resolveLocator(elements, { by: 'text', name: 'All' }).name, 'All (21)');
  assert.equal(resolveLocator(elements, { by: 'text', name: 'Al' }), null);
});

test('turns a Gemini run report into an Arabic summary and bug drafts', async () => {
  const fakeGemini = async () => JSON.stringify({
    summary: 'نجحت حالة وحدة وفشلت حالة وحدة.',
    sections: [{ title: 'اللي فشل', lines: ['الزر مش موجود.', 'Export'] }],
    bugDrafts: [{
      title: 'MAC1 - Dashboard | Export button missing',
      severity: 'Medium',
      testCases: 'TC-02',
      steps: ['Open Dashboard > Sales.', '2. Check the list toolbar.'],
      actual: ['2. No Export button.'],
      expected: 'Export button is shown.',
      evidence: 'qa-agent-X-TC-02-failed.png',
    }],
  });
  const report = await summarizeRun('story', validPlan, [{ id: 'TC-01', status: 'passed' }], 'desktop', fakeGemini);
  assert.equal(report.bugDrafts.length, 1);
  const text = formatBugDraft(report.bugDrafts[0]);
  assert.match(text, /^Title: MAC1 - Dashboard \| Export button missing/);
  assert.match(text, /\n2\. Check the list toolbar\./);
  const markdown = renderRunReportMarkdown(report);
  assert.match(markdown, /## 1\. اللي فشل/);
  assert.match(markdown, /```\nTitle:/);
});
