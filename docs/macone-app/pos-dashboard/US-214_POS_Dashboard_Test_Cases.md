# MAC One POS Dashboard — Test Cases

## Document purpose

This is the working manual test-case set for the complete POS Dashboard story supplied on 2026-11-11. It is intentionally kept separate from Gemini-generated plans so it can be reused and updated later.

- **Target:** MAC One desktop application, QA environment.
- **Scope:** Overview, Sales, WO Info, Cash, Inventory, and their stated calculations, filters, lists, search, and export behavior.
- **Execution status:** TC-POS-001 to 066 were executed on QA on 2026-11-12. Results are in [US-214_POS_Dashboard_Execution_Report_Run1_2026-11-12.md](./US-214_POS_Dashboard_Execution_Report_Run1_2026-11-12.md). TC-POS-067 to 087 were added on 2026-11-13 after a coverage review against the full story and were executed the same day (Run 2 in the same report). The cases themselves remain specifications.
- **Azure DevOps:** All 87 cases were created on 2026-11-13 as Test Case work items in plan **1882 "MAC1 - POS"**, suite **1885 "214 : myShop POS - Company Dashboard"** (Tested By → User Story 214). Work item IDs are 1886–1972; [POS_Dashboard_AzureDevOps_Map.csv](./POS_Dashboard_AzureDevOps_Map.csv) maps each case to its ID. Edits made in this file are **not** synced automatically.
- **Data safety:** Use QA data only. Do not execute destructive actions. Where a case refers to a status or a transaction, prepare the data through approved QA setup or use existing fixtures.
- **Business date:** Use the branch's current business date unless the case explicitly selects a different range.

## Product answers affecting execution (2026-11-13)

| Topic | Answer | Effect on cases |
|---|---|---|
| Permissions | QA currently uses one admin user with all permissions. | TC-POS-003 is not applicable until a restricted user exists. |
| Terminals | Each branch works on a single terminal. | Terminal isolation in TC-POS-004 is not applicable. Branch isolation still needs a second-branch user. |
| "New Sales" / 0% growth | Wait for a full day with no sales, then test the following day. | TC-POS-009 and 010 are scheduled, not blocked. |
| Inventory Value by date | No screen shows Inventory Value by date. | TC-POS-030 is not applicable. |
| Purchases | Purchase Invoice and Return Purchase Invoice exist in the POS menu (Operations). | TC-POS-035 and 036 are executable. |
| Sales invoices and returns | Both are submitted directly; no draft, cancelled, or rejected state exists in the POS. | The draft/cancelled/deleted/rejected parts of TC-POS-007, 044, and 046 are not applicable. |
| Partial returns | Not supported; only Full Return. | TC-POS-069 covers full returns only. |
| Refund method | Cash only (business rule). | The electronic-refund parts of TC-POS-023 and 027 are not applicable. |
| Item deactivation | Done from the portal. The Item **Cancel** action sets Document Status to Cancelled. | Used for TC-POS-087. |
| Stores per branch | The branch (Alshellah) has **2 stores**: *Mohammad store - Branch Store* and *Mohammad Store Branch - 2*, each with its own items. The dashboard Inventory covers both stores of the branch. | Inventory counts, classification, and Stock Value are branch-level, across both stores. Resolves clarification 16. |
| Portal → POS data | Portal changes reach the POS only after a data **Sync** (Menu → System & Devices → Sync). | Any case that changes data in the portal must sync before checking the dashboard. |

## Product answers (2026-11-14)

| # | Topic | Answer | Effect on cases |
|---|---|---|---|
| 1 | "Invoices Today" destination | Opening the Sales **All** list is accepted. Other entry points open the invoice list and the return list. | TC-POS-014 passes. Defect POS-D03 withdrawn. |
| 2 | Item without a Min Qty | Classification follows the definition in the Store form. An item with positive stock and no Min Qty is **In Stock**. | Resolves clarification 15. Check this in the next Inventory run (TC-POS-019, 063, 064). |
| 3 | "In progress" and "Pending" | They are the same status. | Resolves clarification 4. |
| 4 | Unpaid and partially paid invoices | Not supported at present. | Resolves clarification 2. The unpaid parts of TC-POS-006 and 013 are not applicable. |
| 5 | Dashboard refresh | The dashboard must refresh **automatically** while it is open. | Resolves clarification 21. TC-POS-076 needs an idle refresh test. |
| 6 | Date picker clearing the selected date | Not acceptable. | Observation O-9 becomes defect POS-D08. |

Already logged as bugs, so no answer is needed: Fully Refunded list (Bug 1973) and Sales search counts (Bug 1974).

Still open, no product decision yet: Inventory Value (negative stock and unit cost method), category counts per item or per item × store (clarification 16), Gross Profit and Total Sales in a refunds-only period (clarification 20), Return Rate denominator, Cash Sales % basis, Top Selling returns and empty state, and voided WO amount (clarification 19).

## Shared preconditions

1. A QA user can sign in to MAC One and open the POS Dashboard.
2. The QA environment contains (or can safely prepare) confirmed and non-confirmed sales invoices, sales returns, payment records, work orders in each supported status, inventory items with known stock/cost, and cash-register sessions.
3. Test fixtures use a known branch, store, terminal, and working session. Record their identifiers before execution.
4. Unless a case states otherwise, compare displayed amounts in the configured currency and use the application's documented rounding precision.
5. Any expected record counts are based on the exact prepared data set, not unrelated existing QA records.

## Test cases

### Navigation, scope, and Overview

#### TC-POS-001 — Open Overview by default
- **Category:** Positive
- **Preconditions/data:** Authorized POS user; dashboard is not already open.
- **Steps:** 1. Open the POS Dashboard. 2. Observe the selected tab and initial dashboard content.
- **Expected:** Overview is selected by default and its dashboard components load without requiring navigation to another tab.

#### TC-POS-002 — Navigate among all dashboard tabs
- **Category:** Positive
- **Preconditions/data:** User is authorized to see all five tabs.
- **Steps:** 1. Open each tab in turn: Overview, Sales, WO Info, Cash, Inventory. 2. Observe the selected state and the content for each tab.
- **Expected:** Each named tab is reachable and shows its relevant KPIs, chart, list, or summary. Selecting one tab does not open an unrelated screen.

