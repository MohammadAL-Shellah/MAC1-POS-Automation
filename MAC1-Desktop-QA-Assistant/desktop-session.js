'use strict';

// Runs plan steps against the native MacOne desktop app (MAUI / WinUI 3) through Windows UI Automation.
// The app has no WebView2, so Playwright cannot attach to it. desktop-driver.ps1 lists the visible
// elements, clicks with the real mouse and types with SendKeys; this module chooses which element to use.

const path = require('node:path');
const readline = require('node:readline');
const { spawn } = require('node:child_process');

const DRIVER_SCRIPT = path.join(__dirname, 'desktop-driver.ps1');
const STEP_TIMEOUT_MS = 15_000;
const POLL_MS = 400;
const INPUT_TYPES = new Set(['Edit', 'ComboBox']);
const IGNORED_NAME = /^Microsoft\.Maui\./;

// Playwright role names mapped to UI Automation control types. MAUI often renders clickable
// tabs and cards as plain Text, so a role match falls back to any element with the same name.
const ROLE_TYPES = {
  button: ['Button'],
  link: ['Hyperlink'],
  textbox: ['Edit'],
  searchbox: ['Edit'],
  combobox: ['ComboBox'],
  checkbox: ['CheckBox'],
  radio: ['RadioButton'],
  tab: ['TabItem'],
  listitem: ['ListItem'],
  option: ['ListItem', 'ComboBoxItem'],
  row: ['DataItem', 'ListItem'],
  heading: ['Text'],
  menuitem: ['MenuItem'],
  img: ['Image'],
  image: ['Image'],
  switch: ['Button', 'CheckBox'],
};

function normalize(value) {
  return String(value ?? '').replace(/\s+/g, ' ').trim();
}

function center(element) {
  return { x: element.x + Math.round(element.w / 2), y: element.y + Math.round(element.h / 2) };
}

function usable(elements) {
  return elements.filter((element) => normalize(element.name) && !IGNORED_NAME.test(element.name));
}

// Exact name first, then case-insensitive, then a label followed by a live count such as "All (21)".
function byName(elements, name) {
  const wanted = normalize(name);
  const exact = elements.filter((element) => normalize(element.name) === wanted);
  if (exact.length) return exact;
  const lower = wanted.toLowerCase();
  const caseless = elements.filter((element) => normalize(element.name).toLowerCase() === lower);
  if (caseless.length) return caseless;
  const counted = new RegExp(`^${lower.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')} \\(\\d+\\)$`);
  const withCount = elements.filter((element) => counted.test(normalize(element.name).toLowerCase()));
  if (withCount.length) return withCount;
  // Buttons whose text changes with the selection, such as "Assign Bay" shown as "Assign to Bay - 01":
  // every requested word must appear in the element, buttons first.
  const words = lower.split(' ').filter((word) => word.length > 1);
  if (words.length < 2) return [];
  return elements
    .filter((element) => {
      const name = normalize(element.name).toLowerCase();
      return name.length <= lower.length + 40 && words.every((word) => name.includes(word));
    })
    .sort((a, b) => (b.type === 'Button') - (a.type === 'Button'));
}

function nearestInput(elements, label) {
  const from = center(label);
  let best = null;
  let bestDistance = Infinity;
  for (const element of elements) {
    if (!INPUT_TYPES.has(element.type)) continue;
    const to = center(element);
    const sameRow = Math.abs(to.y - from.y) <= Math.max(label.h, 20) && to.x > from.x;
    const below = to.y > from.y && to.y - from.y <= 150 &&
      element.x <= label.x + label.w && element.x + element.w >= label.x;
    if (!sameRow && !below) continue;
    const distance = Math.hypot(to.x - from.x, to.y - from.y);
    if (distance < bestDistance) {
      best = element;
      bestDistance = distance;
    }
  }
  return best;
}

// The top-left icon has no name: it is the menu button on the dashboard and the back arrow on
// other screens. Plans call it "Menu" or "Back".
const TOP_LEFT_ALIASES = new Set(['menu', 'back', 'back arrow', 'menu button', 'back button']);

function topLeftButton(all) {
  const candidates = all.filter((element) => !normalize(element.name) &&
    ['Button', 'Custom', 'Image'].includes(element.type) &&
    element.w >= 20 && element.w <= 90 && element.h >= 20 && element.h <= 90 &&
    center(element).x < 130 && center(element).y > 45 && center(element).y < 175);
  return candidates.sort((a, b) => (a.type === 'Button' ? -1 : 0) - (b.type === 'Button' ? -1 : 0) || a.y - b.y)[0] || null;
}

