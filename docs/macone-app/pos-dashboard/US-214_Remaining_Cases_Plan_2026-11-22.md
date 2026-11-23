# US-214 POS Dashboard: plan for the remaining cases (22 November 2026)

Build 1.2.498. Queries are in Section G of `QA-Database-Reference/Database-Queries/US-214-POS-Dashboard.sql`. Evidence is in `evidence/run11-2026-11-22/ssms/`.

| Case | Status | What was found | What is needed |
|---|---|---|---|
| TC-009 (1894, point 130) | Not Run | Branch 35B06942 in QA - Company had no documents on 21/11 and has 2 invoices of 25.00 on 22/11 (G7, G8) | Screenshots from terminal TO_12 (device R-ABUDELLEH) before midnight on 22/11 |
| TC-082 (1952, point 188) | Not Run | No refunds-only day exists in any branch (G6). Alshellah already has an invoice on 22/11 | Approved for 23/11: one return in Alshellah and no invoices that day before the evidence |
| TC-006 (1891) | Blocked | Credit customers and unpaid invoices are not supported at present | Decision on the case scope (section 3) |

Demo Company cannot be used for these cases: it has no items, stores, payment methods or document numbering (G5).

## 1. TC-009

1. On TO_12, capture Overview with company, branch, date and the growth indicator, then System & Devices > About.
2. Run G7 and G8 again at that time. Daily Sales must equal the database (50.00 if nothing was added).
3. Expected indicator: "New Sales", with no error, infinity or division by zero.
4. If the screenshots are not taken on 22/11, use any later day that follows a day with no sales and no returns in the branch.

## 2. TC-082

1. Switch MAC1 to QA - Company, branch Alshellah, and read the build from About.
2. Confirm in the database that the day has no invoices. Make no sale that day before the evidence is taken.
3. Open the day and make one return of a paid invoice from an earlier day. Refunds are Cash only, so choose an invoice that is not above the cash in the drawer.
4. On Sales, apply that day. Expected: Refunds = return amount, Return Rate 0.0%, Average Invoice 0.00, Invoices 0, Refunds 1.
5. Record how Total Sales is displayed. Whether it may be negative is open question e-20261115-156.
6. Check the return, its payment and the stock chain in the database.

## 3. TC-006

On hold. Do not change a credit limit or customer, and do not create a credit invoice.

1. QA lead, 22/11: credit customers are not supported at present.
2. Product answer 4 of 14/11 (test cases document): unpaid and partially paid invoices are not supported, and the unpaid parts of TC-006 are not applicable.
3. Decision needed: run the supported payment methods only and record the credit part as Not Applicable, or mark the whole case Not Applicable. The case stays Blocked until then.
4. DevOps: the result of 1891 in Run 74 is still Pending with no outcome, and Run 74 is still In Progress. Task 2179 shows Blocked with the old reason (credit limit).

## 4. Company check before every step

Companies share no data.

1. TC-009 and TC-082 belong to QA - Company (`MacOne_255b989cce714d828b70d1f9e4367412`). Confirm the company in MAC1 before capturing or creating anything.
2. The queries of Sections A to F do not name a database. Select the QA - Company database in the SSMS tab before running them: on 22/11 the US-214 tab was on Demo Company.

## 5. Task 2179 and Azure DevOps do not match (read on 22/11)

Task 2179 reports 72 Pass. The latest test point outcomes are 43 Passed, and only 42 of them are Pass in both places.

| Difference | Task 2179 | DevOps | Cases |
|---|---|---|---|
| 16 cases, re-run on 20/11 according to the Task | Pass | No outcome, no file or comment on the result (Run 74) | 007, 024, 028, 035, 036, 038, 044, 052, 056, 059, 068, 069, 073, 076, 079, 087 |
| 13 cases, carried over from 19/11 and not re-executed according to the Task | Pass | No outcome, no file or comment on the result (Run 74) | 039, 040, 042, 047, 050, 051, 057, 066, 080, 081, 083, 084, 086 |
| 1 case | Pass | Blocked, waiting for the counting rule | 019 |
| 1 case | Fail | Passed (Run 74) | 032 |
| 1 case | N/A | No outcome | 060 |
| 1 case | Blocked | No outcome | 006 |

Do not report 72 Pass or 96.4% as verified. Next: check the evidence of each case, record only the proven results, re-execute the others, then correct Task 2179 and close Run 74.

## 6. Run 78 (22/11, 16:41 to 16:44, Demo Company, build 1.2.498)

