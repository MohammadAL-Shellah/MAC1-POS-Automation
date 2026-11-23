'use strict';
(() => {
  const $ = (s) => document.querySelector(s);
  const TYPE_LABEL = {
    story: 'User story', testcase: 'Test case', test_run: 'Test run', bug_opened: 'Bug opened',
    bug_closed: 'Bug closed', bug_draft: 'Bug draft', question: 'Business question', blocker: 'Blocker',
  };
  const NEEDS_ID = ['story', 'testcase', 'bug_opened', 'bug_closed'];
  const STATUS_HINTS = {
    story: ['New', 'Active', 'Resolved', 'Closed'], testcase: ['Design', 'Ready', 'Closed'],
    bug_opened: ['New', 'Active', 'Resolved'], bug_closed: ['Closed'], bug_draft: ['draft'],
    question: ['open', 'answered'], blocker: ['open', 'resolved'], test_run: ['In progress', 'Finished'],
  };
  const CHIP_COLORS = ['var(--k-blue)', 'var(--k-violet)', 'var(--k-teal)', 'var(--k-amber)', 'var(--k-red)', 'var(--k-green)', 'var(--k-slate)'];
  const TAB_STYLE = { work: ['today', 'var(--k-blue)'], bugs: ['bug', 'var(--k-red)'], resolved: ['check', 'var(--k-amber)'], questions: ['help', 'var(--k-amber)'], stories: ['layers', 'var(--k-violet)'], team: ['users', 'var(--k-teal)'] };
  const TITLES = { work: 'Today', bugs: 'Bugs', resolved: 'Resolved, waiting for you to verify', questions: 'Questions and blockers', stories: 'User stories', team: 'QA team' };

  // ---------- icons ----------
  const P = {
    calendar: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>',
    today: '<rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18M9 16l2 2 4-4"/>',
    bug: '<rect x="8" y="6" width="8" height="14" rx="4"/><path d="M19 7l-3 2M5 7l3 2M19 19l-3-2M5 19l3-2M20 13h-4M4 13h4M10 4l1 2M14 4l-1 2"/>',
    help: '<circle cx="12" cy="12" r="10"/><path d="M9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3M12 17h.01"/>',
    layers: '<path d="M12 2 2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>',
    users: '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.9M16 3.1a4 4 0 0 1 0 7.8"/>',
    left: '<path d="m15 18-6-6 6-6"/>',
    right: '<path d="m9 18 6-6-6-6"/>',
    down: '<path d="m6 9 6 6 6-6"/>',
    search: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
    sync: '<path d="M21 12a9 9 0 0 1-15.5 6.3L3 16M3 12a9 9 0 0 1 15.5-6.3L21 8M21 3v5h-5M3 21v-5h5"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    bell: '<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10.3 21a1.9 1.9 0 0 0 3.4 0"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    play: '<path d="M6 3l14 9-14 9z"/>',
    file: '<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M9 15l2 2 4-4"/>',
    alert: '<path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0zM12 9v4M12 17h.01"/>',
    check: '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>',
    draft: '<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z"/>',
    ext: '<path d="M15 3h6v6M10 14 21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>',
    trash: '<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/>',
    chart: '<path d="M3 3v18h18"/><path d="M7 16v-4M12 16V7M17 16v-8"/>',
    flag: '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1zM4 22v-7"/>',
  };
  const icon = (n) => `<svg class="i" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${P[n] || ''}</svg>`;
  const fillIcons = (root = document) => root.querySelectorAll('[data-icon]').forEach((el) => { el.innerHTML = icon(el.dataset.icon); });

  const state = { cfg: null, days: {}, today: '', date: '', tab: 'work', q: '', story: null, bugFilter: 'all', qFilter: 'blockers', rFilter: 'all', closed: new Set() };

  // ---------- utils ----------
  const esc = (s) => String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const ls = {
    get(k) { try { return localStorage.getItem(k); } catch { return null; } },
    set(k, v) { try { localStorage.setItem(k, v); } catch { /* ignore */ } },
  };
  function addDays(date, n) {
    const d = new Date(`${date}T12:00:00Z`);
    d.setUTCDate(d.getUTCDate() + n);
    return d.toISOString().slice(0, 10);
  }
  const fmt = (date, o) => new Date(`${date}T12:00:00Z`).toLocaleDateString('en-GB', Object.assign({ timeZone: 'UTC' }, o));
  const longDate = (d) => fmt(d, { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  const shortDate = (d) => fmt(d, { day: 'numeric', month: 'short' });
  const hhmm = (ts) => (ts && ts.length >= 16 ? ts.slice(11, 16) : '');
  const daysBetween = (a, b) => Math.round((new Date(`${b}T12:00:00Z`) - new Date(`${a}T12:00:00Z`)) / 864e5);
  function toast(msg, ms = 3200) {
    const t = $('#toast');
    t.textContent = msg;
    t.classList.add('show');
    clearTimeout(toast.t);
    toast.t = setTimeout(() => t.classList.remove('show'), ms);
  }
  async function api(method, url, body) {
    const r = await fetch(url, { method, headers: body ? { 'Content-Type': 'application/json' } : {}, body: body ? JSON.stringify(body) : undefined });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(j.error || `Request failed (${r.status})`);
    return j;
  }
  const devops = (id) => `${state.cfg.devopsBase}${id}`;
  const link = (id) => `<a href="${devops(id)}" target="_blank" rel="noopener" data-stop>#${id}</a>`;

  // ---------- data ----------
  function allEntries() {
    const out = [];
    for (const [date, day] of Object.entries(state.days)) for (const e of day.entries || []) out.push(Object.assign({ _date: date }, e));
    return out;
  }
  const dayEntries = (date) => (state.days[date]?.entries || []).map((e) => Object.assign({ _date: date }, e));
  const findEntry = (date, id) => dayEntries(date).find((x) => x.id === id);

  function storyInfo(id) {
    let title = '';
    let st = '';
    for (const d of Object.keys(state.days).sort()) {
      const day = state.days[d];
      const ref = day.storyRefs?.[id];
      if (ref) { title = ref.title || title; st = ref.state || st; }
      for (const e of day.entries || []) if (e.type === 'story' && e.devopsId === id) { title = e.title || title; st = e.status || st; }
      for (const m of day.team || []) for (const s of m.stories || []) if (s.id === id) { title = s.title || title; st = s.state || st; }
    }
    return { title: title.trim(), state: st };
  }
  const isOpenOn = (e, D) => {
    if (e._date > D) return false;
    if (e.type === 'question') return e.status !== 'answered' || (e.question?.answeredOn && e.question.answeredOn > D);
    if (e.type === 'blocker') return e.status !== 'resolved' || (e.resolvedOn && e.resolvedOn > D);
    if (e.type === 'bug_draft') return e.status === 'draft';
    return false;
  };
  const carried = (D, type) => allEntries().filter((e) => e.type === type && isOpenOn(e, D));
  // Azure DevOps is the source of truth: a bug logged as closed that is open again counts as open.
  const CLOSED_RE = /^(closed|done|removed)$/i;
  const bugIsClosed = (e) => e.type === 'bug_closed' && CLOSED_RE.test(String(e.status || '').trim());
  const bugIsOpen = (e) => e.type === 'bug_opened' || (e.type === 'bug_closed' && !bugIsClosed(e));
  const reoBadge = (e) => (e.reopened || (e.type === 'bug_closed' && !bugIsClosed(e)) ? '<span class="btag reo">Reopened</span>' : '');
  const fmtAt = (iso) => { const d = new Date(iso); return isNaN(d) ? '' : d.toLocaleString('en-GB', { timeZone: 'Asia/Amman', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }); };
  function matches(e) {
    if (!state.q) return true;
    const q = state.q.toLowerCase().replace(/^#/, '');
    return [e.devopsId, e.storyId, e.title, e.notes, e.status, e.owner, e.question?.answer, storyInfo(e.storyId).title]
      .some((v) => v != null && String(v).toLowerCase().includes(q));
  }
  function groupByStory(items, key = (x) => x.storyId) {
    const map = new Map();
    for (const it of items) {
      const k = key(it) || 'none';
      if (!map.has(k)) map.set(k, []);
      map.get(k).push(it);
    }
    return [...map.entries()].sort((a, b) => (a[0] === 'none') - (b[0] === 'none') || b[1].length - a[1].length || b[0] - a[0]);
  }

  // ---------- small pieces ----------
  function pillClass(status, type) {
    const s = String(status || '').toLowerCase();
    if (type === 'bug_opened') return s === 'closed' || s === 'resolved' ? 'good' : 'bad';
    if (['closed', 'resolved', 'answered', 'done', 'finished'].includes(s)) return 'good';
    if (type === 'blocker' && s === 'open') return 'bad';
    if (type === 'question' && s === 'open') return 'warn';
    if (s.startsWith('stopped') || s === 'draft') return 'warn';
    if (s === 'active' || s === 'in progress') return 'info';
    return '';
  }
  const pill = (status, type) => (status ? `<span class="pill ${pillClass(status, type)}">${esc(status)}</span>` : '');
  const manualTag = (e) => (e.source === 'manual' ? '<span class="tag" title="Added by hand">manual</span>' : '');

  // A compact row. The whole row opens the details panel.
  function row(e, opts = {}) {
    const age = opts.age && e._date !== state.date ? `<span class="age">${daysBetween(e._date, state.date)} days</span>` : '';
    const st = opts.pill === false || (e.type === 'bug_draft' && e.status === 'draft') ? '' : pill(opts.status || e.status, e.type);
    const noId = opts.noIdLabel ?? 'Draft';
    const rid = e.devopsId ? `<span class="rid">#${e.devopsId}</span>` : noId ? `<span class="rid none">${noId}</span>` : '';
    const kind = opts.kind || { bug_opened: 'opened', bug_closed: 'closed', bug_draft: 'draft', blocker: 'blocker', question: 'question', testcase: 'testcase', story: 'story' }[e.type] || '';
    return `<li class="row k-${kind}${opts.wrap ? ' wrap' : ''}" data-open="entry" data-date="${e._date}" data-id="${e.id}" tabindex="0">
      ${rid}
      <span class="rt">${esc(e.title || TYPE_LABEL[e.type])}</span>
      <span class="rs">${age}${manualTag(e)}${st}</span><span class="go">${icon('right')}</span></li>`;
  }
  function runParts(r) {
    const total = r.pass + r.fail + r.blocked + r.notRun;
    const pct = total ? Math.round((r.pass / total) * 100) : 0;
    const segs = [['pass', 'Pass', r.pass], ['fail', 'Fail', r.fail], ['blocked', 'Blocked', r.blocked], ['notrun', 'Not run', r.notRun]];
    const bar = `<div class="bar" role="img" aria-label="${segs.map((s) => `${s[1]} ${s[2]}`).join(', ')}">${segs.filter((s) => s[2] > 0).map((s) => `<span class="seg-${s[0]}" style="flex:${s[2]}" title="${s[1]}: ${s[2]} of ${total}"></span>`).join('')}</div>`;
    const legend = `<div class="legend">${segs.map((s) => `<span><i class="seg-${s[0]}"></i>${s[1]}<b>${s[2]}</b></span>`).join('')}</div>`;
    return { total, pct, bar, legend };
  }
  function section(key, ico, color, title, subtitle, count, body) {
    const closed = state.closed.has(key);
    return `<section class="card section${closed ? ' closed' : ''}" id="sec-${key}" style="--kc:var(--k-${color});--ks:var(--k-${color}-s)">
      <div class="sec-h" data-toggle="${key}" role="button" tabindex="0" aria-expanded="${!closed}">
        <span class="sec-ico">${icon(ico)}</span>
        <div class="sec-t"><h2>${title}</h2>${subtitle ? `<p>${subtitle}</p>` : ''}</div>
        ${count != null ? `<span class="count">${count}</span>` : ''}<span class="chev">${icon('down')}</span>
      </div><div class="sec-b">${body}</div></section>`;
  }
  const emptyLine = (msg) => `<div class="empty">${msg}</div>`;
  const storyLabel = (sid, none = 'Not linked to a user story') => {
    if (sid === 'none' || !sid) return `<div class="glabel plain">${none}</div>`;
    const s = storyInfo(+sid);
    return `<div class="glabel"><a href="#" data-open="story" data-sid="${sid}">#${sid}</a><span class="gt">${esc(s.title)}</span>${pill(s.state)}</div>`;
  };

  // ---------- KPI cards ----------
  function kpis(D) {
    const es = dayEntries(D);
    const stories = new Set(es.filter((e) => e.storyId).map((e) => e.storyId));
    const executed = es.filter((e) => e.type === 'test_run').reduce((n, e) => n + e.run.pass + e.run.fail + e.run.blocked, 0);
    return [
      ['Stories worked on', stories.size, 'layers', 'blue', 'work:stories'],
      ['Test cases written', es.filter((e) => e.type === 'testcase').length, 'file', 'violet', 'work:tc'],
      ['Cases executed', executed, 'play', 'teal', 'work:runs'],
      ['Bugs opened', es.filter(bugIsOpen).length, 'bug', 'red', 'bugs:opened'],
      ['Bugs closed', es.filter(bugIsClosed).length, 'check', 'green', 'bugs:closed'],
      ['Bug drafts', carried(D, 'bug_draft').length, 'draft', 'slate', 'bugs:drafts'],
      ['Open questions', carried(D, 'question').length, 'help', 'amber', 'questions:questions'],
      ['Open blockers', carried(D, 'blocker').length, 'flag', 'red', 'questions:blockers'],
    ];
  }
  function renderKpis() {
    $('#tiles').innerHTML = kpis(state.date).map(([l, v, ic, c, go]) => `<button class="kpi${v ? '' : ' zero'}" data-go="${go}" style="--kc:var(--k-${c});--ks:var(--k-${c}-s)">
      <span class="kt"><span class="kv">${v}</span><span class="kico">${icon(ic)}</span></span><span class="kl">${l}</span></button>`).join('');
  }

  // ---------- Today (Midnight gold layout) ----------
  const shortTitle = (t) => String(t || '').replace(/^\s*myShop\s+(POS|Portal)\s*-\s*/i, '').trim();
  function ring(r) {
    const total = r.pass + r.fail + r.blocked + r.notRun;
    const pct = total ? Math.round((r.pass / total) * 100) : 0;
    const R = 56;
    const C = 2 * Math.PI * R;
    let off = 0;
    const segs = [['pass', 'Pass', 'var(--pass)'], ['fail', 'Fail', 'var(--fail-fill)'], ['blocked', 'Blocked', 'var(--blocked)'], ['notRun', 'Not run', 'var(--notrun)']]
      .filter(([k]) => r[k] > 0)
      .map(([k, l, c]) => {
        const len = (r[k] / total) * C;
        const gap = segsGap(len);
        const el = `<circle cx="66" cy="66" r="${R}" fill="none" stroke="${c}" stroke-width="12" stroke-dasharray="${Math.max(len - gap, 0.5)} ${C}" stroke-dashoffset="${-off}"><title>${l}: ${r[k]} of ${total}</title></circle>`;
        off += len;
        return el;
      });
    return `<svg viewBox="0 0 132 132" role="img" aria-label="${pct}% pass">${total ? '' : `<circle cx="66" cy="66" r="${R}" fill="none" stroke="var(--notrun)" stroke-width="12"/>`}${segs.join('')}</svg><div class="pc"><div>${pct}%<small>pass</small></div></div>`;
  }
  const segsGap = (len) => (len > 6 ? 3 : 0);

  function renderWork() {
    const D = state.date;
    const es = dayEntries(D).filter(matches);
    const k = Object.fromEntries(kpis(D).map(([l, v]) => [l, v]));
    const blockersAll = carried(D, 'blocker');

    const summary = `<div class="sum">
      <div class="card sumcard wide"><div><div class="lbl">Test cases written ${D === state.today ? 'today' : 'on this day'}</div><div class="big">${k['Test cases written']}</div></div>
        <div class="minis2"><div><b>${k['Stories worked on']}</b><span>Stories</span></div><div><b>${k['Cases executed']}</b><span>Executed</span></div></div></div>
      <div class="card sumcard clickable" data-go="bugs:all"><div class="lbl">Bugs</div>
        <div class="bugnums"><div class="o"><b>${k['Bugs opened']}</b><span>Opened</span></div><div class="c"><b>${k['Bugs closed']}</b><span>Closed</span></div></div></div>
      <div class="card needs"><h3>Needs you</h3>
        <button data-go="questions:blockers"><span>Blockers</span><b class="${k['Open blockers'] ? 'hot' : ''}">${k['Open blockers']}</b></button>
        <button data-go="questions:questions"><span>Business questions</span><b>${k['Open questions']}</b></button>
        <button data-go="bugs:drafts"><span>Bug drafts</span><b>${k['Bug drafts']}</b></button></div>
    </div>`;

    // Stories with a test run on this day
    const runByStory = new Map();
    for (const e of es.filter((x) => x.type === 'test_run')) {
      const cur = runByStory.get(e.storyId);
      if (!cur || e.timestamp > cur.timestamp) runByStory.set(e.storyId, e);
    }
    const storyCards = [...runByStory.values()].map((run) => {
      const id = run.storyId;
      const s = storyInfo(id);
      const r = run.run;
      const total = r.pass + r.fail + r.blocked + r.notRun;
      const executed = r.pass + r.fail + r.blocked;
      const written = es.filter((e) => e.type === 'testcase' && e.storyId === id).length;
      const line = [written ? `${written} cases written` : '', `${executed} of ${total} executed${r.build ? ` on build ${esc(r.build)}` : ''}`, run.status ? esc(run.status.toLowerCase()) : ''].filter(Boolean).join(' · ');
      const counts = [['p', 'pass', r.pass], ['f', 'fail', r.fail], ['bl', 'blocked', r.blocked], ['n', 'not run', r.notRun]].filter((c) => c[2] > 0)
        .map(([c, l, v]) => `<span class="${c}"><b>${v}</b>${l}</span>`).join('');
      const bugs = es.filter((e) => (e.type === 'bug_opened' || e.type === 'bug_closed') && e.storyId === id);
      const blockers = blockersAll.filter((e) => e.storyId === id);
      const drafts = carried(D, 'bug_draft').filter((e) => e.storyId === id).length;
      const questions = carried(D, 'question').filter((e) => e.storyId === id).length;
      const inrows = [
        ...blockers.map((e) => `<div class="inrow bk" data-open="entry" data-date="${e._date}" data-id="${e.id}" tabindex="0"><span class="t">Blocker · ${esc(e.title)}</span></div>`),
        ...bugs.map((e) => `<div class="inrow" data-open="entry" data-date="${e._date}" data-id="${e.id}" tabindex="0"><span class="sid">#${e.devopsId}</span><span class="t">${esc(e.title)}</span>${bugTags(e.bug, true)}${reoBadge(e)}<span class="s ${bugState(e)[1]}">${bugState(e)[0]}</span></div>`),
        drafts || questions ? `<div class="inrow" data-open="story" data-sid="${id}" tabindex="0"><span class="t">${[drafts ? `${drafts} bug drafts` : '', questions ? `${questions} open questions` : ''].filter(Boolean).join(' · ')}</span><span class="s s-gold">View</span></div>` : '',
      ].join('');
      return `<div class="card runstory">
        <div class="ring" data-open="entry" data-date="${run._date}" data-id="${run.id}" title="Open the test run">${ring(r)}</div>
        <div><div class="sid">#${id}</div><div class="stitle" data-open="story" data-sid="${id}">${esc(shortTitle(s.title))}</div>
          <div class="sline">${line}</div><div class="scounts">${counts}</div>${inrows ? `<div class="inrows">${inrows}</div>` : ''}</div>
      </div>`;
    });

    // Other stories touched on this day, without a run
    const otherIds = [...new Set(es.filter((e) => e.storyId && !runByStory.has(e.storyId)).map((e) => e.storyId))];
    const others = otherIds.map((id) => ({ id, n: es.filter((e) => e.storyId === id).length }))
      .sort((a, b) => b.n - a.n)
      .map(({ id, n }) => `<div class="card orow" data-open="story" data-sid="${id}" tabindex="0"><span class="sid">#${id}</span><span class="t">${esc(shortTitle(storyInfo(id).title))}</span><span class="n" title="${n} entries">${n}</span></div>`).join('');

    // Bugs without a user story keep their own group
    const loose = es.filter((e) => (e.type === 'bug_opened' || e.type === 'bug_closed') && !e.storyId);
    const looseHtml = loose.map((e) => lrow(e)).join('');
    const looseOld = loose.map((e) => `<div class="lrow" data-open="entry" data-date="${e._date}" data-id="${e.id}" tabindex="0"><span class="sid">#${e.devopsId}</span><span class="t">${esc(e.title)}</span><span class="${e.type === 'bug_opened' ? 's-open' : 's-closed'}">${e.type === 'bug_opened' ? 'Opened' : 'Closed'}</span></div>`).join('');

    if (!es.length) {
      return `${summary}<div class="card empty-card" style="margin-top:18px">${state.q ? 'Nothing matches the search on this day.' : `Nothing logged on this day yet.<br><br><button class="btn primary" data-act="sync">${icon('sync')}Sync with Azure DevOps</button>`}</div>`;
    }
    return `${summary}
      ${storyCards.length ? `<div class="storygrid">${storyCards.join('')}</div>` : ''}
      ${others ? `<div class="cap">Other stories ${D === state.today ? 'today' : 'on this day'}</div><div class="others">${others}</div>` : ''}
      ${looseHtml ? `<div class="cap">Bugs without a user story</div><div class="card listcard">${looseHtml}</div>` : ''}`;
  }

  // ---------- shared list pieces (Midnight gold) ----------
  const SEV = { 1: ['crit', 'Critical'], 2: ['high', 'High'], 3: ['med', 'Medium'], 4: ['low', 'Low'] };
  // Issue Type, QA Bug Type and Severity from Azure DevOps, shown next to a bug.
  function bugTags(b, compact = false) {
    if (!b) return '';
    const sev = SEV[String(b.severity || '').trim()[0]];
    const parts = [];
    if (b.issueType) parts.push(`<span class="btag it" title="Issue Type">${esc(b.issueType)}</span>`);
    if (b.qaBugType && !compact) parts.push(`<span class="btag qa" title="QA Bug Type">QA · ${esc(b.qaBugType)}</span>`);
    if (sev) parts.push(`<span class="btag sev ${sev[0]}" title="Severity: ${esc(b.severity)}"><i></i>${sev[1]}</span>`);
    if (b.screen && !compact) parts.push(`<span class="btag sc" title="Screen">${esc(b.screen)}</span>`);
    return parts.length ? `<span class="btags">${parts.join('')}</span>` : '';
  }
  function bugState(e) {
    if (e.type === 'bug_draft') return e.status === 'draft' ? ['', ''] : [esc(e.status), 's-closed'];
    if (bugIsClosed(e)) return ['Closed', 's-closed'];
    const st = String(e.status || '').trim();
    const label = e.reopened || e.type === 'bug_closed' ? 'Reopened' : 'Opened';
    return [`${label}${st && !/^(new|active)$/i.test(st) ? ` · ${esc(st)}` : ''}`, /^(resolved)$/i.test(st) ? 's-gold' : 's-open'];
  }
  // One list row: ID, title, a meta line (tags or details), and a status on the right.
  function lrow(e, opts = {}) {
    const [st, cls] = opts.state || bugState(e);
    const id = e.devopsId ? `#${e.devopsId}` : (opts.noId ?? 'Draft');
    const meta = (e.type && e.type.startsWith('bug') ? reoBadge(e) : '') + (opts.meta ?? bugTags(e.bug));
    return `<div class="lrow2" data-open="entry" data-date="${e._date}" data-id="${e.id}" tabindex="0">
      <span class="sid${e.devopsId ? '' : ' dim'}">${id}</span>
      <div class="lt"><div class="t">${esc(e.title)}</div>${meta ? `<div class="lm">${meta}</div>` : ''}</div>
      <span class="st ${cls}">${st}${manualTag(e) ? ' · manual' : ''}</span></div>`;
  }
  function groupCard(sid, inner, count, label) {
    const s = sid === 'none' ? null : storyInfo(+sid);
    const head = s
      ? `<div class="gh" data-open="story" data-sid="${sid}" tabindex="0"><span class="sid">#${sid}</span><span class="gt">${esc(shortTitle(s.title))}</span>${s.state ? `<span class="pill">${esc(s.state)}</span>` : ''}<span class="gc">${count}</span></div>`
      : `<div class="gh plain"><span class="gt">${label || 'Not linked to a user story'}</span><span class="gc">${count}</span></div>`;
    return `<div class="card gcard">${head}<div class="gb">${inner}</div></div>`;
  }
  const segBar = (items, key, cur) => `<div class="seg">${items.map(([k, l, n]) => `<button data-${key}="${k}" aria-pressed="${cur === k}">${l}<span class="n">${n}</span></button>`).join('')}</div>`;

  // ---------- Bugs ----------
  function renderBugs() {
    const D = state.date;
    const opened = dayEntries(D).filter(bugIsOpen).filter(matches);
    const closedL = dayEntries(D).filter(bugIsClosed).filter(matches);
    const drafts = carried(D, 'bug_draft').filter(matches);
    const f = state.bugFilter;
    let list = f === 'opened' ? opened : f === 'closed' ? closedL : f === 'drafts' ? drafts : [...opened, ...closedL, ...drafts];
    // Issue type breakdown, also used as a filter
    const types = new Map();
    for (const e of list) { const t = e.bug?.issueType || (e.type === 'bug_draft' ? 'Draft, not classified' : 'Not set'); types.set(t, (types.get(t) || 0) + 1); }
    if (state.bugType && !types.has(state.bugType)) state.bugType = null;
    const typeChips = types.size > 1 || state.bugType ? `<div class="chips">${[['', 'All issue types', list.length], ...[...types.entries()].sort((a, b) => b[1] - a[1]).map(([t, n]) => [t, t, n])]
      .map(([k, l, n]) => `<button class="chip" data-bugtype="${esc(k)}" aria-pressed="${(state.bugType || '') === k}"><b>${esc(l)}</b><span>${n}</span></button>`).join('')}</div>` : '';
    if (state.bugType) list = list.filter((e) => (e.bug?.issueType || (e.type === 'bug_draft' ? 'Draft, not classified' : 'Not set')) === state.bugType);
    const seg = segBar([['all', 'All', opened.length + closedL.length + drafts.length], ['opened', 'Opened', opened.length], ['closed', 'Closed', closedL.length], ['drafts', 'Drafts', drafts.length]], 'bugf', f);
    if (!list.length) return `<div class="toolbar">${seg}</div>${typeChips}<div class="card empty-card">No bugs here for this day.</div>`;
    return `<div class="toolbar">${seg}</div>${typeChips}<div class="glist">${groupByStory(list).map(([sid, items]) =>
      groupCard(sid, items.map((e) => lrow(e, { meta: bugTags(e.bug) + (e.type === 'bug_draft' && e._date !== D ? `<span class="age">${daysBetween(e._date, D)} days</span>` : '') })).join(''), items.length, 'Bugs without a user story')).join('')}</div>`;
  }

  // ---------- Resolved: every bug and story of mine that is Resolved right now, on any day ----------
  // Stays here until it is closed (or reopened) on Azure DevOps, so nothing is forgotten.
  function renderResolved() {
    const all = resolvedItems().filter((n) => matches(n.e));
    const bugs = all.filter((n) => n.kind === 'bug');
    const stories = all.filter((n) => n.kind === 'story');
    const f = state.rFilter;
    const list = f === 'bugs' ? bugs : f === 'stories' ? stories : all;
    const seg = segBar([['all', 'All', all.length], ['bugs', 'Bugs', bugs.length], ['stories', 'User stories', stories.length]], 'rf', f);
    if (!list.length) return `<div class="toolbar">${seg}</div><div class="card empty-card">${state.q ? 'Nothing matches the search.' : 'Nothing is Resolved and waiting for you. Well done.'}</div>`;
    const age = (n) => { const d = n.at ? daysBetween(n.at.slice(0, 10), state.today) : null; return d === null ? '' : d <= 0 ? 'today' : d === 1 ? '1 day ago' : `${d} days ago`; };
    const row = (n) => {
      const meta = `<span class="lmtext">Resolved${n.by ? ` by ${esc(n.by)}` : ''}${age(n) ? ` · ${age(n)}` : ''}</span>${n.kind === 'bug' ? bugTags(n.e.bug, true) : ''}`;
      if (n.kind === 'bug') return lrow(Object.assign({ _date: n.date }, n.e), { meta, state: ['Verify', 's-gold'] });
      return `<div class="lrow2" data-open="story" data-sid="${n.e.devopsId}" tabindex="0"><span class="sid">#${n.e.devopsId}</span>
        <div class="lt"><div class="t">${esc(n.e.title)}</div><div class="lm">${meta}</div></div><span class="st s-gold">Resolved</span></div>`;
    };
    const card = (title, items) => items.length ? `<div class="card gcard"><div class="gh plain"><span class="gt">${title}</span><span class="gc">${items.length}</span></div><div class="gb">${items.map(row).join('')}</div></div>` : '';
    return `<div class="toolbar">${seg}</div><div class="glist">${f !== 'stories' ? card('Bugs to verify and close', bugs) : ''}${f !== 'bugs' ? card('User stories resolved', stories) : ''}</div>`;
  }

  // ---------- Questions and blockers ----------
  function renderQuestions() {
    const D = state.date;
    const all = allEntries();
    const bOpen = all.filter((e) => e.type === 'blocker' && isOpenOn(e, D)).filter(matches);
    const qOpen = all.filter((e) => e.type === 'question' && isOpenOn(e, D)).filter(matches);
    const done = all.filter((e) => (e.type === 'question' && e.question?.answeredOn === D) || (e.type === 'blocker' && e.resolvedOn === D)).filter(matches);
    const f = state.qFilter;
    const seg = segBar([['blockers', 'Blockers', bOpen.length], ['questions', 'Business questions', qOpen.length], ['done', 'Closed on this day', done.length]], 'qf', f);
    const list = f === 'blockers' ? bOpen : f === 'questions' ? qOpen : done;
    if (!list.length) return `<div class="toolbar">${seg}</div><div class="card empty-card">${f === 'done' ? 'Nothing answered or resolved on this day.' : 'Nothing open.'}</div>`;
    const row = (e) => {
      const open = isOpenOn(e, D);
      const age = daysBetween(e._date, D);
      const meta = [open ? (age ? `open ${age} days` : 'raised today') : e.type === 'question' ? 'answered' : 'resolved', e.devopsId ? `bug #${e.devopsId}` : ''].filter(Boolean).join(' · ');
      const st = open ? (e.type === 'blocker' ? ['Blocker', 's-open'] : ['Open', 's-gold']) : ['Done', 's-closed'];
      return lrow(e, { noId: e.type === 'blocker' ? '!' : '?', meta: `<span class="lmtext">${meta}</span>`, state: st });
    };
    return `<div class="toolbar">${seg}</div><div class="glist">${groupByStory(list).map(([sid, items]) => groupCard(sid, `<div class="wraprows">${items.map(row).join('')}</div>`, items.length)).join('')}</div>`;
  }

  // ---------- User stories ----------
  function storyStats(id, D) {
    const es = allEntries().filter((e) => e._date <= D && e.storyId === id);
    let run = null;
    for (const e of es) if (e.type === 'test_run' && (!run || `${e._date}${e.timestamp}` > `${run._date}${run.timestamp}`)) run = e;
    return {
      tc: es.filter((e) => e.type === 'testcase').length,
      bo: es.filter(bugIsOpen).length,
      bc: es.filter(bugIsClosed).length,
      drafts: carried(D, 'bug_draft').filter((e) => e.storyId === id).length,
      open: [...carried(D, 'question'), ...carried(D, 'blocker')].filter((e) => e.storyId === id).length,
      run,
      last: es.reduce((m, e) => (e._date > m ? e._date : m), ''),
    };
  }
  function renderStories() {
    const D = state.date;
    const ids = [...new Set(allEntries().filter((e) => e._date <= D && e.storyId).map((e) => e.storyId))];
    const q = state.q.toLowerCase().replace(/^#/, '');
    const list = ids.map((id) => Object.assign({ id, info: storyInfo(id) }, storyStats(id, D)))
      .filter((s) => !q || String(s.id).includes(q) || s.info.title.toLowerCase().includes(q))
      .sort((a, b) => (b.run ? 1 : 0) - (a.run ? 1 : 0) || b.last.localeCompare(a.last) || b.id - a.id);
    if (!list.length) return '<div class="card empty-card">No user stories logged up to this day.</div>';
    const st = (v, l) => `<div><b class="${v ? '' : 'z'}">${v}</b><span>${l}</span></div>`;
    return `<div class="storygrid">${list.map((s) => {
      const r = s.run?.run;
      const counts = r ? [['p', 'pass', r.pass], ['f', 'fail', r.fail], ['bl', 'blocked', r.blocked], ['n', 'not run', r.notRun]].filter((c) => c[2] > 0).map(([c, l, v]) => `<span class="${c}"><b>${v}</b>${l}</span>`).join('') : '';
      return `<div class="card storycard" data-open="story" data-sid="${s.id}" tabindex="0">
        <div class="ring sm">${r ? ring(r) : `<svg viewBox="0 0 132 132"><circle cx="66" cy="66" r="56" fill="none" stroke="var(--notrun)" stroke-width="12"/></svg><div class="pc"><div>–<small>no run</small></div></div>`}</div>
        <div class="sc-b"><div class="sc-top"><span class="sid">#${s.id}</span>${s.info.state ? `<span class="pill">${esc(s.info.state)}</span>` : ''}</div>
          <div class="stitle">${esc(shortTitle(s.info.title))}</div>
          <div class="sline">${r ? `Latest run ${esc(shortDate(s.run._date))}${r.build ? ` · build ${esc(r.build)}` : ''}` : 'No test run logged yet'}</div>
          ${counts ? `<div class="scounts">${counts}</div>` : ''}
          <div class="stats">${st(s.tc, 'Test cases')}${st(s.bo, 'Bugs opened')}${st(s.drafts, 'Drafts')}${st(s.open, 'Open items')}</div></div>
      </div>`;
    }).join('')}</div>`;
  }

  // ---------- QA team ----------
  // My own card in the QA team tab, built from my entries on the selected day.
  function myTeamCard(D) {
    const q = state.q.toLowerCase().replace(/^#/, '');
    const es = dayEntries(D);
    const ok = (e) => !q || [e.devopsId, e.storyId, e.title].some((v) => v != null && String(v).toLowerCase().includes(q));
    const stories = es.filter((e) => e.type === 'story').filter(ok);
    const opened = es.filter(bugIsOpen);
    const closedB = es.filter(bugIsClosed);
    const bugs = [...opened, ...closedB].filter(ok);
    const tcs = es.filter((e) => e.type === 'testcase').length;
    const executed = es.filter((e) => e.type === 'test_run').reduce((n, e) => n + e.run.pass + e.run.fail + e.run.blocked, 0);
    const drafts = carried(D, 'bug_draft').length;
    const name = state.cfg.me;
    const initials = name.split(/\s+/).map((w) => w[0]).slice(0, 2).join('').toUpperCase();
    const n = (v, l, c = '') => `<div class="${c}"><b>${v}</b><span>${l}</span></div>`;
    const srow = (e) => `<div class="lrow2" data-open="story" data-sid="${e.devopsId}" tabindex="0"><span class="sid">#${e.devopsId}</span><div class="lt"><div class="t">${esc(shortTitle(e.title))}</div>${e.notes ? `<div class="lm"><span class="lmtext">${esc(e.notes)}</span></div>` : ''}</div><span class="st s-gold">${esc(e.status || '')}</span></div>`;
    const bugGroups = groupByStory(bugs).map(([sid, list]) => `<div class="tsub">${sid === 'none' ? 'Bugs without a user story' : `<span class="sid">#${sid}</span> ${esc(shortTitle(storyInfo(+sid).title))}`}</div>${list.map((e) => lrow(e)).join('')}`).join('');
    return `<div class="card teamcard me">
      <div class="person"><span class="avatar">${esc(initials)}</span><div><h3>${esc(name)} <span class="you">You</span></h3><p>From your dashboard entries</p></div></div>
      <div class="bugnums tn">${n(stories.length, 'Stories')}${n(opened.length, 'Bugs opened', 'o')}${n(closedB.length, 'Bugs closed', 'c')}${n(tcs, 'Test cases')}${n(executed, 'Executed')}</div>
      ${drafts ? `<div class="inrows" style="margin:8px 18px 0"><div class="inrow" data-go="bugs:drafts"><span class="t">${drafts} bug drafts waiting to be opened on DevOps</span><span class="s s-gold">View</span></div></div>` : ''}
      <div class="tsec">User stories</div>${stories.length ? stories.map(srow).join('') : '<div class="empty">No user stories on this day.</div>'}
      <div class="tsec">Bugs</div>${bugs.length ? bugGroups : '<div class="empty">No bugs opened or closed on this day.</div>'}
    </div>`;
  }

  // ---------- QA team (synced members) ----------
  function renderTeam() {
    const D = state.date;
    const day = state.days[D];
    const meCard = myTeamCard(D);
    if (!day || !day.team) return `<div class="teamgrid">${meCard}<div class="card empty-card">The QA team has not been synced for ${esc(shortDate(D))}.<br><br><button class="btn primary" data-act="sync">${icon('sync')}Sync this day</button></div></div>`;
    const q = state.q.toLowerCase().replace(/^#/, '');
    const ok = (x) => !q || String(x.id).includes(q) || String(x.storyId || '').includes(q) || (x.title || '').toLowerCase().includes(q);
    const initials = (n) => n.split(/\s+/).map((w) => w[0]).slice(0, 2).join('').toUpperCase();
    const trow = (x, mi, kind) => {
      const [st, cls] = kind === 'story' ? [esc(x.state || ''), 's-gold'] : kind === 'opened' ? ['Opened', 's-open'] : ['Closed', 's-closed'];
      const meta = kind === 'story' ? '' : bugTags(x.bug);
      return `<div class="lrow2" data-open="team" data-m="${mi}" data-kind="${kind}" data-x="${x.id}" tabindex="0"><span class="sid">#${x.id}</span><div class="lt"><div class="t">${esc(kind === 'story' ? shortTitle(x.title) : x.title)}</div>${meta ? `<div class="lm">${meta}</div>` : ''}</div><span class="st ${cls}">${st}</span></div>`;
    };
    return `<div class="teamgrid">${meCard}${day.team.map((m, mi) => {
      const stories = (m.stories || []).filter(ok);
      const bugs = [...(m.bugsOpened || []).map((b) => Object.assign({ kind: 'opened' }, b)), ...(m.bugsClosed || []).map((b) => Object.assign({ kind: 'closed' }, b))].filter(ok);
      const n = (v, l, c = '') => `<div class="${c}"><b>${v}</b><span>${l}</span></div>`;
      return `<div class="card teamcard">
        <div class="person"><span class="avatar">${esc(initials(m.name))}</span><div><h3>${esc(m.name)}</h3><p>Read only, from Azure DevOps</p></div></div>
        <div class="bugnums tn">${n((m.stories || []).length, 'Stories')}${n((m.bugsOpened || []).length, 'Bugs opened', 'o')}${n((m.bugsClosed || []).length, 'Bugs closed', 'c')}${n((m.testcases || []).length, 'Test cases')}</div>
        <div class="tsec">User stories</div>${stories.length ? stories.map((s) => trow(s, mi, 'story')).join('') : '<div class="empty">No user stories on this day.</div>'}
        <div class="tsec">Bugs</div>${bugs.length ? groupByStory(bugs).map(([sid, list]) => `<div class="tsub">${sid === 'none' ? 'Bugs without a user story' : `<span class="sid">#${sid}</span> ${esc(shortTitle(storyInfo(+sid).title))}`}</div>${list.map((b) => trow(b, mi, b.kind)).join('')}`).join('') : '<div class="empty">No bugs opened or closed on this day.</div>'}
      </div>`;
    }).join('')}</div>`;
  }

  // ---------- search on other days ----------
  function renderOther() {
    const el = $('#searchOther');
    if (!state.q || state.tab === 'stories' || state.tab === 'team') { el.hidden = true; return; }
    const hits = allEntries().filter((e) => e._date !== state.date && matches(e)).sort((a, b) => b._date.localeCompare(a._date)).slice(0, 25);
    if (!hits.length) { el.hidden = true; return; }
    el.hidden = false;
    el.innerHTML = `<h3>Matches on other days</h3><ul class="rows">${hits.map((e) => row(e, { status: shortDate(e._date) })).join('')}</ul>`;
  }

  // ---------- details drawer ----------
  function openDrawer(type, html, actions = '') {
    $('#drawerType').textContent = type;
    $('#drawerBody').innerHTML = html + (actions ? '' : '');
    let foot = document.querySelector('.dactions');
    if (foot) foot.remove();
    if (actions) $('#drawer').insertAdjacentHTML('beforeend', `<div class="dactions">${actions}</div>`);
    $('#drawer').classList.add('open');
    $('#drawer').setAttribute('aria-hidden', 'false');
    $('#scrim').hidden = false;
    $('#drawerClose').focus();
  }
  function closeDrawer() {
    if (state.pendingReload) { state.pendingReload = false; reload().catch(() => {}); }
    $('#drawer').classList.remove('open');
    $('#drawer').setAttribute('aria-hidden', 'true');
    $('#scrim').hidden = true;
  }
  function showEntry(e) {
    const s = e.storyId ? storyInfo(e.storyId) : null;
    const rows = [];
    if (e.devopsId) rows.push(['Azure DevOps', `${link(e.devopsId)}`]);
    if (s) rows.push(['User story', `<a href="#" data-open="story" data-sid="${e.storyId}">#${e.storyId}</a> ${esc(s.title)}`]);
    if (e.status) rows.push(['Status', pill(e.status, e.type)]);
    if (e.assignedTo) rows.push(['Assigned to', esc(e.assignedTo)]);
    if (e.statusLog && e.statusLog.length) rows.push(['Status history', e.statusLog.map((l) => `${esc(l.state)} <span class="muted">${esc(fmtAt(l.at))}${l.by ? ` · ${esc(l.by)}` : ''}</span>`).join('<br>')]);
    if (e.refreshedAt) rows.push(['Checked', `${esc(e.refreshedAt.slice(11, 16))} from Azure DevOps`]);
    if (e.bug) { if (e.bug.issueType) rows.push(['Issue Type', esc(e.bug.issueType)]); if (e.bug.qaBugType) rows.push(['QA Bug Type', esc(e.bug.qaBugType)]); if (e.bug.severity) rows.push(['Severity', esc(e.bug.severity)]); if (e.bug.screen) rows.push(['Screen', esc(e.bug.screen)]); }
    rows.push(['Day', `${esc(longDate(e._date))}${hhmm(e.timestamp) ? ` · ${hhmm(e.timestamp)}` : ''}`]);
    if (e.type === 'question' || e.type === 'blocker' || e.type === 'bug_draft') rows.push(['Open for', isOpenOn(e, state.today) ? `${daysBetween(e._date, state.today)} days` : 'Closed']);
    rows.push(['Owner', esc(e.owner)]);
    rows.push(['Source', { claude: 'Logged by Claude', manual: 'Added by hand', 'devops-sync': 'Azure DevOps sync' }[e.source] || esc(e.source)]);
    let run = '';
    if (e.run) { const p = runParts(e.run); run = `<div style="margin:14px 0"><div style="display:flex;justify-content:space-between;align-items:baseline"><span class="muted small">${p.total} cases${e.run.build ? ` · build ${esc(e.run.build)}` : ''}</span><span class="pct" style="font-size:22px">${p.pct}%</span></div>${p.bar}${p.legend}</div>`; }
    const html = `${e.run ? `<h2>${s ? esc(s.title) : 'Test run'}</h2>` : `<h2>${esc(e.title)}</h2>`}${run}
      <dl class="dl">${rows.map(([k, v]) => `<dt>${k}</dt><dd>${v}</dd>`).join('')}</dl>
      ${e.notes ? `<div class="dnote">${esc(e.notes)}</div>` : ''}
      ${e.question?.answer ? `<div class="dans"><b>Answer:</b> ${esc(e.question.answer)}</div>` : ''}`;
    let primary = '';
    if (e.type === 'bug_draft' && e.status === 'draft') primary = `<button class="btn primary sm" data-act="logged" data-date="${e._date}" data-id="${e.id}">${icon('check')}Opened on DevOps</button>`;
    if (e.type === 'question' && e.status !== 'answered') primary = `<button class="btn primary sm" data-act="answer" data-date="${e._date}" data-id="${e.id}">${icon('check')}Mark answered</button>`;
    if (e.type === 'blocker' && e.status !== 'resolved') primary = `<button class="btn primary sm" data-act="resolve" data-date="${e._date}" data-id="${e.id}">${icon('check')}Resolve</button>`;
    const ext = e.devopsId ? `<a class="btn sm" href="${devops(e.devopsId)}" target="_blank" rel="noopener">${icon('ext')}Open in DevOps</a>` : '';
    openDrawer(e.type === 'bug_closed' && !bugIsClosed(e) ? 'Bug reopened' : e.type === 'bug_opened' && e.reopened ? 'Bug opened, reopened' : TYPE_LABEL[e.type], html, `${primary}${ext}<span class="sp"></span><button class="btn sm" data-act="edit" data-date="${e._date}" data-id="${e.id}">${icon('draft')}Edit</button><button class="btn sm danger" data-act="del" data-date="${e._date}" data-id="${e.id}">${icon('trash')}Delete</button>`);
  }
  function showStory(id) {
    const D = state.date;
    const s = storyInfo(id);
    const st = storyStats(id, D);
    const es = allEntries().filter((e) => e._date <= D && e.storyId === id);
    const p = st.run ? runParts(st.run.run) : null;
    const list = (title, items, opts) => (items.length ? `<div class="glabel plain">${title}<span class="count">${items.length}</span></div><ul class="rows">${items.map((e) => row(e, opts)).join('')}</ul>` : '');
    const html = `<h2>${esc(s.title)}</h2><div style="display:flex;gap:8px;align-items:center">${link(id)}${pill(s.state)}</div>
      ${p ? `<div style="margin:18px 0 6px"><div style="display:flex;justify-content:space-between;align-items:baseline"><span class="muted small">Latest run · ${esc(shortDate(st.run._date))} · ${p.total} cases</span><span class="pct" style="font-size:22px">${p.pct}%</span></div>${p.bar}${p.legend}</div>` : '<p class="muted">No test run logged yet.</p>'}
      <div class="stats" style="margin:14px 0 4px"><div><b>${st.tc}</b><span>Test cases</span></div><div><b>${st.bo}</b><span>Bugs opened</span></div><div><b>${st.bc}</b><span>Bugs closed</span></div><div><b>${st.drafts}</b><span>Drafts</span></div></div>
      ${list('Blockers', carried(D, 'blocker').filter((e) => e.storyId === id), { wrap: true, noIdLabel: '', pill: false })}
      ${list('Open questions', carried(D, 'question').filter((e) => e.storyId === id), { wrap: true, noIdLabel: '', pill: false })}
      ${list('Bugs', es.filter((e) => e.type === 'bug_opened' || e.type === 'bug_closed'), {})}
      ${list('Bug drafts', carried(D, 'bug_draft').filter((e) => e.storyId === id), { pill: false })}
      ${list('Test cases written', es.filter((e) => e.type === 'testcase').sort((x, y) => x.devopsId - y.devopsId), { pill: false })}`;
    openDrawer('User story', html, `<a class="btn sm" href="${devops(id)}" target="_blank" rel="noopener">${icon('ext')}Open in DevOps</a><span class="sp"></span><button class="btn sm" data-act="filter-story" data-sid="${id}">Show in Today's work</button>`);
  }
  function showTeamItem(mi, kind, xid) {
    const m = state.days[state.date].team[mi];
    const pool = kind === 'story' ? m.stories : kind === 'opened' ? m.bugsOpened : m.bugsClosed;
    const x = (pool || []).find((y) => String(y.id) === String(xid));
    if (!x) return;
    const s = x.storyId ? storyInfo(x.storyId) : null;
    const html = `<h2>${esc(x.title)}</h2><dl class="dl">
      <dt>Azure DevOps</dt><dd>${link(x.id)}</dd>
      <dt>Team member</dt><dd>${esc(m.name)}</dd>
      <dt>On this day</dt><dd>${kind === 'story' ? 'Story assigned or worked on' : `Bug ${kind}`}</dd>
      <dt>State</dt><dd>${pill(x.state)}</dd>
      ${x.bug ? ['issueType:Issue Type', 'qaBugType:QA Bug Type', 'severity:Severity', 'screen:Screen'].map((p) => { const [k, l] = p.split(':'); return x.bug[k] ? `<dt>${l}</dt><dd>${esc(x.bug[k])}</dd>` : ''; }).join('') : ''}
      ${s ? `<dt>User story</dt><dd>${link(x.storyId)} ${esc(s.title)}</dd>` : ''}</dl>`;
    openDrawer(kind === 'story' ? 'User story · QA team' : 'Bug · QA team', html, `<a class="btn sm" href="${devops(x.id)}" target="_blank" rel="noopener">${icon('ext')}Open in DevOps</a>`);
  }

  // ---------- render ----------
  function render() {
    const D = state.date;
    $('#datePick').value = D;
    $('#dateLabel').textContent = D === state.today ? `Today, ${shortDate(D)}` : fmt(D, { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
    $('#pageTitle').textContent = fmt(D, { day: 'numeric', month: 'long' });
    $('#pageIco').innerHTML = icon(TAB_STYLE[state.tab][0]);
    document.documentElement.style.setProperty('--pc', TAB_STYLE[state.tab][1]);
    $('#pageSub').textContent = state.tab === 'work' ? '' : TITLES[state.tab];
    const day = state.days[D];
    const si = $('#syncInfo');
    si.textContent = `${fmt(D, { weekday: 'long' })}${D === state.today ? ' · today' : ''} · ${day?.mySyncedAt ? `Synced with Azure DevOps ${day.mySyncedAt.slice(11, 16)}` : 'Not synced with Azure DevOps yet'}`;
    si.classList.toggle('stale', !day?.mySyncedAt);
    const err = day?.lastSyncError;
    si.classList.toggle('err', !!err);
    if (err) si.textContent = `${fmt(D, { weekday: 'long' })} · Sync failed at ${err.at.slice(11, 16)} · showing data from ${day.mySyncedAt ? day.mySyncedAt.slice(11, 16) : 'no sync yet'}`;
    si.title = err ? err.message : '';
    if (!err && state.cfg.autoSyncMinutes > 0) si.textContent += ` · auto every ${state.cfg.autoSyncMinutes} min`;
    $('#nextDay').disabled = D >= state.today;
    $('#tiles').innerHTML = '';
    const es = dayEntries(D);
    const counts = {
      work: es.length || '',
      bugs: es.filter((e) => e.type === 'bug_opened' || e.type === 'bug_closed').length + carried(D, 'bug_draft').length || '',
      resolved: resolvedItems().length || '',
      questions: carried(D, 'question').length + carried(D, 'blocker').length || '',
      stories: '',
      team: '',
    };
    for (const b of document.querySelectorAll('#tabs button')) {
      b.setAttribute('aria-selected', String(b.dataset.tab === state.tab));
      const c = b.querySelector('.nc');
      c.textContent = counts[b.dataset.tab];
      c.classList.toggle('hot', (b.dataset.tab === 'questions' && carried(D, 'blocker').length > 0) || (b.dataset.tab === 'resolved' && counts.resolved > 0));
    }
    const fn = { work: renderWork, bugs: renderBugs, resolved: renderResolved, questions: renderQuestions, stories: renderStories, team: renderTeam }[state.tab];
    $('#view').innerHTML = fn();
    renderOther();
    // Keep the date in the link only for past days, so a refresh on "today" always opens the real today.
    history.replaceState(null, '', D === state.today ? `#tab=${state.tab}` : `#date=${D}&tab=${state.tab}`);
  }
  async function reload() {
    const r = await api('GET', '/api/all');
    state.days = r.days;
    state.today = r.today;
    render();
    checkResolved();
  }

  // ---------- notifications: bugs and stories moved to Resolved (bell + Resolved tab) ----------
  // Which ones you have already seen is kept in this browser; an item resolved again later counts as new.
  const NOTE_KEY = 'qa-dash-resolved-read';
  // Latest copy of each of my bugs and stories (an item can sit on several days), keyed by kind and ID.
  function latestItems() {
    const m = {};
    for (const [date, day] of Object.entries(state.days || {})) {
      for (const e of day.entries || []) {
        if (!e.devopsId || !e.status) continue;
        const kind = /^bug_(opened|closed)$/.test(e.type) ? 'bug' : e.type === 'story' ? 'story' : null;
        if (!kind) continue;
        const k = `${kind}${e.devopsId}`;
        const stamp = e.refreshedAt || e.timestamp || '';
        if (!m[k] || stamp > m[k].stamp) m[k] = { kind, e, date, stamp };
      }
    }
    return Object.values(m);
  }
  // Everything that is Resolved right now (waiting for me to verify), newest first.
  function resolvedItems() {
    // Only items assigned to me in Azure DevOps (the sync fills assignedTo with the DevOps display name).
    const mine = [state.cfg?.me, state.cfg?.meDevops].filter(Boolean).map((s) => s.toLowerCase());
    return latestItems().filter((x) => x.e.status === 'Resolved' && mine.includes(String(x.e.assignedTo || '').toLowerCase())).map(({ kind, e, date }) => {
      const last = (e.statusLog || []).filter((s) => s.state === 'Resolved').pop();
      const at = last?.at || '';
      return { kind, e, date, at: at || e.refreshedAt || e.timestamp || '', by: last?.by || '', key: `${kind}${e.devopsId}@${at}` };
    }).sort((a, b) => (b.at > a.at ? 1 : b.at < a.at ? -1 : 0));
  }
  const readKeys = () => { try { return new Set(JSON.parse(ls.get(NOTE_KEY) || '[]')); } catch { return new Set(); } };
  const baseTitle = document.title;
  let lastUnread = null;
  function checkResolved() {
    const list = resolvedItems();
    const read = readKeys();
    const unread = list.filter((n) => !read.has(n.key));
    const badge = $('#bellCount');
    badge.textContent = unread.length;
    badge.hidden = !unread.length;
    $('#bellBtn').classList.toggle('ring', unread.length > 0);
    document.title = unread.length ? `(${unread.length}) ${baseTitle}` : baseTitle;
    // Say it out loud when the page opens with new items, and whenever a new one arrives.
    if (lastUnread === null ? unread.length : unread.length > lastUnread) {
      const n = unread[0];
      toast(unread.length === 1 ? `${n.kind === 'bug' ? 'Bug' : 'Story'} #${n.e.devopsId} is Resolved: verify it` : `${unread.length} new Resolved items are waiting for you`, 7000);
    }
    lastUnread = unread.length;
    if (!$('#bellPanel').hidden) paintPanel(list, read);
  }
  function paintPanel(list = resolvedItems(), read = readKeys()) {
    const when = (iso) => iso ? new Date(iso).toLocaleString('en-GB', { timeZone: 'Asia/Amman', day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) : '';
    const open = (n) => n.kind === 'bug' ? `data-open="entry" data-date="${n.date}" data-id="${n.e.id}"` : `data-open="story" data-sid="${n.e.devopsId}"`;
    $('#bellPanel').innerHTML = `<div class="np-head">Resolved, waiting for you<span>${list.length}</span></div>${list.length
      ? list.map((n) => `<div class="np-row${read.has(n.key) ? '' : ' unread'}" ${open(n)} tabindex="0">
          <span class="np-dot"></span><div class="np-t"><div><span class="np-k">${n.kind === 'bug' ? 'Bug' : 'Story'}</span> <span class="sid">#${n.e.devopsId}</span> ${esc(n.e.title)}</div>
          <div class="np-m">Resolved${n.by ? ` by ${esc(n.by)}` : ''}${n.at ? ` · ${esc(when(n.at))}` : ''}</div></div></div>`).join('')
      : '<div class="np-empty">Nothing Resolved is waiting for you.</div>'}
      <button type="button" class="np-all" data-go="resolved:all">Open the Resolved tab</button>`;
  }
  function toggleBell(open = $('#bellPanel').hidden) {
    const p = $('#bellPanel');
    if (!open) { p.hidden = true; return; }
    const list = resolvedItems();
    paintPanel(list); // draw first so the new-item dots are visible this time
    p.hidden = false;
    ls.set(NOTE_KEY, JSON.stringify(list.map((n) => n.key))); // opening the list marks everything seen
    checkResolved();
  }

  // ---------- entry form ----------
  const dlg = $('#entryDialog');
  const form = $('#entryForm');
  let editing = null;
  function applyType() {
    const t = form.type.value;
    const show = (f, on) => form.querySelectorAll(`[data-f="${f}"]`).forEach((el) => { el.hidden = !on; });
    show('devopsId', t !== 'test_run' && t !== 'bug_draft');
    show('run', t === 'test_run');
    show('answer', t === 'question');
    show('bug', t.startsWith('bug'));
    show('title', t !== 'test_run');
    form.devopsId.required = NEEDS_ID.includes(t);
    form.storyId.required = t === 'test_run';
    $('#titleLabel').textContent = { question: 'Question', blocker: 'What is blocked and why', story: 'Story title (optional)' }[t] || 'Title';
    form.devopsId.closest('label').firstChild.textContent = t === 'question' || t === 'blocker' ? 'Related bug ID (optional)' : 'Azure DevOps ID';
    $('#statusList').innerHTML = (STATUS_HINTS[t] || []).map((s) => `<option value="${esc(s)}">`).join('');
  }
  function openForm(entry) {
    editing = entry || null;
    form.reset();
    $('#formError').textContent = '';
    $('#formTitle').textContent = entry ? `Edit ${TYPE_LABEL[entry.type].toLowerCase()}` : 'Add entry';
    $('#formDate').textContent = `Day: ${longDate(entry ? entry._date : state.date)}`;
    form.type.disabled = !!entry;
    if (entry) {
      form.type.value = entry.type;
      form.devopsId.value = entry.devopsId || '';
      form.storyId.value = entry.storyId || '';
      form.owner.value = entry.owner || '';
      form.title.value = entry.title || '';
      form.status.value = entry.status || '';
      form.notes.value = entry.notes || '';
      if (entry.run) for (const k of ['build', 'pass', 'fail', 'blocked', 'notRun']) form[k].value = entry.run[k] ?? '';
      if (entry.question) form.answer.value = entry.question.answer || '';
      if (entry.bug) for (const k of ['issueType', 'qaBugType', 'severity', 'screen']) form[k].value = entry.bug[k] || '';
    } else {
      form.owner.value = state.cfg.me;
      if (state.story) form.storyId.value = state.story;
    }
    applyType();
    dlg.showModal();
    (entry ? form.title : form.type).focus();
  }
  form.addEventListener('submit', async (ev) => {
    ev.preventDefault();
    const t = form.type.value;
    const entry = {
      type: t, devopsId: form.devopsId.value.trim() || null, storyId: form.storyId.value.trim() || null,
      owner: form.owner.value.trim(), title: form.title.value.trim(), status: form.status.value.trim(), notes: form.notes.value.trim(),
    };
    if (t.startsWith('bug')) entry.bug = { issueType: form.issueType.value, qaBugType: form.qaBugType.value, severity: form.severity.value, screen: form.screen.value.trim() };
    if (t === 'test_run') entry.run = { build: form.build.value.trim(), pass: +form.pass.value || 0, fail: +form.fail.value || 0, blocked: +form.blocked.value || 0, notRun: +form.notRun.value || 0 };
    if (t === 'question') {
      const answer = form.answer.value.trim();
      entry.question = { answer, answeredOn: answer ? (editing?.question?.answeredOn || state.today) : null };
      if (answer && !entry.status) entry.status = 'answered';
    }
    try {
      if (editing) await api('PUT', `/api/entries/${editing._date}/${editing.id}`, entry);
      else await api('POST', '/api/entries', { date: state.date, entry });
      dlg.close();
      closeDrawer();
      toast(editing ? 'Entry updated' : 'Entry added');
      await reload();
    } catch (e) { $('#formError').textContent = e.message; }
  });
  form.type.addEventListener('change', applyType);
  $('#cancelForm').addEventListener('click', () => dlg.close());

  function ask({ title, hint = '', label, numeric = false }) {
    return new Promise((resolve) => {
      const d = $('#promptDialog');
      const input = $('#promptInput');
      $('#promptTitle').textContent = title;
      $('#promptHint').textContent = hint;
      $('#promptLabel').textContent = label;
      $('#promptError').textContent = '';
      input.value = '';
      input.rows = numeric ? 1 : 3;
      const done = (v) => { d.close(); $('#promptForm').onsubmit = null; resolve(v); };
      $('#promptForm').onsubmit = (ev) => {
        ev.preventDefault();
        const v = input.value.trim();
        if (!v) { $('#promptError').textContent = 'Required'; return; }
        if (numeric && !/^\d+$/.test(v)) { $('#promptError').textContent = 'Enter the numeric DevOps ID'; return; }
        done(v);
      };
      $('#promptCancel').onclick = () => done(null);
      d.onclose = () => resolve(null);
      d.showModal();
      input.focus();
    });
  }

  // ---------- events ----------
  async function sync() {
    const btn = $('#syncBtn');
    btn.disabled = true;
    btn.classList.add('spin');
    try {
      const r = await api('POST', '/api/sync', { date: state.date });
      toast(`Synced ${shortDate(state.date)}: ${r.added} added, ${r.checked} checked, ${r.changes.length} status changes`, 4500);
      await reload();
    } catch (e) { toast(`Sync failed: ${e.message}`, 8000); await reload().catch(() => {}); }
    finally { btn.disabled = false; btn.classList.remove('spin'); }
  }
  function go(target) {
    const [tab, sub] = target.split(':');
    state.tab = tab;
    if (tab === 'bugs') state.bugFilter = sub;
    if (tab === 'questions') state.qFilter = sub;
    if (tab === 'resolved') state.rFilter = sub || 'all';
    if (tab === 'work') state.closed.delete(sub);
    render();
    const el = tab === 'work' ? document.getElementById(`sec-${sub}`) : $('#view');
    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
  function saveClosed() { ls.set('qa-dash-closed', JSON.stringify([...state.closed])); }

  async function onAction(b) {
    const { act, date, id } = b.dataset;
    const e = date && id ? findEntry(date, id) : null;
    if (act === 'edit' && e) openForm(e);
    else if (act === 'del' && e) {
      if (!confirm(`Delete this ${TYPE_LABEL[e.type].toLowerCase()} entry?\n\n${e.devopsId ? '#' + e.devopsId + ' ' : ''}${e.title}\n\nThis removes it from the dashboard only, not from Azure DevOps.`)) return;
      await api('DELETE', `/api/entries/${date}/${id}`);
      closeDrawer();
      toast('Entry deleted');
      await reload();
    } else if (act === 'answer' && e) {
      const a = await ask({ title: 'Mark question answered', hint: e.title, label: 'Answer' });
      if (a == null) return;
      await api('PUT', `/api/entries/${date}/${id}`, { status: 'answered', question: { answer: a, answeredOn: state.today } });
      closeDrawer();
      toast('Question marked answered');
      await reload();
    } else if (act === 'resolve' && e) {
      const n = await ask({ title: 'Resolve blocker', hint: e.title, label: 'How was it resolved?' });
      if (n == null) return;
      await api('PUT', `/api/entries/${date}/${id}`, { status: 'resolved', resolvedOn: state.today, notes: [e.notes, `Resolved: ${n}`].filter(Boolean).join('\n') });
      closeDrawer();
      toast('Blocker resolved');
      await reload();
    } else if (act === 'logged' && e) {
      const bugId = await ask({ title: 'Draft opened on Azure DevOps', hint: e.title, label: 'Real DevOps bug ID', numeric: true });
      if (bugId == null) return;
      await api('POST', `/api/drafts/${date}/${id}/logged`, { devopsId: bugId, date: state.today });
      closeDrawer();
      toast(`Logged as bug #${bugId}`);
      await reload();
    } else if (act === 'filter-story') {
      state.story = +b.dataset.sid;
      state.tab = 'work';
      closeDrawer();
      render();
    } else if (act === 'sync') sync();
  }

  document.addEventListener('click', async (ev) => {
    if (ev.target.closest('#bellBtn')) { toggleBell(); return; }
    if (!$('#bellPanel').hidden && !ev.target.closest('#bellPanel')) toggleBell(false);
    else if (ev.target.closest('#bellPanel [data-open], #bellPanel [data-go]')) toggleBell(false);
    if (ev.target.closest('[data-stop]')) return;
    try {
      const k = ev.target.closest('[data-go]');
      if (k) { go(k.dataset.go); return; }
      const tg = ev.target.closest('[data-toggle]');
      if (tg) {
        const key = tg.dataset.toggle;
        if (state.closed.has(key)) state.closed.delete(key); else state.closed.add(key);
        saveClosed();
        tg.closest('.section').classList.toggle('closed');
        tg.setAttribute('aria-expanded', String(!state.closed.has(key)));
        return;
      }
      const bt = ev.target.closest('[data-bugtype]');
      if (bt) { state.bugType = bt.dataset.bugtype || null; render(); return; }
      const chip = ev.target.closest('[data-story]');
      if (chip) { state.story = chip.dataset.story ? +chip.dataset.story : null; render(); return; }
      const bf = ev.target.closest('[data-bugf]');
      if (bf) { state.bugFilter = bf.dataset.bugf; render(); return; }
      const rf = ev.target.closest('[data-rf]');
      if (rf) { state.rFilter = rf.dataset.rf; render(); return; }
      const qf = ev.target.closest('[data-qf]');
      if (qf) { state.qFilter = qf.dataset.qf; render(); return; }
      const act = ev.target.closest('[data-act]');
      if (act) { await onAction(act); return; }
      const op = ev.target.closest('[data-open]');
      if (op) {
        ev.preventDefault();
        if (op.dataset.open === 'entry') { const e = findEntry(op.dataset.date, op.dataset.id); if (e) showEntry(e); }
        if (op.dataset.open === 'story') showStory(+op.dataset.sid);
        if (op.dataset.open === 'team') showTeamItem(+op.dataset.m, op.dataset.kind, op.dataset.x);
      }
    } catch (err) { toast(err.message, 6000); }
  });
  document.addEventListener('keydown', (ev) => {
    if (ev.key === 'Escape' && !$('#bellPanel').hidden) toggleBell(false);
    if (ev.key === 'Escape' && $('#drawer').classList.contains('open')) closeDrawer();
    if ((ev.key === 'Enter' || ev.key === ' ') && ev.target.matches('[data-open], [data-toggle]')) { ev.preventDefault(); ev.target.click(); }
  });
  // chart tooltip
  const tipEl = () => $('#tip');
  document.addEventListener('mousemove', (ev) => {
    const t = ev.target.closest('[data-tip]');
    const el = tipEl();
    if (!t) { el.classList.remove('show'); return; }
    el.textContent = t.dataset.tip;
    el.classList.add('show');
    const w = el.offsetWidth; const h = el.offsetHeight;
    let x = ev.clientX + 14; let y = ev.clientY + 14;
    if (x + w > innerWidth - 8) x = ev.clientX - w - 14;
    if (y + h > innerHeight - 8) y = ev.clientY - h - 14;
    el.style.left = x + 'px'; el.style.top = y + 'px';
  });
  $('#drawerClose').addEventListener('click', closeDrawer);
  $('#scrim').addEventListener('click', closeDrawer);
  $('#tabs').addEventListener('click', (ev) => {
    const b = ev.target.closest('button[data-tab]');
    if (!b) return;
    state.tab = b.dataset.tab;
    ls.set('qa-dash-tab', state.tab);
    render();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  });
  $('#prevDay').addEventListener('click', () => { state.date = addDays(state.date, -1); state.story = null; render(); });
  $('#nextDay').addEventListener('click', () => { if (state.date < state.today) { state.date = addDays(state.date, 1); state.story = null; render(); } });
  $('#todayBtn').addEventListener('click', () => { state.date = state.today; state.story = null; render(); });
  $('#datePick').addEventListener('change', (ev) => { if (ev.target.value) { state.date = ev.target.value > state.today ? state.today : ev.target.value; state.story = null; render(); } });
  $('#search').addEventListener('input', (ev) => { state.q = ev.target.value.trim(); render(); });
  $('#syncBtn').addEventListener('click', sync);  $('#addBtn').addEventListener('click', () => openForm(null));

  // ---------- start ----------
  (async () => {
    fillIcons();
    try { state.closed = new Set(JSON.parse(ls.get('qa-dash-closed') || '[]')); } catch { state.closed = new Set(); }
    state.cfg = await api('GET', '/api/config');
    $('#who').innerHTML = `<b>${esc(state.cfg.me)}</b>QA team: ${esc(state.cfg.team.join(', '))}`;
    const h = new URLSearchParams(location.hash.slice(1));
    state.today = state.cfg.today;
    state.date = /^\d{4}-\d{2}-\d{2}$/.test(h.get('date') || '') ? h.get('date') : state.today;
    const tab = h.get('tab') || ls.get('qa-dash-tab');
    if (TITLES[tab]) state.tab = tab;
    $('#datePick').max = state.today;
    await reload();
    // Watch for new data (auto sync, or entries added from the chat) and redraw without losing your place.
    let version = (await api('GET', '/api/version').catch(() => ({}))).version;
    setInterval(async () => {
      try {
        const v = await api('GET', '/api/version');
        if (v.today !== state.today) {
          // New day (Asia/Amman midnight): if you were on "today", move to the new today.
          if (state.date === state.today) { state.date = v.today; state.story = null; }
          state.today = v.today;
          $('#datePick').max = v.today;
          version = null; // force a redraw below
        }
        if (v.version !== version) {
          version = v.version;
          const busy = document.querySelector('dialog[open]') || $('#drawer').classList.contains('open');
          if (!busy) { await reload(); toast('Updated from Azure DevOps'); } else { state.pendingReload = true; }
        }
      } catch { /* server not reachable for a moment */ }
    }, 30000);
  })().catch((e) => { $('#view').innerHTML = `<div class="card empty-card">Could not load the dashboard: ${esc(e.message)}</div>`; });
})();
