# All Queries Index

Database: `MacOne_255b989cce714d828b70d1f9e4367412` on `qadb.minerets.com,55009` (QA, ReadUser). Status: W = written, E = executed, V = result verified against the UI.

## US-214 POS Dashboard ([file](Database-Queries/US-214-POS-Dashboard.sql))

| # | Query purpose | Tables | Operation | Verifies | Status | Added |
|---|---|---|---|---|---|---|
| 1 | Daily Sales, Net, VAT, Invoices today | SalInvoice, SalReturn | SELECT | TC-005, 013, 034, 043, 077 | W E V (TC-005, Run 73 and 74) | 2026-11-20 |
| 2 | Yesterday sales | SalInvoice | SELECT | TC-008, 039, 078 | W E | 2026-11-20 |
| 3 | Payment methods received and refunded today | SalInvoiceReceiptPayment, SalInvoiceReceipt, SalReturnReceiptPayment, SalReturnReceipt, GenLkpPaymentMethod | SELECT | TC-022, 027, 074 | W E V (Run 74) | 2026-11-20 |
| 4 | Working day and opening cash | SalWorkingDay, SalInvoice | SELECT | TC-021, 022, 061 | W E V (Run 74) | 2026-11-20 |
| 5 | Sales MTD | SalInvoice, SalReturn | SELECT | TC-038, 042, 045 | W E | 2026-11-20 |
| 6 | Cash tab MTD, cash vs electronic | SalInvoiceReceiptPayment, SalReturnReceiptPayment, GenLkpPaymentMethod | SELECT | TC-058, 059 | W E | 2026-11-20 |
| 7 | Work Orders by status, today and MTD | SalWorkOrder, GenLkpDocumentStatus | SELECT | TC-017, 018, 052, 053, 054 | W E | 2026-11-20 |
| 8 | Top Selling today | SalInvoiceItem, SalInvoice, InvItem | SELECT | TC-025, 026, 073 | W E V (Run 74) | 2026-11-20 |
| 9 | COGS today per invoice | SalInvoiceItemCost, SalInvoice | SELECT | TC-031 | W E | 2026-11-20 |
| 10 | Negative and positive inventory counts | InvStoreTransaction, InvItem, InvItemBranch, GenLkpDocumentStatus | SELECT | TC-019, 020, 064, 072 | W E | 2026-11-20 |
| 11 | Tire item stock vs min and max | InvStoreTransaction, InvItem, InvStore, InvStoreItem | SELECT | TC-063, 065, 066 | W E | 2026-11-20 |
| 12 | Inventory Value (qty x cost) | InvStoreTransaction, InvItem, InvStore, InvItemBranch | SELECT | TC-029, 062 | W E | 2026-11-20 |
| 13 | Today's stock movements | InvStoreTransaction, InvItem, InvStore | SELECT | TC-029, 035 | W E | 2026-11-20 |
| 14 | Air Filter 041 balance before and after purchase | InvStoreTransaction, InvItem, InvStore | SELECT | TC-029 | W E | 2026-11-20 |
| 15 | Air Filter 041 units and price | InvItem, InvItemUnit, SalPriceListItem | SELECT | TC-029 | W E | 2026-11-20 |
| 16 | Stock chain 1: Stock In/Out to source document | InvStockIn, InvStockOut, InvStockInItem, InvStockOutItem, InvStoreTransaction, SalInvoice, SalReturn, SalWorkOrder, ProInvoice, InvStore | SELECT | Stock links after each transaction | W E | 2026-11-20 |
| 17 | Stock chain 2: day's store transactions with item type | InvStoreTransaction, GenLkpDocumentType, InvItem, InvLkpItemType, InvStore | SELECT | Services do not move stock | W E | 2026-11-20 |
| 18 | Stock chain 3: service items holding stock | InvStoreTransaction, InvItem, InvItemService, InvStore | SELECT | Should return no rows | W E | 2026-11-20 |
| 19 | Stock chain 4: batch cost from purchases | InvItemBatchCost, InvItemBatch, InvItem | SELECT | Batch cost written | W E | 2026-11-20 |
| 20 | Q2 v2: net sales per day, last 4 days (growth) | SalInvoice, SalReturn | SELECT | TC-008, 039, 078 | W E V (Run 74) | 2026-11-20 |
| 21 | Q7 v2: WOs today by status with amount | SalWorkOrder, GenLkpDocumentStatus | SELECT | TC-017, 018, 052-054 | W E V (Run 74) | 2026-11-20 |
| 22 | Q9 v2: COGS per sold line x sales qty | SalInvoiceItemCost, SalInvoiceItem, SalReturnItemCost, SalReturnItem, InvItem | SELECT | TC-031 (understates: sales unit, not base unit) | W E | 2026-11-20 |
| 23 | Q9b: COGS from store transactions (base qty x cost) | InvStoreTransaction, GenLkpDocumentType, InvItem | SELECT | TC-031, 032: 792.00 matches dashboard | W E V (Run 74) | 2026-11-20 |
| 24 | Q10 v2: stock classification incl. store items without movement | InvStoreTransaction, InvStoreItem, InvItem, InvItemBranch, GenLkpDocumentStatus | SELECT | TC-019, 020, 064, 072 (does not match UI, see TC-019) | W E | 2026-11-20 |
| 25 | Helper: columns of cost and store item tables | INFORMATION_SCHEMA.COLUMNS | SELECT | Schema check | W E | 2026-11-20 |
| 26 | Q11: today's invoices with paid and returned amounts | SalInvoice, SalInvoiceReceiptPayment, SalInvoiceReceiptInvoice, SalReturn | SELECT | TC-011, 014, 015, 016, 048, 049 | W E V (Run 74) | 2026-11-20 |
| 27 | Q12: today's returns with original invoice | SalReturn, SalInvoice | SELECT | TC-012, 016, 046, 048 | W E V (Run 74) | 2026-11-20 |
| 28 | Q13: Inventory Value per store (qty x cost) | InvStoreTransaction, InvItem, InvStore, InvItemBranch, GenLkpDocumentStatus | SELECT | TC-029, 062: 659,992.41 vs screen 78,689.00 (MISMATCH) | W E V | 2026-11-20 |
| 29 | Q14: WOs today, distinct customers, per status | SalWorkOrder, GenLkpDocumentStatus | SELECT | TC-053, 054, 055 | W E V (Run 74) | 2026-11-20 |
| 30 | Q15: inventory grid values for sample items | InvStoreTransaction, InvItem, InvStore, InvStoreItem | SELECT | TC-063, 065 | W E V (Run 74) | 2026-11-20 |
| 31 | KB1: foreign keys of all US-214 tables | sys.foreign_keys, sys.foreign_key_columns, sys.columns | SELECT | Relationship KB (metadata) | W E V | 2026-11-20 |
| 32 | KB2 (R1): SalReturn.InvoiceID resolves to SalInvoice | SalReturn, SalInvoice | SELECT | 38 of 38 resolve, no FK | W E V | 2026-11-20 |
| 33 | KB3 (R2): Stock In/Out RefDocumentID by ref type | InvStockIn, InvStockOut, GenLkpDocumentType, SalInvoice, SalReturn, SalWorkOrder, ProInvoice | SELECT | Ref targets per document type | W E | 2026-11-20 |
| 34 | KB4 (R3): InvStoreTransaction.DocumentID by document type | InvStoreTransaction, GenLkpDocumentType, SalInvoice, SalReturn, ProInvoice, InvStockIn, InvStockOut | SELECT | Sales Return rows point to SalInvoice ID | W E | 2026-11-20 |
| 35 | KB5 (R4): invoice receipts linked to invoices | SalInvoiceReceipt, SalInvoiceReceiptInvoice | SELECT | 346 of 346 linked | W E V | 2026-11-20 |
| 36 | Section F Q4: confirmed invoices and returns per day 16/11 to 21/11 with first and last time (all branches) | SalInvoice, SalReturn | SELECT | TC-078 boundary documents | W E | 2026-11-21 |
| 37 | Section F Q5: branch Alshellah documents 17/11 to 20/11 with exact time | SalInvoice, SalReturn | SELECT | TC-041, 078: INV-121 22:48:48, INV-122 08:51:57, INV-129 15:38:22 | W E V (Run 75) | 2026-11-21 |
| 38 | Section F Q6: branch totals of the custom range 18/11 to 19/11 | SalInvoice, SalReturn | SELECT | TC-041, 078: 7 invoices, 2 refunds, 1,507.59 = Sales tab | W E V (Run 75) | 2026-11-21 |
| 39 | Section E Q1: opening cash 21/11, close 20/11 and linked cash deposit | SalWorkingDay, SalBankDepositWorkingDay, SalBankDeposit | SELECT | TC-075 | W E | 2026-11-21 |
| 40 | Section E Q2: WO-182 carried to the next day and its invoice INV-137 | SalWorkOrder, SalWorkingDay, SalInvoice | SELECT | TC-071, 067 | W E | 2026-11-21 |
| 41 | Section E Q3: net sales 20/11 vs 21/11 for growth | SalInvoice, SalReturn | SELECT | TC-067: -95.6% as on the Overview | W E V | 2026-11-21 |
| 42 | G1: company name column | INFORMATION_SCHEMA.COLUMNS | SELECT | Supporting check | W E | 2026-11-21 |
| 43 | G2: find Demo Company database | sys.databases, GenCompany, SalInvoice, SalReturn | SELECT | TC-010, 033 | W E (not found among readable databases) | 2026-11-21 |
| 44 | G3: Demo Company zero sales | GenCompany, SalInvoice, SalReturn | SELECT | TC-010, 033 | W E V (Run 77, 22/11 13:35; earlier Msg 916 and 229) | 2026-11-21 |
| 45 | G4: ReadUser SELECT permission in Demo Company | 11 dashboard tables (HAS_PERMS_BY_NAME) | SELECT | TC-010, 033 | W E V (1 on all 11 at 13:34; 0 at 13:12 and 13:29) | 2026-11-22 |
| 46 | G5: Demo Company setup readiness | sys.tables, sys.partitions | SELECT | TC-009, 082 | W E (no items, stores, payment methods, numbering) | 2026-11-22 |
| 47 | G6: refunds-only days | SalReturn, SalInvoice | SELECT | TC-082 | W E (0 rows) | 2026-11-22 |
| 48 | G7: sales yesterday and today per branch | GenBranch, SalInvoice, SalReturn, GenBranchPaymentMethod, GenTerminal | SELECT | TC-009 | W E (branch 35B06942 qualifies) | 2026-11-22 |
| 49 | G8: candidate branch, terminal, invoices | GenBranch, GenTerminal, SalInvoice | SELECT | TC-009 | W E (50.00 today, no UI yet) | 2026-11-22 |
| 50 | G9: credit limit columns | INFORMATION_SCHEMA.COLUMNS | SELECT | TC-006 | W E | 2026-11-22 |
| 51 | G10: credit customers | SalCustomer, SalCustomerContract | SELECT | TC-006 | W E (one customer, limit 3.00; credit customers not supported at present, per QA lead 22/11) | 2026-11-22 |
| 52 | G11: identity and zero data of the company open in MAC1 | GenCompany, GenBranch, GenTerminal, InvItem, SalInvoice, SalReturn, SalWorkOrder, SalWorkingDay, payments | SELECT | TC-009, 045, 047, 073, 083, 085 | W E V (IDs match MAC1, all transactions 0, Run 78) | 2026-11-22 |
| 53 | G12: New Sales, payment and stock chain of one sale | SalInvoice, SalReturn, SalInvoiceReceiptPayment, InvStockOut(Item), InvStoreTransaction | SELECT | TC-009, 032 | W E V (Run 79, all match) | 2026-11-22 |
| 54 | H1: sales and returns per period (Run 80) | SalInvoice, SalReturn | SELECT | TC-005, 008, 013, 034, 037, 038, 039, 042, 043, 045, 077 | W E V (Run 80) | 2026-11-22 |
| 55 | H2: Work Orders, payments and open day (Run 80) | SalWorkOrder, SalInvoiceReceiptPayment, SalReturnReceiptPayment, SalWorkingDay | SELECT | TC-017, 021, 023, 053, 054, 058, 061, 071 | W E V (Run 80) | 2026-11-22 |
| 56 | H3: invoices against receipts per month (Run 80) | SalInvoice, SalInvoiceReceiptPayment, SalReturnReceiptPayment | SELECT | TC-059, 086 | W E V (Run 80) | 2026-11-22 |
| 57 | H4: WO of a range, empty day, top selling, COGS (Run 80) | SalWorkOrder, SalInvoice, SalReturn, SalInvoiceItem, InvStoreTransaction | SELECT | TC-026, 031, 032, 045, 047, 055, 083 | W E V (Run 80) | 2026-11-22 |
| 58 | H5: metadata of working day, financial year, adjustment, item (Run 80) | INFORMATION_SCHEMA.COLUMNS, sys.foreign_key_columns | SELECT | TC-021, 029, 038, 087 | W E (Run 80) | 2026-11-22 |
| 59 | H6: day number and opener, fiscal start, inactive item columns (Run 80) | sys.tables, sys.columns, sys.foreign_key_columns | SELECT | TC-021, 038, 087 | W E (Run 80) | 2026-11-22 |
| 60 | H7: name columns of system user and fiscal month (Run 80) | INFORMATION_SCHEMA.COLUMNS | SELECT | TC-021, 038 | W E (Run 80) | 2026-11-22 |
| 61 | H8: open day and opener, financial year start, empty-day receipts (Run 80) | SalWorkingDay, SecSystemUser, GenCompany, GenLkpCompanyFiscalMonth, SalInvoiceReceipt, SalReturnReceipt | SELECT | TC-021, 038, 085 | W E V (Run 80) | 2026-11-22 |
| 62 | H9: opener full name, raw fiscal month (Run 80) | SalWorkingDay, SecSystemUser, GenCompany | SELECT | TC-021, 038 | W E V (Run 80) | 2026-11-22 |
| 63 | H10: inventory snapshot before test transactions (Run 80) | InvStoreTransaction, InvStoreItem, InvItem, InvItemBranch, GenLkpDocumentStatus | SELECT | TC-019, 020, 029, 062, 063, 064, 072 | W E (Run 80) | 2026-11-22 |
| 64 | H11: INV-140 totals, lines, payments and stock chain (Run 80) | SalInvoice, SalInvoiceItem, SalInvoiceReceiptInvoice, SalInvoiceReceiptPayment, InvStockOut, InvStockOutItem, InvStoreTransaction | SELECT | TC-005, 025, 027, 031, 068, 074, 079 | W E V (Run 80) | 2026-11-22 |
| 65 | H12: INV-141 totals, line, payment and stock chain (Run 80) | SalInvoice, SalInvoiceItem, SalInvoiceReceiptInvoice, SalInvoiceReceiptPayment, InvStockOut, InvStockOutItem, InvStoreTransaction | SELECT | TC-022, 023, 046, 074, 076 | W E V (Run 80) | 2026-11-22 |
| 66 | H13: day totals after RTN-20, money per method, return stock chain, COGS (Run 80) | SalInvoice, SalReturn, SalInvoiceReceiptPayment, SalReturnReceiptPayment, InvStockIn, InvStockInItem, InvStoreTransaction | SELECT | TC-005, 012, 016, 022, 027, 031, 034, 046, 068, 069, 074, 076, 077 | W E V (Run 80) | 2026-11-22 |
| 67 | H14: documents of the day with lines, qty, methods, stock (Run 80) | SalInvoice, SalReturn, SalInvoiceItem, SalInvoiceReceiptInvoice, SalInvoiceReceiptPayment, InvStoreTransaction | SELECT | TC-068, 079 | W E V (Run 80) | 2026-11-22 |
| 68 | H15: Work Orders of the day for the export comparison (Run 80) | SalWorkOrder, GenLkpDocumentStatus | SELECT | TC-051, 057, 081 | W E V (Run 80) | 2026-11-22 |
| 69 | H16: searched items and quantity per store (Run 80) | InvStoreTransaction, InvItem, InvStore | SELECT | TC-066 | W E V (Run 80) | 2026-11-22 |
| 70 | H17: foreign keys of Work Order for customer, vehicle, bay, technician (Run 80) | sys.foreign_key_columns, sys.tables, sys.columns | SELECT | TC-056 | W E (Run 80) | 2026-11-22 |
| 71 | H18: WO info row values and VIN (Run 80) | SalWorkOrder, SalCustomer, AutVehicle, AutBay, SecSystemUser, GenLkpDocumentStatus | SELECT | TC-056 | W E V (Run 80) | 2026-11-22 |
| 72 | H19: Inventory grid values, min and max (Run 80) | InvItem, InvStore, InvStoreItem, InvStoreTransaction | SELECT | TC-065 | W E V (Run 80) | 2026-11-22 |
| 73 | H20: WO-193 completed, invoice, counts, stock (Run 80) | SalWorkOrder, SalInvoice, SalInvoiceReceiptInvoice, SalInvoiceReceiptPayment, InvStoreTransaction | SELECT | TC-084 | W E V (Run 80) | 2026-11-22 |
| 74 | H21: purchase invoice and return columns (Run 80) | INFORMATION_SCHEMA.COLUMNS | SELECT | TC-035, 036 | W E (Run 80) | 2026-11-22 |
| 75 | H22: Input VAT, Net VAT Payable, purchase stock chain (Run 80) | ProInvoice, ProReturn, SalInvoice, SalReturn, InvStockIn, InvStockInItem, InvStoreTransaction | SELECT | TC-035, 036 | W E V (Run 80) | 2026-11-22 |
| 76 | H23: packing size of the purchased item (Run 80) | InvItem, InvItemUnit | SELECT | TC-035 | W E V (Run 80) | 2026-11-22 |
| 77 | H24: purchase return, Input VAT after it, stock out (Run 80) | ProReturn, ProInvoice, InvStockOut, InvStockOutItem, InvStoreTransaction | SELECT | TC-035 | W E V (Run 80) | 2026-11-22 |
| 78 | H25: Stock Out headers of the purchase return (Run 80) | InvStockOut, InvStockOutItem | SELECT | TC-035 | W E V (Run 80) | 2026-11-22 |
| 79 | H26: branch payment methods, inactive item, other branches, users (Run 80) | GenBranchPaymentMethod, GenLkpPaymentMethod, InvItem, InvStoreTransaction, SalInvoice, SalReturn, SalWorkOrder, SecSystemUser | SELECT | TC-003, 004, 028, 087 | W E V (Run 80) | 2026-11-22 |
| 80 | H27: cancelled payment not saved, payments per method (Run 80) | SalInvoice, SalInvoiceReceiptPayment, SalReturnReceiptPayment, GenLkpPaymentMethod, InvStoreTransaction | SELECT | TC-028 | W E V (Run 80) | 2026-11-22 |
| 81 | H28: existing adjustment numbers before Submit (Run 80) | InvStockAdjustment | SELECT | TC-063 | W E (Run 80) | 2026-11-22 |
| 82 | H29: baseline of old TO_11000005 and Tire balance (Run 80) | InvStoreTransaction, InvStockIn, InvStockOut, InvItem | SELECT | TC-063 | W E (Run 80) | 2026-11-22 |
| 83 | H30: T9 chain, duplicate adjustment number (Run 80) | InvStockAdjustment, InvStockIn, InvStockInItem, InvStoreTransaction, InvItem | SELECT | TC-063, 030 | W E V (Run 80) | 2026-11-22 |
| 84 | H31: 23/11 before any sale, yesterday sales, working days, WO-189 (Run 80) | SalInvoice, SalReturn, SalWorkOrder, SalWorkingDay, GenLkpDocumentStatus | SELECT | TC-067, 033, 073, 071 | W E V (Run 80) | 2026-11-23 |
| 85 | H32: RTN-21 refund-only day, cash, stock chain (Run 80) | SalReturn, SalReturnReceipt(Payment), SalInvoice, SalWorkingDay, InvStockIn(Item), InvStoreTransaction | SELECT | TC-082, 075, 069 | W E V (Run 80) | 2026-11-23 |
| 86 | H33: invoices and returns 22-23/11 by document date, discounts, refund methods (Run 80) | SalInvoice, SalReturn, SalInvoiceReceiptPayment, SalInvoiceReceiptInvoice, SalReturnReceipt(Payment), GenLkpPaymentMethod | SELECT | TC-046, 069, 079 | W E, failed (replaced by H34) | 2026-11-23 |
| 87 | H34: H33 corrected (refund receipt ID cast) (Run 80) | SalInvoice, SalReturn, SalInvoiceReceiptPayment, SalInvoiceReceiptInvoice, SalReturnReceipt(Payment), GenLkpPaymentMethod | SELECT | TC-046, 069, 079 | W E V (Run 80) | 2026-11-23 |
| 88 | H35: Work Orders of 23/11 and WO-189 dates after completion (Run 80) | SalWorkOrder, GenLkpDocumentStatus, SalWorkingDay, SalInvoice | SELECT | TC-071 | W E, failed (replaced by H36) | 2026-11-23 |
| 89 | H36: Work Orders of 23/11 and WO-189 dates after completion (Run 80) | SalWorkOrder, GenLkpDocumentStatus, SalWorkingDay | SELECT | TC-071 | W E V (Run 80) | 2026-11-23 |
| 90 | H37: November documents in the first or last hour of a day (Run 80) | SalInvoice, SalReturn | SELECT | TC-078 | W E (Run 80) | 2026-11-23 |
| 91 | H38: Sales range counts 14/11 and 14-20/11 with boundary documents (Run 80) | SalInvoice, SalReturn | SELECT | TC-078 | W E V (Run 80) | 2026-11-23 |
| 92 | H39: Close Day 23/11 and cash deposit TO_11000005 (Run 80) | SalWorkingDay, SalBankDepositWorkingDay, SalBankDeposit, GenLkpDocumentStatus | SELECT | TC-075 | W E V (Run 80) | 2026-11-23 |

