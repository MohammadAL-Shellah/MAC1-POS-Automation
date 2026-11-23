# Run 6: Full retest notes (2026-11-19, MAC1 1.2.498)

Working notes; final results go into Task 2179 and the execution report.

## Scope review (story rev 79 vs rev 84)
1. Top Selling now "Based on sales value" (TC-025).
2. View All opens "Today Top Selling items" instead of the report (TC-026, TC-073).
3. Cash tab block shows cash sales and cash refund; Cash Deposit button removed (TC-060 N/A, TC-061 updated). Draft e-20261115-130 cancelled.

## QA data created
| Doc | Detail |
|---|---|
| RTN-TO_11000017 | Full return of INV-TO_11000127 (19/11, 100 Mada), cash refund |
| RTN-TO_11000018 | Full return of INV-TO_11000009 (26/10, 24.90), cash refund |
| INV-TO_11000128 | WO-TO_11000171 completed from WO Info: Package 1 (590) + Tire - Item (500), invoice discount QA Trans Disc 50, Cash 1,032.49 (Sub-total 947.82, Tax 134.67) |

## Observations so far
| Case | Result | Note |
|---|---|---|
| 084 | PASS | Complete on WO Info opened WO-171 for payment; after payment WO Info showed Pending 0, Completed 5 without reopening. |
| 005 | PASS | Daily Sales 275.10 + 1,032.49 = 1,307.59 (discount and returns applied). |
| 013 | PASS | Invoices Today 5, Fully Paid 5 (refunded invoice still counted as paid, accepted). |
| 022, 074 | PASS | Expected Cash 150 + 1,032.49 - 124.90 = 1,057.59; Cash tab shows Cash Sales and Cash Refunds. |
| 025 | PASS | Top Selling ordered by value: Package 1 590, Tire 500, RService 300. |
| 034, 036 | PASS | Output VAT 134.67 - 3.25 = 131.42; Net VAT Payable 131.42 (Recoverable 3.25 before the sale). |
| 029, 062 | INVESTIGATE | Inventory Value / Stock Value 0.00 before the sale (15/11 it was 6,710.00), 59,565.00 right after one Tire + Package 1 sale. |
| 031, 032 | INVESTIGATE | Gross Profit -748.83 (COGS 1,925.00 implied), Gross Margin -63.67% shown in green. |
| 019 | CHECK | Negative Stock 19 -> 22 after the sale. |
| 011 | PASS | Daily Sales card opens Sales, Daily 19/11/2026, All (7). |
| 012 | PASS | Refunds amount opens Sales > Refunds (2) for 19/11 (the "Refunds" label itself opens All). |
| 014 | PASS | Invoices Today opens Sales > All (accepted 14/11). |
| 015 | PASS | Fully Paid opens Sales > Invoices (5). |
| 016, 069 | PASS | Fully Refunded opens Refunds (2) (business rule 19/11). |
| 018 | PASS | Pending / Completed / Voided open WO Info on the matching sub-tab (0 / 5 / 4). |
| 020 | PASS | Low / Out / Negative open Inventory on the matching sub-tab. |
| 026, 073 | PASS | View All opens "Top Selling Today" items: Package 1 590, Tire 500, RService 300 (3 items, no placeholders). |
| 045 | PASS | Avg Invoice 261.52 = 1,307.59 / 5. |
| 046 | PENDING BA | Return Rate 8.4% = 124.90 / 1,490.00 (gross before discount); question e-20261115-157 open. |
| 029, 062 | FAIL | Portal Inventory Balance report has no cost values, so value cannot be recomputed; 0.00 with stock on hand, then 59,565.00 after one sale. |
| 064 | PENDING BA | Tabs 353+1+12+22 = 388 vs All 363 (question e-20261115-154). |
| 001 | PASS | Leaving the dashboard from Sales and coming back opens Overview. |
| 002 | PASS | All five tabs open (Overview, Sales, WO info, Cash, Inventory). |
| 008 | PASS | Yesterday 18/11 = 200.00 (INV-122 50 + INV-123 150); (1,307.59 - 200) / 200 = +553.8%. |
| 021, 023, 024 | PASS | Register TO_11000030 m.alshellah opened 2026/11/19 11:27; electronic payments excluded; only this session's cash moves. |
| 027 | PASS | Payment methods: Cash 907.59 (1,032.49 - 124.90), Mada/Visa/Master/Hala 100 each. |
| 037 | PASS | Sales opens on Daily 19/11-19/11. |
| 038 | PASS | MTD = 01/11/2026 - 19/11/2026: 68,940.66, 101 invoices, Refunds (18). |
| 039 | PASS | Custom 18/11-18/11: 200.00, 2 invoices (INV-122, INV-123). |
| 040 | PASS | From 19/11 > To 18/11 + Apply: "From Date must be on or before To Date." |
| 041 | PASS | Editing a date clears the Daily/MTD selection. |
| 042 | PASS | MTD range kept when switching to Refunds (18). |
| 043, 044, 048, 049 | PASS | Daily: 1,307.59, 5 invoices, All (7) Refunds (2) Invoices (5); columns Invoice #, Customer, Type, Plate, Items, Amount, Method, Status, ZATCA Status, ZATCA Status Time. |
| 050 | PASS | MTD search "Hala": 17 rows, all with Hala (incl. mixed INV-118). Cosmetic: INV-118 row columns shifted left. |
| 051, 081 | PASS | Export opens Save As, file Transactions_20261119_153009.xlsx holds exactly the 17 searched rows with headers (format is now .xlsx, earlier CSV via Share). |
| 079 | PASS | INV-118: Items 12, Method "Hala + Master + Visa + Mada + Cash". |
| 077 | PASS | Executive Summary Daily Sales 1,307.59 incl. VAT, Daily Net Sales 1,176.17 excl. VAT. |
| 072 | PASS | Overview inventory counts equal Inventory tab (363 / 1 / 12 / 22). |
| 060 | N/A | Cash Deposit button removed from story (rev 80). |
| 052, 055 | PASS | WO Info MTD 01/11-19/11: 142 WOs; range and counts kept across All / Pending (0) / Completed (98) / Voided (44). |
| 053, 054 | PASS | Daily: 9 WOs, 3 customers (Mohammad Alshellah, qa test, Ammar); rates 11.1 / 44.4 / 44.4 %. MTD: 98 + 44 = 142, 69.0 % / 31.0 %. Older pending WOs 142/143 Voided, 152 Completed, so Pending 0 is correct. |
| 056 | PASS | Columns WO No., Customer · Tech, Plate, Bay, Amount, Status, Actions (Complete on Pending only). |
| 057 | PASS | Export of Voided (44) -> WorkOrders_20261119_153221.xlsx with 44 Voided rows. |
| 058 | PASS | Daily Total Net Payment 275.10 (Received 400 - Refund 124.90) before the cash sale. |
| 059 | PASS | Cash MTD: 68,940.66 = Net Cash 19,600.61 + Net Electronic 49,340.05 = Sales MTD total. |
| 061 | PASS | Cash tab register block = Overview (Opening 150, Cash Sales 1,032.49, Refunds 124.90, Expected 1,057.59); not affected by the period filter. |
| 086 | PASS | Cash From 19/11 > To 18/11 + Apply: "From Date must be on or before To Date." |
| 063 | PASS | Tire - Item Branch-2: qty 7 < Min 10 -> Low Stock. |
| 065, 066 | PASS | Grid columns Item Name, Number, Store, Current/Min/Max Qty, Status; search "Tire - Item" -> 2 rows (one per store). |
| 084 | PASS | (see above) |

