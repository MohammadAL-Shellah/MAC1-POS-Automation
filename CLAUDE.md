# Project instructions

## QA daily dashboard (top priority)

A local dashboard in `dashboard/` logs every day's work against Azure DevOps (project Shop on devops2.minerets.com). Data is one JSON file per day in `dashboard/data/YYYY-MM-DD.json`, with dates in Asia/Amman time. Start it with `npm run dashboard` (http://localhost:4180).

### Rule 1: log in the same step
As soon as anything is created or changed in Azure DevOps, add it to today's file in the same step, before doing anything else, with its real DevOps ID. This covers a test case written, a bug opened, a bug closed, and a user story started. Nothing is opened on DevOps without showing up on the dashboard.

Log with the CLI (it validates the entry and writes the file even when the server is not running):

```
node dashboard/scripts/log.js add --type testcase   --id 2036 --story 1041 --title "..."
node dashboard/scripts/log.js add --type bug_opened --id 1977 --story 1717 --title "..."
node dashboard/scripts/log.js add --type bug_closed --id 1838 --story 1041 --title "..."
node dashboard/scripts/log.js add --type story      --id 1041 --title "..." --notes "Started testing"
node dashboard/scripts/log.js add --type test_run   --story 1041 --build 1.2.488 --pass 50 --fail 6 --blocked 0 --not-run 2
node dashboard/scripts/log.js add --type question   --story 214 --title "Should ...?"
node dashboard/scripts/log.js add --type blocker    --story 1624 --title "..." --notes "Needs: ..."
node dashboard/scripts/log.js add --type bug_draft  --story 1041 --title "..."
```

For bugs and drafts, add the classification when it is known: --issue-type (Business Issue, Code, Cosmetic, Data Corruption, Documentation, Feature Request, Incorrect Functionality, Performance, Usability), --qa-type (Happy Scenario, Invalid, Other), --severity (1 - Critical to 4 - Low) and --screen. The sync reads these from Azure DevOps (Custom.IssueType, Custom.QABugType, Severity, Custom.ScreenName) for bugs that exist there.

For many items at once (for example a pushed batch of test cases), run `node dashboard/scripts/log.js sync` right after the push instead of adding them one by one.

Also log, in the same step:
1. A test run (execution) whenever a run finishes or stops, and update it when it continues.
2. A business question whenever something needs an answer from the business. When it is answered: `log.js answer <entryId> --date <its date> --answer "..."`.
3. A blocker whenever work cannot continue. When it is cleared: `log.js resolve <entryId> --date <its date>`.

### Rule 2: never invent IDs, never create DevOps items without approval
1. Never invent or guess an Azure DevOps ID.
2. Never create a work item in Azure DevOps without the user's explicit approval. The user writes bug text themselves.
3. A bug that is not on DevOps yet is logged as `bug_draft` (no ID). Once the user opens it, run `log.js logged <draftEntryId> --date <draft date> --id <real bug ID>`.
4. A bug goes under a user story only when DevOps links it to that story (parent link), or when the user says so. Otherwise it stays in "Bugs without a user story".

### Rule 3: sync
1. A SessionStart hook runs `node dashboard/scripts/log.js sync --hook` at the start of each session. Read its output; if it failed, run the sync again.
2. Whenever the user says "sync", run `node dashboard/scripts/log.js sync` (or `sync YYYY-MM-DD` for another day).
3. Azure DevOps is the source of truth for status. Every sync also re-reads the current state of every item with a DevOps ID on that day, plus bugs, questions and blockers still open from earlier days (scripts/refresh-items.ps1). It updates status, title, assignee and parent story, and keeps a per-bug status history (statusLog). A bug that went from Closed to any other state is marked reopened. Counters use the current status, so a bug that was closed and then reopened counts as open, not closed. Manual entries without an ID are not touched. After a sync, report the items whose status changed (log.js prints them).
4. While the server runs it also syncs today by itself every autoSyncMinutes (config/team.json, default 15; 0 turns it off). Its output goes to dashboard/server.log. The page checks /api/version every 30 seconds and redraws when the data changed.
4. If a sync fails, the error is saved on the day (lastSyncError) and shown on the dashboard.
5. The sync is read only. It adds my missing items: stories assigned to me or created by me, stories I wrote test cases or opened or closed bugs under, test cases I wrote, and bugs I opened or closed. An item I only edited is never added as my task and refreshes the QA team snapshot (Rahaf Abdullah, Ahmad Hayajneh), whose names and DevOps accounts are in `dashboard/config/team.json`.