function resolveLocator(elements, target) {
  const all = Array.isArray(elements) ? elements : [elements].filter(Boolean);
  const found = resolveNamedLocator(all, target);
  if (found || !TOP_LEFT_ALIASES.has(normalize(target.name).toLowerCase())) return found;
  return topLeftButton(all);
}

function resolveNamedLocator(all, target) {
  const named = usable(all);
  switch (target.by) {
    case 'role': {
      const matches = byName(named, target.name);
      const types = ROLE_TYPES[String(target.role).toLowerCase()];
      return (types && matches.find((element) => types.includes(element.type))) || matches[0] || null;
    }
    case 'label': {
      const inputs = all.filter((element) => INPUT_TYPES.has(element.type));
      const direct = inputs.find((element) =>
        normalize(element.name) === normalize(target.name) || normalize(element.help) === normalize(target.name));
      if (direct) return direct;
      for (const label of byName(named, target.name)) {
        if (INPUT_TYPES.has(label.type)) return label;
        const input = nearestInput(all, label);
        if (input) return input;
      }
      return null;
    }
    case 'placeholder': {
      const wanted = normalize(target.name).toLowerCase();
      const inputs = all.filter((element) => INPUT_TYPES.has(element.type));
      return inputs.find((element) => normalize(element.name).toLowerCase() === wanted ||
        normalize(element.help).toLowerCase() === wanted) || null;
    }
    case 'text':
      return byName(named, target.name)[0] || null;
    default:
      throw new Error(`Unsupported locator type: ${target.by}`);
  }
}

// ---- Reading numbers -------------------------------------------------------------------
// The app draws an amount as separate texts: a currency icon, the integer part "17,725" and the
// decimals ".11". A value sits to the right of its label on the same row, or below it in a card.

const NUMERIC_TEXT = /^[+\-−]?(?:\d[\d,]*(?:\.\d+)?|\.\d+)\s*(?:%|Items?)?$/;
const DECIMAL_PART = /^\.\d+$/;

function centerY(element) {
  return element.y + element.h / 2;
}

function joinAmount(elements, integerPart) {
  let text = normalize(integerPart.name);
  const decimal = elements.find((element) => DECIMAL_PART.test(normalize(element.name)) &&
    element.x >= integerPart.x + integerPart.w - 4 && element.x <= integerPart.x + integerPart.w + 14 &&
    Math.abs(centerY(element) - centerY(integerPart)) <= 15);
  if (decimal && !text.includes('.')) text += normalize(decimal.name);
  const sign = elements.find((element) => /^[-−]$/.test(normalize(element.name)) &&
    element.x + element.w <= integerPart.x + 2 && element.x + element.w >= integerPart.x - 30 &&
    Math.abs(centerY(element) - centerY(integerPart)) <= 15);
  if (sign && !/^[-−]/.test(text)) text = `-${text}`;
  return text;
}

function valueNearLabel(elements, label) {
  const numbers = elements.filter((element) => element !== label &&
    NUMERIC_TEXT.test(normalize(element.name)) && !DECIMAL_PART.test(normalize(element.name)));
  const right = numbers
    .filter((element) => Math.abs(centerY(element) - centerY(label)) <= Math.max(label.h * 0.75, 12) &&
      element.x >= label.x + label.w * 0.5 && element.x - (label.x + label.w) <= 600)
    .sort((a, b) => a.x - b.x)[0];
  if (right) return joinAmount(elements, right);
  const below = numbers
    .filter((element) => element.y >= label.y + label.h - 4 && element.y <= label.y + label.h + 90 &&
      element.x + element.w >= label.x - 10 && element.x <= label.x + label.w)
    .sort((a, b) => (a.y - b.y) || (a.x - b.x))[0];
  return below ? joinAmount(elements, below) : null;
}