## DB cross-check (2026-11-19, read-only SQL on MAC1 local DB, branch ff31fb19)
| Area | Dashboard | DB | Match |
|---|---|---|---|
| Daily Sales | 1,307.59 | 5 invoices 1,432.49 - returns 124.90 | Yes |
| Daily Net Sales | 1,176.17 | 1,297.82 - 121.65 | Yes |
| Net VAT | 131.42 | 134.67 - 3.25 | Yes |
| Invoices Today | 5 | 5 | Yes |
| Refunds Today | 2 (124.90) | RTN-17 100.00, RTN-18 24.90 | Yes |
| Payment methods | Cash 907.59, Mada/Visa/Master/Hala 100 | Cash 1,032.49 - 124.90, others 100 | Yes |
| Opening Cash | 150 | Working day 11:27 OpenBalance 150 | Yes |
| Yesterday | 200.00 (2) | 200.00 (2) | Yes |
| MTD Sales | 68,940.66, 101 inv, 18 refunds | 91,610.26 - 22,669.60; 101; 18 | Yes |
| WO Today | 9: Completed 5, Voided 4, 3 customers | Submitted 5, Cancelled 4, 3 customers | Yes |
| WO MTD | 142: 98 / 44 | 98 / 44 | Yes |
| COGS / Gross Profit | 1,925 / -748.83 | Stock-out base qty 35 x cost 55 = 1,925 | Yes (031 PASS); SalInvoiceItemCost stores 275 (cost per line, not x qty) |
| Inventory rows | All 363, tabs sum 388 | 388 store/item rows | All tab short by 25 |
| Inventory status | In 353, Low 1, Out 12, Neg 22 | In 364, Low 1, Out 0, Neg 23 (balance from InvStoreTransaction) | No |
| Inventory Value | 0.00 then 59,565.00 | Sum qty x tx cost 685,618.09; default store 636.70; no formula gives 59,565 | No (029/062 FAIL) |
| Working days | n/a | Branch has 3 open working days (18/11 08:49, 19/11 11:11, 19/11 11:27), IsClosed False | Observation |