### Useful commands
- `node dashboard/scripts/log.js list [date]` shows a day.
- `node dashboard/scripts/log.js open` shows open drafts, questions and blockers on all days.
- `node dashboard/scripts/log.js update <entryId> --date <date> --status ... --notes ...` changes an entry.

Do not touch application code when working on the dashboard. Everything stays inside `dashboard/`.

## Release regression plan

The regression plan is `docs/regression/Regression_Plan.md` (Workorder detail in `docs/regression/WO_Smoke_Regression.md`).

1. Every story QA tests must join the plan. When the first execution run of a story finishes, follow section 11 of the plan: choose its Smoke, Core and Full cases, add its section, record exclusions with the reason, and update the summary counts. Then tell the user what was added.
2. When a bug is closed (seen in a sync or logged as bug_closed), add a retest case for it to Core and remove it from the Excluded section.
3. When a story changes scope, review its cases in the plan.
4. Do not tag or create regression cases on Azure DevOps without the user's approval.
5. When the user says "run regression", follow the release day runbook in section 13 of the plan, step by step.

## QA Database Reference

Every story or bug tested gets UI plus SQL Server verification. All queries go to `QA-Database-Reference/Database-Queries/US-<ID>-<Name>.sql` (one file per story, created when a new story starts; for a retest of an old story, extend its existing file; queries are never deleted). Lookups that belong to no story go to `QA-Database-Reference/Database-Queries/General-Queries.sql`. Write each query into the file first, then run it from that file in SSMS. Queries are added at once to `ALL-QUERIES-INDEX.md` and `Story-Index.md`. Only real screenshots, in `QA-Database-Reference/Screenshots/US-<ID>-<Name>/`. See its README.md.

After each test case is executed, attach its real UI and SSMS screenshots to its Test Result in the Azure DevOps Test Run (standing approval from the user, 2026-11-20). Name them `TC-xxx_ui_*.png` and `TC-xxx_db_Qn.png`.
Every screenshot attached to a Test Case, Test Result, QA Task or Bug (including screenshots prepared for bug drafts) must explain itself (added 2026-11-26): add a caption band on the image (outside the captured area, never covering or changing it) with the case ID, what the image shows and what to check, the date, the build and the environment. Highlight the field or value being checked with a box or arrow. Keep the original unedited screenshot next to it as raw evidence.
Also attach the same screenshots to the Test Case work item, only on its first run with evidence, as a fixed reference. If the test case already has attachments, do not add or replace them on later runs. Only exception: the case failed because of a bug, the bug was fixed, and the retest passed. Then replace the reference images with the passing ones, and name the bug ID and build in the attachment comment.

## Permanent QA standards (every Story, Bug, Enhancement, testing task)

1. Evidence integrity: only real application screenshots and real SQL Server results from the QA database. Never fabricate or alter. Each screenshot linked to Story and case, with case ID, date, environment. Save the exact query behind every DB screenshot. Mark each query as Written, Executed or Verified. Report any evidence that could not be collected. No Pass without evidence.
2. Screen-to-database mapping for every Story: screens, actions, tables, PK/FK and linking tables (from metadata, never from column names alone), how each action changes the DB, indirect changes (status, totals, stock, balances), other screens that show or use the same data, and UI/DB consistency. Record results in the Story QA doc and in `QA-Database-Reference/Relationship-Knowledge-Base.md`.
3. Knowledge base: before a new Story, read `Relationship-Knowledge-Base.md` and re-validate the entries it touches. Only Verified relationships go in its section 3/4; anything else goes to section 5.
4. Regression impact analysis per Story: related modules, tables, workflows, shared logic, consumers of the data; choose regression scenarios and document exclusions with reason (feeds the Regression plan).
5. No assumptions: never invent business rules, expected results, relationships, field meanings or outcomes. Classify findings as Verified, Partially Verified, Assumed or Unknown. Ask when expected behavior is unclear. Document missing access.
6. Final QA review before closing a Story, and a final report with: Story ID and title, AC coverage, UI results, DB results, related screens and tables, confirmed relationships, regression results, evidence references, SQL file, failed/blocked/unverified items, risks and open questions, recommendation. Statuses: Passed, Failed, Blocked, Not Tested, Needs Clarification, Partially Verified. Never Passed while important items stay unverified.
7. Test case result rules (every executed case):
   - Passed (Verified): screen, Expected Result and database all match the expected behaviour, and the required evidence exists.
   - Failed (Defect): a confirmed difference between Actual and Expected Result.
   - Blocked: the test could not be completed because of environment, permissions, data or a dependency.
   - Needs Investigation (Unverified): a difference or an unclear result that needs investigation before a verdict. In the DevOps Test Run it is recorded as Inconclusive with the reason; it becomes Passed or Failed once investigated.