Same database as G3 (`MacOne_165d415d66034069b7b0171a6c242a6e`). It now has 20 items and still no transactions (G11). Evidence: `evidence/run12-2026-11-22/`.

| Case | Result | Observation |
|---|---|---|
| 045 | Passed | Zero-invoice part: Average Invoice 0.00 |
| 047 | Passed | Return Rate 0.0% |
| 083 | Passed | Custom range without work orders: all 0 and 0.0% |
| 073 | Needs Investigation | Blank card, View All hidden (question e-20261115-159). Case A not executed |
| 085 | Needs Investigation | 0% and 0% as expected. Total row shows 100% of 0 (question e-20261122-010) |
| 081 | Not recorded, partly executed | Empty export gives "No data available to export." in Sales and WO info. A file with data is still to be checked |

Seen again on 1.2.498: the Sales grid has no ZATCA Rejection Reason column (TC-049 and 081, draft e-20261115-129). TC-049 is still Passed on DevOps and needs a re-run.

After Run 78 the test points are: 45 Passed, 3 Failed, 5 Needs Investigation, 1 Blocked, 3 N/A, 30 without outcome. Section 5 shows the state before this run.

## 7. TC-009 and TC-082 in Demo Company (replaces the Demo Company note under the first table)

State at 17:00 on 22/11: paused because the PC screen locked.

1. Done: the branch has Cash, Visa, Master, Mada and Hala, Default Price List and 15% Tax Procedure. Sync completed and the methods show in MAC1.
2. Next: close the Sync message, Open Day, one Cash invoice before midnight on 22/11. Check New Sales, the database and the stock chain (TC-009).
3. On 23/11: return that invoice and make no sale that day in Demo Company (TC-082).
4. Then continue the cases without outcome in QA - Company.

## 8. Review of the 20/11 evidence (22/11)

None of the five cases has enough evidence to be recorded as Passed from the old screenshots. All five are to be executed again. One main screenshot per case and the DB captures db01 and db04 were opened; the other files of run8 were not.

| Case | What the evidence shows | What is missing |
|---|---|---|
| 007 | Overview after a void: 1 Voided, Daily Sales 850.00. db01: invoices 850.00 | A DB row for the cancelled document; draft and deleted documents |
| 028 | Payment screen of WO-TO_11000177 with 100.00 entered. db04: totals per method | A DB check of the removed line; failed, cancelled and not applicable methods |
| 035 | Input VAT 30.00 after a purchase | A DB query of purchase VAT; the purchase-return deduction |
| 068 | Daily Sales 825.00 before the fourth invoice. db01 and db04 were taken later (850.00 less 25.00 return) | A discount (0 in DB); UI and DB taken at the same state |
| 087 | Total 363 after cancel and Sync | A DB check; stock value, grid and search (the test item needs stock) |

## 9. Run 79 and the state at 20:30 on 22/11 (replaces sections 1 and 2 and the steps of section 7)

| Item | State |
|---|---|
| TC-009 | Passed in Run 79: New Sales, 5.00, database and stock chain match (G12) |
| TC-082 | 23/11 in Demo Company: Open Day, full return of invoice TO_1000001 (5.00 Cash), no sale that day before the evidence |
| QA data created in Demo Company | Make KIA, model SPORTAGE, engine 2.5L Smartstream G2.5 GDi, customer Mohammad Al-Khatib, vehicle 5281DRB, day TO_1000001 (open, opening cash 0.00), one invoice |
| TC-032 | Reproduced: -129.89% shown in green. The value is correct (-5.65 / 4.35). The case does not define a colour, so the verdict (Task Fail, DevOps Passed) needs a decision. Draft e-20261122-012 |
| Observation | New Vehicle: Create did nothing and showed no message while VIN and Year were empty. Which field is mandatory was not isolated |
| Next | The cases without outcome, in QA - Company |

Test points after Run 79: 46 Passed, 3 Failed, 5 Needs Investigation, 1 Blocked, 3 N/A, 29 without outcome.

## 10. Correction: the cases without a DevOps outcome were executed (replaces the conclusions of sections 5 and 8 and the "Next" row of section 9)

A test point without an outcome was wrongly read as "not executed", and evidence was searched by file name only. 26 of the 29 cases were executed on build 1.2.498 on 19 or 20/11 (Task 2179 figures, Run 6 and 7 notes, db-check-2026-11-19 and run8 captures). Their results were not recorded in a Test Run. Do not execute them all again.