#### TC-POS-003 — Respect dashboard permissions
- **Category:** Negative / permissions
- **Preconditions/data:** Two QA accounts with different dashboard or detail-screen permissions, if available.
- **Steps:** 1. Sign in with the more restricted account. 2. Open the dashboard and try to open a component whose detail screen is not permitted. 3. Repeat with an account that has the required permission.
- **Expected:** Dashboard information and drill-down actions respect the signed-in user's permissions; restricted details are not exposed or opened. The story does not define the exact denial message.

#### TC-POS-004 — Scope dashboard data to assigned branch, terminal, and session
- **Category:** Positive / data isolation
- **Preconditions/data:** Two branches or stores, two terminals/sessions, and distinct known records for each.
- **Steps:** 1. Sign in with a user assigned to branch/store A and terminal/session A. 2. Record dashboard values. 3. Repeat with a user assigned to branch/store B and terminal/session B.
- **Expected:** Each view reflects the logged-in user's assigned branch/store, terminal, and active working session; records from the other context do not leak into scoped figures.

#### TC-POS-005 — Calculate Overview Daily Sales with discount and returns
- **Category:** Positive / calculation
- **Preconditions/data:** For the current business date, confirmed gross sales = 1,500 JOD, discounts = 100 JOD, confirmed returns = 200 JOD.
- **Steps:** 1. Open Overview. 2. Read Daily Sales and Refund Amount.
- **Expected:** Daily Sales is 1,200 JOD using confirmed sales less discounts and returns; Refund Amount reflects the confirmed returns total (200 JOD). Apply the story's tax-inclusion rule to the prepared invoice values.

#### TC-POS-006 — Include confirmed sales regardless of payment method or collection
- **Category:** Positive
- **Preconditions/data:** Confirmed invoices paid by Cash, Mada, Visa, MasterCard, configured alternative methods, Credit, and unpaid/partially paid examples. Include a 200 JOD confirmed credit invoice with no collection.
- **Steps:** 1. Open Overview for the business date. 2. Compare Daily Sales with the sum of eligible invoice values, discounts, and returns.
- **Expected:** Confirmed invoice value contributes once irrespective of payment method or amount collected; the 200 JOD credit invoice contributes 200 JOD. Sales are not calculated from payment collections.

#### TC-POS-007 — Exclude ineligible documents from Overview Daily Sales
- **Category:** Negative
- **Preconditions/data:** Same-date draft, cancelled, deleted, and confirmed sales/return documents with distinguishable amounts.
- **Steps:** 1. Record the expected total from confirmed eligible documents only. 2. Open Overview and read Daily Sales and Refund Amount.
- **Expected:** Draft, cancelled, and deleted documents do not affect sales or refund figures.

#### TC-POS-008 — Calculate Overview sales growth for non-zero yesterday sales
- **Category:** Positive / calculation
- **Preconditions/data:** Today's net sales = 1,200 JOD; yesterday's net sales = 1,000 JOD.
- **Steps:** 1. Open Overview. 2. Read the sales growth percentage.
- **Expected:** Growth is 20%, calculated as ((1,200 - 1,000) / 1,000) × 100.

#### TC-POS-009 — Show New Sales when yesterday is zero and today is positive
- **Category:** Boundary
- **Preconditions/data:** Yesterday's eligible sales = 0; today's eligible net sales > 0.
- **Steps:** 1. Open Overview. 2. Read the sales growth indicator.
- **Expected:** The indicator displays “New Sales”, not an error, infinity, or a division-by-zero result.

#### TC-POS-010 — Show zero growth when both days have zero sales
- **Category:** Boundary
- **Preconditions/data:** Yesterday's and today's eligible sales both equal zero.
- **Steps:** 1. Open Overview. 2. Read the sales growth indicator.
- **Expected:** The indicator displays 0%.

#### TC-POS-011 — Open Daily Sales report filtered to the business date
- **Category:** Positive / navigation
- **Preconditions/data:** Current business date has eligible invoices.
- **Steps:** 1. Click the Overview Daily Sales KPI or its View Details action. 2. Inspect the opened report's date filter and records.
- **Expected:** The Daily Sales Report opens with the **All** category selected, filtered to the current business date, and corresponds to eligible sales.

#### TC-POS-012 — Open Sales Return List filtered to the business date
- **Category:** Positive / navigation
- **Preconditions/data:** Current business date has a confirmed sales return.
- **Steps:** 1. Click the Overview Sales Returns/Refund Amount action. 2. Inspect the opened list's date filter.
- **Expected:** The Sales Return List opens with the **Refunds** category selected and the current business date applied.

#### TC-POS-013 — Count today's confirmed invoices and fully paid invoices
- **Category:** Positive / calculation
- **Preconditions/data:** Current-day confirmed invoices include two with Outstanding Amount = 0 and one with Outstanding Amount > 0; also prepare draft, cancelled, and deleted invoices.
- **Steps:** 1. Open Overview. 2. Read Total Invoices and Fully Paid.
- **Expected:** Total counts confirmed eligible invoices only; Fully Paid counts invoices with Outstanding Amount = 0. Draft, cancelled, and deleted invoices are excluded. Partially paid/unpaid KPI behavior is out of scope where marked not supported.

#### TC-POS-014 — Open the total invoice list from Overview
- **Category:** Positive / navigation
- **Preconditions/data:** Current business date has confirmed invoices.
- **Steps:** 1. Click Total Invoices on Overview. 2. Inspect the destination list and its records.
- **Expected:** Invoice List opens and shows the eligible invoices represented by the KPI. Product answer (2026-11-14): opening the Sales **All** list here is accepted.

#### TC-POS-015 — Open fully paid invoices from Overview
- **Category:** Positive / navigation
- **Preconditions/data:** At least one confirmed fully paid invoice exists today.
- **Steps:** 1. Click Fully Paid on the Overview invoice KPI. 2. Inspect the opened list.
- **Expected:** The resulting list contains fully paid invoices (Outstanding Amount = 0) and excludes invoices that are not fully paid.

#### TC-POS-016 — Open fully refunded invoices from Overview
- **Category:** Positive / navigation
- **Preconditions/data:** Prepare one invoice whose return value equals its paid amount and one that does not.
- **Steps:** 1. Click Fully Refunded on the Overview invoice KPI. 2. Inspect the resulting records.
- **Expected:** The list is filtered to invoices whose return value equals invoice paid amount. The story mentions this action but does not clearly specify a separate Fully Refunded KPI count.

