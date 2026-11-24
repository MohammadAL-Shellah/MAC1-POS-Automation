# US-214 POS Dashboard: Final QA Report

| Item | Value |
|---|---|
| Story | 214, myShop POS - Company Dashboard |
| Build | MAC1 1.2.498 (System & Devices, About) |
| Environment | QA company (branch Alshellah) and Demo Company for TC-009 and TC-010 |
| Test Run | Run 80, plan 1882, suite 1885, state Completed 24/11/2026 |
| QA Task | 2179 (rev 23, 174 figures) |
| Execution dates | 22/11/2026 to 24/11/2026 |
| Report status | **Failed** (open defects) |

## 1. Story ID and title
User Story 214, myShop POS - Company Dashboard. The MAC1 dashboard with the tabs Overview, Executive Summary, Sales, WO Info, Cash and Inventory.

## 2. Acceptance criteria coverage

| # | Story area | Cases | Passed | Failed | Blocked | N/A | Coverage |
|---|---|---|---|---|---|---|---|
| 1 | Navigation, scope and Overview | 38 | 34 | 2 (019, 071) | 2 (003, 004) | 0 | Partially covered |
| 2 | Executive Summary | 9 | 9 | 0 | 0 | 0 | Covered |
| 3 | Sales tab | 20 | 19 | 1 (040) | 0 | 0 | Covered |
| 4 | WO Info tab | 8 | 7 | 1 (052) | 0 | 0 | Covered |
| 5 | Cash tab | 6 | 4 | 1 (086) | 0 | 1 (060) | Covered |
| 6 | Inventory tab | 6 | 6 | 0 | 0 | 0 | Covered |
| | **Total** | **87** | **79** | **5** | **2** | **1** | |

Not covered: permissions with a second account (003) and a second branch, terminal or session context (004). TC-060 is Not Applicable: the story (revision 84) defines no separate Current Cash Register block on the Cash tab.

## 3. UI results
1. All tabs open, refresh and show the figures of the selected period.
2. Overview growth rules verified: positive and negative growth, full drop to zero, New Sales (TC-009) and zero growth (TC-010, Demo Company).
3. Date presets MTD, QTD and YTD fill the right dates. An invalid range (From later than To) shows a message but the tab still refreshes with the invalid range (Bug 2288).
4. Cosmetic note: the Close Day counted fields show raw decimals (for example 38.5100000000000015).

## 4. Database results
Every executed case has a query in the SQL file, run in SSMS on the database of the company under test. Sales, returns, payments, working day, Work Orders, Top Selling, COGS and the stock chain matched the UI, except for the items listed in section 9. Final queries H40 and H41 (Demo Company) are Verified.

## 5. Related screens and tables

| Screen | Tables |
|---|---|
| Overview, Sales, Executive Summary | SalInvoice, SalInvoiceItem, SalReturn, SalWorkingDay, GenBranch |
| Payments, Cash | SalInvoiceReceipt, SalInvoiceReceiptInvoice, SalInvoiceReceiptPayment, SalReturnReceipt, SalReturnReceiptReturn, SalReturnReceiptPayment, GenLkpPaymentMethod, SalBankDeposit |
| WO Info, Work Orders | SalWorkOrder, SalWorkOrderInvoice, GenLkpDocumentStatus, SalCustomer, AutVehicle, AutBay, SecSystemUser |
| Inventory, Gross Profit | InvStoreTransaction, InvStoreItem, InvStore, InvStoreBranch, InvStockIn, InvStockOut, InvItem |

Other screens that use the same data: POS sales and returns, Work Order, Close Day and Z-Report, the Daily Sales and Top Selling reports.

## 6. Confirmed relationships
Knowledge Base section 3, entries 1 to 11, and flows 1 and 2 (sale and return to dashboard). New in this run, kept in section 5 until FK metadata or a business answer is available: SalWorkOrderInvoice (item 12), SalReturnReceiptReturn (item 13), branch store rule for inventory figures (item 14).

## 7. Regression results
Story 214 joined Regression Test Plan 2115 with 79 of 87 cases: Smoke 5, Core 19, Full 55, Excluded 8. See [Regression_Plan.md](../../regression/Regression_Plan.md) section 6.7. Excluded cases wait for Bug 2286, Bug 2288 or a second account and context.

## 8. Evidence references
1. Screenshots: `docs/macone-app/pos-dashboard/evidence/run13-2026-11-22/` (UI) and its `ssms/` folder.
2. Attached to each Test Result in Run 80 and, on first run, to the Test Case work items.
3. QA Task 2179 lists each case with its result and figures.

## 9. SQL file
[US-214-POS-Dashboard.sql](../../../QA-Database-Reference/Database-Queries/US-214-POS-Dashboard.sql), sections A to H (H40 and H41 last), indexed in ALL-QUERIES-INDEX.md rows up to 94. General lookups in General-Queries.sql.

## 10. Failed, blocked and unverified items

| # | Case | Result | Reference |
|---|---|---|---|
| 1 | TC-019 Inventory stock state classification | Failed | Bug 2286 (store filter, all-branch stores missing) |
| 2 | TC-040 Sales invalid date range | Failed | Bug 2288 |
| 3 | TC-052 WO Info invalid date range | Failed | Bug 2288 |
| 4 | TC-086 Cash invalid date range | Failed | Bug 2288 |
| 5 | TC-071 Work Orders by creation date | Failed | Bug 2294 (parent story 408) |
| 6 | TC-003 Permissions | Blocked | Needs a second account with other permissions |
| 7 | TC-004 Branch, terminal and session scope | Blocked | Needs a second context |
| 8 | Inventory Value formula | Unverified | KB section 5 item 6 |

## 11. Risks and open questions
1. Gross Profit equals Net Sales with a 100% margin in Demo Company (item cost 0). Question e-20261124-001.
2. Carried-over Work Orders: counted on the new day; completing one overwrites WorkOrderDate (e-20261121-001, e-20261121-002).
3. Which stores count in inventory figures (IsApplyToAllBranch).
4. Gross Profit in a refunds-only period, Return Rate denominator, Cash Sales % basis (e-20261115-155, 157, 158).
5. Stock movement links of Sales Returns and empty Stock Out headers (e-20261120-008, 009).
6. MAC1 closed after paying a carried-over WO (draft e-20261121-003) did not reproduce on 24/11 in Demo Company.

## 12. Recommendation
**Failed.** The story is not ready to close. Fix Bug 2286, Bug 2288 and Bug 2294, then retest TC-019, 040, 052, 071 and 086. Run TC-003 and TC-004 once a second account and context are available, and get answers to the open questions in section 11.
