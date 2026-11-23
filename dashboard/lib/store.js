'use strict';
// Data layer: one JSON file per day in dashboard/data, dates in Asia/Amman.
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFile } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const DATA_DIR = path.join(ROOT, 'data');
const CONFIG_PATH = path.join(ROOT, 'config', 'team.json');
const FETCH_SCRIPT = path.join(ROOT, 'scripts', 'fetch-devops.ps1');
const REFRESH_SCRIPT = path.join(ROOT, 'scripts', 'refresh-items.ps1');

const TYPES = ['story', 'testcase', 'test_run', 'bug_opened', 'bug_closed', 'bug_draft', 'question', 'blocker'];
// Types that are Azure DevOps work items: they always carry a real DevOps ID.
const NEEDS_ID = ['story', 'testcase', 'bug_opened', 'bug_closed'];
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

function loadConfig() {
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}

// Wall-clock parts of `d` in the configured timezone.
function zoneParts(d, tz) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23',
  }).formatToParts(d);
  const o = {};
  for (const p of parts) o[p.type] = p.value;
  return o;
}

function today(tz = loadConfig().timezone) {
  const p = zoneParts(new Date(), tz);
  return `${p.year}-${p.month}-${p.day}`;
}

// ISO timestamp with the timezone offset, e.g. 2026-11-15T18:57:00+03:00.
function nowIso(tz = loadConfig().timezone) {
  const d = new Date();
  d.setMilliseconds(0);
  const p = zoneParts(d, tz);
  const local = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute, +p.second);
  const off = Math.round((local - d.getTime()) / 60000);
  const sign = off >= 0 ? '+' : '-';
  const hh = String(Math.floor(Math.abs(off) / 60)).padStart(2, '0');
  const mm = String(Math.abs(off) % 60).padStart(2, '0');
  return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}:${p.second}${sign}${hh}:${mm}`;
}

function checkDate(date) {
  if (!DATE_RE.test(date || '')) throw new Error(`Invalid date "${date}", expected YYYY-MM-DD`);
}

function dayPath(date) {
  checkDate(date);
  return path.join(DATA_DIR, `${date}.json`);
}

function emptyDay(date) {
  return { date, entries: [], team: null, teamSyncedAt: null, mySyncedAt: null, storyRefs: {} };
}

function readDay(date) {
  const p = dayPath(date);
  if (!fs.existsSync(p)) return emptyDay(date);
  return Object.assign(emptyDay(date), JSON.parse(fs.readFileSync(p, 'utf8')));
}

function writeDay(day) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
  const p = dayPath(day.date);
  const tmp = `${p}.tmp`;
  fs.writeFileSync(tmp, JSON.stringify(day, null, 2) + '\n', 'utf8');
  fs.renameSync(tmp, p);
}

function listDays() {
  if (!fs.existsSync(DATA_DIR)) return [];
  return fs.readdirSync(DATA_DIR)
    .filter((f) => /^\d{4}-\d{2}-\d{2}\.json$/.test(f))
    .map((f) => f.slice(0, 10))
    .sort();
}

function devopsUrl(id, cfg = loadConfig()) {
  if (!id) return null;
  return `${cfg.devops.collection.replace(/\/$/, '')}/${cfg.devops.project}/_workitems/edit/${id}`;
}

function toIntOrNull(v) {
  if (v === undefined || v === null || v === '') return null;
  const n = Number(v);
  if (!Number.isInteger(n) || n <= 0) throw new Error(`Invalid ID "${v}"`);
  return n;
}

// Validates and normalises an entry. Never invents IDs: DevOps item types must come with one.
function normalise(input, existing = {}) {
  const cfg = loadConfig();
  const e = Object.assign({}, existing, input);
  if (!TYPES.includes(e.type)) throw new Error(`Unknown type "${e.type}". Use one of: ${TYPES.join(', ')}`);
  e.devopsId = toIntOrNull(e.devopsId);
  e.storyId = toIntOrNull(e.storyId);
  if (NEEDS_ID.includes(e.type) && !e.devopsId) {
    throw new Error(`Type "${e.type}" needs a real Azure DevOps ID. Log it as bug_draft (or question / blocker) until it exists in DevOps.`);
  }
  if (e.type === 'bug_draft' && e.devopsId) throw new Error('A bug draft has no DevOps ID. Use "logged" to turn it into an opened bug.');
  if (e.type === 'story' && !e.storyId) e.storyId = e.devopsId;
  e.title = String(e.title || '').trim();
  if (!e.title && !(e.type === 'story' || e.type === 'test_run')) throw new Error('Title (or question text) is required');
  e.owner = e.owner || cfg.me.name;
  e.source = ['claude', 'manual', 'devops-sync'].includes(e.source) ? e.source : 'claude';
  e.timestamp = e.timestamp || nowIso(cfg.timezone);
  e.notes = e.notes || '';
  e.url = devopsUrl(e.devopsId, cfg);
  if (!e.status) {
    e.status = { question: 'open', blocker: 'open', bug_draft: 'draft' }[e.type] || '';
  }
  if (e.type === 'test_run') {
    const r = e.run || {};
    e.run = {
      build: String(r.build || ''),
      pass: +r.pass || 0, fail: +r.fail || 0, blocked: +r.blocked || 0, notRun: +r.notRun || 0,
    };
    if (!e.storyId) throw new Error('A test run needs the user story ID');
  } else delete e.run;
  if (!String(e.type).startsWith('bug')) delete e.bug;
  else if (e.bug) {
    const b = { issueType: String(e.bug.issueType || ''), qaBugType: String(e.bug.qaBugType || ''), severity: String(e.bug.severity || ''), screen: String(e.bug.screen || '').trim() };
    if (Object.values(b).some(Boolean)) e.bug = b; else delete e.bug;
  }
  if (e.type === 'question') {
    const q = e.question || {};
    e.question = { answer: q.answer || '', answeredOn: q.answeredOn || null };
  } else delete e.question;
  if (e.type === 'blocker') {
    e.resolvedOn = e.resolvedOn || null;
  }
  return e;
}

function nextId(day) {
  const stamp = day.date.replace(/-/g, '');
  let max = 0;
  for (const e of day.entries) {
    const m = /^e-\d{8}-(\d+)$/.exec(e.id || '');
    if (m) max = Math.max(max, +m[1]);
  }
  return `e-${stamp}-${String(max + 1).padStart(3, '0')}`;
}

function addEntry(date, input) {
  const day = readDay(date);
  const e = normalise(input);
  e.id = nextId(day);
  day.entries.push(e);
  writeDay(day);
  return e;
}

function updateEntry(date, id, patch) {
  const day = readDay(date);
  const i = day.entries.findIndex((e) => e.id === id);
  if (i < 0) throw new Error(`Entry ${id} not found on ${date}`);
  const merged = normalise(Object.assign({}, patch, { id }), day.entries[i]);
  day.entries[i] = merged;
  writeDay(day);
  return merged;
}

function deleteEntry(date, id) {
  const day = readDay(date);
  const before = day.entries.length;
  day.entries = day.entries.filter((e) => e.id !== id);
  if (day.entries.length === before) throw new Error(`Entry ${id} not found on ${date}`);
  writeDay(day);
}

// A draft is opened on DevOps: the draft is kept (status "logged"), and a bug_opened entry is added on `date`.
function logDraft(draftDate, draftId, devopsId, date) {
  const id = toIntOrNull(devopsId);
  if (!id) throw new Error('The real DevOps bug ID is required');
  const draftDay = readDay(draftDate);
  const d = draftDay.entries.find((e) => e.id === draftId);
  if (!d || d.type !== 'bug_draft') throw new Error(`Draft ${draftId} not found on ${draftDate}`);
  d.status = `logged as ${id}`;
  d.loggedAs = id;
  writeDay(draftDay);
  const existing = readDay(date).entries.find((e) => e.type === 'bug_opened' && e.devopsId === id);
  if (existing) return existing;
  return addEntry(date, {
    type: 'bug_opened', devopsId: id, storyId: d.storyId, title: d.title, status: 'New',
    owner: d.owner, source: d.source, notes: d.notes, fromDraft: `${draftDate}/${draftId}`,
  });
}

function readAll() {
  const days = {};
  for (const date of listDays()) days[date] = readDay(date);
  return days;
}

// ---- Azure DevOps sync ----

function runFetch(date) {
  checkDate(date);
  const out = path.join(os.tmpdir(), `qa-dash-${date}-${process.pid}-${Date.now()}.json`);
  return new Promise((resolve, reject) => {
    execFile('powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', FETCH_SCRIPT, '-Date', date, '-Config', CONFIG_PATH, '-Out', out],
      { timeout: 240000, windowsHide: true },
      (err, stdout, stderr) => {
        if (err) return reject(new Error(`DevOps fetch failed: ${(stderr || err.message).trim()}`));
        try {
          const data = JSON.parse(fs.readFileSync(out, 'utf8').replace(/^﻿/, ''));
          fs.unlinkSync(out);
          resolve(data);
        } catch (e) { reject(e); }
      });
  });
}

const arr = (v) => (Array.isArray(v) ? v : v ? [v] : []);

// Adds missing DevOps items to my entries and refreshes the team snapshot. Never touches manual notes.
function mergeSync(date, data) {
  const cfg = loadConfig();
  const day = readDay(date);
  const added = [];
  const updated = [];
  const upsert = (type, item, extra = {}) => {
    const found = day.entries.find((e) => e.type === type && e.devopsId === item.id);
    if (found) {
      let changed = false;
      for (const [k, raw] of Object.entries({ title: item.title, status: item.state })) {
        const v = String(raw || '').trim();
        if (v && found[k] !== v) { found[k] = v; changed = true; }
      }
      if (!found.storyId && item.storyId && type !== 'story') { found.storyId = item.storyId; changed = true; }
      const bf = bugFields(item, type);
      if (bf && JSON.stringify(found.bug) !== JSON.stringify(bf)) { found.bug = bf; changed = true; }
      if (changed) updated.push(found);
      return;
    }
    const e = normalise(Object.assign({
      type, devopsId: item.id, storyId: type === 'story' ? item.id : item.storyId || null,
      title: item.title, status: item.state, owner: cfg.me.name, source: 'devops-sync',
      timestamp: devopsTime(item, type) || nowIso(cfg.timezone),
    }, extra));
    const bf = bugFields(item, type);
    if (bf) e.bug = bf;
    e.id = nextId(day);
    day.entries.push(e);
    added.push(e);
  };
  const me = data.me || {};
  for (const s of arr(me.stories)) upsert('story', s, { notes: storyReason(s.reason) });
  for (const t of arr(me.testcases)) upsert('testcase', t);
  for (const b of arr(me.bugsOpened)) upsert('bug_opened', b);
  for (const b of arr(me.bugsClosed)) upsert('bug_closed', b);
  day.team = arr(data.team).map((m) => ({
    name: m.name,
    stories: arr(m.stories).map(pick),
    testcases: arr(m.testcases).map(pick),
    bugsOpened: arr(m.bugsOpened).map(pick),
    bugsClosed: arr(m.bugsClosed).map(pick),
  }));
  day.storyRefs = Object.assign({}, day.storyRefs, data.storyRefs || {});
  day.teamSyncedAt = nowIso(cfg.timezone);
  day.mySyncedAt = day.teamSyncedAt;
  writeDay(day);
  return { date, added: added.length, updated: updated.length, scanned: data.scanned, addedEntries: added };
}

// Bug classification from Azure DevOps (Issue Type, QA Bug Type, Severity, Screen).
function bugFields(item, type) {
  if (type && !String(type).startsWith('bug')) return null;
  const b = { issueType: item.issueType || '', qaBugType: item.qaBugType || '', severity: item.severity || '', screen: (item.screen || '').trim() };
  return Object.values(b).some(Boolean) ? b : null;
}

function pick(x) {
  const p = { id: x.id, title: x.title, state: x.state, storyId: x.storyId || null, reason: x.reason || '', url: devopsUrl(x.id) };
  const bf = bugFields(x);
  if (bf) p.bug = bf;
  return p;
}

function storyReason(r) {
  return { assigned: 'Assigned to me', created: 'Created by me', 'linked work': 'Test cases or bugs logged under it' }[r] || '';
}

// Uses the DevOps created or closed time as the entry time, shown in local time.
function devopsTime(item, type) {
  const v = type === 'bug_closed' ? item.closedDate : type === 'story' ? null : item.createdDate;
  if (!v) return null;
  const tz = loadConfig().timezone;
  const d = new Date(v);
  if (isNaN(d)) return null;
  const p = zoneParts(d, tz);
  return `${p.year}-${p.month}-${p.day}T${p.hour}:${p.minute}:${p.second}${offsetOf(d, tz)}`;
}

function offsetOf(d, tz) {
  const p = zoneParts(d, tz);
  const local = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute, +p.second);
  const off = Math.round((local - Math.floor(d.getTime() / 1000) * 1000) / 60000);
  const sign = off >= 0 ? '+' : '-';
  return `${sign}${String(Math.floor(Math.abs(off) / 60)).padStart(2, '0')}:${String(Math.abs(off) % 60).padStart(2, '0')}`;
}

// ---- Refresh: Azure DevOps is the source of truth for status ----

const CLOSED_RE = /^(closed|done|removed)$/i;
const isClosedState = (st) => CLOSED_RE.test(String(st || '').trim());

// A bug counts as reopened when its history shows Closed followed by any other state
// (for example Closed by mistake, then back to Resolved or Active).
function wasReopened(log) {
  let closed = false;
  for (const l of log || []) {
    if (isClosedState(l.state)) closed = true;
    else if (closed) return true;
  }
  return false;
}

function runRefresh(ids) {
  const stamp = `${process.pid}-${Date.now()}`;
  const idsFile = path.join(os.tmpdir(), `qa-dash-ids-${stamp}.txt`);
  const out = path.join(os.tmpdir(), `qa-dash-refresh-${stamp}.json`);
  fs.writeFileSync(idsFile, ids.join(','), 'utf8');
  return new Promise((resolve, reject) => {
    execFile('powershell.exe',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', REFRESH_SCRIPT, '-IdsFile', idsFile, '-Config', CONFIG_PATH, '-Out', out],
      { timeout: 300000, windowsHide: true },
      (err, stdout, stderr) => {
        try { fs.unlinkSync(idsFile); } catch { /* ignore */ }
        if (err) return reject(new Error(`DevOps refresh failed: ${(stderr || err.message).trim()}`));
        try {
          const data = JSON.parse(fs.readFileSync(out, 'utf8').replace(/^\uFEFF/, ''));
          fs.unlinkSync(out);
          resolve(data);
        } catch (e) { reject(e); }
      });
  });
}

// Re-reads every item with a DevOps ID on the selected day, plus bugs, questions and blockers
// from earlier days that are still open, and updates them from the fresh read.
async function refreshFromDevops(date) {
  const cfg = loadConfig();
  const days = {};
  const targets = [];
  for (const d of listDays()) {
    if (d > date) continue;
    const day = readDay(d);
    days[d] = day;
    for (const e of day.entries) {
      if (!e.devopsId) continue; // manual entries without an ID stay untouched
      const stillOpen = (e.type === 'bug_opened' || e.type === 'bug_closed') ? !isClosedState(e.status)
        : (e.type === 'question' || e.type === 'blocker') ? e.status !== 'answered' && e.status !== 'resolved'
        : e.type === 'story' ? !isClosedState(e.status) && e.status !== 'Removed' : false; // stories still in progress or Resolved
      if (d === date || stillOpen || (e.type === 'bug_closed' && d === date)) targets.push({ d, e });
    }
  }
  const ids = [...new Set(targets.map((t) => t.e.devopsId))];
  if (!ids.length) return { checked: 0, changes: [], missing: [] };
  const data = await runRefresh(ids);
  const byId = new Map(arr(data.items).map((x) => [x.id, x]));
  const changes = [];
  const touched = new Set();
  for (const { d, e } of targets) {
    const x = byId.get(e.devopsId);
    if (!x) continue;
    const before = { status: e.status, title: e.title, assignedTo: e.assignedTo || '', storyId: e.storyId || null, reopened: !!e.reopened };
    const isBug = e.type.startsWith('bug');
    const isStoryRef = e.type === 'question' || e.type === 'blocker';
    if (!isStoryRef) {
      if (x.title) e.title = String(x.title).trim();
      if (x.state) e.status = x.state;
      e.assignedTo = x.assignedTo || '';
      if (e.type !== 'story') {
        if (x.storyId) e.storyId = x.storyId;
        else if (e.source === 'devops-sync') e.storyId = null; // keep a story the user set by hand
      }
    }
    if (isBug) {
      const bf = bugFields(x, e.type);
      if (bf) e.bug = bf;
      e.statusLog = arr(x.statusLog).map((l) => ({ state: l.state, at: l.at, by: l.by || '' }));
      e.reopened = wasReopened(e.statusLog);
      e.closedNow = isClosedState(e.status);
    }
    // Stories keep their status history too, so the Resolved tab can show when and by whom.
    if (e.type === 'story' && x.statusLog) e.statusLog = arr(x.statusLog).map((l) => ({ state: l.state, at: l.at, by: l.by || '' }));
    e.refreshedAt = nowIso(cfg.timezone);
    const after = { status: e.status, title: e.title, assignedTo: e.assignedTo || '', storyId: e.storyId || null, reopened: !!e.reopened };
    const diff = Object.keys(after).filter((k) => JSON.stringify(before[k]) !== JSON.stringify(after[k]));
    // the first refresh only fills in assignee and history; report it as a change only when something was already known
    const real = diff.filter((k) => !(k === 'assignedTo' && !before.assignedTo) && !(k === 'reopened' && !after.reopened));
    if (real.length) changes.push({ date: d, id: e.id, devopsId: e.devopsId, type: e.type, title: e.title, fields: real.map((k) => ({ field: k, from: before[k], to: after[k] })) });
    touched.add(d);
  }
  for (const d of touched) writeDay(days[d]);
  return { checked: ids.length, changes, missing: arr(data.missing) };
}

function recordSyncError(date, message) {
  try {
    const day = readDay(date);
    day.lastSyncError = { at: nowIso(), message: String(message).slice(0, 500) };
    writeDay(day);
  } catch { /* ignore */ }
}

async function sync(date = today()) {
  try {
    const data = await runFetch(date);
    const res = mergeSync(date, data);
    const ref = await refreshFromDevops(date);
    const day = readDay(date);
    day.mySyncedAt = nowIso();
    day.teamSyncedAt = day.mySyncedAt;
    delete day.lastSyncError;
    writeDay(day);
    return Object.assign(res, { checked: ref.checked, changes: ref.changes, missing: ref.missing });
  } catch (e) {
    recordSyncError(date, e.message);
    throw e;
  }
}

module.exports = {
  TYPES, NEEDS_ID, loadConfig, today, nowIso, readDay, writeDay, listDays, readAll,
  addEntry, updateEntry, deleteEntry, logDraft, sync, devopsUrl, checkDate, refreshFromDevops, recordSyncError,
};