#### TC-POS-017 — Count today's Work Orders by current status
- **Category:** Positive / calculation
- **Preconditions/data:** Today's eligible work orders include 2 Pending, 2 Completed, and 0 Voided (or use a fixture set with known counts).
- **Steps:** 1. Open Overview. 2. Read Total Work Orders, Pending, Completed, and Voided.
- **Expected:** Counts match work orders created during the current business day, classified by current status; total equals the sum of status counts.

#### TC-POS-018 — Open each Overview Work Order status list
- **Category:** Positive / navigation
- **Preconditions/data:** At least one pending and completed work order exists; voided records may be included if supported.
- **Steps:** 1. Click Pending, Completed, Voided, and Total in turn. 2. Inspect each destination and filters.
- **Expected:** Each action opens the corresponding status-filtered list; Total opens all eligible work orders created today.

#### TC-POS-019 — Classify Overview inventory stock states
- **Category:** Positive / boundary
- **Preconditions/data:** Selected store contains an item with positive stock below minimum, an item at zero, an item below zero, and a normal in-stock item.
- **Steps:** 1. Open Overview. 2. Read Total Inventory Items, Low Stock, Out of Stock, and Negative Stock.
- **Expected:** Items are classified into the correct stock buckets for the selected branch/store; total and category counts match the fixture data.

#### TC-POS-020 — Open Overview inventory detail lists
- **Category:** Positive / navigation
- **Preconditions/data:** Selected store has low-stock, zero-stock, negative-stock, and other items.
- **Steps:** 1. Click Low Stock, Out of Stock, Negative Stock, and Total in turn. 2. Inspect each list.
- **Expected:** Each action opens the corresponding item list, filtered to the selected store and requested stock category.

#### TC-POS-021 — Display the current cash-register and session details on Overview
- **Category:** Positive
- **Preconditions/data:** An active working session has known open day number, opener, opening date/time, and opening cash.
- **Steps:** 1. Open Overview. 2. Inspect the cash-register section.
- **Expected:** Open Day Number, Opened By, Opening Date and Time, Opening Cash Balance, and Expected Cash Balance correspond to the active register/session.

#### TC-POS-022 — Calculate expected cash for opening cash, cash sales, and cash refund
- **Category:** Positive / calculation
- **Preconditions/data:** Opening cash = 100 JOD; cash sales = 300 JOD; cash refund = 50 JOD. Original invoice for the refund was paid electronically.
- **Steps:** 1. Open Overview. 2. Read Expected Cash Balance.
- **Expected:** Expected cash is 350 JOD (100 + 300 - 50). The electronic original payment does not change the drawer; the cash refund decreases it.

#### TC-POS-023 — Exclude electronic sales and electronic refunds from physical cash
- **Category:** Negative / calculation
- **Preconditions/data:** Active session includes Visa sales = 200 JOD, Mada sales = 150 JOD, and a Mada refund = 30 JOD, with no cash movement from these transactions.
- **Steps:** 1. Record expected cash before these transactions. 2. Open or refresh Overview.
- **Expected:** Visa and Mada sales and electronic refunds do not change Expected Cash Balance; the note that electronic payments are excluded from physical cash is present.

#### TC-POS-024 — Include only confirmed cash movements from the selected session
- **Category:** Negative / data isolation
- **Preconditions/data:** Selected session has known confirmed cash movements; also prepare an unconfirmed movement and a confirmed movement in another session.
- **Steps:** 1. Open Overview for the selected session. 2. Compare Expected Cash Balance with only confirmed movements in that session.
- **Expected:** Unconfirmed movements and movements associated with another session are excluded.

#### TC-POS-025 — Show the five top-selling products/services for today
- **Category:** Positive / calculation
- **Preconditions/data:** Today's sales include at least six products/services with known quantities and selling values.
- **Steps:** 1. Open Overview. 2. Inspect the Top Selling (Today) component.
- **Expected:** Exactly five top-selling products/services are shown, with Item Name, selling Quantity, and Total Selling Value corresponding to today's business data.

#### TC-POS-026 — Open the Today Top Selling Report
- **Category:** Positive / navigation
- **Preconditions/data:** Top-selling data exists for the current business date.
- **Steps:** 1. Click View All in Top Selling (Today). 2. Inspect the report's date and records.
- **Expected:** The Today Top Selling Report opens for the current business date and provides the full list behind the summarized component.

#### TC-POS-027 — Calculate payment-method distribution from actual confirmed collections
- **Category:** Positive / calculation
- **Preconditions/data:** Confirmed payment records include a split-paid transaction across Cash and Visa and a confirmed refund.
- **Steps:** 1. Open Overview. 2. Compare each chart segment with actual confirmed payment records, including the refund deduction.
- **Expected:** Split payments are allocated to their actual methods; confirmed refund values are deducted; chart totals and segments match eligible collection records.

#### TC-POS-028 — Exclude failed, cancelled, and inapplicable payment methods
- **Category:** Negative
- **Preconditions/data:** Payment data includes confirmed, failed, and cancelled records, plus a method not applicable to the selected branch/company.
- **Steps:** 1. Open Overview. 2. Inspect the payment-method chart and legend.
- **Expected:** Failed/cancelled payments and methods not applicable to the branch/company are excluded; applicable configured methods are shown dynamically.

#### TC-POS-067 — Show negative sales growth and a full drop to zero
- **Category:** Boundary / calculation
- **Preconditions/data:** Case A: today's net sales = 800 JOD, yesterday's = 1,000 JOD. Case B: today's eligible sales = 0, yesterday's = 1,000 JOD.
- **Steps:** 1. Prepare Case A, open Overview, and read the growth indicator. 2. Repeat for Case B.
- **Expected:** Case A shows -20% with a decrease indicator. Case B shows -100%. Neither case shows "New Sales", an error, or a positive indicator.

#### TC-POS-068 — Calculate Daily Sales for the mixed-payment-method example
- **Category:** Positive / calculation
- **Preconditions/data:** Same-day confirmed invoices: Cash 500, Mada 300, Visa 150, MasterCard 50 JOD (total 1,000 JOD). Discounts 50 JOD. Confirmed sales returns 100 JOD.
- **Steps:** 1. Open Overview. 2. Read Daily Sales and Refund Amount.
- **Expected:** Daily Sales = 1,000 - 50 - 100 = 850 JOD. Refund Amount = 100 JOD. Every payment method contributes its invoice value.