| Group | Count | Cases | Action |
|---|---|---|---|
| A. Evidence exists | 11 | 024, 038, 039, 040, 042, 044, 059, 068, 069, 081, 084 | Open each image, then record with it after approval. 081 is expected Fail (ZATCA Rejection Reason) |
| B. One query missing | 2 | 036 (Input VAT), 079 (lines and methods of INV-118) | Run the query, then record |
| C. Executed, one step has no evidence | 10 | 035 (purchase return), 050 (other search fields), 051 (export per tab), 052 (QTD, YTD, invalid range), 056 (search), 057 (other categories), 066 (number, no match), 076 (idle refresh after a sale), 086 (QTD, YTD), 087 (stock value and DB) | Execute the missing step only |
| D. Decision on scope or result | 3 | 007 (draft, deleted), 028 (failed payment), 080 (Task note and figure captions disagree on search) | QA lead decides |
| Not part of the 26 | 3 | 082 (23/11), 006 (scope decision), 060 (record N/A) | As planned |

Section 8 was wrong on 068: the Overview after the refund (825.00) matches db01 and db04 of the same state, and the discount is covered by the 19/11 evidence (1,307.59 with a 50 discount and returns).

The grouping comes from captions, notes and query files. Each image is still to be opened before its result is recorded.

## 11. Run 80: full execution from scratch (started 22/11, replaces sections 1 to 10 as the working plan)

1. All 87 cases are executed again and Task 2179 is rebuilt from Run 80 only (format: task-2179-backup-2026-11-22/FORMAT.md).
2. Every case with data gets a query in the story SQL file and an SSMS screenshot. A case without database impact says why.
3. Done: TC-069 expected updated, wrong YTD image removed from Test Case 1937, Run 74 closed.
4. Not as planned: the image stays in Run 75 (delete refused, 405), and closing Run 74 set its 37 pending results to Aborted.

### Run 80 progress at 21:05 on 22/11

1. UI captured and opened: baseline of the five tabs (21:02, before any transaction), TC-038 (MTD, QTD, YTD) and TC-042 (three categories). No result recorded: the database evidence is still to be taken.
2. Waiting: the story SQL tab has an unsaved edit made by the user, so Section H cannot be written yet.
3. Next: Section H queries for the baseline, then 039 and 040, the other read-only steps, and a pending Work Order for TC-071 before midnight.

4. 21:12: WO-TO_11000189 (5282GZT, Car Wash 100.00) left pending for TC-071. Do not complete or void it before the check on 23/11.
5. 21:13: TC-040, the rejected date range is applied after returning to Sales. Being reproduced.
6. 21:14: TC-040 Failed (reproduced, bug draft logged). Check the same step on WO info and Cash (TC-052, 086): always close the message and read the values.

### Run 80 checkpoint, 22/11 21:25

| Result | Count | Cases |
|---|---|---|
| Passed | 17 | 002, 008, 011, 014, 015, 017, 018, 037, 039, 042, 043, 048, 053, 054, 059, 061, 070 |
| Failed | 4 | 040, 052, 086 (invalid range applied, draft e-20261122-014), 049 (column, draft e-20261115-129) |
| Not run yet | 66 | All the others |

1. Partly captured, not recorded: 038 (financial year start not verified), 021 (Opened By in the database), 058 (method table cropped), 071 (second half on 23/11).
2. Changed 22/11 21:36 (the user approved creating any test data on the QA POS): 005, 012, 016, 022, 023, 025, 027, 031, 034, 036, 046, 068, 069, 074, 076, 077 get their data on 22/11, after the read-only Cash and Inventory baseline is captured. Keep for 23/11: WO-TO_11000189 (071) and the return of Demo invoice TO_1000001 (082).
3. 23/11 in this order: 067 and 071 before any sale, Open Day, transactions, remaining tabs, Close Day and deposit, then 082 in Demo Company. 010 and 009 need a company with no sale on the day before.
4. For every validation case: close the message, then read the values.
5. Regression plan and Task 2179 are updated from Run 80 when it finishes.

### Execution incident, 22/11 21:39

1. While running H7 the SSMS selection was lost between the check and the click, so Execute ran the whole US-214 SQL file (550 rows).
2. The file was audited afterwards: 58 SELECT, 5 WITH and one dynamic block (G2) that builds SELECT COUNT only. No statement changes data. G2 read the company name and document counts of every MacOne database ReadUser can access.
3. No result of that execution is used as evidence or as a query status.
4. Execute is now allowed only through a guard that compares the selected text with the intended block in the same process as the click.

