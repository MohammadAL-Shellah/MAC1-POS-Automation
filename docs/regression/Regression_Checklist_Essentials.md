# Release Regression Checklist: Essentials

| Item | Value |
|---|---|
| Source | [Regression_Plan.md](Regression_Plan.md) (Draft 3, updated 25/11/2026) |
| Azure DevOps | Test Plan 2115: Smoke suite 2181 (33 cases), Core suite 2182 (78 cases) |
| Build under test | ____________ (read from System & Devices > About) |
| Company and branch | ____________ |
| Tester and date | ____________ |

## 1. Rules for the run

1. Run Smoke first. **One failed Smoke case rejects the build.** Stop and report it.
2. Run Core only when Smoke has passed.
3. Prepare the data before you start: a customer with a price list and vehicle (5281DRB or 5282GZT), a service and a product on the price list, a discount, bays, payment methods (Cash, Mada, Visa), two printers, and an open business day.
4. Run Sync on the MacOne app before you start and after every Portal change.
5. Record every case as Pass, Fail or Blocked. A Pass needs evidence: a UI screenshot, plus a DB check for figures.
6. Log the run on the QA dashboard. Each failure becomes a bug draft.

## 2. Smoke: must pass (build gate)

| # | Area | Case (DevOps ID) | Check | Result |
|---|---|---|---|---|
| S1 | Login and day | REG-APP-001 (2263) | Log in to the company with a valid user | |
| S2 | Login and day | REG-APP-002 (2264) | Open the day with an opening balance; the Opening Balance Summary shows its details | |
| S3 | Login and day | REG-APP-003 (2265) | Sync: a Portal change appears in the app | |
| S4 | Workorder | TC-WO 001, 002, 007, 010 | Open a WO, find the vehicle, assign a bay, add an item at the branch price | |
| S5 | Workorder | TC-WO 020, 022 | Invoice discount, totals and VAT | |
| S6 | Workorder | TC-WO 031, 040, 041 | Cash and Mada payment, invoice number created | |
| S7 | Workorder | TC-WO 050 to 055 | Print the invoice with header, lines, totals and QR; reprint | |
| S8 | Workorder | TC-WO 060 | Void a WO | |
| S9 | Workorder | TC-WO 080, 081 | WO and invoice in the Portal; a voided WO is Cancelled in the Portal | |
| S10 | Return | REG-APP-010 (2266) | Full return with Cash refund, return invoice prints with no error | |
| S11 | Reports | REG-APP-020 | Print any voucher with no error | |
| S12 | Printing | TC-SOC 036 (2071), 039 (2074) | Print with the configured printer, layout and count; nothing prints by itself | |
| S13 | Sticker | TC-SST 011 (1989), 013 (1991), 038 (2016) | Sticker action in the WO menu, manual print, automatic print after the invoice | |
| S14 | Dashboard | TC-POS 005 (1890), 022 (1907) | Daily Sales and Expected Cash Balance | |
| S15 | Dashboard | TC-POS 031 (1926), 034 (1929), 036 (1931) | Executive Summary: Gross Profit, Output VAT, Net VAT Payable | |
| S16 | Portal | REG-PRT-001 (2267) | Portal opens and the Item list loads | |
| S17 | Portal | REG-PRT-002 (2268), 003 (2269) | Invoice report with a QR code that scans; Return Invoice report layout | |
| S18 | Integration | REG-INT-001 (2270), 002, 003 | New customer, vehicle and item reach the app; WO, invoice and return reach the Portal | |

## 3. Core: run on every normal release

| # | Area | Cases | What to confirm | Result |
|---|---|---|---|---|
| C1 | Login and day | REG-APP-004, 005 | Close the day and print End of Day; log in again after a company clean | |
| C2 | Workorder | TC-WO 004, 011, 012, 021, 023, 030, 032 to 034, 042, 043, 045, 046 | New vehicle, product line, price list, line discount, totals, payment breakdown, Cash and Mada together, partial payment refused | |
| C3 | Workorder | TC-WO 061 to 063, 065, 070 to 073, 075, 082 to 084 | Pending WO completed (also the next day), return, stock out for a product, no stock for a service or a voided WO, invoice cost, Portal sync | |
| C4 | Return | REG-APP-011, 012 | Returnable item list; a card return updates Daily Sales | |
| C5 | Reports | REG-APP-021 to 024 | WO voucher, Opening Balance report, Return Invoice report, no automatic print unless configured | |
| C6 | Printing | TC-SOC 003, 010, 016, 021, 023, 026, 032, 038, 040, 043, 047, 049 | Add a printer, test print, assign documents, Hard Copy, default printer, Email share, unavailable printer | |
| C7 | Sticker | 26 TC-SST cases (plan section 6.6) | Item setup, next date calculation, mileage and date stickers, reprint, packages, permissions, fixed bugs 1824, 1830, 2165, 2167, 2168 | |
| C8 | Dashboard | TC-POS 002, 007, 013, 017, 023, 027, 028, 068, 072, 074 to 077, 032, 035, 043, 084, 058, 063 | Tabs, WO and invoice counts, payment methods, split payment, cash sales and refunds, Gross Margin, Input VAT, Sales and Cash totals, Low Stock | |
| C9 | Dashboard bug retests | TC-POS 019 (1904), 040 (1936), 052 (1953), 086 (1966), 071 (1918) | Store filter and stock categories (Bug 2286); an invalid date range cannot be chosen (Bug 2288); a completed earlier-day WO keeps its date (Bug 2294) | |
| C10 | Dashboard DB check | Queries H11 to H14, H22, H24, H27, H30, H32 | Every sale, return and purchase writes the right Stock In or Stock Out and store transaction | |
| C11 | Portal | REG-PRT-004 to 007 | End of Day report, E-Invoice Certificate, item status per document type, company data and image | |
| C12 | Integration | REG-INT-004 to 009 | Discount, bay, payment methods, cancelled item, vehicle make and bank, 15% tax | |

## 4. Known gaps (not in this run)

| Item | Reason |
|---|---|
| TC-POS 003, 004 (1888, 1889) | Need a second account and a second branch, terminal and session. The tester checked them on 25/11/2026, no evidence yet |
| TC-POS 060 (1963) | Not applicable: the Cash Deposit button was removed from the story |
| Bug 2300 | Portal Store form: removing an item that has transactions. Retest it when it is fixed |
| Full level | Edge, validation and layout cases. Major releases only (plan section 2.3) |

## 5. Run summary

| Level | Total | Pass | Fail | Blocked | Decision |
|---|---|---|---|---|---|
| Smoke | 18 checks | | | | Build accepted or rejected |
| Core | 12 groups | | | | Release ready or not |