#### TC-POS-069 — Count Fully Refunded invoices on Overview
- **Category:** Positive / calculation
- **Preconditions/data:** Today's confirmed invoices: INV-A paid and fully returned today; INV-C paid with no return. Also a full return made today of an invoice from an earlier day. (Partial returns are not supported, so there is no partially returned case.)
- **Steps:** 1. Open Overview. 2. Read the Fully Refunded count. 3. Click it and inspect the records.
- **Expected:** Fully Refunded = 2: every full return made today is counted, whatever the date of the original invoice (business rule confirmed 19/11/2026). INV-A and the earlier-day invoice are both counted, INV-C is not, and the list matches the count.

#### TC-POS-070 — Hide invoice KPIs marked as not supported
- **Category:** Negative / scope
- **Preconditions/data:** Today has confirmed invoices in any state.
- **Steps:** 1. Open Overview. 2. Inspect the Invoices Today component.
- **Expected:** The component shows Total Confirmed, Fully Paid, and Fully Refunded. Partially Paid, Unpaid, and Partially Refunded, which the story marks as not supported, are not shown with misleading or zero values. If product decides to show them, record that as a scope change.

#### TC-POS-071 — Count Work Orders by creation date and current status
- **Category:** Positive / date behavior
- **Preconditions/data:** WO-X was created yesterday and completed today. WO-Y was created today and is still pending. WO-Z was created today and voided later today.
- **Steps:** 1. Open Overview. 2. Read Total, Pending, Completed, and Voided. 3. Open the Completed list.
- **Expected:** WO-X is not counted because it was not created today. WO-Y counts as Pending and WO-Z as Voided, which is its current status. Total = Pending + Completed + Voided.

#### TC-POS-072 — Keep Overview inventory counts consistent with the Inventory tab
- **Category:** Positive / consistency
- **Preconditions/data:** The selected store has items in every stock state.
- **Steps:** 1. Record Total, Low Stock, Out of Stock, and Negative Stock on Overview. 2. Open Inventory and record the counts on its tabs and cards.
- **Expected:** Both places show the same counts for the same store and the same counting basis (distinct active items).

#### TC-POS-073 — Show Top Selling when fewer than five items, or no items, were sold
- **Category:** Boundary
- **Preconditions/data:** Case A: only three distinct products/services were sold today. Case B: no sales today.
- **Steps:** 1. Open Overview in Case A and inspect Top Selling (Today). 2. Repeat in Case B. 3. Click View All in each case.
- **Expected:** Case A lists exactly the three sold items, with no empty or placeholder rows. Case B shows an empty state without an error. View All opens the report in both cases.

#### TC-POS-074 — Calculate Cash Sales Balance and Cash Refunds Balance, including split payments
- **Category:** Positive / calculation
- **Preconditions/data:** Active session with: a cash invoice of 300 JOD; a split invoice of Cash 100 + Mada 100; a Mada invoice of 150; and a cash refund of 50 JOD for a Visa-paid invoice.
- **Steps:** 1. Open the Current Cash Register block. 2. Read Cash Sales Balance, Cash Refunds Balance, and Expected Cash Balance.
- **Expected:** Cash Sales Balance = 400 JOD (only the cash portion of the split invoice counts). Cash Refunds Balance = 50 JOD. Expected Cash = Opening + 400 - 50.

#### TC-POS-075 — Reduce Expected Cash Balance by a confirmed cash deposit
- **Category:** Positive / calculation
- **Preconditions/data:** Active session: Opening 100 JOD, cash sales 300 JOD, cash refund 50 JOD (expected 350). Then a confirmed cash deposit of 100 JOD, plus a second deposit left unconfirmed or in draft, if the screen supports it.
- **Steps:** 1. Record Expected Cash Balance (350). 2. Create and confirm the 100 JOD deposit from Cash Deposit. 3. Refresh Overview and the Cash tab.
- **Expected:** Expected Cash = 100 + 300 - 50 - 100 = 250 JOD on both Overview and the Cash tab. The unconfirmed deposit has no effect. Cash in, transfers, expenses, and adjustments are not supported, so they appear in no figure.

#### TC-POS-076 — Refresh dashboard figures after new transactions
- **Category:** Positive / real-time behavior
- **Preconditions/data:** The dashboard is open on Overview.
- **Steps:** 1. Record Daily Sales, Invoices Today, Work Orders, and Expected Cash. 2. In the same session, complete a new paid WO/invoice and create a confirmed return. 3. Return to the dashboard or switch tabs, without signing in again.
- **Expected:** Every affected KPI, chart, and list reflects the new documents, and no stale values remain. Product answer (2026-11-14): the refresh must be **automatic** while the dashboard stays open, with no tab change or manual refresh.

### Executive Summary

#### TC-POS-029 — Calculate current Inventory Value
- **Category:** Positive / calculation
- **Preconditions/data:** Engine Oil: 100 × 10 JOD; Oil Filter: 50 × 5 JOD; Battery: 20 × 50 JOD.
- **Steps:** 1. Open the Executive Summary. 2. Read Inventory Value.
- **Expected:** Inventory Value is 2,250 JOD, calculated as current stock quantity multiplied by inventory unit cost and summed across eligible items.

#### TC-POS-030 — Keep Inventory Value current rather than tied to the sales date
- **Category:** Positive / date behavior
- **Preconditions/data:** Select a past sales date while current stock differs from stock on that date.
- **Steps:** 1. View Inventory Value in the Executive Summary. 2. Change the selected sales date/period, if available. 3. Re-read Inventory Value.
- **Expected:** Inventory Value represents current inventory, not inventory value as of the selected sales date.

#### TC-POS-031 — Calculate Gross Profit from net sales and COGS
- **Category:** Positive / calculation
- **Preconditions/data:** Gross Sales = 10,000 JOD; Discounts = 500 JOD; Sales Returns = 300 JOD; COGS = 5,000 JOD.
- **Steps:** 1. Open Executive Summary. 2. Read Daily Net Sales and Gross Profit.
- **Expected:** Net Sales is 9,200 JOD (10,000 - 500 - 300); Gross Profit is 4,200 JOD (9,200 - 5,000). COGS uses net quantity sold × applicable unit cost.

#### TC-POS-032 — Calculate Gross Margin excluding tax
- **Category:** Positive / calculation
- **Preconditions/data:** Gross Profit = 4,200 JOD; Net Sales excluding tax = 9,200 JOD.
- **Steps:** 1. Open Executive Summary. 2. Read Gross Margin.
- **Expected:** Gross Margin is approximately 45.65%, calculated as Gross Profit ÷ Net Sales × 100, excluding tax.