## Run 7: per-case dashboard vs DB (2026-11-19 16:56, fresh screen readings, evidence scratchpad run7)
| Cases | Dashboard | DB | Result |
|---|---|---|---|
| 005, 043, 077 | Daily 1,307.59; Net 1,176.17 | 1,432.49 - 124.90; 1,297.82 - 121.65 | Match |
| 008 | +553.8% vs 200.00 | Yesterday 2 inv 200.00 | Match |
| 012, 016, 069 | Refunds 124.90 (2) | RTN-17 100.00 + RTN-18 24.90 | Match |
| 013, 044 | Invoices 5, Fully Paid 5 | 5 submitted invoices, all paid | Match |
| 018, 053 | WO 9: 0 / 5 / 4, 3 customers | Submitted 5, Cancelled 4, 3 customers | Match |
| 021, 022, 061, 074 | Opening 150, Cash Sales 1,032.49, Refunds 124.90, Expected 1,057.59 | Working day 11:27 OpenBalance 150; cash receipts 1,032.49; cash refunds 124.90 | Match |
| 025, 026, 073 | Package 1 590, Tire 500, RService 300 (Qty 3) | 590 / 500 / RService 4 x 100 - 1 returned | Match (net of returns) |
| 027 | Cash 907.59, Mada/Visa/Master/Hala 100 | Same | Match |
| 031 | Gross Profit -748.83 | Net 1,176.17 - COGS 1,925 (35 base units x 55) | Match |
| 034, 036 | Output VAT 131.42, Input 0.00, Net 131.42 | 134.67 - 3.25 | Match |
| 038, 042 | MTD 68,940.66 / 101 / Refunds 18 | 91,610.26 - 22,669.60; 101; 18 | Match |
| 038 (cards) | Net 60,248.44, Avg 682.58, Return Rate 24.7% | 80,000.25 - 19,751.81; 68,940.66 / 101; 22,669.60 / 91,610.26 | Match |
| 045 | Avg Invoice 261.52 | 1,307.59 / 5 | Match |
| 046 | Return Rate 8.4% | 124.90 / 1,490.00 (incl VAT, before discount); same formula as MTD 24.7% | Match (formula consistent; BA question open) |
| 052, 054, 055 | MTD WO 142, 6 customers, 98 / 44 | 98 + 44, 6 customers | Match |
| 058, 059 | Net Cash 19,600.61, Net Electronic 49,340.05 | 34,841.51 - 15,240.90; 56,768.75 - 7,428.70 | Match |
| 063, 065 | Tire - Item Branch-2 7 / Min 10 / Max 100 Low; Branch Store 34 | 7 / 10 / 100; 34 | Match |
| 019, 020 | Negative 22 | 22 negative rows for Submitted items applied to the branch (23 incl. Air Filter 012, not applied to branch, correctly hidden) | Match |
| 020 | Low 1 | 1 | Match |
| 064, 072 | All 363; In 353; Out 12 | 382 branch rows with stock movement (In 359, zero qty 0); Out 12 come from store items without movement | Mismatch, needs dev definition |
| 029, 062 | Stock Value 59,565.00 | No formula matches: sum qty x tx cost 660,584.41 (branch items), default store 1,036.70 | FAIL |
| 032 | Margin -63.67% green | -748.83 / 1,176.17 = -63.67% | Value match, colour FAIL (cosmetic) |
UI-only cases (navigation, filters, columns, export, validation): 001, 002, 011, 014, 015, 037, 039, 040, 041, 048, 049, 050, 051, 056, 057, 065, 066, 079, 081, 084, 086: no DB value to compare; results unchanged from Run 6.
