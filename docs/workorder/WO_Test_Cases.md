# MAC1 Workorder Test Cases (QA)

| Item | Value |
|---|---|
| Version | 1, 20 November 2026 |
| Test Plan (DevOps) | "MAC1 - Workorder (QA)" plan 2184, root suite 2185, not linked to a story. Uploaded 20/11/2026: 9 suites (2186 to 2194), Shared Steps SS-WO-01 2195, SS-WO-02 2196, SS-WO-03 2197, Test Cases TC-WO-001 to TC-WO-084 = IDs 2198 to 2258 (map in WO_Test_Cases_DevOps_IDs.json) |
| Build used for expected values | MAC1 1.2.498 |
| Scope | The daily Workorder flow and everything that affects money and stock. Priority 1 and 2 only |
| Out of scope for now | Promotion, Product Package (not finished), layout and field validation (Priority 3, later) |
| Tag on every case | `Workorder`, the suite name, `Positive` or `Negative`, `Calculation` when a total is checked, `Provisional` (story not complete) |

## 1. Test data

| No | Data | Current QA value |
|---|---|---|
| 1.1 | Branch, terminal, user | Alshellah, M-ALSHELLAH, m.alshellah |
| 1.2 | Vehicle without a customer price list | 1111AAA, choose the BMW M5 row (the search also returns a BYD) |
| 1.3 | Customer with its own price list and vehicle | QA Auto Customer 1114 (Main Price List), vehicle 4114BDR |
| 1.4 | Bays | Bay - 01 (capacity 2), Bay - QA_INT (3), Bay - 02 (4) |
| 1.5 | Service with VAT | Car Wash, 100.00 incl. VAT (86.96 + 13.04) |
| 1.6 | Product with stock | Tire - Item, 500.00 incl. VAT (434.78 + 65.22), cost 55.00, store Mohammad Store Branch - 2 |
| 1.7 | Second service | QA_SST Brake Check, 25.00 incl. VAT (21.74 + 3.26) |
| 1.8 | Out of stock product | QA_SST Engine Oil (shows Out of Stock) |
| 1.9 | Service package | QAINT1114P |
| 1.10 | Discount | QA_INT Disc 10 (10 percent, has Reason and Tax Procedure) |
| 1.11 | Payment methods | Cash, Hala, Master, Mada Pay, Credit Card |
| 1.12 | Operational setting | Mileage entry = Optional |

Prices in the catalog include VAT 15 percent. Net = price / 1.15, VAT = price - net, rounded to 2 decimals.

## 2. Shared Steps

| ID | Title | Steps | Expected |
|---|---|---|---|
| SS-WO-01 | Open a new WO for 1111AAA on Bay - 01 | 1. Menu, Quick Access, Workorder. 2. Type plate 1111AAA and Search. 3. Select the BMW M5 row. 4. In Enter mileage, Skip. 5. Continue. 6. Select Bay - 01, Assign Bay | Workorder screen opens with a new WO number, header shows 1111AAA, Bay - 01, BMW M5, cart is empty and Total 0.00 |
| SS-WO-02 | Pay the full amount in Cash | 1. Payment. 2. Cash. 3. Enter the Grand Total. 4. Confirm Payment. 5. Cancel the print questions | Remaining 0.00, the app returns to the dashboard and the invoice number is shown in the print question |
| SS-WO-03 | Run Sync | 1. Menu, System and Devices, Sync. 2. Wait for Sync Completed, Ok | Sync Completed with no error |

## 3. Suites and cases

Priority: 1 = daily main flow (blocks a release), 2 = money, stock and important cases.

### 3.1 Start WO

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-001 | 1 | Open a new WO for an existing vehicle | Day open | SS-WO-01 | New WO number (WO - TO_xxxxxxxx), vehicle and bay shown in the header, empty cart |
| TC-WO-002 | 1 | Search a vehicle by plate returns all matching vehicles | 1111AAA exists on two vehicles | 1. Workorder. 2. Search 1111AAA | Both vehicles listed with make, model, year, VIN and last visit date |
| TC-WO-003 | 2 | Search a vehicle by VIN | | 1. Workorder, VIN Number tab. 2. Type the BMW VIN 12222223334H66888. 3. Search | Only the BMW M5 is listed |
| TC-WO-004 | 1 | Add a new vehicle and start a WO for it | Plate not in the system | 1. Workorder. 2. New Vehicle. 3. Fill plate, make, model, year, VIN, customer. 4. Save. 5. Continue | Vehicle saved, the WO opens for it |
| TC-WO-005 | 2 | Enter mileage when starting a WO | Vehicle has no open WO | 1. Select 1111AAA BMW. 2. Enter current mileage above the last mileage. 3. Save Mileage | Mileage saved, Last mileage and Number of visits update on the next visit |
| TC-WO-006 | 2 | Mileage lower than the last mileage is refused | Last mileage known (for example 1,600 km) | 1. Select the vehicle. 2. Enter 1,000. 3. Save Mileage | A clear message, the mileage is not saved |
| TC-WO-007 | 1 | Assign a bay increases its count | Bay - 01 shows 0/2 | SS-WO-01 | Bay - 01 shows 1/2 for the next WO while this WO is open |
| TC-WO-008 | 2 | A full bay cannot be assigned | Bay - 01 has 2 open WOs | 1. Start a third WO. 2. Try to select Bay - 01 | Bay is shown as full and cannot be assigned |

