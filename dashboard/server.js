'use strict';
// Local QA daily dashboard server. Start with: npm run dashboard
const http = require('http');
const fs = require('fs');
const path = require('path');
const store = require('./lib/store');

const PUBLIC = path.join(__dirname, 'public');
const PORT = Number(process.env.DASHBOARD_PORT) || store.loadConfig().port || 4180;
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.svg': 'image/svg+xml' };

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
  res.end(JSON.stringify(body));
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let s = '';
    req.setEncoding('utf8');
    req.on('data', (c) => { s += c; if (s.length > 1e6) req.destroy(); });
    req.on('end', () => { try { resolve(s ? JSON.parse(s) : {}); } catch (e) { reject(new Error('Invalid JSON body')); } });
    req.on('error', reject);
  });
}

let syncing = null;

// Auto sync: today's file is refreshed from Azure DevOps every N minutes while the server runs.
const AUTO_MIN = Number(store.loadConfig().autoSyncMinutes ?? 15);
let lastAuto = null;
async function autoSync() {
  if (syncing) return;
  const date = store.today();
  syncing = store.sync(date);
  try {
    const r = await syncing;
    lastAuto = { at: store.nowIso(), ok: true, added: r.added, changes: r.changes.length };
    console.log(`[auto sync] ${lastAuto.at} ${date}: ${r.added} added, ${r.changes.length} changed`);
    for (const c of r.changes) console.log(`  ~ #${c.devopsId} ${c.fields.map((f) => `${f.field} ${JSON.stringify(f.from)} -> ${JSON.stringify(f.to)}`).join(', ')}`);
  } catch (e) {
    lastAuto = { at: store.nowIso(), ok: false, error: e.message };
    console.log(`[auto sync] failed: ${e.message}`);
  } finally { syncing = null; }
}

// Latest change time of the data files, so the page knows when to reload.
function dataVersion() {
  const dir = require('path').join(__dirname, 'data');
  let v = 0;
  try { for (const f of fs.readdirSync(dir)) if (f.endsWith('.json')) v = Math.max(v, fs.statSync(require('path').join(dir, f)).mtimeMs); } catch { /* none yet */ }
  return Math.round(v);
}

async function api(req, res, url) {
  const parts = url.pathname.split('/').filter(Boolean); // ['api', ...]
  const m = req.method;
  if (m === 'GET' && parts[1] === 'config') {
    const cfg = store.loadConfig();
    return send(res, 200, { me: cfg.me.name, meDevops: cfg.me.devopsName, team: cfg.team.map((t) => t.name), today: store.today(), autoSyncMinutes: AUTO_MIN, devopsBase: store.devopsUrl(1).replace(/1$/, '') });
  }
  if (m === 'GET' && parts[1] === 'version') return send(res, 200, { version: dataVersion(), syncing: !!syncing, lastAuto, today: store.today() });
  if (m === 'GET' && parts[1] === 'all') return send(res, 200, { today: store.today(), days: store.readAll() });
  if (m === 'POST' && parts[1] === 'entries') {
    const b = await readBody(req);
    store.checkDate(b.date);
    return send(res, 201, store.addEntry(b.date, Object.assign({}, b.entry, { source: 'manual' })));
  }
  if (m === 'PUT' && parts[1] === 'entries' && parts.length === 4) {
    const b = await readBody(req);
    return send(res, 200, store.updateEntry(parts[2], parts[3], b));
  }
  if (m === 'DELETE' && parts[1] === 'entries' && parts.length === 4) {
    store.deleteEntry(parts[2], parts[3]);
    return send(res, 200, { ok: true });
  }
  if (m === 'POST' && parts[1] === 'drafts' && parts[4] === 'logged') {
    const b = await readBody(req);
    return send(res, 200, store.logDraft(parts[2], parts[3], b.devopsId, b.date || store.today()));
  }
  if (m === 'POST' && parts[1] === 'sync') {
    const b = await readBody(req);
    const date = b.date || store.today();
    store.checkDate(date);
    if (syncing) return send(res, 409, { error: 'A sync is already running' });
    syncing = store.sync(date);
    try {
      const r = await syncing;
      delete r.addedEntries;
      return send(res, 200, r);
    } catch (e) {
      return send(res, 502, { error: e.message });
    } finally { syncing = null; }
  }
  return send(res, 404, { error: 'Not found' });
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, 'http://localhost');
  try {
    if (url.pathname.startsWith('/api/')) return await api(req, res, url);
    const rel = url.pathname === '/' ? 'index.html' : decodeURIComponent(url.pathname).replace(/^\/+/, '');
    const file = path.resolve(PUBLIC, rel);
    if (!file.startsWith(PUBLIC + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
      res.writeHead(404); return res.end('Not found');
    }
    res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
    fs.createReadStream(file).pipe(res);
  } catch (e) {
    send(res, 400, { error: e.message });
  }
});

server.listen(PORT, '127.0.0.1', () => {
  console.log(`QA dashboard running at http://localhost:${PORT}`);
  if (AUTO_MIN > 0) {
    console.log(`Auto sync with Azure DevOps every ${AUTO_MIN} minutes`);
    setTimeout(autoSync, 15000);
    setInterval(autoSync, AUTO_MIN * 60000);
  }
});