#### TC-POS-033 — Handle zero net sales in Gross Margin
- **Category:** Boundary
- **Preconditions/data:** Selected period has zero Net Sales.
- **Steps:** 1. Open Executive Summary. 2. Read Gross Margin.
- **Expected:** The application displays N/A or 0% as specified by its agreed product behavior and does not display an error or divide by zero. The story permits either N/A or 0%.

#### TC-POS-034 — Calculate Output VAT net of sales-return VAT
- **Category:** Positive / calculation
- **Preconditions/data:** Eligible sales Output VAT = 1,500 JOD; eligible sales-return VAT = 100 JOD.
- **Steps:** 1. Open Executive Summary. 2. Read Output VAT.
- **Expected:** Output VAT is 1,400 JOD.

#### TC-POS-035 — Calculate Input VAT net of purchase-return VAT
- **Category:** Positive / calculation
- **Preconditions/data:** Recoverable purchase VAT = 700 JOD; purchase-return VAT = 50 JOD.
- **Steps:** 1. Open Executive Summary. 2. Read Input VAT.
- **Expected:** Input VAT is 650 JOD.

#### TC-POS-036 — Calculate Net VAT Payable
- **Category:** Positive / calculation
- **Preconditions/data:** Output VAT = 1,400 JOD; Input VAT = 650 JOD.
- **Steps:** 1. Open Executive Summary. 2. Read Net VAT Payable.
- **Expected:** Net VAT Payable is 750 JOD (Output VAT - Input VAT).

#### TC-POS-077 — Show Daily Sales including VAT and Daily Net Sales excluding VAT in the Executive Summary
- **Category:** Positive / consistency
- **Preconditions/data:** Today's confirmed invoices include standard-rated (15%) and zero-rated items, a discount, and a confirmed return.
- **Steps:** 1. Read Daily Sales (Incl. VAT) and Daily Net Sales (Excl. VAT) in the Executive Summary. 2. Compare them with the Overview Daily Sales KPI and the Sales tab (Daily) Total Sales and Total Net Sales.
- **Expected:** Daily Sales (Incl. VAT) equals the Overview Daily Sales KPI and the Sales tab Total Sales Amount. Daily Net Sales equals Daily Sales minus net Output VAT and equals the Sales tab Total Net Sales Amount. Zero-rated items add no VAT.

### Sales tab

#### TC-POS-037 — Use Daily as the default Sales period
- **Category:** Positive
- **Preconditions/data:** Open the Sales tab in a new dashboard session.
- **Steps:** 1. Select Sales. 2. Inspect the selected period and From/To dates.
- **Expected:** Daily is selected by default and From/To are the current business date.

#### TC-POS-038 — Populate MTD, QTD, and YTD date ranges
- **Category:** Positive / date boundary
- **Preconditions/data:** Known current business date and configured financial-year start date.
- **Steps:** 1. Select MTD, QTD, then YTD. 2. Record From and To for each period.
- **Expected:** MTD starts on the first day of the current month; QTD starts on the first day of the current quarter; YTD starts on the first day of the current financial year. Each ends on the current business date.

#### TC-POS-039 — Apply a valid custom Sales date range
- **Category:** Positive
- **Preconditions/data:** QA records exist both inside and outside a chosen From/To range.
- **Steps:** 1. Enter From Date and To Date with From ≤ To. 2. Click Apply. 3. Inspect KPIs, counts, and records.
- **Expected:** All Sales KPIs, transaction counts, and records refresh to the chosen date range.

#### TC-POS-040 — Reject an invalid custom Sales date range
- **Category:** Negative / boundary
- **Preconditions/data:** None.
- **Steps:** 1. Set From Date later than To Date. 2. Click Apply.
- **Expected:** The invalid range is not applied; the user receives clear validation and existing data is not silently shown as if the invalid range succeeded.

#### TC-POS-041 — Refresh date range when changing period or manually editing dates
- **Category:** Positive
- **Preconditions/data:** Periods have distinguishable fixture data.
- **Steps:** 1. Select MTD, QTD, and YTD in turn. 2. Manually change either date. 3. Apply the custom range.
- **Expected:** Choosing a predefined period updates From/To and refreshes the data; manually changing either date makes the selection a custom range.

#### TC-POS-042 — Preserve Sales date range across All, Refunds, and Invoices
- **Category:** Positive / state retention
- **Preconditions/data:** Apply a non-default date range.
- **Steps:** 1. Switch among All, Refunds, and Invoices. 2. Observe the selected dates after each switch.
- **Expected:** The chosen date range remains unchanged while switching transaction categories.

#### TC-POS-043 — Calculate Sales Total Sales, Net Sales, and invoice count
- **Category:** Positive / calculation
- **Preconditions/data:** Selected period gross sales = 5,000 JOD; discounts = 300 JOD; sales returns = 200 JOD; 50 eligible confirmed invoices.
- **Steps:** 1. Open Sales for the selected period. 2. Read Total Sales Amount, Total Net Sales Amount, and Invoices Number.
- **Expected:** Net Sales is 4,500 JOD; invoice count is 50. Total Sales Amount follows the include-tax rule; Total Net Sales Amount excludes tax.

#### TC-POS-044 — Include eligible invoices once and exclude ineligible Sales documents
- **Category:** Positive and negative
- **Preconditions/data:** Confirmed invoices across payment methods including credit/pending settlement; one invoice with multiple payment records; failed, draft, cancelled, and deleted invoices.
- **Steps:** 1. Open Sales for the period. 2. Compare Total Sales and invoice count with eligible invoice documents.
- **Expected:** Confirmed invoices are included irrespective of payment method or pending electronic settlement, each invoice is counted once regardless of payment-record count; failed, draft, cancelled, and deleted invoices are excluded. Unpaid invoice support is identified in the story as not yet supported and requires product clarification.

#### TC-POS-045 — Calculate Average Invoice and handle zero invoices
- **Category:** Positive / boundary
- **Preconditions/data:** First use Sales = 4,500 JOD and 50 confirmed invoices; then use a period with zero eligible invoices.
- **Steps:** 1. Read Average Invoice for the first period. 2. Apply the zero-invoice period and read it again.
- **Expected:** First result is 90 JOD (4,500 ÷ 50); when invoice count is zero, display 0.00.

