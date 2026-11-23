'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { compareNumbers, evaluateExpression, parseNumber } = require('./calc');
const { readCellText, readValueText } = require('./desktop-session');
const { validatePlan } = require('./qa-agent');

const el = (name, x, y, w, h, type = 'Text') => ({ name, type, help: '', x, y, w, h });

// Positions copied from the MacOne dashboard on 2026-11-14.
const overview = [
  el('Overview', 30, 241, 61, 19), el('Cash', 293, 241, 34, 19),
  el('Daily Sales Amount (Incl. VAT)', 41, 293, 285, 22), el('', 41, 333, 26, 22),
  el('17,725', 68, 325, 94, 37), el('.11', 163, 322, 26, 22),
  el('Refunds', 41, 473, 55, 19), el(':', 101, 473, 4, 19), el('0', 126, 473, 9, 19), el('.00', 138, 470, 16, 14),
  el('Invoices Today', 368, 293, 284, 22), el('12', 368, 325, 284, 37),
  el('Fully Paid', 378, 468, 65, 19), el('12', 448, 468, 16, 19),
  el('Total Work Orders', 695, 293, 285, 22), el('21', 695, 325, 285, 37),
  el('2 Pending', 705, 395, 265, 19), el('9 Completed', 705, 432, 265, 19), el('10 Voided', 705, 468, 265, 19),
  el('Cash', 829, 874, 402, 19), el('', 1241, 877, 15, 13), el('400', 1257, 874, 27, 19), el('.00', 1285, 872, 17, 14),
  el('Inventory Value ', 1360, 639, 423, 22), el('15,608', 1802, 640, 51, 20), el('.50', 1855, 637, 20, 17),
  el('All (365)', 68, 484, 64, 20),
];

const sales = [
  el('Invoice #', 56, 683, 217, 20), el('Customer', 288, 683, 242, 20), el('Items', 842, 683, 121, 20),
  el('Amount (Incl. VAT)', 980, 683, 194, 20), el('Method', 1189, 683, 145, 20), el('Status', 1349, 683, 145, 20),
  el('INV - TO_11000093', 56, 754, 217, 20), el('14/11/2026', 56, 777, 217, 19),
  el('QA Auto Customer 1114', 288, 765, 177, 20), el('1', 842, 765, 121, 20),
  el('', 980, 768, 16, 14), el('100', 997, 765, 29, 20), el('.00', 1028, 762, 17, 14),
  el('Master', 1189, 765, 145, 20), el('Paid', 1359, 766, 28, 16),
];

test('parses numbers the way the dashboard shows them', () => {
  assert.equal(parseNumber('17,725.11'), 17725.11);
  assert.equal(parseNumber('−51.00'), -51);
  assert.equal(parseNumber('2.3%'), 2.3);
  assert.equal(parseNumber('All (365)'), 365);
  assert.equal(parseNumber('+2266.5% vs yesterday'), 2266.5);
  assert.equal(parseNumber('Paid'), null);
});

test('evaluates safe expressions with read values', () => {
  const values = { pending: { value: 2 }, total: { value: 21 }, sales: { value: 17725.11 } };
  assert.equal(evaluateExpression('round({pending} / {total} * 100, 1)', values), 9.5);
  assert.equal(evaluateExpression('-({sales} - 17725.11) + max(1, 2)', values), 2);
  assert.throws(() => evaluateExpression('{missing} + 1', values), /was not read/);
  assert.throws(() => evaluateExpression('process.exit()', values), /Unknown function|Unsupported|Invalid/);
  assert.throws(() => evaluateExpression('1 / 0', values), /Division by zero/);
  assert.equal(compareNumbers(9.52, '=', 9.5, 0.05), true);
  assert.equal(compareNumbers(9.6, '=', 9.5, 0.05), false);
  assert.equal(compareNumbers(3, '>=', 3, 0), true);
});