## General: MAC1 local Sync storage, SQLite copy ([file](Database-Queries/General-Queries.sql))

| # | Query purpose | Tables | Operation | Verifies | Status | Added |
|---|---|---|---|---|---|---|
| G-L1 | Sync and Work Order schema | sqlite_master | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-L2 | Upload rows by status and format | SyncUpload, SyncLkpUploadStatus | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-L3 | Local Work Order count | SalWorkOrder | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-L4 | Waiting upload and delete rows | SyncUpload, SyncDelete | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-L5 | Local rows of WO-TO_11000184 vs recovered JSON | SalWorkOrder and child tables | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-L6 | Live capture of upload rows | SyncUpload | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-S1 | Server state of WO-TO_11000185 after upload | SalWorkOrder and child tables, InvStockOut, InvStoreTransaction | SELECT | WO one JSON check | W E V | 2026-11-22 |
| G-L7 | Car Wash item type | InvItem, InvItemService | SELECT | WO one JSON check | W E | 2026-11-22 |
| G-Q1 | Stock Out headers with no lines and their source document | InvStockOut, InvStockOutItem, SalWorkOrder, SalInvoice, GenLkpDocumentStatus | SELECT | Question e-20261120-009 | W E, second part failed (replaced by G-Q1b) | 2026-11-23 |
| G-Q1b | Count of Stock Outs with and without lines (G-Q1 second part corrected) | InvStockOut, InvStockOutItem | SELECT | Question e-20261120-009 | W | 2026-11-23 |
| G-Q2 | Inventory counts per item x store, per category | InvStoreTransaction, InvStoreItem, InvItem | SELECT | Answer to e-20261115-154 / e-20261120-075 (TC-019, 020, 062, 063, 064, 072, 087) | W | 2026-11-23 |
| G-T1 | Stock Out headers from 22/11 (SELECT *) | InvStockOut | SELECT | e-20261120-009 | W | 2026-11-23 |
| G-T2 | Stock Out lines of G-T1 (SELECT *) | InvStockOutItem | SELECT | e-20261120-009 | W | 2026-11-23 |
| G-T3 | Work Orders from 22/11 (SELECT *) | SalWorkOrder | SELECT | e-20261120-009 | W | 2026-11-23 |
| G-T4 | Store setup rows of the branch stores (SELECT *) | InvStoreItem | SELECT | item x store counts | W | 2026-11-23 |
| G-T5 | Quantity per item x store | InvStoreTransaction | SELECT | item x store counts | W | 2026-11-23 |
| G-T6 | Item x store counts split by item status, item kind and category | InvStoreTransaction, InvStoreItem, InvItem, InvItemService | SELECT | item x store counts vs Inventory tab | W | 2026-11-23 |
| G-T7 | Columns of stock in and stock out tables | INFORMATION_SCHEMA.COLUMNS | SELECT | item x store counts from stock documents | W | 2026-11-23 |
| G-T8 | Item x store counts from Stock In and Stock Out documents | InvStockIn, InvStockInItem, InvStockOut, InvStockOutItem, InvItemUnit, InvItem, InvItemService, InvStoreItem | SELECT | item x store counts vs Inventory tab | W | 2026-11-23 |
| G-T9 | Stock In source types, and stock items sold with no Stock In at all | InvStockIn, InvStockInItem, InvStockOut, InvStockOutItem, InvItemUnit, InvItem, InvItemService, InvStore | SELECT | items without opening balance or adjustment | W | 2026-11-23 |
| G-T10 | Inventory counts with the developer rules (distinct items, item type 1 and 3, branch items and stores, Min > 0) | InvItem, InvItemBranch, InvStore, InvStoreBranch, InvStoreTransaction, InvStoreItem | SELECT | TC-019, 020, 062, 063, 064, 072, 087 vs Inventory tab | W | 2026-11-23 |
| G-T11 | Negative and Out of Stock items by name, store and quantity (developer rules) | InvItem, InvItemBranch, InvStore, InvStoreBranch, InvStoreTransaction, InvStoreItem | SELECT | Negative 29 vs 22, Out of Stock 11 vs 12 | W | 2026-11-23 |
| G-T12 | Inventory counts with the developer rules, branch stores only | InvItem, InvItemBranch, InvStoreBranch, InvStoreTransaction, InvStoreItem | SELECT | whether all-branch stores cause the Negative / Out of Stock difference | W | 2026-11-23 |

## Table lookup

| Table | Stories |
|---|---|
| SalInvoice, SalReturn, SalInvoiceItem, SalInvoiceItemCost, SalReturnItem, SalReturnItemCost, SalInvoiceReceiptInvoice | 214 |
| SalInvoiceReceipt(Payment), SalReturnReceipt(Payment), GenLkpPaymentMethod | 214 |
| SalWorkingDay, SalWorkOrder, GenLkpDocumentStatus | 214 |
| InvStoreTransaction, InvItem, InvStore, InvStoreItem, InvItemBranch, InvItemUnit | 214 |
| InvStockIn, InvStockOut, InvStockInItem, InvStockOutItem, InvItemBatch, InvItemBatchCost, InvItemService | 214 |
| ProInvoice, SalPriceListItem, GenLkpDocumentType, InvLkpItemType | 214 |
| SalBankDeposit, SalBankDepositWorkingDay, SalWorkingDay (close, deposit, open), SalWorkOrder (WorkingDayID, ShiftedFromWorkingDayID) | 214 |
| SyncUpload, SyncDelete, SalWorkOrder (local SQLite) | General |
