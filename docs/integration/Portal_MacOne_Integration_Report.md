# Portal and MacOne App Integration Report

| Item | Value |
|---|---|
| Date | 14 November 2026 |
| Environment | QA Company (portal at QA_BASE_URL, MacOne app version 1.2.484) |
| Branch | Alshellah, terminal M-ALSHELLAH, day TO_11000025 |
| Status | Complete. One optional check was not run (section 7) |

## 1. Purpose

This report maps which data moves between the myShop **Portal** and the **MacOne app** (Windows POS), in which direction, and whether it arrives correctly. Each link was tested with real data in QA.

## 2. Summary

| No | Result | Count |
|---|---|---|
| 2.1 | Links verified and working | 22 |
| 2.2 | Links working with an issue | 9 |
| 2.3 | Links not working | 1 |
| 2.4 | Links deferred (feature not finished) | 1 |
| 2.5 | Links with no screen on the other side | 2 |
| 2.6 | Links not testable in QA | 1 |
| 2.7 | Findings (section 6): open 13, bug draft 2, business rule 1, deferred 1, closed 1 | 18 |

## 3. How the two systems are connected

| No | Rule | Details |
|---|---|---|
| 3.1 | Portal to MacOne needs Sync | Master data changed in the portal appears in the app only after Menu, System and Devices, **Sync**. Sync once failed with a database error while package work orders were pending (finding 6.17) |
| 3.2 | MacOne to Portal is immediate | Documents and records created in the app appear in the portal at once, without Sync |
| 3.3 | The Branch record is the hub | The portal Branch holds the payment methods, bays, stores and warehouse rules that the app uses |
| 3.4 | Workorder catalog needs a Business Category | A portal item shows in the Workorder catalog only when it is linked to a Business Category (General, Business Category, for example OilChangeServices) or its hidden flag **Is Apply To All Business Category** is true. Without it, the item shows in My items only (finding 6.11) |
| 3.5 | Item price comes from the customer or the branch price list | The Workorder takes the price from the customer Default Price List when the customer has one, otherwise from the branch Default Price List. Seen in QA: with QA Auto Customer 1114 linked to Main Price List, Car Wash (not on that list) dropped to 0. Branch Alshellah uses "Default", which does not hold QA_INT Service 1114 |
| 3.6 | The app should sell from the branch default store | Branch, Store tab: the store with **Is Default** true is the one the app uses. For Alshellah this is Mohammad Store Branch - 2, with Apply To All Item false and 6 items. The Workorder catalog should offer only those 6 items, but today it shows all items (finding 6.6) |
| 3.7 | A discount needs a Reason and a Tax Procedure | When Is Mandatory Reason is true the portal will not submit without a row in Reasons, and it shows a warning at the bottom of the page. A Transaction discount without a Tax Procedure reaches the app but cannot be selected (finding 6.2) |
| 3.8 | A service package is built from three portal screens | Item (Type Service Package, Service Package tab with Service Pricing Type and services), Service Item Group (a Submitted group of parts with an Item Kind) and Price List. Only Submitted groups appear in the package lookup. Item Kind is hidden on the Item form, so every item is General and a package row must use Item Kind General |

## 4. Portal to MacOne (master data)