### 3.2 Cart

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-010 | 1 | Add a service to the cart | SS-WO-01 | 1. Click Car Wash | Line Car Wash, qty 1, 100.00, card shows Added 1, Total 100.00 |
| TC-WO-011 | 1 | Add a product to the cart | SS-WO-01 | 1. Click Tire - Item | Line Tire - Item, qty 1, 500.00, Total 500.00 |
| TC-WO-012 | 1 | Change the quantity of a line | Car Wash in the cart | 1. Press + on the line. 2. Press - | Qty 2 then 1, Total 200.00 then 100.00 |
| TC-WO-013 | 2 | Remove a line | Car Wash and Tire in the cart | 1. Remove the Car Wash line | Only Tire left, Total 500.00 |
| TC-WO-014 | 2 | Search an item in the catalog | SS-WO-01 | 1. Type "Brake" in the item search | QA_SST Brake Check is shown, other items hidden |
| TC-WO-015 | 2 | Filter the catalog by group | SS-WO-01 | 1. Click the Services Group circle | Only items of that group are shown. All shows every item again |
| TC-WO-016 | 2 | Out of stock product shows its state | SS-WO-01 | 1. Look at QA_SST Engine Oil | The card shows Out of Stock. Adding it follows the Allow Negative Stock setting of the store |
| TC-WO-017 | 1 | Add a service package | SS-WO-01 | 1. Add QAINT1114P. 2. Choose its parts | Package added once (qty 1) with its lines; package total equals the sum of its lines |
| TC-WO-018 | 2 | Clear cart | Two lines in the cart | 1. Clear cart. 2. Confirm | Cart empty, Total 0.00, discount removed |

### 3.3 Price and Discount

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-020 | 1 | Price comes from the branch default price list | Vehicle 1111AAA (customer has no price list) | 1. Add Car Wash | Price 100.00 as on the branch Default price list |
| TC-WO-021 | 2 | Price comes from the customer price list | QA Auto Customer 1114 on Main Price List | 1. Start a WO for 4114BDR. 2. Add QA_INT Service 1114 | Price taken from Main Price List, not from the branch list |
| TC-WO-022 | 1 | Apply an invoice discount | Car Wash in the cart | 1. Discount. 2. Choose QA_INT Disc 10 | Discount shows its reason, Discount 10.00 on the correct base, Total 90.00 |
| TC-WO-023 | 2 | Apply a discount on one line | Car Wash and Tire in the cart | 1. Line menu of Tire, Discount. 2. Choose QA_INT Disc 10 | Only the Tire line is discounted by 50.00, Total 550.00 |
| TC-WO-024 | 2 | Discount above Max Discount is refused | Item with Max Discount set | 1. Apply a discount above the max | A clear message, discount not applied |

### 3.4 Totals and VAT

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-030 | 1 | Totals for one taxable service | Car Wash in the cart | 1. Read the totals | Sub-total 86.96, Discount 0.00, Tax 13.04, Total 100.00 |
| TC-WO-031 | 1 | Totals for a service and a product | Car Wash and Tire in the cart | 1. Read the totals | Sub-total 521.74, Tax 78.26, Total 600.00 |
| TC-WO-032 | 2 | Totals with quantity 2 | Car Wash qty 2 | 1. Read the totals | Sub-total 173.91, Tax 26.09, Total 200.00 |
| TC-WO-033 | 2 | Totals after a discount | Car Wash with QA_INT Disc 10 | 1. Read the totals | VAT is calculated after the discount: Sub-total 78.26, Tax 11.74, Total 90.00 |
| TC-WO-034 | 2 | Payment screen breakdown equals the cart | Car Wash and Tire | 1. Payment | Total With VAT 600.00, Item/Service Discount 0.00, Invoice Discount 0.00, Grand Total 600.00, Remaining 600.00 |