## Executive Summary check (every invoice, WO, return or stock adjustment, added 2026-11-26)

After every invoice, Work Order, return (invoice or WO return) or stock adjustment in MAC1, check the POS Dashboard "Executive Summary" card: Inventory Value, Daily Sales (Incl. VAT), Daily Net Sales (Excl. VAT), Gross Profit (Excl. VAT), Gross Margin, Output VAT, Input VAT, Net VAT Payable.
1. Capture the values before and after the transaction, with screenshots of both.
2. Compare the change with the transaction totals (net, VAT, item cost) and confirm with the database.
3. Do it together with the stock chain check.
4. When the expected value is unclear (for example which date or store a WO counts under), raise a business question; do not assume.

## Stock quantity check (every stock transaction, added 2026-11-26)

After every transaction that moves stock (invoice, WO, invoice return, stock adjustment or any other inventory change):
1. Query the store transaction table (InvStoreTransaction) for each affected item and store: the new rows, their in and out quantities, and the running total that gives the current quantity.
2. Calculate the expected quantity: quantity before plus in minus out.
3. Compare it with CURRENT Qty on the POS Dashboard Inventory tab for the same item and store, and check that the Status (In Stock, Low Stock, Out of Stock, Negative) and the top counters (Stock Value, In Stock, Low, Out of Stock, Negative) changed accordingly.
4. Capture annotated UI and SSMS screenshots, before and after. Any mismatch is a bug draft.

## New story workflow (agreed 2026-11-21)

When the user gives a new story ID, follow in order: 1) read it on DevOps, log it on the dashboard, read the knowledge base, raise business questions; 2) create its SQL file, screenshot folder and Story-Index row, map screens to tables, analyse regression impact; 3) write test cases in a logical flow, covering for every operation the happy path plus negative and boundary cases (empty or invalid data, minimum and maximum limits, duplicates and existing data, permissions and blocking an unauthorised user, cancel and undo, failure while saving or on connection loss) and integration cases (when the operation affects another screen, module or external service, test the data transfer and the resulting effect, not only the main screen); upload only after approval; 4) execute with the build from About, including the negative, boundary and integration cases, UI + DB evidence per case (query written in the story SQL file, readable style, run from that file), results per standard 7, bugs as drafts; 5) Test Run with screenshots, Test Case reference images, QA Task annotated, dashboard and query indexes updated; 6) add to the regression plan and write the final report.

### Complete Scenario Coverage (mandatory, added 2026-11-21)

Before writing test cases, analyse every operation, Acceptance Criterion, validation, business rule, state transition and dependency of the story. Do not stop at the categories below; derive all applicable scenarios from the real requirements and system behaviour.

For each operation consider:
1. Positive: valid inputs, successful operations, expected state transitions, completion.
2. Negative: invalid inputs, missing required data, validation failures, unauthorised access, duplicate records, rejected operations.
3. Boundary: minimum and maximum values, empty values, limits, date and numeric boundaries, special characters.
4. Alternative: other valid paths, optional fields, different configurations, supported user choices.
5. State and lifecycle: valid and invalid status transitions, repeated operations, cancel, reopen, edit, delete.
6. Integration: data propagation and business impact across related screens, modules, tables and external services.
7. Failure and recovery: save failures, network interruptions, timeouts, partial failures, retries, recovery.
8. Data integrity: successful and failed operations leave no unexpected, duplicate, missing or inconsistent data.

Coverage requirements:
- Map every Acceptance Criterion, business rule and validation to one or more test cases (coverage matrix).
- Never invent scenarios or expected results without requirement or confirmed behaviour; unclear behaviour becomes a Business Question and waits.
- Mark every scenario Covered, Not Applicable (reason) or Not Tested (reason). Never claim complete coverage while a relevant scenario is untested or unresolved.
- No unnecessary duplicate test cases.
- Before asking for approval of the test cases, give a coverage summary: covered, excluded and why, still unclear.