| No | Data | Portal screen | MacOne screen | Test | Result | Evidence |
|---|---|---|---|---|---|---|
| 4.1 | Customer | Sales, Customer List | Workorder vehicle search, Customers | Created QA Auto Customer 1114 | Pass | portal customer_submitted, app wo_new_cart |
| 4.2 | Vehicle | Automotive, Vehicle | Workorder vehicle search | Created 4114BDR | Pass | app wo_new_search |
| 4.3 | Item in My items | Inventory, Item | Cash and Stock, My items | Created QA_INT Service 1114 | Pass | app int_mac_myitems |
| 4.4 | Item in Workorder catalog | Inventory, Item and Price List | Workorder item search | Same item. Missing until Is Apply To All Business Category was set to true, then shown after Sync. Still shown after the Document Default Unit row was removed | Pass with issue (finding 6.11) | app int_mac_wo_item_after_minprice, int_mac_wo_item_found, int_mac_wo_item_found_without_ddu |
| 4.5 | Item cancelled | Inventory, Item, Cancel | Dashboard Inventory | Cancelled Air Filter 039 | Pass after Sync | POS Dashboard report, TC-POS-087 |
| 4.6 | Vehicle make | Automotive, Vehicle Make | Add New Vehicle, Make list | Created QA_INT Make | Pass | app int_mac_makes |
| 4.7 | Bank | Finance, Bank | Cash Deposit, Select Bank | Created QA_INT Bank | Pass | app int_mac_banks |
| 4.8 | Branch stores | Branch, Store tab | Dashboard Inventory, Stock Adjustment | Two stores. Is Default is Mohammad Store Branch - 2 | Pass | portal int_portal_branch_store, dashboard report |
| 4.9 | Branch bays | Branch, Bays tab | Workorder, Bay | Added Bay - QA_INT, capacity 3. App shows it as (0/3) and a WO was assigned to it | Pass | app int_mac_bays |
| 4.10 | Branch payment methods | Branch, Financial, Payment Methods | Payment screen | Hala, Visa, Cash, Mada, Master | Pass with issue (finding 6.9) | app int_mac_payment |
| 4.11 | Refund methods | Branch, Payment Methods, Is Allow Refund | Return Invoice, Return Method | Mada allows refund in the portal. Checked after Sync | Pass with issue: Cash only, as the business rule says, but the portal flag has no effect (finding 6.4) | app int_mac_refund_methods |
| 4.12 | Discount | Sales, Discount | Workorder, Discount | QA Trans Disc 50 (Amount 50) listed with its dates and range, and deducts 50.00 SAR. The highlighted card shows "50%" | Pass with issue (finding 6.13) | app D613_app_selected_percent, D613_app_unselected_ok, D613_app_discount_annotated |
| 4.13 | New discount | Sales, Discount | Workorder, Discount | Created QA_INT Disc 10 (10 percent) with Reason "QA test reason". It showed in the app with its reason after Sync, but Select did nothing until a Tax Procedure was set. Then it deducted 6.52 from 65.22 | Pass with issue (finding 6.2) | app int_mac_disc10_list, int_mac_disc10_applied |
| 4.14 | Promotion | Sales, Promotion | Workorder, Promotion | Promotion button pressed twice with an item in cart | Deferred: the feature is not finished yet (finding 6.12) | app int_mac_promotions_a |
| 4.15 | Tax procedure | Sales, Tax Procedure | Cart and invoice tax | 15 percent applied on taxable items | Pass | dashboard report |
| 4.16 | Store item assignment | Store, Items tab | Workorder catalog and sales | Default store Branch 2 has Apply To All Item false and 6 items. The Workorder catalog shows all items (for example NEW-ITEM-0047 to 0054 and QA_INT Service 1114), and they can be sold | **Fail** (finding 6.6) | portal int_store_b2_items, app int_mac_wo_all_items, portal Inventory Balance export |
| 4.17 | Company data | General, Company | Administration, Company Profile | Same name, business type, country | Pass | app map_CompanyProfile |
| 4.18 | Customer price list | Customer, Financial, Default Price List | Workorder item prices | Set QA Auto Customer 1114 to Main Price List. After Sync the item showed 75.00 (65.22 plus tax) and Car Wash, which is not on that list, showed 0 | Pass | portal int_cust_pricelist, app int_mac_wo_prices_custpl |
| 4.19 | Service package | Item (Service Package), Service Item Group, Price List, Business Category | Workorder, Service package screen | Created QA_INT Package 1114: service QA_INT Service 1114, oil group QA_INT Oil Group, Labor and Item (fixed), price 100 with tax. After Sync it showed at 100.00, and the app asked to choose one oil from the group | Pass with issue (finding 6.14) | app int_mac_pkg_choose_oil, int_mac_pkg_qty64, portal int_pkg_service_row |
| 4.20 | Service Item Group | Inventory, Service Item Group | Service package oil choice | Group with 2 oils. Both listed in the app, including the 4L in Box although the package row asks for Liter, so the unit is not used as a filter | Pass | app int_mac_pkg_choose_oil |
| 4.21 | Service package, Labor Only (Summation) with Service Package Items | Item (Service Package), Service Item Group, Price List | Workorder, Service package screen | QA_INT Package Sum 1114 with no price of its own: services 75 and 60, items Liter x2 from QA_INT Oil Group. The app showed the oil at 34.78 (17.39 x 2) and the cart at 175.00 = 152.17 plus 22.83 tax, which is 75 + 60 + 40 | Pass with issue (finding 6.14) | video Captures 2026-11-14 16-55-13 |