#### TC-POS-046 — Calculate Refund Amount and Return Rate using return date
- **Category:** Positive / calculation / date behavior
- **Preconditions/data:** Gross Sales = 5,000 JOD; confirmed sales returns = 200 JOD; include draft, cancelled, and rejected return documents. Include a return whose original invoice date is outside the period but return document date is inside.
- **Steps:** 1. Apply a period containing the return document date. 2. Read Refunds Amount and Return Rate. 3. Apply a period containing only the original invoice date.
- **Expected:** Refunds Amount is 200 JOD and Return Rate is 4.0% for the first period; only confirmed returns are included, based on return document date. Draft/cancelled/rejected returns are excluded.

#### TC-POS-047 — Handle zero gross sales in Return Rate
- **Category:** Boundary
- **Preconditions/data:** Selected period has zero Gross Sales and zero eligible refunds.
- **Steps:** 1. Open Sales for the period. 2. Read Return Rate.
- **Expected:** Return Rate is 0.0%; no division-by-zero error occurs.

#### TC-POS-048 — Show Sales transaction categories and document counts
- **Category:** Positive / calculation
- **Preconditions/data:** Known confirmed invoice and return documents in the selected range, with multiple payments on one invoice.
- **Steps:** 1. Inspect All, Refunds, and Invoices tabs and the count beside each. 2. Compare each count with eligible documents.
- **Expected:** All shows eligible invoice and return documents; Refunds shows confirmed return/refund documents only; Invoices shows confirmed sales invoices only. Counts are document counts, not payment-record counts, and follow the selected date range.

#### TC-POS-049 — Verify Sales transaction table columns and values
- **Category:** Positive
- **Preconditions/data:** Fixtures include invoice and return documents, customer types, multiple payment methods, and ZATCA statuses/reasons/timestamps where available.
- **Steps:** 1. Inspect rows under All, Refunds, and Invoices. 2. Compare displayed values with source documents.
- **Expected:** The table presents Invoice #/Date, Customer, Customer Type, distinct item/service line count, document Amount including applicable tax, payment Method(s), Status, ZATCA Status, ZATCA Rejection Reason, and ZATCA Status Time. Refund rows show the return/refund document number.

#### TC-POS-050 — Search Sales transactions using supported fields
- **Category:** Positive / negative
- **Preconditions/data:** Distinct invoice/refund numbers, customer names, payment methods, ZATCA statuses, and plate numbers exist in the active range.
- **Steps:** 1. Search separately by invoice/refund number, customer name, payment method, ZATCA status, and plate number. 2. Search for a value with no match.
- **Expected:** Each supported search term returns matching transaction rows; a no-match term shows no matching records without unrelated results.

#### TC-POS-051 — Export the currently displayed Sales transaction list
- **Category:** Positive
- **Preconditions/data:** Apply a date range and search/filter; select each transaction tab in turn.
- **Steps:** 1. Export under All. 2. Repeat under Refunds and Invoices. 3. Compare each exported file with the currently displayed list.
- **Expected:** Each export contains only records from the selected tab and respects the applied date range and active filters.

#### TC-POS-078 — Include documents on the boundary dates of a custom range
- **Category:** Boundary / date behavior
- **Preconditions/data:** Documents dated at the start of the From date (for example 00:05), at the end of the To date (for example 23:55), and one minute outside each end.
- **Steps:** 1. Apply From = To = a single day and inspect the records. 2. Apply a multi-day range whose ends match the boundary documents.
- **Expected:** Both ends of the range are inclusive. Documents on the From and To dates are included and documents outside are excluded. KPIs and tab counts match the listed records.

#### TC-POS-079 — Verify Items and Method values for multi-quantity, multi-line, and split-paid documents
- **Category:** Positive
- **Preconditions/data:** INV-1 has one service with quantity 2. INV-2 has three different items. INV-3 is split-paid by Cash + Mada. A return of INV-3 is refunded in Cash.
- **Steps:** 1. Open Sales → All for the range. 2. Inspect the Items, Method, Amount, and Status columns for each row.
- **Expected:**
  - **Items:** shows the number of distinct lines (INV-1 = 1, INV-2 = 3), not the total quantity.
  - **Method:** INV-3 lists both methods (Cash + Mada). The return row shows its refund method.
  - **Amount:** the return row shows the return document number and the return amount, visibly distinguished as a refund.

#### TC-POS-080 — Keep Sales KPIs consistent with active search or filters
- **Category:** Positive / clarification-dependent
- **Preconditions/data:** The range has invoices for two customers.
- **Steps:** 1. Record the KPIs and tab counts with no search. 2. Search by one customer name. 3. Record the KPIs and tab counts again. 4. Clear the search.
- **Expected:** The story counts invoices "based on used filters". Confirm with product whether the search box filters only the list, or the KPIs too. Whichever applies, tab counts must equal the listed records. Clearing the search restores the original values.

#### TC-POS-081 — Verify export file format, columns, and empty-list export
- **Category:** Positive / negative
- **Preconditions/data:** Sales and WO Info contain records. Also a range or search that returns no records.
- **Steps:** 1. Export from Sales and from WO Info. 2. Open each file and compare its headers and values with the grid. 3. Export an empty list.
- **Expected:**
  - Each file opens and its columns match the grid columns defined in the story; for Sales this includes ZATCA Rejection Reason.
  - Amounts, dates, and document numbers match the screen.
  - Exporting an empty list produces a header-only file or a clear "no data" message, without an error.

#### TC-POS-082 — Show a refunds-only period with zero gross sales
- **Category:** Boundary
- **Preconditions/data:** The selected period contains a confirmed return (dated in the period) of an invoice from an earlier period, and no sales invoices.
- **Steps:** 1. Apply the period. 2. Read Total Sales, Refunds, Return Rate, Average Invoice, and the tab counts.
- **Expected:**
  - Refunds shows the return amount.
  - Return Rate shows 0.0%, with no division error, because gross sales are 0.
  - Average Invoice shows 0.00.
  - Invoices tab = 0 and Refunds tab = 1.
  - Record how Total Sales is displayed (negative or 0) and confirm with product.

### WO Info tab

#### TC-POS-052 — Apply WO Info period and custom date filters
- **Category:** Positive / negative / boundary
- **Preconditions/data:** Work orders exist in multiple periods; same period options and controls as Sales.
- **Steps:** 1. Verify Daily, MTD, QTD, and YTD populate their correct dates. 2. Apply a valid custom range. 3. Try From Date later than To Date.
- **Expected:** WO Info uses the same period/date behavior as Sales; valid Apply refreshes the tab, and an invalid range is rejected with clear validation.