// Returns the text of the value that belongs to a label, or null.
function readValueText(elements, target) {
  const all = Array.isArray(elements) ? elements : [];
  const named = usable(all);
  const wanted = normalize(target.name).toLowerCase();
  const matches = target.by === 'text' || target.by === 'role' ? byName(named, target.name) : [];
  const ownNumber = (element) => {
    const name = normalize(element.name);
    return name.toLowerCase() !== wanted && /\d/.test(name.replace(new RegExp(wanted.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'), ''))
      ? name : null;
  };
  for (const label of matches) {
    const own = ownNumber(label);
    if (own) return own;                       // "All (365)"
    const near = valueNearLabel(all, label);
    if (near) return near;
  }
  // "2 Pending", "356 Items": the label and its number share one text.
  const phrase = new RegExp(`(^|\\s)${wanted.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}(\\s|$)`, 'i');
  const combined = named.find((element) => phrase.test(normalize(element.name)) && ownNumber(element));
  return combined ? normalize(combined.name) : null;
}

// Reads one cell of a list: the row is found by a text in it, the column by its header.
function readCellText(elements, { row, column, rowAlso }) {
  const all = usable(Array.isArray(elements) ? elements : []);
  const headers = byName(all, column);
  const header = headers
    .map((candidate) => ({ candidate, peers: all.filter((element) => Math.abs(element.y - candidate.y) <= 3).length }))
    .sort((a, b) => b.peers - a.peers)[0]?.candidate;
  if (!header) return null;
  const headerRow = all.filter((element) => Math.abs(element.y - header.y) <= 3).sort((a, b) => a.x - b.x);
  const next = headerRow.find((element) => element.x > header.x + 2);
  const left = header.x - 8;
  const right = next ? next.x - 2 : header.x + header.w + 60;
  const wantedRow = normalize(row).toLowerCase();
  let anchors = all.filter((element) => element.y > header.y + header.h &&
    normalize(element.name).toLowerCase() === wantedRow);
  if (!anchors.length) {
    anchors = all.filter((element) => element.y > header.y + header.h &&
      normalize(element.name).toLowerCase().includes(wantedRow));
  }
  for (const anchor of anchors) {
    const top = anchor.y - 12;
    const bottom = anchor.y + anchor.h + 15;
    const band = all.filter((element) => centerY(element) >= top && centerY(element) <= bottom);
    if (rowAlso && !band.some((element) => normalize(element.name).toLowerCase().includes(normalize(rowAlso).toLowerCase()))) {
      continue;
    }
    const cells = band.filter((element) => center(element).x >= left && center(element).x <= right)
      .sort((a, b) => a.x - b.x);
    if (!cells.length) return '';
    return normalize(cells.reduce((text, element) => {
      const part = normalize(element.name);
      if (!text) return part;
      return DECIMAL_PART.test(part) ? `${text}${part}` : `${text} ${part}`;
    }, ''));
  }
  return null;
}

// ---- OCR fallback ----------------------------------------------------------------------
// OCR confuses a few characters ("Ok" is read as "0k"), so both sides are compared in a canonical form.
function ocrCanonical(value) {
  return normalize(value).toLowerCase().replace(/0/g, 'o').replace(/[1|]/g, 'l').replace(/[^\p{L}\p{N} ]/gu, '');
}

function box(words) {
  const left = Math.min(...words.map((word) => word.x));
  const top = Math.min(...words.map((word) => word.y));
  const right = Math.max(...words.map((word) => word.x + word.w));
  const bottom = Math.max(...words.map((word) => word.y + word.h));
  return { x: left, y: top, w: right - left, h: bottom - top };
}

// Finds a phrase in OCR lines and returns a clickable pseudo element, or null.
function findOcrText(lines, text) {
  const wanted = ocrCanonical(text);
  if (!wanted) return null;
  const wantedWords = wanted.split(' ');
  for (const line of Array.isArray(lines) ? lines : []) {
    const words = (line.words || []).filter((word) => ocrCanonical(word.text));
    for (let start = 0; start + wantedWords.length <= words.length; start += 1) {
      const slice = words.slice(start, start + wantedWords.length);
      if (slice.map((word) => ocrCanonical(word.text)).join(' ') === wanted) {
        return { name: slice.map((word) => word.text).join(' '), type: 'Ocr', help: '', ...box(slice) };
      }
    }
  }
  return null;
}

function ocrHasText(lines, text) {
  const wanted = ocrCanonical(text);
  return (Array.isArray(lines) ? lines : []).some((line) => ocrCanonical(line.text).includes(wanted));
}

function hasText(elements, text) {
  const wanted = normalize(text).toLowerCase();
  return usable(Array.isArray(elements) ? elements : []).some((element) =>
    normalize(element.name).toLowerCase().includes(wanted));
}

function escapeSendKeys(text) {
  return String(text)
    .replace(/[+^%~(){}[\]]/g, (character) => `{${character}}`)
    .replace(/\r?\n/g, '{ENTER}');
}

function describe(target) {
  return target.by === 'role' ? `${target.role} "${target.name}"` : `${target.by} "${target.name}"`;
}

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

class DesktopDriver {
  constructor() {
    this.nextId = 1;
    this.pending = new Map();
    this.stderr = '';
  }

  start() {
    const env = { ...process.env };
    for (const key of Object.keys(env)) {
      if (/(API_KEY|PASSWORD|TOKEN|SECRET|CREDENTIAL)|^QA_/i.test(key)) delete env[key];
    }
    this.child = spawn('powershell.exe',
      ['-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', DRIVER_SCRIPT],
      { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true, env });
    this.child.stderr.on('data', (chunk) => { this.stderr = (this.stderr + chunk).slice(-2_000); });
    this.child.once('exit', (code) => {
      const error = new Error(`The desktop driver stopped (exit code ${code}). ${normalize(this.stderr)}`.trim());
      for (const { reject } of this.pending.values()) reject(error);
      this.pending.clear();
    });
    readline.createInterface({ input: this.child.stdout }).on('line', (line) => {
      let reply;
      try {
        reply = JSON.parse(line.replace(/^﻿/, ''));
      } catch {
        return;
      }
      const waiter = this.pending.get(reply.id);
      if (!waiter) return;
      this.pending.delete(reply.id);
      if (reply.ok) waiter.resolve(reply.data);
      else waiter.reject(new Error(reply.error));
    });
  }

  send(cmd, args = {}, timeoutMs = 60_000) {
    if (!this.child || this.child.exitCode !== null) {
      return Promise.reject(new Error('The desktop driver is not running.'));
    }
    const id = this.nextId;
    this.nextId += 1;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`The desktop driver did not answer "${cmd}" in time.`));
      }, timeoutMs);
      this.pending.set(id, {
        resolve: (data) => { clearTimeout(timer); resolve(data); },
        reject: (error) => { clearTimeout(timer); reject(error); },
      });
      this.child.stdin.write(`${JSON.stringify({ id, cmd, ...args })}\n`);
    });
  }

  async close() {
    if (!this.child || this.child.exitCode !== null) return;
    try {
      await this.send('quit', {}, 3_000);
    } catch {
      // the driver is closing anyway
    }
    if (this.child.exitCode === null) this.child.kill();
  }
}