## 5. MacOne to Portal (documents and records)

| No | Data | MacOne screen | Portal screen | Test record | Result | Evidence |
|---|---|---|---|---|---|---|
| 5.1 | Sales invoice | Workorder, Payment | Sales, Invoice | INV TO_11000082 and INV TO_11000083 | Pass | portal int_P01, int_T1 |
| 5.2 | Sales return | Operations, Return Invoice | Sales, SalReturn | RTN TO_11000016 | Pass | portal int_P02 |
| 5.3 | Work order | Workorder | Sales, Work Order | WO TO_11000097 and WO TO_11000098 | Pass | portal int_P03, int_T2 |
| 5.4 | Working day | Open Day | Sales, Working Day | TO_11000025 | Pass | portal int_P04 |
| 5.5 | Stock adjustment | Cash and Stock, Stock Adjustment | Inventory, StockAdjustment | ST TO_11000005 | Pass | portal int_P05 |
| 5.6 | Opening balance | Cash and Stock, Opening Balance | Inventory, InvOpeningBalance | OP TO_11000014 | Pass | portal int_P06 |
| 5.7 | Purchase invoice | Operations, Purchase Invoice | Procurement, Invoice | PR TO_11000002 | Pass | portal int_P07 |
| 5.8 | Customer | Customers, Add a new customer | Sales, Customer List | QA_INT POS Customer | Pass | portal int_R3 |
| 5.9 | Vehicle | Add New Vehicle | Automotive, Vehicle | 4115LGZ | Pass | portal int_R1 |
| 5.10 | Vehicle model | Add New Vehicle, Add New Model | Automotive, Vehicle Model | QA_INT Model | Pass with issue (finding 6.5) | portal int_R2 |
| 5.11 | Item and its price | My items, New item | Inventory, Item and Main Price List | TO_11000001, price 60 stored as 52.17 plus tax | Pass | portal int_R4, int_pl_saved |
| 5.12 | Purchase return | Operations, Return Purchase Invoice | none found | TO_11000001 | No portal screen | app map_ReturnPurchaseInvoice |
| 5.13 | Cash deposit | Cash and Stock, Cash Deposit | none found | TO_11000003 | No portal screen | app map_CashDeposit |
| 5.14 | Electronic invoice | Payment | Sales, ElectronicInvoice | INV TO_11000082 | Not created, ZATCA inactive in QA | portal int_P08 |
| 5.15 | Invoice with a package | Workorder, Payment | Sales, Invoice and Work Order | INV TO_11000084 and WO TO_11000100: one line QA_INT Package 1114, quantity 1, 86.96 plus 13.04 = 100. The service row arrived at 0, but the chosen oil (Engine Oil 15W-40 1L) is missing from the package items | Pass with issue (finding 6.15) | portal int_inv84, app int_mac_pkg_inv84 |

## 6. Findings