### 3.5 Payment

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-040 | 1 | Pay the full amount in Cash | Car Wash and Tire (600.00) | SS-WO-02 | Invoice created. Overview: Daily Sales +600.00, Cash +600.00, Expected Cash +600.00 |
| TC-WO-041 | 1 | Pay with Mada | Car Wash (100.00) | 1. Payment, Mada Pay. 2. Amount 100. 3. Confirm | Invoice created. Mada +100.00, Expected Cash unchanged |
| TC-WO-042 | 2 | Pay with Master | Brake Check (25.00) | 1. Payment, Master. 2. Confirm | Invoice created. Master +25.00, Expected Cash unchanged |
| TC-WO-043 | 1 | Pay one invoice with Cash and Mada | Car Wash (100.00) | 1. Payment, Cash 40, Confirm Payment. 2. Mada Pay, 60, Confirm Payment | First confirm adds a Cash 40.00 line and Remaining 60.00. Second creates the invoice. Method shows "Cash + Mada". Cash +40, Mada +60 |
| TC-WO-044 | 1 | Cash above the total gives change | Car Wash (100.00) | 1. Payment, Cash 150. 2. Confirm | Payment accepted, change 50.00 shown, cash drawer increases by 100.00 only |
| TC-WO-045 | 1 | Partial payment is refused when the customer has no credit | Customer credit limit 0, Car Wash | 1. Payment, Cash 40, Confirm. 2. Confirm again with 0 | "Please enter a valid payment amount". No invoice is created |
| TC-WO-046 | 2 | Remove a payment line before confirming | Car Wash, Cash 40 line added | 1. Delete the Cash 40 line. 2. Leave Payment | Line removed, Total Paid 0.00. Nothing is recorded in Cash or Overview |
| TC-WO-047 | 2 | Switching method fills the remaining amount | Car Wash | 1. Payment, Cash. 2. Choose Mada Pay | The amount field shows the remaining amount for the new method |
| TC-WO-048 | 2 | Card payment keeps the card reference | Car Wash | 1. Mada Pay. 2. Fill Credit Number and Transaction Number. 3. Confirm | Values saved on the receipt and shown in the portal invoice payment |

### 3.6 Invoice and Print

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-050 | 1 | Invoice is created with a new number | After TC-WO-040 | 1. Read the print question | "Do you want to print invoice INV - TO_xxxxxxxx?" with the next invoice number |
| TC-WO-051 | 1 | Print the invoice | Printer connected | 1. Ok on the print question | Invoice prints once with no error |
| TC-WO-052 | 1 | Printed invoice header and details | Printed invoice | 1. Check the paper | Company, branch, VAT number, address, invoice number, date and time, customer, plate, cashier are correct |
| TC-WO-053 | 1 | Printed invoice lines and totals | Printed invoice | 1. Check the paper | Every line, qty, price, discount, sub-total, VAT 15 percent, total, method, paid and change equal the app |
| TC-WO-054 | 1 | QR code on the invoice | Printed invoice | 1. Scan the QR | Seller name, VAT number, date and time, total with VAT and VAT amount match the invoice |
| TC-WO-055 | 2 | Reprint the last invoice | After TC-WO-051 | 1. WO menu, Cart Actions, Print last invoice | Reprint equals the original |
| TC-WO-056 | 2 | Print the current cart before paying | Car Wash in the cart | 1. WO menu, Print Current Cart | Cart printout with lines and totals, no invoice is created |
| TC-WO-057 | 2 | Invoice appears in the Sales list | After TC-WO-040 | 1. Dashboard, Sales, Daily | Invoice listed with customer, plate, items count, amount, method and status Paid |

