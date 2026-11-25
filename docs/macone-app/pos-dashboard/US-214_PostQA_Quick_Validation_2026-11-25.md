# US-214 POS Dashboard: Post-QA Quick Validation

This is a **Post-QA Quick Validation**, not full QA testing. Only the main happy paths and the linked bug retests were checked. Negative, boundary and regression scenarios were not repeated.

| Item | Value |
|---|---|
| Story | 214, myShop POS - Company Dashboard |
| Build | MAC1 1.2.508 (process file version, session started 25/11 08:29) |
| Environment | QA - Company, branch Alshellah, working day TO_11000036 |
| Date | 25/11/2026, 10:40 to 10:46 |
| Result | **Failed** (1 happy path failed) |

## 1. Happy path validation

| # | Check | UI result | DB result (query) | Verdict |
|---|---|---|---|---|
| 1 | Overview: Daily Sales, Invoices Today, Refunds, Work Orders, Cash Register, Executive Summary | Daily Sales 0.00, 1 invoice, Refunds 500.00, WO 3 (2 Pending, 1 Completed), Expected Cash 100.00 | Invoice 500.00 and return 500.00, net 0.00 (L1) | Passed |
| 2 | Sales tab: cards and list of the day | Total 0.00, Invoices 1, Refunds 500.00, Return Rate 100.0%, list INV-TO_11000150 and RTN-TO_11000025 | Same two documents and amounts (L1) | Passed |
| 3 | WO Info tab: cards and list | Total 3, Pending 2, Completed 1, WO 202, 199, 197 with their dates | WO 202 Submitted 25/11, 199 New 24/11, 197 New 23/11 (L1) | Passed |
| 4 | Cash tab: register and payment methods | Opening 100.00, Cash Sales 500.00, Cash Refunds 500.00, Expected 100.00; Cash 500 received, 500 refunded | Same invoice and return, both Cash (L1) | Passed |
| 5 | Inventory tab: stock categories and new Store filter | All 367, In Stock 355, Low 1, Out 11, **Negative 0**; Filters panel: Branch Store 363 items, Branch - 2 **4 items** | 390 item x store rows: In 357, Low 1, Out 11, **Negative 21**; Branch - 2 has **27** rows, 21 of them negative (L2) | **Failed** |

## 2. Bug retest results

| Bug | Title (short) | DevOps state | Retest on 1.2.508 | Result |
|---|---|---|---|---|
| 2294 | Completing an earlier-day Work Order overwrites its creation date | Resolved | Completed WO-TO_11000197 (created 23/11) with Cash 25.00. UI keeps 23/11; DB WorkOrderDate stays 2026-11-23 08:56:23, status Submitted, invoice INV-TO_11000151 25.00 dated 25/11 (L3) | **Passed** |
| 2286 | Store filter on Inventory tab and Overview card | Closed (25/11) | The filter now exists, but 23 Branch - 2 rows (all 21 negative items) are missing from the tab, cards and filter | **Failed** (see item 3.1) |
| 2288 | Invalid date range on Sales, WO Info, Cash | Closed (24/11) | Retested on 24/11 (1.2.504), Passed. Not repeated. | Passed earlier |

The other story bugs (1246, 1478, 1585, 1723, 1854, 1870, 1973, 1974, 2110) were already Closed before this validation and are not in scope.

## 3. Failed, blocked and needs investigation items

1. **Inventory rows of Mohammad Store Branch - 2 are missing (Failed).** Negative Stock shows 0 although the DB has 21 negative item rows in Branch - 2; on 1.2.504 the UI showed Negative 21. The tab and the filter show only 4 Branch - 2 items, the DB has 27. Logged as draft e-20261125-004 (no DevOps bug, waiting for your text). Bug 2286 is Closed, so it may need to be reopened instead. Cause (L4b): Branch Store applies to all items, so all its items show without InvStoreItem rows; Branch - 2 does not, and 30 of its item rows with movements (22 negative, 8 positive) have no InvStoreItem setup, so they are hidden. The items were most likely removed from the store after they had transactions; you will open a bug that removal must be blocked when the item has transactions.
2. **Share after payment (observation).** After the WO payment, closing Share Options was followed in the log by SMS, Email and WhatsApp share events at 10:45:09 to 10:45:11 and a Chrome "Share on WhatsApp" page opened. Nothing was sent from Chrome. Needs a check whether one click triggers all three shares.

## 4. Evidence

| Kind | Location |
|---|---|
| UI | `docs/macone-app/pos-dashboard/evidence/postqa-2026-11-25/` (hp_ui_01 to 05, b2286_ui_01, b2294_ui_00 to 06) |
| DB | same folder, `ssms/` (L1, L2, L3) |
| SQL | `QA-Database-Reference/Database-Queries/US-214-POS-Dashboard.sql`, Section L (L1 to L3), index rows 98 to 100 |

## 5. Recommendation

**Not ready to close.** Bug 2294 can be closed. The Inventory regression after the 2286 fix must be fixed (reopen 2286 or open a new bug), then recheck the Inventory tab and the Overview inventory card.