| No | Finding | Severity | Status | Where |
|---|---|---|---|---|
| 6.1 | Portal forms do not save and show no message when a hidden requirement is missing. Customer needs a Billing Address, Item needs a Unit | Medium | Open | Portal, Customer and Item |
| 6.2 | A Transaction discount submitted without a Tax Procedure reaches the app, but Select does nothing and shows no message. The portal allows submitting it without a Tax Procedure. The earlier failed save was a missing Reason, which the portal reports with a warning, so that part is not a defect | Medium | Open | Portal Discount and app Workorder, Discounts |
| 6.3 | Many portal lists show only Document Type and Document Status, with no number, date or customer, so records are hard to find | Low | Open | Portal lists for Vehicle, Sales Return, Work Order, Stock Adjustment, Purchase Invoice |
| 6.4 | Refunds are Cash only by business rule (confirmed 13 November). The portal still lets Mada set Is Allow Refund to true, and the app ignores it, also after Sync. The flag misleads users | Low | Open | Portal Branch and app Return Invoice |
| 6.5 | A vehicle model created in the app is saved in the portal with status New instead of Submitted | Low | Open | Portal Vehicle Model |
| 6.6 | The Workorder catalog is not filtered by the default store. Default store Branch 2 has Apply To All Item false and only 6 items, but the catalog shows all items, and the app sold items outside the store and left negative balances | High | Open. Check whether the team bug about wrong store data covers it | Portal Store and app Workorder catalog |
| 6.7 | App work orders took stock from Branch 2 although Document Type Warehouses maps Work Order to Warehouse Store | None | Closed: Branch 2 is the Is Default store, so the stock source is correct. The item list problem is finding 6.6 | Portal Branch, Store tab |
| 6.8 | Vehicle form captions are technical names, for example FK_AutVehicle_SalCustomer and VehiclePlate | Low | Open | Portal Vehicle form |
| 6.9 | Payment method names differ: portal Visa is Credit Card in the app, portal Mada is Mada Pay in the app | Low | Open | App Payment screen |
| 6.10 | In the app, a new vehicle with a make that has no models cannot be created. Create does nothing and shows no message until a model is added | Low | Open | App Add New Vehicle |
| 6.11 | An item with no Business Category does not show in the Workorder catalog. This is the business design (rule 3.4). Open question for the business: should the Item form show the Is Apply To All Business Category flag, which is hidden today | None | Business rule. Flag question sent to business | Portal Item and Business Category |
| 6.12 | The Workorder Promotion button does nothing and shows no message, although the portal has Promotion 1 | Medium | Deferred: feature not finished, retest later | App Workorder |
| 6.13 | An Amount discount shows as a percentage when its card is highlighted. QA Trans Disc 50 shows "50%" when highlighted and 50 SAR when not. The cart deducts 50.00 SAR correctly | Low | Bug draft ready, waiting for review | App Workorder, Discounts |
| 6.14 | Any service package is added to the cart with quantity 64 instead of 1, so the line total is 64 times the price (6,400.26 for a 100 package). Seen with QA_INT Package 1114 and with the existing Package 2 services. The quantity varies: 64 twice, 7 once, and 32 with QA_INT Package Sum 1114 (recorded on video). Workaround: press minus, then type 1 on the keypad | High | Open | App Workorder, Service package |
| 6.15 | The oil chosen in the package screen does not reach the portal. The work order line has the package and its service, but SalWorkOrderServicePackageItems is empty, so the stock effect of the part is unclear | Medium | Open, needs dev check | Portal Work Order line |
| 6.16 | A discount selected once on a work order stays attached. After Cancel in the Discounts panel and Clear cart, QA Trans Disc 50 was applied again when a new item was added | Medium | Open | App Workorder, Discounts |
| 6.17 | Sync fails every time while a work order with a service package is pending: DELETE conflicted with FK_SalWorkOrderService_SalWorkOrderItem (dbo.SalWorkOrderService, WorkOrderItemID). No portal change could reach the terminal until the data was fixed. Seen 3 times in a row with WO TO_11000099 pending with QA_INT Package 1114. Not reproduced after the data fix in 4 attempts on video: package WO pending, Clear cart with a package, Save as Draft, and re-saving the package edit screen | High | **Reproduced** with two package WOs pending (error on FK_SalWorkOrderItemBatch_SalWorkOrderItem). Steps in Bug_Repro_Sync_Fails_WorkOrder_Lines_Lost.md. Bug draft needs the new steps | App Sync |
| 6.18 | Work order lines move between open work orders. QA_INT Package Sum 1114 was added to WO TO_11000102 (175). After Syncs it was gone from WO 102 (0 lines in app and portal, header still 175) and appeared in WO TO_11000099 and in WO TO_11000096 (another customer, 1111AAA). WO 96 also holds QA_INT Package 1114 x70 (7,000.28). Header totals no longer match the lines (WO 99 = 7,175.28) | High | **Reproduced** together with 6.17: after the failed Sync, WO-103 lost its line, voided WOs 96, 99 and 100 came back Pending, and WO-99 showed Package 1114 x72. Steps in Bug_Repro_Sync_Fails_WorkOrder_Lines_Lost.md | App carts and Sync, Portal Work Order |