test('reads values next to dashboard labels', () => {
  assert.equal(readValueText(overview, { by: 'text', name: 'Daily Sales Amount (Incl. VAT)' }), '17,725.11');
  assert.equal(readValueText(overview, { by: 'text', name: 'Invoices Today' }), '12');
  assert.equal(readValueText(overview, { by: 'text', name: 'Fully Paid' }), '12');
  assert.equal(readValueText(overview, { by: 'text', name: 'Refunds' }), '0.00');
  assert.equal(readValueText(overview, { by: 'text', name: 'Inventory Value' }), '15,608.50');
  assert.equal(readValueText(overview, { by: 'text', name: 'Pending' }), '2 Pending');
  assert.equal(readValueText(overview, { by: 'text', name: 'All' }), 'All (365)');
  assert.equal(readValueText(overview, { by: 'text', name: 'Cash' }), '400.00');
  assert.equal(readValueText(overview, { by: 'text', name: 'Missing label' }), null);
});

test('reads list cells by row text and column header', () => {
  assert.equal(readCellText(sales, { row: 'INV - TO_11000093', column: 'Amount (Incl. VAT)' }), '100.00');
  assert.equal(readCellText(sales, { row: 'TO_11000093', column: 'Method' }), 'Master');
  assert.equal(readCellText(sales, { row: 'INV - TO_11000093', column: 'Status' }), 'Paid');
  assert.equal(readCellText(sales, { row: 'INV - TO_11000093', column: 'Method', rowAlso: 'Other customer' }), null);
  assert.equal(readCellText(sales, { row: 'INV - TO_99999999', column: 'Method' }), null);
});

test('validates calculation steps and the order of read values', () => {
  const plan = {
    summary: 's',
    acceptanceCriteria: ['c'],
    testCases: [{
      id: 'TC-01',
      title: 't',
      steps: [
        { action: 'readValue', target: { by: 'text', name: 'Pending' }, as: 'pending' },
        { action: 'readValue', target: { by: 'text', name: 'Total WOs' }, as: 'total' },
        { action: 'readCell', row: 'INV - 1', column: 'Method', as: 'method' },
        { action: 'expectNumber', expression: 'round({pending} / {total} * 100, 1)', op: '=', value: 9.5, tolerance: 0.05 },
        { action: 'expectValue', var: 'method', contains: 'Cash' },
      ],
    }],
  };
  assert.doesNotThrow(() => validatePlan(structuredClone(plan)));
  const early = structuredClone(plan);
  early.testCases[0].steps.unshift({ action: 'expectNumber', expression: '{late}', value: '1' });
  assert.throws(() => validatePlan(early), /before it is read/);
  const badOp = structuredClone(plan);
  badOp.testCases[0].steps[3].op = '=>';
  assert.throws(() => validatePlan(badOp), /unsupported comparison/);
  const badName = structuredClone(plan);
  badName.testCases[0].steps[0].as = '1bad';
  assert.throws(() => validatePlan(badName), /value name/);
});

const { findOcrText, ocrHasText, resolveLocator } = require('./desktop-session');

test('finds popup buttons in OCR lines even when OCR misreads Ok as 0k', () => {
  const lines = [
    { text: 'Do you want to print invoice INV -', words: [{ text: 'Do', x: 772, y: 509, w: 30, h: 25 }, { text: 'print', x: 949, y: 509, w: 50, h: 25 }] },
    { text: '0k', words: [{ text: '0k', x: 812, y: 606, w: 26, h: 20 }] },
    { text: 'Cancel', words: [{ text: 'Cancel', x: 1041, y: 606, w: 66, h: 20 }] },
  ];
  assert.deepEqual(findOcrText(lines, 'Ok'), { name: '0k', type: 'Ocr', help: '', x: 812, y: 606, w: 26, h: 20 });
  assert.equal(findOcrText(lines, 'Cancel').x, 1041);
  assert.equal(findOcrText(lines, 'Skip'), null);
  assert.equal(ocrHasText(lines, 'print invoice'), true);
});