#### TC-POS-053 — Calculate Total WOs and distinct Total Customers Served
- **Category:** Positive / calculation
- **Preconditions/data:** Selected range has pending, completed, and voided WOs; multiple WOs share one customer.
- **Steps:** 1. Open WO Info for the range. 2. Read Total WOs and Total Customers Served.
- **Expected:** Total WOs includes pending, completed, and voided work orders; Total Customers Served counts distinct customers across all statuses, not WO rows.

#### TC-POS-054 — Calculate Pending, Completed, and Voided rates
- **Category:** Positive / calculation
- **Preconditions/data:** Selected range has 10 WOs: 2 Pending, 6 Completed, and 2 Voided.
- **Steps:** 1. Read the In Progress/Pending, Completed, and Voided summary cards.
- **Expected:** Counts are 2, 6, and 2; rates are 20%, 60%, and 20%, respectively, each divided by all WOs in the selected range.

#### TC-POS-055 — Preserve WO Info range and category counts
- **Category:** Positive / state retention
- **Preconditions/data:** Apply a custom date range with known WO counts by status.
- **Steps:** 1. Switch among All, Pending, Completed, and Voided. 2. Record each count and the date range.
- **Expected:** Each tab shows only its status category; counts follow the applied range; switching tabs does not reset dates.

#### TC-POS-056 — Verify WO transaction table, status action, and search
- **Category:** Positive / negative
- **Preconditions/data:** WOs exist with known customer, plate, bay, amount, status, VIN, and technician data.
- **Steps:** 1. Inspect columns WO #/date, Customer, Plate Number, Bay Name, Amount, WO Status, and Action. 2. Check pending and completed rows. 3. Search by WO number, customer, bay, technician, and VIN.
- **Expected:** Row values correspond to source WOs; the Completed action appears beside pending WOs as stated; each supported search returns matching WOs. Do not trigger completion during this read-only case.

#### TC-POS-057 — Export the currently displayed WO list
- **Category:** Positive
- **Preconditions/data:** Apply a date range and search/filter; select All, Pending, Completed, and Voided in turn.
- **Steps:** 1. Export the list for each selected category. 2. Compare each export with the visible rows.
- **Expected:** Export includes only the selected category's displayed records and respects the applied date range and active filters.

#### TC-POS-083 — Show WO Info for a range with no work orders
- **Category:** Boundary
- **Preconditions/data:** A custom range that contains no work orders.
- **Steps:** 1. Apply the range. 2. Read all summary cards and tab counts.
- **Expected:** Every count is 0 and the rates show 0% (or the agreed N/A), with no error or division by zero. The list shows an empty state.

#### TC-POS-084 — Complete a pending WO from the WO Info action
- **Category:** Positive / state change
- **Preconditions/data:** A pending WO that can be completed in QA.
- **Steps:** 1. Record the WO Info counts and rates and the Overview WO counts. 2. Click the Complete action beside the pending WO and finish the flow. 3. Return to WO Info and Overview.
- **Expected:**
  - The action opens the completion/payment flow for that WO.
  - After completion, the WO moves from Pending to Completed and the Complete action is no longer shown for it.
  - Counts and rates update on WO Info and Overview.
  - The resulting invoice appears in Sales.

### Cash tab

#### TC-POS-058 — Calculate Total Payment Received and payment-method breakdown
- **Category:** Positive / calculation
- **Preconditions/data:** During selected working day/range, confirmed receipts: Cash 500, Mada 300, Visa 150, MasterCard 50, Bank Transfer 100 JOD.
- **Steps:** 1. Open Cash. 2. Read Total Payment Received, Cash Received, Electronic Payments Received, and method breakdown.
- **Expected:** Total received is 1,100 JOD; Cash Received is 500 JOD; Electronic Payments Received is 600 JOD; each applicable method matches actual confirmed receipts.

#### TC-POS-059 — Apply Cash tab selected day or date range
- **Category:** Positive / date behavior
- **Preconditions/data:** Confirmed payment records exist inside and outside the selected day/range.
- **Steps:** 1. Select the working day or date range. 2. Compare the totals with confirmed receipts inside that range.
- **Expected:** Total, Cash Received, and Electronic Payments Received include only actual receipts in the selected day/range.

#### TC-POS-060 — Open Cash Deposit screen from Current Cash Register
- **Category:** Positive / navigation
- **Preconditions/data:** Cash tab is available and a register is open.
- **Steps:** 1. Open Cash. 2. Click the cash deposited/deposit button. 3. Inspect the destination without submitting a deposit.
- **Expected:** The Cash Deposit screen opens. This case does not create or confirm a deposit.

#### TC-POS-061 — Keep Cash tab register details consistent with Overview
- **Category:** Positive / consistency
- **Preconditions/data:** Active session has known opening and expected cash balances.
- **Steps:** 1. Record register details on Overview. 2. Open Cash and inspect Current Cash Register.
- **Expected:** Cash tab shows the same current register/session details as Overview, including the values for the same active session.

#### TC-POS-085 — Calculate Cash Sales % and Other Payments %
- **Category:** Positive / boundary
- **Preconditions/data:** Receipts of Cash 500, Mada 300, Visa 150, MasterCard 50, and Bank Transfer 100 JOD (total 1,100). Also a range with no receipts.
- **Steps:** 1. Open Cash for the range. 2. Read Cash Sales % and Other Payments %. 3. Apply the range with no receipts.
- **Expected:** Cash Sales % = 500 / 1,100 = 45.5%. Other Payments % = 600 / 1,100 = 54.5%. The two add up to 100%. In the empty range both show 0% with no error.

#### TC-POS-086 — Apply Cash tab period controls and reject an invalid range
- **Category:** Positive / negative
- **Preconditions/data:** Receipts exist in several periods.
- **Steps:** 1. Open Cash and check the default period. 2. Select MTD, QTD, and YTD. 3. Set From later than To and click Apply.
- **Expected:**
  - The default is Daily (the current business date).
  - Each preset fills its correct From/To and refreshes the payment totals.
  - The invalid range is rejected with clear validation.
  - The Current Cash Register block keeps showing the active session.

### Inventory tab

