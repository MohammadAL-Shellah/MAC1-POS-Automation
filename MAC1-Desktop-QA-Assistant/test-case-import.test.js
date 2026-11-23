'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { parseMarkdownTestCases } = require('./test-case-import');

test('parses Markdown test cases and numbered steps', () => {
  const cases = parseMarkdownTestCases([
    '# Dashboard tests',
    '#### TC-POS-001 — Open dashboard',
    '- **Category:** Positive',
    '- **Preconditions/data:** User can sign in.',
    '- **Steps:** 1. Open the dashboard. 2. Observe the Overview tab.',
    '- **Expected:** Overview is selected.',
    '#### TC-POS-002 — Search inventory',
    '- **Category:** Positive / negative',
    '- **Preconditions/data:** Items exist.',
    '- **Steps:** 1. Search for an item.',
    '- **Expected:** Matching item appears.',
  ].join('\n'));

  assert.equal(cases.length, 2);
  assert.deepEqual(cases[0], {
    id: 'TC-POS-001',
    title: 'Open dashboard',
    category: 'Positive',
    preconditions: 'User can sign in.',
    manualSteps: ['Open the dashboard.', 'Observe the Overview tab.'],
    expected: 'Overview is selected.',
  });
  assert.deepEqual(cases[1].manualSteps, ['Search for an item.']);
});

test('rejects incomplete Markdown cases', () => {
  assert.throws(
    () => parseMarkdownTestCases('#### TC-01 — Incomplete\n- **Category:** Positive'),
    /must include Category, Preconditions\/data, Steps, and Expected/,
  );
});

test('rejects duplicate IDs and plans over the supported limit', () => {
  const oneCase = [
    '#### TC-01 — Valid case',
    '- **Category:** Positive',
    '- **Preconditions/data:** Ready.',
    '- **Steps:** 1. Open dashboard.',
    '- **Expected:** Dashboard appears.',
  ].join('\n');

  assert.throws(() => parseMarkdownTestCases(`${oneCase}\n${oneCase}`), /Duplicate test case ID/);
  assert.throws(
    () => parseMarkdownTestCases(Array.from({ length: 101 }, (_, index) =>
      oneCase.replaceAll('TC-01', `TC-${String(index + 1).padStart(3, '0')}`)).join('\n')),
    /maximum supported is 100/,
  );
});