test('maps Menu and Back to the unnamed top-left button and matches changing button text', () => {
  const screen = [
    { name: '', type: 'Button', help: '', x: 20, y: 53, w: 55, h: 55 },
    { name: 'Vehicles List', type: 'Text', help: '', x: 93, y: 66, w: 134, h: 28 },
    { name: 'Assign to Bay - 01 ', type: 'Button', help: '', x: 968, y: 940, w: 933, h: 60 },
  ];
  assert.equal(resolveLocator(screen, { by: 'text', name: 'Back' }).x, 20);
  assert.equal(resolveLocator(screen, { by: 'role', role: 'button', name: 'Menu' }).x, 20);
  assert.equal(resolveLocator(screen, { by: 'role', role: 'button', name: 'Assign Bay' }).x, 968);
});

test('allows sensitive clicks only when the request asks for them', () => {
  const plan = (name, allowedClicks) => ({
    summary: 's', acceptanceCriteria: ['c'], allowedClicks,
    testCases: [{ id: 'TC-01', title: 't', steps: [{ action: 'click', target: { by: 'text', name } }] }],
  });
  assert.doesNotThrow(() => validatePlan(plan('Cancel', ['cancel'])));
  assert.throws(() => validatePlan(plan('Void', ['cancel'])), /did not ask for/);
  assert.doesNotThrow(() => validatePlan(plan('Void', ['void'])));
  assert.throws(() => validatePlan(plan('Delete', [])), /did not ask for/);
});

const { chatTurn } = require('./qa-agent');

test('chat answers questions, hands desktop work to the agent, and plans web work', async () => {
  const question = await chatTurn([], 'شو معادلة الكاش المتوقع؟', 'desktop', async () => JSON.stringify({
    reply: 'الكاش المتوقع يساوي رصيد الافتتاح زائد مبيعات الكاش ناقص مرتجعات الكاش.', task: null,
  }));
  assert.equal(question.task, null);
  const desktop = await chatTurn([], 'افتح شاشة الشغل وادفع كاش', 'desktop', async () => JSON.stringify({
    reply: 'عم بفتح شاشة الشغل وبدفع كاش.', task: 'Open Workorder for 1111AAA, add Car Wash, pay cash.',
  }));
  assert.match(desktop.task, /Workorder/);
  assert.ok(desktop.allowedClicks.includes('cancel'));
  const web = await chatTurn([], 'open the portal item list', 'web', async () => JSON.stringify({
    reply: 'OK',
    plan: {
      summary: 's', acceptanceCriteria: ['c'], clarificationQuestions: ['q?'],
      testCases: [{ id: 'TC-01', title: 't', steps: [{ action: 'click', target: { by: 'text', name: 'Item' } }] }],
    },
  }));
  assert.equal(web.plan.testCases.length, 1);
  assert.deepEqual(web.plan.clarificationQuestions, []);
});

const { describeScreen, remember } = require('./agent');
const os = require('node:os');
const pathModule = require('node:path');
const fsModule = require('node:fs');

test('agent describes the screen with ids and saves learned notes once', () => {
  const text = describeScreen([
    { id: 1, kind: 'ui', type: 'Image', text: '(icon, no text)', x: 48, y: 111, w: 25, h: 25 },
    { id: 2, kind: 'ocr', type: 'ImageText', text: 'Skip', x: 130, y: 950, w: 40, h: 20 },
  ]);
  assert.match(text, /#1 Image: \(icon, no text\) @\(48,111,25x25\)/);
  assert.match(text, /#2 ImageText: Skip .*\[read from image\]/);
  const file = pathModule.join(fsModule.mkdtempSync(pathModule.join(os.tmpdir(), 'qa-learn-')), 'learned.md');
  assert.equal(remember('The mileage panel opens after a vehicle is chosen.', file), true);
  assert.equal(remember('The mileage panel opens after a vehicle is chosen.', file), false);
  assert.match(fsModule.readFileSync(file, 'utf8'), /mileage panel/);
});
