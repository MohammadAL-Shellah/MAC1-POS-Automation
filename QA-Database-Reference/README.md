# QA Database Reference

## 1. Purpose
Permanent library of every SQL query, database check and evidence screenshot used in QA testing of MacOne (MAC1) and the portal. Every Story, Bug, Enhancement and Change Request tested gets its database impact recorded here.

## 2. Folder structure

| Path | Content |
|---|---|
| `README.md` | This guide |
| `ALL-QUERIES-INDEX.md` | Central index of every query, searchable by Story, table, purpose and operation |
| `Story-Index.md` | One row per tested Story: tables, files, impact, status |
| `Database-Queries/` | One `.sql` file per Story, plus `General-Queries.sql` for lookups that belong to no story |
| `Screenshots/<Story folder>/` | Real UI and SSMS screenshots for that Story |

## 3. SQL file naming
`US-<StoryID>-<Short-Story-Name>.sql`, for example `US-214-POS-Dashboard.sql`. Bugs without a story use `BUG-<BugID>-<Short-Name>.sql`.

## 4. Inside each SQL file
1. Header: Story, environment, fixed IDs (branch, stores), date and build.
2. Sections per test scenario, each query preceded by a comment with its purpose and the test cases it covers.
3. Before and after queries kept next to each other.
4. UPDATE or DELETE only in the QA/Test database, after a SELECT of the target rows, and marked clearly.
5. Never mix queries from different Stories in one file.
6. Queries are never deleted: every query used for a story stays in its file, appended at the end under a dated section.
7. Retesting an old story: open and extend its existing file, do not start a new one.
8. Lookups that belong to no story (schema, finding a document, setup data) go to `General-Queries.sql`, appended with date and purpose.
9. Write the query into the file first, then run it from that file in SSMS (select the new lines and Execute), so the file always holds what was run.

### Query block format (every query, in every file)
```sql
-- =====================================================================
-- Section F: Sales custom date range   |   2026-11-21   |   Build 1.2.498
-- =====================================================================

-- Test case: TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Totals for 18/11 to 19/11 in branch Alshellah, to compare with the Sales tab.
-- Expected : Same invoices, refunds and total as the screen.
-- Status   : Verified (Run 75)
SELECT ...;
```
1. One section per test session or screen, with date and build.
2. Every query starts with the test case ID and title, then a one-line purpose in plain English.
3. Expected and Status (Written, Executed, Verified) are added after the run. In General-Queries.sql the Test case line is replaced by `-- For :` (the story or question it served).
4. One blank line between queries.

## 5. ALL-QUERIES-INDEX.md
One table row per query: Story, query purpose, database, tables, operation, what it verifies, file, date added. Search it with Ctrl+F by Story ID, table name or operation. Entries are never deleted; only queries that exist in the SQL files are listed.

## 6. Story-Index.md
One row per tested Story: date tested, tables, SQL file, screenshot folder, database impact and status (Passed, Failed, Blocked, Not Tested).

## 7. Screenshots
`Screenshots/US-<StoryID>-<Short-Name>/`. Only real screenshots from the application and from SSMS on the QA database. No mock or illustrative tables.

## 8. Adding a new Story
1. Create `Database-Queries/US-<ID>-<Name>.sql` with the header.
2. Create `Screenshots/US-<ID>-<Name>/`.
3. Add a row to `Story-Index.md`.
4. Add a row to `ALL-QUERIES-INDEX.md` for every query as soon as it is written, and mark whether it was executed and verified.

## 9. Relationship Knowledge Base
`Relationship-Knowledge-Base.md` holds verified screen, field, table and workflow relationships. Before a new Story: read it and re-validate the entries the Story touches. After a Story: add newly verified relationships, keep unconfirmed ones in its section 5.