### 3.7 WO Lifecycle

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-060 | 1 | Void a WO | WO with Car Wash, not paid | 1. WO menu, Cart Actions, Void work order. 2. Confirm | WO voided, bay released, Overview Voided +1, Daily Sales unchanged |
| TC-WO-061 | 1 | Leave a WO pending and continue it | WO with Car Wash, not paid | 1. Back to the dashboard. 2. WO menu, Pending WOs. 3. Open the WO | WO listed under Pending with its cart, it opens with the same lines |
| TC-WO-062 | 2 | Complete a pending WO from WO Info | Pending WO | 1. Dashboard, WO info, Pending. 2. Complete. 3. Pay | WO moves from Pending to Completed and an invoice is created |
| TC-WO-063 | 2 | Pending WO is completed on the next day | WO left pending, day closed and a new day opened | 1. Open the WO. 2. Pay | Invoice dated on the new day, counted in the new day sales |
| TC-WO-064 | 2 | Two WOs open at the same time | Two vehicles | 1. Start a WO for vehicle A. 2. New, start a WO for vehicle B. 3. Switch back to A | Each WO keeps its own cart and bay; counter shows 2 |
| TC-WO-065 | 2 | Return an invoice made from a WO | Paid invoice from TC-WO-042 | 1. Operations, Return Invoice, Full Return. 2. Find the invoice, Cash, reason Customer Return. 3. Submit, Confirm Return | Credit note RTN number, amount equal to the invoice, Refunds +25.00, Cash -25.00 |

### 3.8 Stock and DB

Checked in SSMS with [Stock_chain_check.sql](../macone-app/pos-dashboard/evidence/run8-2026-11-20/Stock_chain_check.sql) (read only).

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-070 | 1 | Selling a product reduces the stock | Tire - Item stock known in Branch - 2 | 1. Sell 1 Tire (TC-WO-040). 2. Run the stock chain query | Stock Out linked to the invoice, 1 item line, store transaction -1 at cost 55.00; Inventory tab qty -1 |
| TC-WO-071 | 1 | Selling a service does not move stock | | 1. Sell Car Wash. 2. Run the stock chain query | No store transaction for Car Wash |
| TC-WO-072 | 2 | Voided WO does not move stock | WO with Tire, voided | 1. Run the stock chain query | No store transaction for the voided WO; Tire qty unchanged |
| TC-WO-073 | 2 | Returning a product puts it back in stock | Invoice with Tire returned | 1. Run the stock chain query | Stock In and store transaction +1 at the same cost |
| TC-WO-074 | 2 | Returning a service does not add stock | Invoice with Car Wash returned | 1. Run the stock chain query | No positive store transaction for Car Wash (currently fails: bug draft e-20261120-007) |
| TC-WO-075 | 2 | Invoice cost is saved | After TC-WO-070 | 1. Query SalInvoiceItemCost for the invoice | Cost 55.00 on the Tire line; Gross Profit on the Overview = net sales - 55.00 |

### 3.9 Portal Sync

| ID | P | Title | Preconditions | Steps | Expected |
|---|---|---|---|---|---|
| TC-WO-080 | 1 | Paid WO and invoice appear in the portal | After TC-WO-040 | 1. Portal, Work Order list and Sales Invoice list | Both appear without Sync, with the same lines, totals and payment |
| TC-WO-081 | 1 | Voided WO shows Cancelled in the portal | After TC-WO-060 | 1. Portal, Work Order list | WO status Cancelled |
| TC-WO-082 | 2 | New item from the portal reaches the WO catalog | Item Submitted on the portal with a Business Category and a price | 1. SS-WO-03. 2. SS-WO-01. 3. Search the item | Item shown in the catalog with its price |
| TC-WO-083 | 2 | Cancelled item leaves the WO catalog | Item Cancelled on the portal | 1. SS-WO-03. 2. SS-WO-01. 3. Search the item | Item not shown |
| TC-WO-084 | 2 | Return made in the app appears in the portal | After TC-WO-065 | 1. Portal, Sales Return list | Return listed with the same amount and reason |

## 4. Summary

| Suite | Priority 1 | Priority 2 | Total |
|---|---|---|---|
| Start WO | 4 | 4 | 8 |
| Cart | 4 | 5 | 9 |
| Price and Discount | 2 | 3 | 5 |
| Totals and VAT | 2 | 3 | 5 |
| Payment | 5 | 4 | 9 |
| Invoice and Print | 5 | 3 | 8 |
| WO Lifecycle | 2 | 4 | 6 |
| Stock and DB | 2 | 4 | 6 |
| Portal Sync | 2 | 3 | 5 |
| Total | 28 | 33 | 61 |

## 5. Open points to confirm before upload

| No | Point |
|---|---|
| 5.1 | TC-WO-006: is a mileage lower than the last one refused, or only warned? |
| 5.2 | TC-WO-008: what happens when a bay is full (hidden, disabled, or a message)? |
| 5.3 | TC-WO-016: should an out of stock product be blocked or allowed with negative stock? |
| 5.4 | TC-WO-044: is change shown on the payment screen? |
| 5.5 | RService is sold without VAT; is that its tax setting (question e-20261120-005)? Cases avoid RService until answered |