## 7. Checks not run

| No | Check | Reason |
|---|---|---|
| 7.1 | Change one setting in the app Operational Setting and compare with the portal Setting list | Skipped by choice. The setting is shared by all users of the company, and the read only comparison is already recorded in 8.1.14 |

## 8. Screen inventory

### 8.1 MacOne app screens

| No | Menu | Screen | What it does | Data source |
|---|---|---|---|---|
| 8.1.1 | Operations | Purchase Invoice | Create purchase invoices | Portal suppliers, items, stores |
| 8.1.2 | Operations | Return Purchase Invoice | Return to supplier | Portal suppliers, items |
| 8.1.3 | Operations | Return Invoice | Full return of a sales invoice, Cash only | App invoices |
| 8.1.4 | Operations | Vouchers List | All documents of the branch | App documents |
| 8.1.5 | Cash and Stock | Opening Balance | Item opening quantities | Portal items, stores |
| 8.1.6 | Cash and Stock | Cash Deposit | Deposit cash of past days | Portal banks |
| 8.1.7 | Cash and Stock | Stock Adjustment | Stock in and out | Portal items, stores, reasons |
| 8.1.8 | Cash and Stock | My items | View and create items | Portal items, groups, units, tax |
| 8.1.9 | Customers and Vehicles | Customers | View and create customers | Portal customers |
| 8.1.10 | Customers and Vehicles | Add New Vehicle | Create vehicles, models, engines | Portal vehicle groups, makes, models |
| 8.1.11 | Reports | Report | 15 reports by category | Server reports |
| 8.1.12 | Administration | Users | Company users and invitations | Company users |
| 8.1.13 | Administration | Company Profile | Company, branches, subscription | Portal company |
| 8.1.14 | Administration | Operational Setting | Workflow, negative stock, plate scan, bay tracking | Portal settings |
| 8.1.15 | System and Devices | Sync | Pull portal changes | Portal |
| 8.1.16 | System and Devices | App Setting | Language and printers | Local and portal print documents |
| 8.1.17 | Quick Access | Open Day and Close Day | Working day and cash register | App |
| 8.1.18 | Quick Access | Workorder | Vehicle search, bay with capacity and Add Bay, cart, discount, promotion, payment | Portal customers, vehicles, items, bays, discounts |
| 8.1.19 | Dashboard | Overview, Sales, WO info, Cash, Inventory | Branch KPIs | App documents and portal items |

### 8.2 Portal screens linked to the app

| No | Module | Screens |
|---|---|---|
| 8.2.1 | Automotive | Vehicle, Vehicle Make, Vehicle Model, Vehicle Engine, Vehicle Group, Bay Type |
| 8.2.2 | Inventory | Item, Item Group, Unit, Store, StockAdjustment, InvOpeningBalance, Stock Adjustment Type, Service Item Group |
| 8.2.3 | Sales | Customer List, Customer Group, Discount, Promotion, Price List, Tax Procedure, Invoice, SalReturn, Work Order, Working Day, ElectronicInvoice |
| 8.2.4 | Procurement | Supplier, Invoice |
| 8.2.5 | Finance | Bank, Bank Account |
| 8.2.6 | General | Branch, Company, Terminal, Setting, Print Document, Document Number, E Invoice Certificate |
| 8.2.7 | Security | System User |