class DesktopSession {
  constructor(driver) {
    this.driver = driver;
  }

  async elements() {
    const data = await this.driver.send('elements');
    return Array.isArray(data) ? data : [data].filter(Boolean);
  }

  async ocrLines() {
    try {
      const data = await this.driver.send('ocr', {}, 30_000);
      return Array.isArray(data) ? data : [data].filter(Boolean);
    } catch {
      return [];
    }
  }

  // UI Automation first; from the second attempt, OCR as well, for popups automation cannot see.
  async waitFor(target, timeoutMs = STEP_TIMEOUT_MS) {
    const deadline = Date.now() + timeoutMs;
    for (let attempt = 0; ; attempt += 1) {
      const element = resolveLocator(await this.elements(), target);
      if (element) return element;
      if (attempt >= 1 && (target.by === 'text' || target.by === 'role')) {
        const seen = findOcrText(await this.ocrLines(), target.name);
        if (seen) return seen;
      }
      if (Date.now() > deadline) throw new Error(`Could not find ${describe(target)} in the desktop app.`);
      await delay(POLL_MS);
    }
  }

  // Buttons such as "Continue" turn active a moment after a selection, so give the app time to settle.
  async click(element) {
    await this.driver.send('click', center(element));
    await delay(600);
  }

  // Some buttons ignore the first press (for example "Continue" right after choosing a vehicle).
  // When nothing on screen changes, press once more. Single-character keys (keypad digits) are never
  // pressed twice, so an amount cannot be entered twice.
  async clickAndConfirm(element, target) {
    const signature = (elements) => usable(elements).map((item) => `${normalize(item.name)}@${item.x},${item.y}`).join('|');
    const before = signature(await this.elements());
    await this.click(element);
    if (element.type !== 'Button' || normalize(element.name).length <= 1) return;
    for (const wait of [700, 1_500]) {
      if (signature(await this.elements()) !== before) return;
      await delay(wait);
    }
    if (signature(await this.elements()) !== before) return;
    const again = resolveLocator(await this.elements(), target);
    if (again) await this.click(again);
  }

  // MAUI text boxes ignore Ctrl+A, so select with Shift+Home, then check the value and
  // fall back to backspaces until the box is empty.
  async clearInput(target) {
    await this.driver.send('keys', { keys: '{END}+{HOME}{DELETE}' });
    for (let attempt = 0; attempt < 3; attempt += 1) {
      const element = resolveLocator(await this.elements(), target);
      const current = element && typeof element.value === 'string' ? element.value : '';
      if (!current) return;
      await this.driver.send('keys', { keys: `{END}{BACKSPACE ${current.length + 2}}` });
    }
    throw new Error(`Could not clear ${describe(target)} before typing.`);
  }

