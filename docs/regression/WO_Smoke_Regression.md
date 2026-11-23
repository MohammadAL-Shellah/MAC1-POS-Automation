# Workorder Smoke Regression (MacOne App and Portal)

| Item | Value |
|---|---|
| Version | Draft 1, 16 November 2026 |
| Scope | Workorder main flow: create, price, pay, invoice, print, and its result in the portal |
| When to run | Every new build and every release, before any other regression |
| Status | Provisional. The Workorder story is not complete, so Expected results follow the current verified behaviour, not a signed requirement |
| DevOps | Cases are not on DevOps yet. IDs REG-WO-xxx are local until the cases are created there |

## 1. Rules for this suite

| No | Rule |
|---|---|
| 1.1 | A failure in any case here blocks the release |
| 1.2 | Every case carries the tag `Provisional` until the Workorder story is complete. Then the Expected results are reviewed against the story and the tag is removed |
| 1.3 | Features that are not finished or have an open bug stay out (for example Promotion, and store item assignment finding 6.6). They join when fixed |
| 1.4 | Run on clean data: a new WO for every run, never an old WO left from earlier tests |

## 2. Test data needed before the run

| No | Data | Where | Current QA value |
|---|---|---|---|
| 2.1 | Customer with a Default Price List | Portal, Customer | QA Auto Customer 1114, Main Price List |
| 2.2 | Vehicle linked to the customer | Portal, Vehicle | 4114BDR |
| 2.3 | Service item in a Business Category and on the customer price list | Portal, Item and Price List | QA_INT Service 1114 |
| 2.4 | Service package (Submitted Service Item Group) | Portal, Item | QAINT1114P |
| 2.5 | Discount with Reason and Tax Procedure | Portal, Discount | QA_INT Disc 10 |
| 2.6 | Bay with free capacity | Portal, Branch, Bays | Bay - QA_INT (capacity 3) |
| 2.7 | Payment methods on the branch | Portal, Branch, Payment Methods | Cash, Mada, Visa |
| 2.8 | Open day and a connected printer | MacOne app | Branch Alshellah, terminal M-ALSHELLAH |

## 3. Test cases

| ID | Title | Steps | Expected |
|---|---|---|---|
| REG-WO-001 | Sync completes | 1. Menu, System and Devices, Sync | Sync finishes with no error. Portal changes (2.1 to 2.7) are visible in the app |
| REG-WO-002 | Find vehicle and customer | 1. Workorder, New. 2. Search plate 4114BDR | Vehicle and its customer are found and loaded on the WO |
| REG-WO-003 | Add item from the catalog | 1. Search QA_INT Service 1114. 2. Add it | Item is in the catalog. Price comes from the customer price list |
| REG-WO-004 | Add a service package | 1. Add QAINT1114P. 2. Choose the parts | Package lines are correct. Package total equals the sum of its lines |
| REG-WO-005 | Assign a bay | 1. Choose Bay - QA_INT | WO is assigned. Bay count rises by one (for example 0/3 to 1/3) |
| REG-WO-006 | Apply a discount | 1. Discount, choose QA_INT Disc 10 | Discount is selectable, shows its reason, and deducts 10 percent of the correct base |
| REG-WO-007 | Totals and VAT | 1. Review the cart totals | Subtotal, discount, VAT 15 percent on taxable items and Total are correct to 2 decimals |
| REG-WO-008 | Pay with Cash | 1. Pay, Cash, amount above total | Payment accepted. Change is correct |
| REG-WO-009 | Pay with a card method | 1. New WO. 2. Pay with Mada or Visa | Payment accepted with the chosen method |
| REG-WO-010 | Create invoice | 1. Complete the WO | WO becomes an Invoice with a new INV number. Bay is released |
| REG-WO-011 | Invoice prints | 1. Print after payment | Invoice prints once, with no error |
| REG-WO-012 | Printed invoice header | 1. Check the printed invoice | Company name, branch, VAT registration number and address are correct |
| REG-WO-013 | Printed invoice details | 1. Check the printed invoice | Invoice number, date and time, customer, vehicle plate, cashier are correct |
| REG-WO-014 | Printed invoice lines and totals | 1. Check the printed invoice | Every line with quantity and price, discount, subtotal, VAT 15 percent, total, payment method, paid and change match the app |
| REG-WO-015 | Printed invoice QR code | 1. Scan the QR with a phone | QR is readable and shows seller name, VAT number, date and time, total with VAT, and VAT amount, all matching the invoice |
| REG-WO-016 | Reprint invoice | 1. Open the invoice from the invoice list. 2. Print | Reprint matches the original |
| REG-WO-017 | Invoice in the portal | 1. Open the portal. 2. Find the WO and the invoice | Both appear at once, without Sync, with the same lines, totals and payment |
| REG-WO-018 | Void a WO | 1. New WO with a bay. 2. Void it | WO is voided in the app. Bay is released. Portal shows the WO as Cancelled |

## 4. Run record

| Run | Date | Build | Pass | Fail | Blocked | Not run | Notes |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |

## 5. Next suites

| No | Suite | Content |
|---|---|---|
| 5.1 | WO Core Regression | Return invoice, pending WO completed on a later day, price change by customer price list, multiple payment methods on one invoice |
| 5.2 | MacOne Core Regression | POS Dashboard, Service Sticker, Share Options (happy scenarios and fixed bugs) |
| 5.3 | Portal Core Regression | Master data that feeds the app: item, price list, discount, branch setup |
