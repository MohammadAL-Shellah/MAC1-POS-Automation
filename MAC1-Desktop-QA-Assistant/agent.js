'use strict';

// Interactive agent: works like a person at the screen. Every turn it looks at what is on screen
// (automation texts, unnamed icons, and OCR text for popups), asks Gemini for the next actions,
// does them, and looks again, until Gemini says the task is done. When something fails, Gemini
// sees the error and the screen and chooses another way.

const fs = require('node:fs');
const path = require('node:path');
const { compareNumbers, evaluateExpression, formatNumber, parseNumber } = require('./calc');
const { findOcrText, readValueText, resolveLocator } = require('./desktop-session');

const MAX_TURNS = 45;
const MAX_ELEMENTS = 260;
const LEARNED_FILE = path.join(__dirname, 'knowledge', '06-learned-by-the-agent.md');
const MAX_LEARNED_BYTES = 24 * 1024;

const normalize = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

// Builds the numbered list of things on screen that Gemini can act on.
async function observe(desktop, { withOcr }) {
  const elements = await desktop.elements();
  const items = [];
  const seen = new Set();
  for (const element of elements) {
    const name = normalize(element.name);
    if (/^Microsoft\.Maui\./.test(name)) continue;
    const small = element.w >= 12 && element.w <= 140 && element.h >= 12 && element.h <= 140;
    const actionable = ['Button', 'Edit', 'Image', 'ComboBox', 'CheckBox', 'ListItem', 'Hyperlink', 'TabItem'].includes(element.type);
    if (!name && !(actionable && (small || element.type === 'Edit'))) continue;
    const key = `${element.type}|${name}|${element.x}|${element.y}`;
    if (seen.has(key)) continue;
    seen.add(key);
    items.push({
      kind: 'ui',
      type: element.type,
      text: name || (element.type === 'Edit' ? '(text box)' : '(icon, no text)'),
      value: element.value ?? undefined,
      x: element.x, y: element.y, w: element.w, h: element.h,
    });
  }
  items.sort((a, b) => (a.y - b.y) || (a.x - b.x));
  if (withOcr) {
    const uiTexts = new Set(items.map((item) => item.text.toLowerCase()));
    for (const line of await desktop.ocrLines()) {
      const text = normalize(line.text);
      if (!text || uiTexts.has(text.toLowerCase()) || !(line.words || []).length) continue;
      const words = line.words;
      const x = Math.min(...words.map((w) => w.x));
      const y = Math.min(...words.map((w) => w.y));
      items.push({
        kind: 'ocr', type: 'ImageText', text, words,
        x, y, w: Math.max(...words.map((w) => w.x + w.w)) - x, h: Math.max(...words.map((w) => w.y + w.h)) - y,
      });
    }
  }
  const list = items.slice(0, MAX_ELEMENTS).map((item, index) => ({ id: index + 1, ...item }));
  return { list, elements, signature: list.filter((item) => item.kind === 'ui').map((item) => `${item.text}@${item.x},${item.y}`).join('|') };
}

function describeScreen(list) {
  return list.map((item) => {
    const value = item.value ? ` value="${item.value}"` : '';
    const source = item.kind === 'ocr' ? ' [read from image]' : '';
    return `#${item.id} ${item.type}: ${item.text}${value} @(${item.x},${item.y},${item.w}x${item.h})${source}`;
  }).join('\n');
}

const center = (item) => ({ x: item.x + Math.round(item.w / 2), y: item.y + Math.round(item.h / 2) });