  async runStep(step, interpolate = (value) => value) {
    if (step.action === 'open') {
      return `Skipped "open ${step.path}": the desktop app has no page paths.`;
    }
    if (step.action === 'expectText') {
      const deadline = Date.now() + STEP_TIMEOUT_MS;
      for (let attempt = 0; ; attempt += 1) {
        if (hasText(await this.elements(), step.text)) return null;
        if (attempt >= 1 && ocrHasText(await this.ocrLines(), step.text)) return null;
        if (Date.now() > deadline) throw new Error(`Text "${step.text}" is not visible in the desktop app.`);
        await delay(POLL_MS);
      }
    }
    let element;
    try {
      element = await this.waitFor(step.target, step.optional ? 10_000 : STEP_TIMEOUT_MS);
    } catch (error) {
      // A popup that only sometimes appears (for example the mileage prompt) is marked optional.
      if (step.optional) return `Skipped optional step: ${describe(step.target)} did not appear.`;
      throw error;
    }
    if (step.action === 'click') {
      await this.clickAndConfirm(element, step.target);
    } else if (step.action === 'fill') {
      await this.click(element);
      await this.clearInput(step.target);
      const value = interpolate(step.value);
      if (value) await this.driver.send('keys', { keys: escapeSendKeys(value) });
    } else if (step.action === 'select') {
      await this.click(element);
      const option = await this.waitFor({ by: 'text', name: interpolate(step.value) });
      await this.click(option);
    }
    return null;
  }

  // Each case starts from the dashboard Overview tab when it is on screen, so cases do not depend
  // on the tab the previous case left open. Nothing happens on other screens.
  // Goes back to the dashboard with the back arrow (at most 5 screens) and opens Overview.
  async goHome() {
    for (let attempt = 0; attempt < 6; attempt += 1) {
      const elements = await this.elements();
      const overview = resolveNamedLocator(elements, { by: 'text', name: 'Overview' });
      if (overview) {
        await this.click(overview);
        return true;
      }
      const back = topLeftButton(elements);
      if (!back) return false;
      await this.click(back);
      await delay(2_000);
    }
    return false;
  }

  // What a person would see now: automation texts top to bottom plus OCR lines (popups).
  async screenText() {
    const automation = [...new Set(usable(await this.elements())
      .sort((a, b) => (a.y - b.y) || (a.x - b.x))
      .map((element) => `${element.type}: ${normalize(element.name)}`))].slice(0, 250);
    const ocr = (await this.ocrLines()).map((line) => normalize(line.text)).filter(Boolean).slice(0, 120);
    return { automation, ocr };
  }

  async readValue(target, timeoutMs = STEP_TIMEOUT_MS) {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const text = readValueText(await this.elements(), target);
      if (text) return text;
      if (Date.now() > deadline) throw new Error(`Could not read a value next to ${describe(target)}.`);
      await delay(POLL_MS);
    }
  }

  async readCell(spec, timeoutMs = STEP_TIMEOUT_MS) {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const text = readCellText(await this.elements(), spec);
      if (text !== null) return text;
      if (Date.now() > deadline) {
        throw new Error(`Could not find row "${spec.row}" with column "${spec.column}". Search for the row first so it is on screen.`);
      }
      await delay(POLL_MS);
    }
  }

  async verifyQa(timeoutMs = 60_000) {
    const deadline = Date.now() + timeoutMs;
    for (;;) {
      const elements = usable(await this.elements());
      if (elements.some((element) => /\bQA\b/.test(element.name))) return;
      if (Date.now() > deadline) {
        throw new Error('Could not see a QA label in the desktop app. Sign in to the QA company first. No tests were run.');
      }
      await delay(1_000);
    }
  }

  async screenshot(filePath) {
    return this.driver.send('screenshot', { path: filePath });
  }

  async close() {
    await this.driver.close();
  }
}

async function createUiaSession(exePath, { verify = true } = {}) {
  const driver = new DesktopDriver();
  driver.start();
  const session = new DesktopSession(driver);
  try {
    await driver.send('attach', { exePath, launch: true, launchTimeoutSec: 90 }, 120_000);
    if (verify) {
      await session.goHome();   // the QA label is shown on the dashboard header
      await session.verifyQa();
    }
    return session;
  } catch (error) {
    await driver.close();
    throw error;
  }
}

module.exports = {
  createUiaSession, escapeSendKeys, findOcrText, hasText, ocrHasText, readCellText, readValueText, resolveLocator,
};
