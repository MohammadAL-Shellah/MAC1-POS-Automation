#!/usr/bin/env node
'use strict';
// Command line for Claude Code (and you) to write to the dashboard data.
//
//   node dashboard/scripts/log.js add --type testcase --id 2036 --story 1041 --title "..."
//   node dashboard/scripts/log.js add --type test_run --story 1041 --build 1.2.488 --pass 50 --fail 6 --not-run 2
//   node dashboard/scripts/log.js add --type bug_draft --story 1041 --title "..." [--issue-type "Incorrect Functionality"] [--qa-type "Happy Scenario"] [--severity "3 - Medium"] [--screen "..."]
//   node dashboard/scripts/log.js add --type question --story 214 --title "Should ...?"
//   node dashboard/scripts/log.js add --type blocker --story 1624 --title "..." --notes "Needs: Product"
//   node dashboard/scripts/log.js logged <draftEntryId> --date <draftDate> --id <bugId>
//   node dashboard/scripts/log.js answer <entryId> --date <date> --answer "..."
//   node dashboard/scripts/log.js resolve <entryId> --date <date> [--notes "..."]
//   node dashboard/scripts/log.js update <entryId> --date <date> [--status ..] [--title ..] [--notes ..] [--story N]
//   node dashboard/scripts/log.js delete <entryId> --date <date>
//   node dashboard/scripts/log.js sync [YYYY-MM-DD] [--hook]
//   node dashboard/scripts/log.js list [YYYY-MM-DD]
//   node dashboard/scripts/log.js open        (open drafts, questions and blockers on all days)
//
// --date defaults to today (Asia/Amman). Types: story, testcase, test_run, bug_opened, bug_closed, bug_draft, question, blocker.
const store = require('../lib/store');

function parse(argv) {
  const pos = [];
  const opt = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a.startsWith('--')) {
      const k = a.slice(2);
      const next = argv[i + 1];
      if (next === undefined || next.startsWith('--')) opt[k] = true;
      else { opt[k] = next; i++; }
    } else pos.push(a);
  }
  return { pos, opt };
}

function entryFrom(opt) {
  const e = {};
  if (opt.type) e.type = opt.type;
  if (opt.id !== undefined) e.devopsId = opt.id;
  if (opt.story !== undefined) e.storyId = opt.story;
  for (const k of ['title', 'status', 'notes', 'owner']) if (opt[k] !== undefined) e[k] = String(opt[k]);
  if (opt.source) e.source = opt.source;
  if (['issue-type', 'qa-type', 'severity', 'screen'].some((k) => opt[k] !== undefined)) {
    e.bug = { issueType: opt['issue-type'] || '', qaBugType: opt['qa-type'] || '', severity: opt.severity || '', screen: opt.screen || '' };
  }
  if (['build', 'pass', 'fail', 'blocked', 'not-run'].some((k) => opt[k] !== undefined)) {
    e.run = { build: opt.build, pass: opt.pass, fail: opt.fail, blocked: opt.blocked, notRun: opt['not-run'] };
  }
  return e;
}

function line(e, date) {
  const id = e.devopsId ? `#${e.devopsId}` : '(no id)';
  const story = e.storyId && e.type !== 'story' ? ` story #${e.storyId}` : '';
  const run = e.run ? ` [${e.run.pass} pass, ${e.run.fail} fail, ${e.run.blocked} blocked, ${e.run.notRun} not run]` : '';
  return `${date ? date + ' ' : ''}${e.id}  ${e.type.padEnd(10)} ${id}${story}  ${e.status ? '(' + e.status + ') ' : ''}${e.title}${run}`;
}

async function main() {
  const [cmd, ...rest] = process.argv.slice(2);
  const { pos, opt } = parse(rest);
  const date = opt.date || store.today();
  switch (cmd) {
    case 'add': {
      const e = store.addEntry(date, Object.assign({ source: 'claude' }, entryFrom(opt)));
      console.log('Added', line(e, date));
      break;
    }
    case 'update': {
      const e = store.updateEntry(date, pos[0], entryFrom(opt));
      console.log('Updated', line(e, date));
      break;
    }
    case 'answer': {
      if (!opt.answer) throw new Error('--answer is required');
      const e = store.updateEntry(date, pos[0], { status: 'answered', question: { answer: String(opt.answer), answeredOn: store.today() } });
      console.log('Answered', line(e, date));
      break;
    }
    case 'resolve': {
      const patch = { status: 'resolved', resolvedOn: store.today() };
      if (opt.notes) patch.notes = String(opt.notes);
      const e = store.updateEntry(date, pos[0], patch);
      console.log('Resolved', line(e, date));
      break;
    }
    case 'logged': {
      const e = store.logDraft(date, pos[0], opt.id, store.today());
      console.log('Draft logged, added', line(e, store.today()));
      break;
    }
    case 'delete':
      store.deleteEntry(date, pos[0]);
      console.log('Deleted', pos[0]);
      break;
    case 'sync': {
      const d = pos[0] || store.today();
      try {
        const r = await store.sync(d);
        console.log(`Dashboard sync ${d}: ${r.added} added, ${r.updated} updated (${r.scanned} DevOps items scanned).`);
        console.log(`Refreshed ${r.checked} items from Azure DevOps, ${r.changes.length} changed.`);
        for (const c of r.changes) console.log(`  ~ ${c.date} #${c.devopsId} ${c.type}: ${c.fields.map((f) => `${f.field} ${JSON.stringify(f.from)} -> ${JSON.stringify(f.to)}`).join(', ')}  (${c.title})`);
        if (r.missing.length) console.log(`  ! not found in DevOps: ${r.missing.join(', ')}`);
        for (const e of r.addedEntries.slice(0, 15)) console.log('  +', line(e));
        if (r.addedEntries.length > 15) console.log(`  ... and ${r.addedEntries.length - 15} more`);
      } catch (e) {
        if (opt.hook) { console.log(`Dashboard sync failed: ${e.message}. Run "node dashboard/scripts/log.js sync" later.`); return; }
        throw e;
      }
      break;
    }
    case 'list': {
      const d = pos[0] || date;
      const day = store.readDay(d);
      console.log(`${d}: ${day.entries.length} entries`);
      for (const e of day.entries) console.log(' ', line(e));
      break;
    }
    case 'open': {
      for (const [d, day] of Object.entries(store.readAll())) {
        for (const e of day.entries) {
          const open = (e.type === 'bug_draft' && e.status === 'draft') || (['question', 'blocker'].includes(e.type) && e.status === 'open');
          if (open) console.log(line(e, d));
        }
      }
      break;
    }
    default:
      console.log(require('fs').readFileSync(__filename, 'utf8').split('\n').filter((l) => l.startsWith('//')).map((l) => l.slice(3)).join('\n'));
      if (cmd) process.exitCode = 1;
  }
}

main().catch((e) => { console.error('Error:', e.message); process.exitCode = 1; });