### 8.3 Portal screens with no app link found

| No | Module | Screens |
|---|---|---|
| 8.3.1 | Finance | Chart Of Account, General Journal, Journal Entry Notice, Cost Center, Account Type Category, Voucher Major Type, Voucher Minor Type, Credit Card Type (empty), Bank Branch |
| 8.3.2 | Hr | Department, Employee, Employee Group, Job Position |
| 8.3.3 | Sales | Competitor, Customer Contract, Customer Journey, Customer Visit, Order Customer, Route, SalOrder, Service Provider screens |
| 8.3.4 | Other | KPI, Analysis, Dashboards, Audit Event, Workflow, State Machine, User Request, Franchise, Working Hour, Term And Condition |

## 9. Test data created or changed

| No | System | Record |
|---|---|---|
| 9.1 | Portal | Customer QA Auto Customer 1114, mobile 966550011140. Default Price List set to Main Price List |
| 9.2 | Portal | Vehicle 4114BDR, BMW M5 2026 |
| 9.3 | Portal | Item QA_INT Service 1114, number QAINT1114S. Changed during finding 6.11: Min Service Price 75 to 0, Item Sort Order 999 to 0, Service Time 30 to 0, Is Apply To All Business Category set to true. A Document Default Unit row was added for a test, then removed |
| 9.4 | Portal | Main Price List row for QA_INT Service 1114, price 65.22 plus tax |
| 9.5 | Portal | Vehicle make QA_INT Make |
| 9.6 | Portal | Bank QA_INT Bank |
| 9.7 | Portal | Bay "Bay - QA_INT" on branch Alshellah, type Washing Bay, capacity 3 |
| 9.8 | App | Day TO_11000025, opened without closing 13 November |
| 9.9 | App | WO TO_11000097 with INV TO_11000082, Cash 200 |
| 9.10 | App | WO TO_11000098 on Bay - QA_INT with INV TO_11000083, Car Wash, Cash 100 |
| 9.11 | App | WO TO_11000099 created empty, then deleted. The dashboard counts it as Voided |
| 9.12 | App | Customer QA_INT POS Customer |
| 9.13 | App | Vehicle 4115LGZ with model QA_INT Model |
| 9.14 | App | Item TO_11000001, name contains stray characters from automation input |
| 9.15 | App | WO TO_11000100 for 4114BDR on Bay - QA_INT, saved as Draft with no items. Discounts were tried on it and then removed |
| 9.17 | Portal | Service Item Group QA_INT Oil Group (General): Engine Oil 5W-40 4L and Engine Oil 15W-40 1L |
| 9.18 | Portal | Service package QA_INT Package 1114 (QAINT1114P): Labor and Item (fixed), service QA_INT Service 1114 with QA_INT Oil Group 1 Liter, unit Each, Main Price List 86.96 plus tax, Business Category OilChangeServices |
| 9.19 | App | WO TO_11000100 paid: INV TO_11000084, QA_INT Package 1114 with Engine Oil 15W-40 1L, Cash 100 |
| 9.20 | Portal | Service package QA_INT Package Sum 1114 (QAINT1114PS): Labor Only (Summation), services QA_INT Service 1114 and aQA_INT POS Servicea60, items Liter x2 from QA_INT Oil Group, no price list row. Engine Oil 5W-40 1L added to Main Price List at 17.39 and to QA_INT Oil Group |
| 9.21 | App | WO TO_11000102 for 4114BDR, Pending with QA_INT Package Sum 1114 at 175.00 |
| 9.16 | Portal | Discount QA_INT Disc 10: Transaction, 10 percent, range 1 to 100, Reason "QA test reason", Tax Procedure 15%, apply to all document types, branches and customers |

## 10. Evidence

Screenshots are in the [evidence](./evidence/) folder, split into **portal** and **macone-app**. Each table row names its screenshot.