### Run 80 test data created 22/11 evening (QA - Company, Alshellah)

| Ref | Document | Data | For cases | Database and stock check |
|---|---|---|---|---|
| T1 | WO-TO_11000190, INV-TO_11000140, 21:50, 5281DRB | Six lines, discount 36.09, total 473.51, Cash 300.00 + Mada 173.51 | 005, 025, 027, 031, 068, 074, 079 | Verified H11: Stock Out TO_11000201, Sticker Item 1, cost 88.00 |
| T2 | WO-TO_11000191, INV-TO_11000141, 21:55, 5281DRB | Sticker Item 210.00, Mada, to be fully returned in Cash | 012, 016, 022, 034, 046, 069, 074, 076 | Sale verified H12: Stock Out TO_11000202, cost 88.00 |
| T3 | RTN-TO_11000020 of INV-TO_11000141, 21:58 | Full return 210.00 (VAT 27.39), refunded in Cash, original Mada | 005, 012, 016, 022, 027, 031, 034, 046, 069, 074, 076 | Verified H13: Stock In TO_11000040, net movement 0 |
| T4 | WO-TO_11000192, INV-TO_11000142, 22:03, 5281DRB | Car Wash qty 2, 200.00, Master | 068, 079 | Verified H14: service only, no stock movement |
| T5 | WO-TO_11000193, INV-TO_11000143, 22:21, 5281DRB | QA_SST AC Check 30.00, completed from WO info, Mada | 084 | Verified H20: no stock movement |
| T6 | PR-TO_11000004, 22:23, Default Supplier, Branch Store | Purchase of Air Filter 041 x2, 200.00 + VAT 30.00 = 230.00 | 035, 036 | Verified H22, H23: Stock In TO_11000041, 4 base units (packing 2) |
| T7 | Purchase return TO_11000002 (reference entered: PR-TO_11000004) | Air Filter 041 x1, 100.00 + VAT 15.00 = 115.00 | 035 | H24: saved, two Stock Out headers TO_11000205, one empty (H25, bug draft) |
| T8 | WO-TO_11000194, INV-TO_11000144, 22:45, 5281DRB | 30.00: Cash line 10.00 added and cancelled, then Visa 30.00 | 028 | Verified H27: only Visa saved, no stock movement |
| T9 | ST Adjustment - TO_11000005 (ID F2844371-D6B1-47A8-A9F3-72D368C52BC8), 22:52 | Stock In of Tire - Item +6 in Mohammad Store Branch - 2, 330.00, to make quantity = minimum (10) | 063, 030 | Verified H28 to H30: Stock In TO_11000042, balance 4 to 10. The number duplicates the 13/11 adjustment, which is unchanged (bug draft) |

Observation for TC-029 and 062 (Needs Investigation): after T1 took out Sticker Item at cost 88.00, Overview Inventory Value stayed 83,474.00 (21:43 and 21:52 screens).

### Run 80 checkpoint, 22/11 22:15 (replaces the 21:25 checkpoint)

| Result | Count | Cases |
|---|---|---|
| Passed | 39 | 002, 005, 008, 011, 012, 014, 015, 016, 017, 018, 021, 022, 025, 026, 027, 031, 032, 034, 037, 039, 042, 043, 045, 047, 048, 051, 053, 054, 055, 057, 058, 059, 061, 068, 070, 074, 077, 080, 085 |
| Failed | 5 | 040, 049, 052, 081, 086 |
| Needs Investigation | 3 | 038, 050, 083 |
| Not run yet | 40 | All the others |

1. 23/11: after the 067 and 071 checks, return INV-TO_11000140 (own invoice, split payment, earlier day) for 046, 069 and 079.
2. Only invoices created by QA in this run are returned. Invoices of the user are not touched.
3. Exports open a Save As dialog and are saved to Downloads with a timestamped name, then copied to the evidence folder.
4. 056: searches captured, the database check of customer, plate and bay is still to do.

### Run 80 checkpoint, end of 22/11 evening (read from DevOps, replaces the earlier checkpoints)

| Result | Count | Cases |
|---|---|---|
| Passed | 47 | 002, 005, 006, 008, 011, 012, 014, 015, 016, 017, 018, 021, 022, 025, 026, 027, 031, 032, 034, 035, 036, 037, 039, 041, 042, 043, 045, 047, 048, 051, 053, 054, 055, 056, 057, 058, 059, 061, 065, 066, 068, 070, 074, 077, 080, 084, 085 |
| Failed | 5 | 040, 049, 052, 081, 086 |
| Inconclusive | 15 | 007, 013, 019, 020, 023, 024, 029, 038, 044, 050, 062, 064, 072, 076, 083 |
| NotApplicable | 1 | 060 |
| Blocked | 0 |  |
| NotRun | 19 | 001, 003, 004, 009, 010, 028, 030, 033, 046, 063, 067, 069, 071, 073, 075, 078, 079, 082, 087 |