function buildAgentPrompt({ knowledge, goal, log, values, screen, turn }) {
  return [
    'You are the senior QA engineer of this team, sitting at the MacOne desktop app and doing the user\'s task yourself, exactly like a careful human tester. You see the screen as a numbered list and act through actions.',
    knowledge ? `Team knowledge (follow it):\n<<<KNOWLEDGE\n${knowledge}\nKNOWLEDGE>>>` : '',
    'Return only valid JSON: {"thought":"<short Arabic: what you see and what you do next>","actions":[...]}',
    'Actions:',
    '{"do":"click","id":12} or {"do":"click","text":"Continue"} (click by list id is most reliable; icons without text are listed as "(icon, no text)" with their position, for example the menu icon at the top left).',
    '{"do":"type","id":5,"text":"1111AAA"} clicks a text box, clears it, and types.',
    '{"do":"key","keys":"{ESC}"} sends keys (SendKeys format: {ENTER}, {ESC}, {TAB}, {BACKSPACE}).',
    '{"do":"wait","seconds":2}',
    '{"do":"read","label":"Daily Sales Amount (Incl. VAT)","as":"sales_before"} reads the number next to a label; or {"do":"read","id":30,"as":"x"} reads the number in that item.',
    '{"do":"check","expression":"{sales_before} + 100","op":"=","value":"{sales_after}","tolerance":0.01,"what":"<what this proves>"} compares numbers (ops = != < <= > >=; functions round, abs, min, max).',
    '{"do":"look"} reads the screen image again on the next turn (to find popups automation cannot see).',
    '{"do":"screenshot","name":"short_name"} keeps evidence.',
    '{"do":"remember","note":"<one English line about this app worth knowing next time, for example a screen label or a popup>"} saves what you learned while exploring.',
    '{"do":"done","status":"passed|failed|blocked","report":["<Arabic lines with the real numbers>"],"bugDrafts":[{"title":"MAC1 - <Screen> | ...","severity":"Low|Medium|High","steps":["..."],"actual":["..."],"expected":"...","evidence":"..."}]} ends the task.',
    'How to work:',
    '1. Do what the user asked fully. Never refuse and never reduce the task. If the request is about exploring, explore the screens and report what you found.',
    '2. Work step by step. The batch stops after the first click or key, and then you see the new screen, so put reads before a click.',
    '3. If an action failed or the screen did not change, think about why: a popup in front (use "look"), a button that is not active yet (wait, then click again), a different screen than expected (go another way), data from an earlier test (adapt). Try another way before giving up.',
    '4. Before and after an action that changes numbers, read the numbers and check the difference.',
    '5. Finish with "done" and a clear Arabic report: what you did, the real numbers, what passed, what failed and why. Bug drafts only for real product defects.',
    `Turn ${turn} of ${MAX_TURNS}.`,
    '',
    `Task from the user: ${goal}`,
    '',
    `What you did so far (oldest first): ${JSON.stringify(log.slice(-30))}`,
    `Values read: ${JSON.stringify(Object.fromEntries(Object.entries(values).map(([name, value]) => [name, value.text])))}`,
    '',
    'Screen now:',
    screen,
  ].filter(Boolean).join('\n');
}