#### TC-POS-062 — Show Inventory Value and In Stock item count
- **Category:** Positive / calculation
- **Preconditions/data:** Selected store has active inventory items with known current quantities and unit costs, including positive, zero, and negative stock.
- **Steps:** 1. Open Inventory. 2. Read Stock Value and In Stock item count.
- **Expected:** Stock Value reflects the sum of current stock quantity × unit cost; In Stock count follows the agreed product definition for positive available stock. Count only distinct active inventory items.

#### TC-POS-063 — Classify Inventory stock at minimum, zero, negative, and normal levels
- **Category:** Positive / boundary
- **Preconditions/data:** Minimum stock = 5; items have quantities 3, 5, 0, -2, and 15.
- **Steps:** 1. Open Inventory for the selected store. 2. Inspect each item's status and category totals.
- **Expected:** Positive stock ≤ minimum (3 and 5) is Low Stock; 0 is Out of Stock; below 0 is Negative Stock; stock above minimum (15) is Normal. The Low Stock rule is 0 < stock ≤ minimum.

#### TC-POS-064 — Filter Inventory by All, In Stock, Low Stock, and Out of Stock
- **Category:** Positive / calculation
- **Preconditions/data:** Selected store has items in all stock states.
- **Steps:** 1. Select All, In Stock, Low Stock, and Out of Stock. 2. Record the count beside each tab and inspect rows.
- **Expected:** Each tab shows the correct stock category and total record count. Counts are based on distinct active inventory items; Negative is also available as a status/category where specified.

#### TC-POS-065 — Verify Inventory grid columns and values
- **Category:** Positive
- **Preconditions/data:** Known active inventory items exist in multiple stores/statuses.
- **Steps:** 1. Open Inventory and inspect the grid. 2. Compare rows with source inventory records.
- **Expected:** Grid includes Item Name, Item Number, Store Name, Current Qty, Min Qty, Max Qty, and Status, with values matching the selected store's current inventory.

#### TC-POS-066 — Search Inventory by Item Name and Item Number
- **Category:** Positive / negative
- **Preconditions/data:** Distinct item names and numbers exist in the inventory list.
- **Steps:** 1. Search by an exact/partial Item Name. 2. Search by Item Number. 3. Search for a nonexistent value.
- **Expected:** Matching items are returned for both supported search fields; a nonexistent value returns no unrelated items.

#### TC-POS-087 — Exclude inactive items from Inventory counts, value, and grid
- **Category:** Negative
- **Preconditions/data:** An item that is inactive but still has stock, and an active item with stock.
- **Steps:** 1. Record the Inventory counts and Stock Value. 2. Deactivate the test item in the portal (Item → Cancel), or use an existing inactive item. 3. In the POS, run the data sync (Menu → System & Devices → Sync). 4. Re-open Inventory and search for the item.
- **Expected:** The inactive item is excluded from the All and category counts, from Stock Value, and from the grid and search results. The Overview inventory KPI changes the same way.

## Requirements needing clarification before strict pass/fail execution

1. **Overview Daily Sales tax treatment:** The KPI is labeled “Include tax,” while some formulas/examples call the result Net Sales without defining whether discount/return values include VAT. Prepare expected values using the agreed invoice-total convention.
2. **Sales tab unpaid invoices — resolved 2026-11-14: not supported at present.** One rule says unpaid invoices are included if the invoice is confirmed; another labels unpaid support “Not supported yet.” Confirm the intended product behavior before treating unpaid invoice coverage as a release gate.
3. **Overview invoice KPIs:** The component says Total Confirmed and Fully Paid; actions additionally mention Fully Refunded. Confirm whether Fully Refunded is a displayed KPI/count or only a drill-down.
4. **WO status naming — resolved 2026-11-14: In Progress and Pending are the same status.** Summary calls the count “In progress WOs” but defines the formula using Pending WOs. Confirm whether In Progress and Pending are the same status.
5. **Zero-WO rates:** The story does not define rate display when the selected range contains no WOs.
6. **Inventory “In Stock” and value of negative stock:** Confirm whether In Stock means strictly positive stock, and whether negative quantities reduce Stock Value or are excluded.
7. **Top-selling ranking:** Tie-breaking, treatment of returned quantities, and whether Total Selling Value includes tax are not specified.
8. **Payment chart refund allocation:** The story says deduct refund values but does not specify whether a refund is allocated to original payment methods or to its refund payment method.
9. **Cash tab date filters:** It refers to the selected working day or date range but does not specify the date-control options or whether cash-register details change with a historical range.
10. **Cash expected-balance examples:** The Overview example gives 350 JOD for opening + cash sales - cash refund; another example gives 230 JOD including expenses and deposits. Cash expenses are marked unsupported, while deposits are supported. Confirm the scenarios and supported movement types before execution.
11. **Cash Deposit control:** Confirm the exact button label and whether the button opens a deposit-entry screen or a deposited-cash history screen.
12. **Date/time and export details:** Time zone/business-day boundary, export file format, and exact custom-range inclusivity are not stated.
13. **VAT and cost rules:** Rounding precision, VAT eligibility rules, inventory unit-cost method, and treatment of purchase/sales returns beyond the listed formulas are not stated.
14. **Unspecified navigation and permissions:** The story does not enumerate every role-to-component permission mapping or exact destination route/filter names; confirm these from product configuration.
15. **Items without a minimum stock level — resolved 2026-11-14: follows the Store form definition; positive stock with no Min Qty is In Stock.** Several items have no Min Qty ("--"). The story does not define how these are classified when stock is positive (Normal or In Stock), nor whether they can ever be Low Stock.
16. **Inventory store scope — resolved 2026-11-13:** The branch has 2 stores, and the dashboard Inventory covers both. Still open (TC-POS-064): should the category tabs count item × store rows, or distinct items like "All" does?
17. **Search box effect on KPIs:** It is unclear whether "based on used filters" means the Sales search box also filters the KPIs, or only the list (TC-POS-080).
18. **Refund payment method — resolved 2026-11-13:** By current business rule, refunds are **Cash only**, whatever the original payment method. The Mada/Visa refund scenarios in TC-POS-023 and TC-POS-027 are out of scope until that changes. A cash refund also requires enough cash in the drawer.
19. **Voided WO amount:** The story does not say whether a voided WO shows its original amount or 0 in the WO list and export.
20. **Refunds-only period:** It is not defined whether Total Sales may be negative when returns exceed sales in the selected period (TC-POS-082).
21. **Refresh behavior — resolved 2026-11-14: the dashboard must refresh automatically while open.** The objective says "real-time", but it is not stated whether the dashboard refreshes automatically or on navigation (TC-POS-076).