1. 23/11 order: re-verify company and build and re-pin the driver, check 067 and 071 before any sale, Open Day, then return INV-TO_11000140 (046, 069, 079), remaining cases, Close Day and deposit (075), then 082 in Demo Company.
2. SSMS is executed only with ssms5 (selection compared in the same process).
3. Task 2179, the Regression plan and the final report are done after all 87 have a result.


### Run 80 checkpoint, 22/11 23:00 (read from DevOps, replaces the earlier checkpoints)

| Result | Count | Cases |
|---|---|---|
| Passed | 48 | The 47 of the previous checkpoint and 030 |
| Failed | 5 | 040, 049, 052, 081, 086 |
| Inconclusive | 18 | The 15 of the previous checkpoint and 028, 063, 087 |
| NotApplicable | 1 | 060 |
| Blocked | 3 | 001, 003, 004 (blockers e-20261122-023, 024, 025) |
| NotRun | 12 | 009, 010, 033, 046, 067, 069, 071, 073, 075, 078, 079, 082 |

1. T9 was not reversed: the Stock Out form proposes TO_11000005 again and would create a third document with that number (bug draft e-20261122-022). Tire - Item in Mohammad Store Branch - 2 stays at 10 until the user decides.
2. The 23/11 order of the previous checkpoint is unchanged. Inventory baseline for 23/11: value 83,904.00.


### Test data created on 23/11 (QA - Company, Alshellah)

| Ref | Document | Content | Cases | Check |
|---|---|---|---|---|
| T10 | RTN-TO_11000021 of INV-TO_11000143, 08:37 | Full return 30.00 in Cash, first document of the day, before any sale | 082, 069, 046 | H32: Stock In TO_11000043 +1 for a service (draft e-20261120-007) |
| T11 | WO-TO_11000195, INV-TO_11000145, 08:42 | Car Wash 100.00, Cash 60.00 + Mada 40.00 | 069, 079 | H34 |
| T12 | WO-TO_11000196, INV-TO_11000146, 08:45 | Car Wash, RService, QA_SST Brake Check, 225.01 Cash | 069, 073, 079, 067 | H34 |
| T13 | RTN-TO_11000022 of INV-TO_11000145, 08:48 | Full return 100.00 in Cash | 069, 079, 046 | H34 |
| T14 | WO-TO_11000197 (pending), WO-TO_11000198 (voided), WO-TO_11000189 completed with INV-TO_11000147 | 071 data | 071 | H36: WO-189 date overwritten (draft e-20261123-001) |

1. INV-TO_11000140 was not returned: Cash refund 473.51 is above the drawer balance (Insufficient balance) and Mada refunds are not supported.
2. Day TO_11000034 opened 08:34 with 200.00 via Continue without closing; days of 21/11 and 22/11 are still open.
3. 08:52 to 08:53: a Send via SMS from Vouchers List was done by someone else on MAC1, then a QA click landed on Send to Email (document unknown). Reported to the user.

### Run 80 checkpoint, 23/11 09:11 (read from DevOps)

| Result | Count | Cases |
|---|---|---|
| Passed | 55 | The 48 of 22/11 and 033, 082, 067, 069, 046, 079, 078 |
| Failed | 6 | 040, 049, 052, 081, 086, 071 |
| Inconclusive | 19 | The 18 of 22/11 and 073 |
| NotApplicable | 1 | 060 |
| Blocked | 3 | 001, 003, 004 |
| NotRun | 3 | 075 (Close Day needs the Admin PIN), 009, 010 (need a day with zero sales after or before a day with zero sales) |

### Decisions of 23/11 (afternoon)

1. TC-001 executed and passed by the user on 23/11.
2. TC-009 and TC-010 approved for Demo Company on 24/11: no sale in Demo Company on 23/11; on 24/11 check TC-010 (0%) before any sale, then make one sale and check TC-009 (New Sales). Needs the user's sign-in to Demo Company.
3. TC-003 and TC-004 stay Blocked (accounts not available).
4. TC-071: the user checks the Work Order date behaviour before the bug is opened (draft e-20261123-001).