function parseJson(text) {
  return JSON.parse(String(text || '').trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
}

function remember(note, file = LEARNED_FILE) {
  const line = normalize(note).slice(0, 300);
  if (!line) return false;
  let current = '';
  try {
    current = fs.readFileSync(file, 'utf8');
  } catch {
    current = '# 6. Learned by the agent while working\n\nShort notes the agent saved about the app. Review and move good ones into the other files.\n';
  }
  if (current.includes(line) || Buffer.byteLength(current, 'utf8') > MAX_LEARNED_BYTES) return false;
  fs.writeFileSync(file, `${current.trimEnd()}\n- ${new Date().toISOString().slice(0, 10)}: ${line}\n`, 'utf8');
  return true;
}

// guards: [{ key, name: RegExp }]; allowedClicks: keys the user's own request allows.
async function runAgent({
  desktop, goal, knowledge, requestJson, guards = [], allowedClicks = [], outputDir, runId, onProgress = () => {},
}) {
  const log = [];
  const values = {};
  const checks = [];
  const evidence = [];
  const learned = [];
  let withOcr = true;
  let lastSignature = null;
  let lastWasClick = false;

  for (let turn = 1; turn <= MAX_TURNS; turn += 1) {
    const screen = await observe(desktop, { withOcr });
    if (lastWasClick && screen.signature === lastSignature) {
      log.push({ note: 'The screen did not change after the last click (a popup may be in front, or the button was not active).' });
    }
    withOcr = false;
    let answer;
    try {
      answer = parseJson(await requestJson(buildAgentPrompt({
        knowledge, goal, log, values, screen: describeScreen(screen.list), turn,
      })));
    } catch (error) {
      log.push({ error: `Could not understand the model answer: ${error.message}` });
      continue;
    }
    if (answer.thought) onProgress(answer.thought);
    const actions = Array.isArray(answer.actions) ? answer.actions.slice(0, 8) : [];
    if (!actions.length) {
      log.push({ error: 'No actions were given.' });
      continue;
    }
    lastSignature = screen.signature;
    lastWasClick = false;
    for (const action of actions) {
      const entry = { action };
      try {
        if (action.do === 'done') {
          return {
            status: ['passed', 'failed', 'blocked'].includes(action.status) ? action.status : 'passed',
            report: Array.isArray(action.report) ? action.report.map(normalize).filter(Boolean) : [],
            bugDrafts: Array.isArray(action.bugDrafts) ? action.bugDrafts : [],
            log, values, checks, evidence, learned, turns: turn,
          };
        }
        if (action.do === 'click' || action.do === 'type') {
          let target = Number.isInteger(action.id) ? screen.list.find((item) => item.id === action.id) : null;
          if (!target && action.text) {
            target = resolveLocator(screen.elements, { by: 'text', name: action.text });
            if (!target) target = findOcrText((await desktop.ocrLines()), action.text);
          }
          if (!target) throw new Error(`Nothing on screen matches ${action.id ? `#${action.id}` : `"${action.text}"`}.`);
          const label = normalize(target.text ?? target.name);
          const guard = guards.find((item) => item.name.test(label));
          if (action.do === 'click' && guard && !allowedClicks.includes(guard.key)) {
            throw new Error(`"${label}" is a ${guard.key} action; do it only if the user asked for it in the request.`);
          }
          await desktop.driver.send('click', center(target));
          await delay(600);
          if (action.do === 'type') {
            await desktop.driver.send('keys', { keys: '{END}+{HOME}{DELETE}' });
            await desktop.driver.send('keys', { keys: `{END}{BACKSPACE ${String(target.value || '').length + 2}}` });
            if (action.text) await desktop.driver.send('keys', { keys: escapeKeys(action.text) });
            entry.result = `typed into "${label}"`;
          } else {
            entry.result = `clicked "${label}"`;
            lastWasClick = true;
          }
        } else if (action.do === 'key') {
          await desktop.driver.send('keys', { keys: String(action.keys || '') });
          entry.result = 'keys sent';
          lastWasClick = true;
        } else if (action.do === 'wait') {
          await delay(Math.min(Math.max(Number(action.seconds) || 1, 0.5), 15) * 1000);
          entry.result = 'waited';
        } else if (action.do === 'look') {
          withOcr = true;
          entry.result = 'the screen image will be read next turn';
        } else if (action.do === 'read') {
          if (!/^[A-Za-z][A-Za-z0-9_]{0,40}$/.test(String(action.as))) throw new Error('"as" must be a simple name.');
          let text = null;
          if (Number.isInteger(action.id)) text = screen.list.find((item) => item.id === action.id)?.text ?? null;
          if (text === null && action.label) text = readValueText(screen.elements, { by: 'text', name: action.label });
          if (text === null) throw new Error(`No number found for ${action.label ? `"${action.label}"` : `#${action.id}`}.`);
          values[action.as] = { text, value: parseNumber(text), source: action.label || `#${action.id}` };
          entry.result = `${action.as} = ${text}`;
        } else if (action.do === 'check') {
          const op = action.op || '=';
          const tolerance = typeof action.tolerance === 'number' ? action.tolerance : 0.01;
          const left = evaluateExpression(action.expression, values);
          const right = evaluateExpression(String(action.value), values);
          const pass = compareNumbers(left, op, right, tolerance);
          const check = {
            expression: action.expression, value: String(action.value), op, tolerance,
            left: formatNumber(left), right: formatNumber(right), pass, what: action.what,
          };
          checks.push(check);
          entry.result = `${pass ? 'PASS' : 'FAIL'}: ${check.left} ${op} ${check.right}`;
        } else if (action.do === 'screenshot') {
          const name = String(action.name || 'screen').replace(/[^\w-]/g, '_').slice(0, 60);
          const file = path.join(outputDir, `qa-agent-${runId}-${name}.png`);
          fs.mkdirSync(outputDir, { recursive: true });
          await desktop.screenshot(file);
          evidence.push(file);
          entry.result = `saved ${path.basename(file)}`;
        } else if (action.do === 'remember') {
          entry.result = remember(action.note) ? 'saved to knowledge' : 'already known';
          if (entry.result === 'saved to knowledge') learned.push(normalize(action.note));
        } else {
          throw new Error(`Unknown action "${action.do}".`);
        }
      } catch (error) {
        entry.error = error.message;
        withOcr = true;   // after a problem, read the screen image too
      }
      log.push(entry);
      if (entry.error || lastWasClick) break;   // look at the screen again before going on
    }
  }
  return {
    status: 'blocked',
    report: [`Stopped after ${MAX_TURNS} turns without finishing.`],
    bugDrafts: [], log, values, checks, evidence, learned, turns: MAX_TURNS,
  };
}

function escapeKeys(text) {
  return String(text).replace(/[+^%~(){}[\]]/g, (character) => `{${character}}`).replace(/\r?\n/g, '{ENTER}');
}

module.exports = { buildAgentPrompt, describeScreen, observe, remember, runAgent };
