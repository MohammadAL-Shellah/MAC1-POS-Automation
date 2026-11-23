# POS Dashboard — Execution Report

- **Dates:**
  - **Run 1, 2026-11-12:** TC-POS-001 … 066, business date 12/11/2026, register/session `TO_11000023` (opened 11:41 AM, opening cash 100.00).
  - **Run 2, 2026-11-13:** TC-POS-067 … 087, plus re-runs of 024, 033, and 046. Business date 13/11/2026, new register/session `TO_11000024` (opened 07:58 PM, opening cash 100.00). See [Run 2](#run-2--2026-11-13-tc-pos-067--087-and-re-runs).
- **Environment:** QA - Company (MAC One desktop, `Minerets.Shop.MacOne.exe`), user `m98`, branch Alshellah.
- **Source cases:** [US-214_POS_Dashboard_Test_Cases.md](./US-214_POS_Dashboard_Test_Cases.md) (TC-POS-001 … TC-POS-087)
- **Execution mode:** Manual-assisted. The desktop app is native .NET MAUI / WinUI 3 (no WebView2), so Playwright cannot drive it. Screens were read and driven through Windows UI Automation (text plus bounding boxes) and real mouse clicks. Exported CSVs were read from `%LOCALAPPDATA%\Minerets\MineretsMacOne\Cache`.
- **Data changes:** Authorized by the product owner for the QA environment. Work orders, invoices, a void, and two returns were created (listed below). No data was changed outside QA.
- **Supersedes:** The earlier read-only partial run of the same day (16 cases). Its results are merged into this report.

## Summary (all runs, 87 cases, status as of 2026-11-14)

| Result | Count | Test cases |
|---|---|---|
| PASS | 69 | 001, 002, 005, 006, 007, 008, 011, 012, 013, 014, 015, 017, 018, 019, 020, 021, 022, 023, 024, 025, 026, 027, 031, 032, 033, 034, 035, 036, 037, 038, 039, 040, 041, 042, 043, 044, 045, 046, 047, 048, 050, 051, 052, 053, 054, 055, 056, 057, 058, 059, 061, 063, 065, 066, 067, 068, 069, 070, 072, 074, 077, 078, 079, 082, 083, 084, 085, 086, 087 |
| PARTIAL | 3 | 028, 073, 075 |
| FAIL | 8 | 016, 029, 049, 060, 062, 076, 080, 081 |
| INVESTIGATE | 1 | 064 |
| BLOCKED | 1 | 004 (branch isolation: no second-branch user) |
| NOT APPLICABLE | 2 | 003 (single admin user), 030 (no date-based Inventory Value) |
| SCHEDULED | 3 | 009 and 010 (need a full day with no sales), 071 (WO-TO_11000096 left Pending on 13/11, to be completed on 14/11) |
| **Total** | **87** | |

Status changes after the product answers and the follow-up run (see [Run 3](#run-3--2026-11-13-follow-ups-after-product-answers)):
- PARTIAL → PASS: 007, 019, 023, 024, 036, 044, 046, 063, 069.
- BLOCKED → PASS: 035.
- INVESTIGATE / PARTIAL → FAIL: 029 and 062 (POS-D06).
- 087: first recorded as FAIL (POS-D07), then PASS once the POS data Sync was run. POS-D07 is withdrawn.

Status changes after the product answers of 2026-11-14 (see the test-case file, section "Product answers (2026-11-14)"):
- FAIL → PASS: 014. Opening the All list from "Invoices Today" is accepted behaviour, so POS-D03 is withdrawn.
- PASS → FAIL: 076. Product requires the dashboard to refresh automatically while it is open. The idle test in Run 4 showed no automatic refresh (POS-D09).
- Observation O-9 (date picker) is now defect POS-D08.

## Test data created in QA

All work orders use plate `1111AAA`, Bay 01, technician m.alshellah. Prices are VAT-inclusive at 15%. RService carries 0% VAT.

| Ref | Document | Content | Payment | Result |
|---|---|---|---|---|
| WO-A | WO-TO_11000086 → INV-TO_11000075 | Tire - Item 500 + Car Wash 100, discount "QA Trans Disc 50" (50.00 before VAT; 57.50 incl. VAT) | Cash 542.50 | Completed / Paid (VAT 70.76) |
| WO-B | WO-TO_11000087 → INV-TO_11000076 | RService 100 (customer Ammar) | Master 100.00 | Completed / Paid (VAT 0) |
| WO-C | WO-TO_11000088 → INV-TO_11000077 | Car Wash ×2 = 200 (customer Ammar) | Split: Cash 100 + Mada 100 | Completed / Paid |
| WO-V | WO-TO_11000089 | RService 100 | — | Voided |
| WO-D | WO-TO_11000090 | RService 100 | — | Pending during the run. Completed later, outside the scripted run (see note) |
| RTN-1 | RTN-TO_11000013 | Full return of INV-TO_11000076 (paid by Master), reason "Customer Return" | Refund in Cash 100.00 | Refunded |
| RTN-2 | RTN-TO_11000014 | Full return of INV-TO_11000077 (paid Cash + Mada), credit note 200.00 (VAT 26.09) | Refund in Cash 200.00 | Refunded |

Before the run, the day already contained INV-TO_11000074 / WO-TO_11000085: 2,898.46 Cash, Battery Fluid 009 + Battery Fluid 007 + Oil Filter 008.

A Stock In adjustment draft (`ST Adjustment - TO_11000005`, Branch-2) was started to build a Low Stock boundary item. The app was then used interactively and the form was left without submitting, so the fixture was **not** created.

## Checkpoint values (Overview, Daily)

| Metric | After RTN-1 | After RTN-2 | After WO-D completed | Reconciliation |
|---|---|---|---|---|
| Daily Sales (Incl. VAT) | 3,640.96 | 3,440.96 | 3,540.96 | Gross 3,798.46 − discount 57.50 − returns (100 / 300) |
| Refunds | 100.00 | 300.00 | 300.00 | RTN-1 + RTN-2 |
| Growth vs yesterday (8,527.93) | −57.3% | −59.7% | −58.5% | (today − 8,527.93) / 8,527.93 |
| Invoices / Fully Paid / Fully Refunded | 4 / 4 / 1 | 4 / 4 / 2 | 5 / 5 / 2 | |
| WOs total / Pending / Completed / Voided | 6 / 1 / 4 / 1 | 6 / 1 / 4 / 1 | 6 / 0 / 5 / 1 | |
| Payment chart (Cash / Mada / Master) | 3,440.96 / 100 / 100 | 3,240.96 / 100 / 100 | Cash 3,240.96 (others not re-read) | Refunds are deducted from the refund method (Cash) |
| Expected Cash Balance | 3,540.96 | 3,340.96 | 3,340.96 | 100 + cash sales 3,540.96 − cash refunds |
| Daily Net Sales (Excl. VAT) | 3,166.05 | 2,992.14 | 3,092.14 | Σ invoice net (2,520.40 + 471.74 + 100 + 173.91) − return net |
| Gross Profit / Margin | 2,891.05 / 91.31% | 2,717.14 / 90.81% | 2,817.14 / — | COGS 275.00 (displayed Net − GP) |
| Output VAT / Input VAT / Net VAT | 474.91 / 0 / 474.91 | 448.82 / 0 / 448.82 | — | Return VAT 26.09 deducted |
| Inventory Value | 6,710.00 | 6,710.00 | 6,710.00 | See INVESTIGATE TC-029 |

## Results by test case

### Navigation, scope, and Overview

| TC | Result | Evidence / observation |
|---|---|---|
| 001 | PASS | The dashboard opens on Overview. |
| 002 | PASS | Overview, Sales, WO info, Cash, and Inventory all open with their own content. |
| 003 | BLOCKED | Needs a second QA account with different permissions; none was available. |
| 004 | BLOCKED | Needs a second branch/terminal/session with a user assigned to it; none was available. |
| 005 | PASS | Daily Sales = gross 3,798.46 − discount 57.50 − returns. Values: 3,640.96 with Refunds 100, then 3,440.96 with Refunds 300. |
| 006 | PASS | Invoices paid by Cash, Master, and split Cash + Mada each count their full invoice value once. No credit or unpaid invoice could be produced from the POS (all WOs require full payment). |
| 007 | PARTIAL | Voided WO-89 (100) and pending WO-90 (no invoice yet) did not affect Daily Sales or Invoices. Draft, cancelled, or deleted sales/return documents cannot be produced from the POS. |
| 008 | PASS | −57.3%, −59.7%, and −58.5% all equal (today − 8,527.93) / 8,527.93. |
| 009 | NOT RUN | Requires a day where yesterday has zero sales. Yesterday already had 8,527.93 in QA. |
| 010 | NOT RUN | Requires zero sales on both days. |
| 011 | PASS | The Daily Sales KPI opens Sales → Daily (12/11–12/11) listing RTN-13, INV-77, 76, 75, 74. There is no separate "Daily Sales Report"; the Sales tab acts as it. |
| 012 | PASS | Refunds opens Sales → Refunds, dated 12/11, with only RTN-TO_11000013. |
| 013 | PASS | Invoices 4, Fully Paid 4; later 5 / 5. No partially paid invoice could be produced. |
| 014 | PASS (after product answer) | "Invoices Today" opens Sales on **All (5)**, which includes the refund RTN-TO_11000013. First recorded as FAIL. On 2026-11-14 product accepted this behaviour, because other entry points open the invoice list and the return list. |
| 015 | PASS | Fully Paid opens Sales → Invoices (4): INV-74…77. |
| 016 | **FAIL** (needs clarification) | Fully Refunded opens Sales → Refunds and lists the **return documents** (RTN-13, then RTN-13 + RTN-14). The spec expects the fully refunded **invoices** (INV-76, INV-77). The count (1 → 2) is correct. |
| 017 | PASS | 6 = 1 Pending + 4 Completed + 1 Voided, later 0 + 5 + 1. |
| 018 | PASS | Pending → WO-90; Completed → WO-85…88; Voided → WO-89; Total → all 6. All are dated 12/11. |
| 019 | PARTIAL | 366 items: 0 Low, 13 Out of stock, 6 Negative. Selling Tire - Item from Branch-2 (0 → −1) moved it from Out of Stock (14 → 13) to Negative (5 → 6). A positive-stock low-level item was not available (fixture not created). |
| 020 | PASS | Low/Out/Negative/Total each open Inventory on the matching category. Out of Stock rows show 0 and Negative rows show negative quantities. |
| 021 | PASS | Register TO_11000023 · m.alshellah, opened 2026/11/12 11:41 AM, opening cash 100.00, expected cash shown. |
| 022 | PASS | 100 + cash sales 3,540.96 − cash refund 100 = 3,540.96, then − 300 = 3,340.96. RTN-1 is exactly the case's scenario: the original was paid electronically (Master) and refunded in cash. |
| 023 | PARTIAL | Mada 100 and Master 100 sales did not change Expected Cash, and the exclusion note is present. The electronic-refund part is not applicable: refunds are Cash only by current business rule (O-3). |
| 024 | PARTIAL (Run 2) | The new session TO_11000024 started with Expected Cash 100.00 (opening only), so none of session TO_11000023's cash movements (3,240.96 net) carried over. An unconfirmed cash movement could not be produced: no draft deposit could be created (see TC-075). |
| 025 | PASS | Exactly 5 rows, sorted by value: Battery Fluid 009 1,160.01; Battery Fluid 007 1,125.69; Oil Filter 008 612.77; Tire - Item 500.00; Car Wash 300.00 (Qty 3). Observation: returned quantities are not deducted (see O-1). |
| 026 | PASS | View All opens "Top Selling (Today)" with category filters, search, and the full list (6 items including RService). |
| 027 | PASS | Split INV-77 is allocated Cash 100 + Mada 100. Refunds are deducted from the **refund** method: Cash went 3,540.96 → 3,440.96 → 3,240.96 while Master (the original method of INV-76) stayed at 100 (clarification item 8). |
| 028 | PARTIAL | The chart shows the configured methods Cash, Mada, Master, Visa, and Hala (Visa and Hala are 0). Failed or cancelled payments cannot be produced from the POS. |

### Executive Summary

| TC | Result | Evidence / observation |
|---|---|---|
| 029 | **INVESTIGATE** | Inventory Value was 4,840 before today's scripted sales and 6,710 after, an increase of 1,870, although sales should reduce stock value. Displayed COGS shows a Tire cost of about 55. The same value appears on the Inventory tab. The formula could not be recomputed without unit-cost data. |
| 030 | NOT RUN | Overview has no date selector, so there is no historic period to compare against. |
| 031 | PASS | Net Sales = Σ invoice net − returns net (3,166.05, then 2,992.14). Gross Profit = Net − COGS 275.00 (2,891.05, then 2,717.14). COGS was not independently verified against costing. |
| 032 | PASS | 2,891.05 / 3,166.05 = 91.31% and 2,717.14 / 2,992.14 = 90.81%. Both match the displayed margins. |
| 033 | PASS (Run 2) | On 13/11, with no transactions, Gross Margin shows **0.00%** with no error (`d2_overview_start`). |
| 034 | PASS | Output VAT 474.91 (378.06 + 70.76 + 0 + 26.09) drops to 448.82 after RTN-2 (VAT 26.09). |
| 035 | BLOCKED | The POS app has no purchase screen (Cash & Stock menu: Opening Balance, Cash Deposit, Stock Adjustment, My items). Input VAT = 0. |
| 036 | PARTIAL | Net VAT Payable = Output VAT − Input VAT (474.91 − 0, 448.82 − 0). A non-zero Input VAT could not be tested. |

### Sales tab

| TC | Result | Evidence / observation |
|---|---|---|
| 037 | PASS | Daily is selected by default, From/To 12/11/2026. |
| 038 | PASS | MTD 01/11–12/11, QTD 01/10–12/11, YTD 01/01–12/11 (calendar financial year assumed). |
| 039 | PASS | 11/11–11/11: Total 8,527.93, Net 7,428.63, 9 invoices, Avg 947.55, Refunds 52.61, rate 0.6%, All 10 / Refunds 1 / Invoices 9. |
| 040 | PASS | From 12/11 > To 11/11 shows "From Date must be on or before To Date." and the range is not applied. |
| 041 | PASS | MTD/QTD/YTD update From/To and refresh data. Manually picking dates and pressing Apply refreshes data. |
| 042 | PASS | The date range is kept when switching All / Refunds / Invoices. |
| 043 | PASS | Total 3,640.96 / Net 3,166.05 / Invoices 4, then 3,440.96 / 2,992.14 / 4 after RTN-2. Both reconcile with the source invoices (see checkpoint table). |
| 044 | PARTIAL | Split-paid INV-77 is counted once (Invoices 4). Failed, draft, cancelled, or deleted invoices cannot be produced. |
| 045 | PASS | Avg = 3,640.96 / 4 = 910.24, then 3,440.96 / 4 = 860.24. Zero range (13/11) shows 0.00. |
| 046 | PARTIAL | Refunds 100 → 300. Return Rate 2.6% → 7.9% = refunds / gross sales **before discount** (3,798.46). **Run 2:** RTN-TO_11000015 returns INV-TO_11000038 (invoice dated 1/11) on 13/11. It is counted on 13/11 (Refunds 51.00), and the return date is what is used. Not tested: draft or rejected returns (the POS submits returns directly). |
| 047 | PASS | Range 13/11 (zero sales, zero refunds) shows Return Rate 0.0% with no error. |
| 048 | PASS | All 5 = 4 + 1, then 6 = 4 + 2. On 11/11: 10 = 9 + 1. Counts are document counts (the split invoice is one row). |
| 049 | **FAIL** | Columns shown: Invoice # / Date, Customer, Customer Type, Plate Number, Items, Amount, Method, Status, ZATCA Status, ZATCA Status Time. **ZATCA Rejection Reason is missing** from both the grid and the CSV export. ZATCA Status is empty for every QA document. |
| 050 | PASS | Searches by invoice # (11000075), customer (Ammar, Mohammad), method (Mada, Master), plate (1111AAA), and "RTN" return correct rows. A no-match term returns no rows. ZATCA status search is not testable (values are empty). |
| 051 | PASS | Export All produced 5 rows identical to the grid. Refunds produced 1 row. Invoices + search "Ammar" produced 2 rows (INV-77, INV-76). Files: `evidence/exports/Transactions_20261112_*.csv`. |

### WO Info tab

| TC | Result | Evidence / observation |
|---|---|---|
| 052 | PASS | Daily 12/11; MTD 01/11–12/11; QTD 01/10–12/11; YTD 01/01–12/11. The invalid range is rejected with the same validation message. |
| 053 | PASS | Total WOs 6 (including pending and voided). Customers Served 2 (Mohammad Alshellah, Ammar), which is a distinct count. |
| 054 | PASS | Daily: 1 / 4 / 1 → 16.7% / 66.7% / 16.7%. MTD 61: 1 / 50 / 10 → 1.6% / 82.0% / 16.4%. QTD/YTD 90: 1 / 75 / 14 → 1.1% / 83.3% / 15.6%. |
| 055 | PASS | Each status tab shows only that status, and the dates are unchanged after switching. |
| 056 | PASS | Columns: WO # / date, Customer · Tech, Plate, Bay, Amount, Status. The pending WO-90 row shows a **Complete** action (not clicked by the test). Searches by WO #, customer, bay, technician, and VIN (12222223334H66888, KL987GTT666668890) return correct rows, and no-match returns none. Observation O-5. |
| 057 | PASS | The Voided tab export produced exactly WO-TO_11000089 (`evidence/exports/WorkOrders_20261112_144603.csv`). |

### Cash tab

| TC | Result | Evidence / observation |
|---|---|---|
| 058 | PASS | Received 3,740.96 − Refund 100 = Net 3,640.96. Cash 3,540.96 − 100 = 3,440.96 (94.5%). Electronic 200 (5.5%). Methods table Cash / Mada / Mastercard. After RTN-2: Cash refunds 300, Net cash 3,240.96 (94.2%). |
| 059 | PASS | MTD changes the totals (Received 65,576.28, Refund 22,251.20, …) while register details stay on the current session. |
| 060 | **FAIL** | The Cash tab's Current Cash Register card has **no Cash Deposit button**, and none appears after scrolling. The Cash Deposit screen exists only in the side menu (Cash & Stock → Cash Deposit). |
| 061 | PASS | Same register TO_11000023, opening 100.00, expected 3,540.96 / 3,340.96 on both Overview and Cash. |

### Inventory tab

| TC | Result | Evidence / observation |
|---|---|---|
| 062 | PARTIAL | Stock Value 6,710.00 (same as Overview), In Stock 357. The value could not be recomputed (see TC-029), and counts are per item × store row (see TC-064). |
| 063 | PARTIAL | 0 qty → Out of Stock and negative qty → Negative are verified (e.g. Tire - Item, Branch-2: −1, Min 10 → Negative). The Low Stock boundary (0 < qty ≤ min) was not produced: 0 items are Low Stock and the adjustment fixture was not submitted. |
| 064 | **INVESTIGATE** | All 366 vs In Stock 357 + Low 0 + Out 13 + Negative 6 = **376**. Rows are item × store (e.g. Oil Filter 008 appears twice: Branch Store 21, Branch-2 −1), so "All" and the category counts appear to use different bases. |
| 065 | PASS | Columns: Item Name, Item Number, Store Name, Current Qty, Min Qty, Max Qty, Status. |
| 066 | PASS | "Oil Filter 008" returns 2 rows; "NEW-ITEM-0008" returns the same 2; "Oil Filter" (partial) returns 9; "TO_1000001" returns Tire - Item in 2 stores; a no-match term returns 0. |

## Run 2 — 2026-11-13 (TC-POS-067 … 087 and re-runs)

The day opened as a new business day (session `TO_11000024`, opening cash 100.00) with **no transactions**. The empty-day boundary cases ran first, then data was created in this order.

### Test data created on 13/11

| Ref | Document | Content | Payment | Result |
|---|---|---|---|---|
| R-1 | RTN-TO_11000015 | Full return of **INV-TO_11000038** (dated 1/11, paid Master 51.00; subtotal 44.35 + VAT 6.65) | Refund in Cash 51.00 | Refunded. Creates a refunds-only day. |
| — | (no document) | Attempted full return of INV-TO_11000075 (542.50) | — | **Blocked by the app:** "The Cash balance is not enough to refund this invoice." (the drawer held 100) |
| S-1 | WO-TO_11000091 → INV-TO_11000079 | Car Wash 100 + RService 100 + Tire - Item 500 = 700.00 (subtotal 621.74, tax 78.26), customer Ammar | Split: Cash 300 + Mada Pay 400 | Completed / Paid |
| S-2 | WO-TO_11000092 → INV-TO_11000080 | Car Wash with "QA Trans Disc 50" = 42.50 (86.96 − 50 + VAT 5.54) | Master 42.50 | Completed / Paid |
| S-3 | WO-TO_11000093 → INV-TO_11000081 | RService 100 (BMW, Mohammad Alshellah). Left Pending, then completed through the WO Info **Complete** action | Cash 100 | Completed / Paid |
| S-4 | WO-TO_11000094 | Car Wash | — | Voided ("Are you sure you want to cancel the current WO?" → Confirm) |
| R-2 | RTN-TO_11000016 | Full return of INV-TO_11000080 (today, paid Master) | Refund in Cash 42.50 | Refunded |

Cash Deposit and Stock Adjustment forms were opened but nothing was saved.

### Checkpoints on 13/11 (Overview, Daily)

| Point | Daily Sales | Growth vs 12/11 (3,540.96) | Refunds | Invoices / Fully Paid / Fully Refunded | WOs (P / C / V) | Expected Cash |
|---|---|---|---|---|---|---|
| Empty day | 0.00 | −100% | 0.00 | 0 / 0 / 0 | 0 (0 / 0 / 0) | 100.00 |
| After R-1 | **−51.00** | −101.4% | 51.00 | 0 / 0 / 0 | 0 | 49.00 |
| After S-1 | 649.00 | −81.7% | 51.00 | 1 / 1 / 0 | 1 (0 / 1 / 0) | 349.00 |
| After S-2, S-3 pending, S-4 voided | 691.50 | −80.5% | 51.00 | 2 / 2 / 0 | 4 (1 / 2 / 1) | 349.00 |
| After S-3 completed and R-2 | **749.00** | −78.8% | 93.50 | 3 / 3 / 1 | 4 (0 / 3 / 1) | 406.50 |

Final reconciliation:
- **Daily Sales:** gross 900.00 − discount 57.50 − returns 93.50 = 749.00.
- **Net Sales:** 621.74 + 36.96 + 100 − 44.35 − 36.96 = 677.39.
- **COGS:** 55.00, so Gross Profit is 622.39 and Margin 91.88%.
- **Output VAT:** 78.26 + 5.54 − 6.65 − 5.54 = 71.61.
- **Payment chart:** Cash 306.50 (400 − 93.50), Mada 400, Master 42.50.

### Results

| TC | Result | Evidence / observation |
|---|---|---|
| 067 | PASS | Case B: the empty day shows −100% vs yesterday. Case A: today 649.00 vs 3,540.96 shows **−81.7%** with a down arrow (later −80.5% and −78.8%). The refunds-only point shows −101.4%. All match ((today − yesterday) / yesterday). |
| 068 | PASS | Cash 400, Mada 400, and Master 42.50 invoices (gross 900.00), discount 57.50 incl. VAT, returns 93.50 → Daily Sales 749.00. Refunds shows 93.50. Visa is not a POS payment method in QA (methods are Hala, Credit Card, Cash, Mada Pay, Master). |
| 069 | PARTIAL | Fully Refunded = **1** after fully returning today's INV-80. The return of the 1/11 invoice (RTN-15) is correctly not counted. A partial return cannot be produced, because the POS only offers **Full Return**. The drill-down lists **2** rows (RTN-16 and RTN-15) against a count of 1; see POS-D04. |
| 070 | PASS | Invoices Today shows only Total, Fully Paid, and Fully Refunded. Partially Paid, Unpaid, and Partially Refunded are not shown. |
| 071 | PARTIAL | WO-94, created today and voided, counts under Voided. WO-93, created today as pending and later completed, moved from Pending to Completed. Not available: a WO created yesterday and completed today (all 12/11 WOs were already closed). |
| 072 | PASS | Overview (366 / 0 Low / 13 Out / 6 Negative) equals the Inventory tab (All 366, Low 0, Out 13, Negative 6). The two places use the same counting basis. |
| 073 | PARTIAL | Case A: with 3 items sold, the list shows exactly 3 rows (Tire - Item 500, RService 100, Car Wash 100) and no placeholder rows. Case B: with no sales, the card is **blank** with no "no data" message and **View All is hidden**. The case expected View All to remain available, so this needs product confirmation. |
| 074 | PASS | Cash Sales Balance **400.00** (300 cash part of split INV-79 + 100 INV-81). Cash Refunds Balance **93.50** (R-1 + R-2, both cash). Expected 100 + 400 − 93.50 = **406.50** on both Cash and Overview. |
| 075 | **BLOCKED** | The New Cash Deposit form takes its amount from **Select Days +**, and the list offered **no days** for the open session. A deposit could not be created, so its effect on Expected Cash could not be verified. An older deposit TO_11000002 in status "New" (344.80, 29/10) exists. |
| 076 | **FAIL** (Run 4) | After every transaction, returning to the dashboard showed updated KPIs, chart, Top Selling, and lists without signing in again. Updates were seen on navigation; an automatic refresh while idle on the screen was not observed. On 2026-11-14 product confirmed the dashboard must refresh automatically while open, so the case needs a dedicated idle test (dashboard left open while data changes). |
| 077 | PASS | Executive Daily Sales 749.00 = Overview KPI = Sales tab Total. Executive Daily Net Sales 677.39 = Sales tab Total Net Sales. RService (0% VAT) adds no VAT. |
| 078 | PASS | Ranges: 12/11–12/11 = 3,540.96, 5 invoices, All 7. 13/11–13/11 = 749.00, 3 invoices, All 5. **12/11–13/11 = 4,289.96, 8 invoices, Refunds 393.50, All 12**, exactly the sum, so both ends are inclusive. Documents at 00:05 or 23:55 could not be created. Observation O-9. |
| 079 | PASS | Export and grid: INV-79 Items **3**, Method **"Cash + Mada"**. INV-80 Items 1. RTN-16 shows the return number, amount −42.50, and method Cash. From Run 1: INV-77 (Car Wash ×2) shows Items 1, so the column counts lines rather than quantity. |
| 080 | **FAIL** (clarify) | Searching "Master" lists only INV-80, but **tab counts stay All (5) / Refunds (2) / Invoices (3)** and the KPIs are unchanged. The tab counts do not match the listed records. Clearing the search restores the list. Evidence `d2_search_counts`. |
| 081 | **FAIL** | Sales export columns match the grid **except that ZATCA Rejection Reason is missing** (POS-D01). The WO export columns (WO No, Date, Customer, Plate, Bay, Amount, Status) match the grid. Exporting an empty list shows **"No data available to export."** with no file and no error. The export respects an active search (1 row while "Master" was searched). |
| 082 | PASS | Refunds-only day: Total Sales **−51.00**, Net −44.35, Invoices 0, Avg Invoice 0.00, Refunds 51.00, Return Rate **0.0%**, tabs All 1 / Refunds 1 / Invoices 0. Total Sales is shown as a negative value (clarification 20). On Overview, Output VAT is −6.65 and the label changes to "Net VAT Recoverable". See POS-I03 for Gross Profit. |
| 083 | PASS | WO Info on the empty day: every count is 0, rates are 0.0%, tabs are 0, and there is no error. |
| 084 | PASS | The **Complete** action on pending WO-93 opens it in the POS cart. After paying (INV-81), WO Info shows Pending 0, Completed 3 (75.0%), Voided 1 (25.0%), and no Complete action remains. Overview and Sales updated. |
| 085 | PASS | Cash Sales % **40.9%** = net cash 306.50 / net total 749.00. Other Payments % **59.1%** = 442.50 / 749.00. They sum to 100%. The empty day shows 0% / 0%. The percentages use **net** (after refunds) values. |
| 086 | PASS | The default is Daily (13/11–13/11). MTD 01/11, QTD 01/10, and YTD 01/01, each to 13/11. From 13/11 > To 12/11 shows "From Date must be on or before To Date." The register block keeps the active session. |
| 087 | PARTIAL | The Item Group fixtures QA_IG Tire Product 02 (**Draft**) and 03 (**Cancelled**) are absent from the Inventory grid and search, while 01 (active) is listed. No inactive item with stock was available, so the effect on Stock Value and counts was not verified. |

Additional evidence for existing items: today's sale took Tire - Item in Branch-2 from −1 to **−2**, and Stock Value stayed **6,710.00** (POS-I01). Top Selling still shows Car Wash Qty 2 / 200 after one Car Wash was returned (O-1).

## Run 3 — 2026-11-13 (follow-ups after product answers)

These follow-ups use the product answers recorded in [US-214_POS_Dashboard_Test_Cases.md](./US-214_POS_Dashboard_Test_Cases.md#product-answers-affecting-execution-2026-11-13). The business-rule questions are still awaiting confirmation.

### Data created

| Document | Content | Result |
|---|---|---|
| PR-TO_11000002 (Purchase Invoice) | Default Supplier → Branch-2. Air Filter 012 ×1 Box at 100.00 + VAT 15.00 = 115.00. Saved first as **Draft** (status New), then **Submitted**. | Submitted |
| Return Purchase Invoice | Default Supplier, Branch-2, ref "PR - TO_11000002". Air Filter 012 ×1 at 100.00 + VAT 15.00. The default line price was the sales price (1,094.56) and was edited to 100. | Submitted. The return list then showed "0 Voucher" (O-13). |
| ST Adjustment - TO_11000005 | Stock In, Branch-2: Tire - Item +12 (−2 → **10**, Min 10) and Engine Oil 5W-40 1L +2 (0 → **2**, Min 3). Adjustment value 861.40. | Submitted |
| Cash Deposit TO_11000003 | Collector m.alshellah, bank "test", slip QA075, day **9/11** (200.00). Saved as **New** (draft), then Submitted. | Submitted |
| WO-TO_11000095 | Car Wash 100. **Partial cash payment 50** confirmed, then the WO was voided. | Voided |
| WO-TO_11000096 | RService 100 on BMW 1111AAA, left **Pending** for TC-071 (to be completed on 14/11). | Pending |
| Item **Air Filter 039** (NEW-ITEM-0039, portal) | Toolbar **Cancel** → Document Status **Cancelled**. It holds 50 units in Branch Store. | Cancelled (still Cancelled in QA) |

### Results

| TC | Result | Evidence / observation |
|---|---|---|
| 003 | N/A | QA uses a single admin user with all permissions (product answer). |
| 004 | BLOCKED | Each branch has one terminal, so terminal isolation is N/A. Branch isolation still needs a user assigned to a second branch. |
| 007 | PASS | Product confirmed that POS sales and returns are submitted directly, so draft, cancelled, and deleted documents cannot exist. Voided WOs (WO-89, WO-94, WO-95) never affected Daily Sales or invoice counts. |
| 009 / 010 | SCHEDULED | Need a full day with no sales (e.g. no sales on 14/11), then check on the following day: 010 before any sale, 009 after the first sale. |
| 019 | PASS | After the adjustment, Overview shows **2 Low stock**, 13 Out of stock, and **5 Negative** (Tire left Negative; Engine Oil left Out of Stock; the Air Filter 012 Branch-2 row became 0). |
| 023 | PASS | Electronic refunds are N/A (Cash-only rule). Electronic sales never changed Expected Cash. |
| 024 | PASS | The new session started with Expected Cash = opening 100. A **draft** deposit (TO_11000003, status New) and then the **submitted** deposit for a past day (9/11) both left the current session's Expected Cash at **406.50**. |
| 028 | PARTIAL | **Cancelled payment:** WO-95's confirmed partial cash payment of 50 was excluded after the WO was voided. Cash chart (306.50), Expected Cash (406.50), and TRANSACTIONS NO (4) were unchanged, and voided WOs went 1 → 2. Failed payments cannot be produced. The chart lists Visa and Hala, while the POS payment screen offers Hala, Credit Card, Cash, Mada Pay, and Master. |
| 029 | **FAIL** | See POS-D06. |
| 030 | N/A | No screen shows Inventory Value by date (product answer). |
| 035 | PASS | **Draft** PR-TO_11000002 left Input VAT at **0.00**. After Submit, Input VAT = **15.00**. After the purchase return (VAT 15.00), Input VAT = **0.00**, so purchase-return VAT is deducted. |
| 036 | PASS | Net VAT Payable = Output − Input: 71.61 − 15.00 = **56.61** after the purchase, and 71.61 after the purchase return. |
| 044 | PASS | Each invoice is counted once (split INV-77 and INV-79). Draft, cancelled, and deleted invoices are N/A (direct submit). |
| 046 | PASS | The return date governs (RTN-15 for the 1/11 invoice is counted on 13/11). Draft and rejected returns are N/A (direct submit). |
| 062 | **FAIL** | Stock Value follows the inconsistent calculation in POS-D06. In Stock count = 357 item × store rows (see TC-064). |
| 063 | PASS | Inventory → Low Stock (2) lists **Tire - Item, Branch-2, 10 / Min 10 → Low Stock** (boundary = minimum) and **Engine Oil 5W-40 1L, Branch-2, 2 / Min 3 → Low Stock**. 0 → Out of Stock and < 0 → Negative were verified earlier. |
| 064 | INVESTIGATE (explained) | All stayed **366** while category rows changed (Air Filter 012 gained a 0-qty row in Branch-2; Engine Oil moved from Out of Stock to Low Stock). **All counts distinct items, while the category tabs count item × store rows**, which is why they sum to 376. Under "count distinct active items", the categories are wrong (business question 18). |
| 069 | PASS | Only full returns are supported. Fully Refunded = 1 (today's INV-80); the return of the 1/11 invoice is not counted. The drill-down list mismatch is tracked in POS-D04. |
| 071 | SCHEDULED | WO-TO_11000096 created and left Pending on 13/11, to be completed on 14/11. Expected: it is not counted in 14/11's Total Work Orders. |
| 075 | PARTIAL / clarify | "Select Days +" lists days only after a **Cash Collector** is chosen, and only **past days up to 10/11** (11/11, 12/11, and the open 13/11 session are not offered). A deposit therefore cannot be taken from the open session, and the "− Cash Deposits" term of Expected Cash cannot be exercised. Deposits for past days correctly leave the current session's Expected Cash unchanged. |
| 087 | PASS (after Sync) | After **Air Filter 039** (50 units, Branch Store) was cancelled in the portal, the POS kept showing it until data was synced (Menu → System & Devices → **Sync**). After the sync, the item is no longer listed or searchable, and counts dropped to **All 365 / In Stock 356** on both the Inventory tab and Overview. The control item Air Filter 012 is still listed. Stock Value stayed 25,069.90, so the cancelled item contributed 0 to the value (see POS-D06). Portal changes reach the POS only after Sync. |

### Inventory Value trace (basis for POS-D06)

| Step | Inventory Value | Change | Explanation from item rows |
|---|---|---|---|
| Start of 13/11 | 6,710.00 | — | — |
| Sale of Tire from Branch-2 (−1 → −2) | 6,710.00 | 0 | Negative rows are not valued. |
| Purchase 1 Air Filter 012 at 100 (Branch-2) | 8,810.00 | +2,100 | 21 units (20 Branch Store + 1 Branch-2) × new cost 100. Branch Store stock is revalued at the new cost. |
| Purchase return 1 Air Filter 012 | 8,710.00 | −100 | 20 × 100. |
| Stock In: Tire +12 (−2 → 10), Engine Oil +2 (0 → 2) | **25,069.90** | **+16,359.90** | Tire 10 × 55 = 550, plus **Engine Oil 157 × 100.70 = 15,809.90**. The **155 Engine Oil units in Branch Store were not counted** before Branch-2 went from 0 to 2. |
| 12/11 (Run 1) | 4,840 → 6,710 | +1,870 | = Tire **34 units in Branch Store × 55**, which became counted when Tire in Branch-2 moved from 0 to −1. |

## Run 4 — 2026-11-14 (retest after product answers)

| # | Check | Steps | Result |
|---|---|---|---|
| 1 | TC-076, automatic refresh | The dashboard was left open on WO Info with no input. The KPIs and the header clock were read at 21:40:33 and again at 21:43:04. Then the Overview tab was opened at 21:43:19. | **FAIL.** Nothing changed while idle. The header clock still showed **09:18 PM** at 21:43 (system clock), so the screen had not refreshed for about 25 minutes, and switching to Overview did not update it either. Evidence `rt_00_state`, `rt_076_idle_wo_after150s`, `rt_076_overview_tab`. Defect POS-D09. |
| 2 | Item without Min Qty (product answer 2) | Inventory tab, All and Low Stock lists. | **PASS.** Items with positive stock and Min Qty "--" show **In Stock**, for example FRONT BRAKE ROTORS (Branch Store, 300) and Air Filter 012 (Branch Store, 20). Low Stock (1) lists only Tire - Item (Branch-2, 10, Min 10), which has a Min Qty. Evidence `rt_inv_00`, `rt_inv_lowstock`. |
| 3 | TC-064, category counts | Inventory tab counts. | Still **INVESTIGATE**, waiting for the product decision (counting per item or per item × store). Current values: All 365, In Stock 356, Low 1, Out 13, Negative 8, so the categories sum to 378. |

Other things seen on 14/11 (from the integration work, see docs/integration): Top Selling shows QA_INT Package Sum 1114 with Qty 51 and QA_INT Package 1114 with Qty 84. These come from the package quantity defect (integration finding 6.14). The payment chart lists **Visa 799.99**, although the POS payment screen offers no Visa method (see TC-028).

## Defects

| ID | TC | Severity | Summary |
|---|---|---|---|
| POS-D01 | 049, 081 | Medium | The Sales transactions grid and CSV export have no **ZATCA Rejection Reason** column. |
| POS-D02 | 060 | Medium | The Cash tab's Current Cash Register has no **Cash Deposit** button. The screen is reachable only from the side menu. |
| ~~POS-D03~~ | 014 | — | **Withdrawn 2026-11-14.** Opening Sales **All** from "Invoices Today" is accepted by product. |
| POS-D04 ([Bug 1973](https://devops2.minerets.com/DefaultCollection/Shop/_workitems/edit/1973)) | 016, 069 | Low / clarify | Overview "Fully Refunded" lists return documents instead of the fully refunded invoices. It also includes returns of older invoices: the count was 1 but the list had 2 rows on 13/11. |
| POS-D05 ([Bug 1974](https://devops2.minerets.com/DefaultCollection/Shop/_workitems/edit/1974)) | 080 | Low / clarify | With a search active, the Sales tab counts (All / Refunds / Invoices) and the KPIs do not follow the filtered list. |
| POS-D06 | 029, 062 | **High** | **Inventory Value is calculated inconsistently.** The branch has 2 stores (Branch Store and Branch-2), so the expected value is Σ (qty × unit cost) across **both** stores at all times. An item's stock in other stores (Branch Store) is left out while its row in Branch-2 is 0, and is suddenly added when that row changes. A Stock In of 2 Engine Oil (value 201.40) raised Inventory Value by **15,809.90** (157 × 100.70), and a Tire sale on 12/11 raised it by 1,870 (34 × 55). Negative rows are ignored. A new purchase cost also revalues all existing stock of the item. Air Filter 039 (50 units in Branch Store) was never included: Stock Value did not change when it was removed. Replaces POS-I01. |
| ~~POS-D07~~ | 087 | — | **Withdrawn.** The cancelled item disappears after the POS data **Sync** (System & Devices → Sync). This is expected behaviour, not a defect. |
| POS-D08 | 041, 078 | Low | In the date picker, clicking the date that is already selected clears the field. Pressing Apply with the empty date shows no validation and silently keeps the previous data. Product confirmed on 2026-11-14 that this is not acceptable (was O-9). |
| POS-D09 | 076 | Medium | The dashboard does not refresh automatically while it is open. Product requires automatic refresh. During the idle test the KPIs did not change, and the header clock stayed at the time the screen was opened: 09:18 PM while the system time was 21:43. Switching tabs did not update the clock either. |

## Items to investigate

| ID | TC | Summary |
|---|---|---|
| POS-I01 | 029 / 062 | **Superseded by POS-D06.** |
| POS-I02 | 064 | **Explained:** All counts distinct items; category tabs count item × store rows, which is why they sum to 376 vs 366. Product to confirm the intended basis (business question 18). |
| POS-I03 | 031 / 082 | On the refunds-only day, Gross Profit showed **0.00** while Net Sales was −44.35. Once sales existed, GP = Net − COGS held exactly, and the returned item contributed no COGS. Expected −44.35, so this may be clamping at zero. |

## Observations (no pass/fail; need product decision)

- **O-1:** Top Selling (Today) does not deduct returns. Car Wash still shows Qty 3 / 300 after 2 were returned. RService shows Qty 1 / 100 although fully returned (clarification item 7).
- **O-2:** The POS allows selling from a store with zero stock (Tire - Item, Branch-2 went 0 → −1).
- **O-3 (confirmed business rule, 2026-11-13):** Refunds are currently **Cash only**, whatever the original payment method. This is intended behavior, not a defect. Electronic refunds (the Mada/Visa refund parts of TC-023 and TC-027) are out of scope until the rule changes. A refund also needs enough cash in the drawer (O-8).
- **O-4:** Return Rate uses gross sales before discount as the denominator (3,798.46), not net sales. Confirm this is intended.
- **O-5:** Voided WO-TO_11000089 shows an amount of 100.00 in the WO list and export. Older voided WOs show 0.00.
- **O-6:** Future dates (13/11) are accepted in the Sales range and return zero data without a warning.
- **O-7:** WO-TO_11000090 (left Pending for TC-017/018/056) was later completed outside the scripted run. The Overview then showed 0 Pending / 5 Completed, 5 invoices, and Daily Sales 3,540.96, all consistent with a +100 electronic sale. Its invoice is INV-TO_11000078.
- **O-8:** A cash refund is blocked when the drawer holds less than the refund amount ("The Cash balance is not enough to refund this invoice."). The story does not mention this rule, but it is consistent with the Expected Cash logic.
- **O-9 (now defect POS-D08):** In the date picker, clicking the date that is already selected clears the field ("select a date"). Pressing Apply with an empty date shows no validation and silently keeps the previous data.
- **O-10:** Top Selling on a day with no sales shows a blank card (no "no data" message) and hides View All.
- **O-11:** Cash Deposit amounts can only be built from "Select Days", and no day was offered for the open session (TC-075).
- **O-13:** After a Return Purchase Invoice was submitted, its list showed "0 Voucher", although Input VAT and Inventory Value reflected the return. The return line also defaulted to the item's **sales** price (1,094.56) instead of the purchase cost and had to be edited.
- **O-14:** Voiding a WO after a confirmed partial cash payment (WO-95, 50.00) gave no prompt to refund the customer. The 50 disappears from Expected Cash although it was physically collected.
- **O-15:** Cash Deposit days appear only after a Cash Collector is selected. Only past days up to 10/11 are offered (not 11/11, 12/11, or the open session).
- **O-12:** Cash Sales % and Other Payments % use net (after refund) amounts. Return Rate uses gross sales before discount (900.00 on 13/11, giving 10.4%), as in O-4.

## Evidence

Screenshots and exports are in [evidence/](./evidence/), split into four folders:

| Folder | Contents |
|---|---|
| [run1-2026-11-12/](./evidence/run1-2026-11-12/) | Run 1 screenshots |
| [run2-2026-11-13/](./evidence/run2-2026-11-13/) | Run 2 and Run 3 screenshots (`d2_*`, `portal_item*`) |
| [bugs/](./evidence/bugs/) | Annotated screenshots used in DevOps bugs (`D04_*`, `D05_*`) |
| [exports/](./evidence/exports/) | CSV exports from the dashboard, plus the portal Inventory Balance reports |

Files by area:

- **Transactions:** `wo_cart1`, `wo_discount`, `pay_done`, `split_after`, `void_done`, `ret_ready`, `ret_confirmed`, `ret_done_11000077`.
- **Overview:** `overview_after`, `ov_after_ret2`, `stockadj_state` (after WO-D completion).
- **Drill-downs:** `drill_sales`, `drill_refunds`, `drill_invoices`, `drill_paid`, `drill_refunded`, `drill_refunded2`, `drill_wo_pending`, `drill_wo_completed`, `drill_wo_voided`, `drill_wo_total`, `drill_low`, `drill_out`, `drill_neg`, `drill_invtotal`, `drill_topsell`.
- **Sales:** `sales_daily`, `sales_custom`, `sales_zero`, `export1`, `sales_after_ret2`, and `Transactions_20261112_*.csv`.
- **WO Info:** `wo_daily`, `woinfo_mtd`, and `WorkOrders_20261112_144603.csv`.
- **Cash:** `cash_tab`, `cash_tab_bottom`, `cash_after_ret2`.
- **Inventory and menu:** `inv_tab`, `menu_all`, `stockadj_new`.
- **Run 2 (13/11):**
  - Empty day and returns: `d2_overview_start`, `d2_empty_wo`, `d2_export_empty`, `d2_ret_cashlimit`, `d2_ret38_done`, `d2_sales_refundonly`, `d2_ov_refundonly`.
  - Sales and work orders: `d2_ov_s1`, `d2_disc_applied`, `d2_pay_master`, `d2_void_confirm`, `d2_wo_after`, `d2_complete_click`, `d2_wo_after_complete`, `d2_ov_after_ret`, `d2_drill_fullyrefunded`.
  - Deposit, search, Cash, and date ranges: `d2_deposit_days`, `d2_search_counts`, `d2_cash`, `d2_cash_invalid`, `d2_empty_to`, `d2_range_12_13`.
  - Inventory: `d2_inv`, `d2_inv_tire`, `d2_inv_qaig`.
  - Exports: `Transactions_20261113_*.csv`.
- **Run 3 (13/11 evening):**
  - Purchase and VAT: `d2_pi_review`, `d2_exec_draft_pi`, `d2_pi_submitted`, `d2_exec_pi`, `d2_prt_review`, `d2_exec_prt`.
  - Stock adjustment and inventory: `d2_sa_tire12`, `d2_sa_review`, `d2_ov_lowstock`, `d2_drill_lowstock`, `d2_inv_after_sa`.
  - Cash deposit: `d2_dep_days2`, `d2_dep_days_end`, `d2_dep_ticked`, `d2_dep_submitted`.
  - Work orders: `d2_partial50`, `d2_void95`, `d2_wo_pending_tomorrow`.
  - Item cancellation: `d2_087_before`, `d2_087_after`, `portal_item`, `portal_item_after`.

## Run 5: Retest of Resolved bugs (2026-11-19, build 1.2.498)

| Bug | Steps | Result |
|---|---|---|
| 2110 (POS-D09) | Dashboard left idle 130 s (14:34:41 to 14:37:03). | **PASS (clock).** Header clock moved 02:34 to 02:37 on its own. KPI auto refresh while open verified by the user. Retest comment posted on DevOps. |
| 1974 (POS-D05) | Sales tab, Daily, search "Ammar" (also pressed Enter). | **PASS (as designed).** List shows 1 row while tabs and cards stay unchanged. The bug's System Info records the agreement with Banan and Ahmad Alsoub: tab numbers and cards are independent of the search and stay unchanged. |
| 1973 (POS-D04) | Full return of today's INV-TO_11000127 (RTN-TO_11000017, 100) and of 26/10 INV-TO_11000009 (RTN-TO_11000018, 24.90). Overview, Fully Refunded. | **PASS.** Count and list now match (2 and 2). Business rule confirmed by the user on 2026-11-19: Fully Refunded counts every invoice that had a return made today, whatever the invoice date. Fully Paid staying 4 (INV-127 counted in both) is accepted by the user. |

Evidence: [run5-2026-11-19/](./evidence/run5-2026-11-19/).
