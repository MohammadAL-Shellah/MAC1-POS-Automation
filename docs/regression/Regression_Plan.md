# Release Regression Plan (MacOne App and Portal)

| Item | Value |
|---|---|
| Version | Draft 3, 23 November 2026 (POS Dashboard updated after Run 80) |
| Owner | QA, myShop (Azure DevOps project Shop) |
| Applies to | Every MacOne app build and every Portal release in QA |
| Detailed WO cases | [WO_Smoke_Regression.md](WO_Smoke_Regression.md) |
| Azure DevOps | Test Plan 2115 "Release Regression", root suite 2116. Since the review of 20 November 2026 ([Release_Regression_Review_2026-11-20.html](Release_Regression_Review_2026-11-20.html)) each case sits in one level only: Smoke 2181 (33, including 8 REG cases 2263 to 2270 created 20/11/2026), Core 2182 (73), Full 2183 (126 since 24/11/2026). Two cases are on hold outside the suites (1904, 2014). Priority field: 1 = Smoke, 2 = Core, 3 and 4 = Full. The other REG-APP, REG-WO, REG-PRT and REG-INT cases (Core) are not on DevOps yet |

## 1. How to use this plan

| No | Step |
|---|---|
| 1.1 | Choose the level from section 2 based on the type of release |
| 1.2 | Prepare the test data in section 4 and run Sync on the MacOne app |
| 1.3 | Run the areas in the order of section 5: Smoke first. If any Smoke case fails, stop and report, the build is rejected |
| 1.4 | Run the cases listed for the chosen level in each area. A higher level includes all cases of the lower levels |
| 1.5 | Record the result in section 9 and log the run on the QA dashboard |
| 1.6 | After the run, update section 8: cases whose bug was fixed move into the plan, new cases are added |

## 2. Levels

| No | Level | When | Content | Estimated time |
|---|---|---|---|---|
| 2.1 | Smoke | Every new build | Main daily flows only. Failure means the build is rejected | 2 to 3 hours |
| 2.2 | Core | Every normal release | Smoke, plus the happy scenarios of every story and a retest of every fixed bug | 1 to 2 days |
| 2.3 | Full | Major release or before go live | Core, plus edge cases, validation and invalid input cases | 3 to 5 days |

## 3. How cases were chosen

| No | Rule | Level |
|---|---|---|
| 3.1 | The main flow a cashier uses every day. If it breaks, the release cannot go out | Smoke |
| 3.2 | The happy scenario of each Acceptance Criterion in the story | Core |
| 3.3 | A case that once had a bug which is now fixed (Closed or Resolved) | Core |
| 3.4 | Calculations: totals, VAT, discount, cash and sales figures | Core |
| 3.5 | Data that moves between the Portal and the app | Core |
| 3.6 | Validation, invalid input, edge cases and layout checks | Full |
| 3.7 | A case that fails now, has an open bug or draft, is not applicable, or waits for a business answer | Excluded (section 8) |

## 4. Test data needed

| No | Data | Where |
|---|---|---|
| 4.1 | Customer with a Default Price List, vehicle with mileage | Portal |
| 4.2 | Service item and product in a Business Category, on the price list, with service reminder settings | Portal |
| 4.3 | Service package with a Submitted Service Item Group | Portal |
| 4.4 | Discount with Reason and Tax Procedure | Portal |
| 4.5 | Branch bays, payment methods (Cash, Mada, Visa) | Portal, Branch |
| 4.6 | Two printers registered (one receipt, one A4 or PDF) | MacOne, Share Option Configurations |
| 4.7 | Open business day with opening balance | MacOne |

The current QA values are in [WO_Smoke_Regression.md](WO_Smoke_Regression.md), section 2.

## 5. Summary by area

| No | Area | Story | Smoke | Core (added) | Full (added) | Excluded |
|---|---|---|---|---|---|---|
| 5.1 | Login, Opening Day and Sync | 431 | 3 | 2 | 1 | 0 |
| 5.2 | Workorder, Invoice and Printing | WO plan 2184 (story 493 not complete) | 18 | 26 | 11 | 7 |
| 5.3 | Return Invoice | none | 1 | 2 | 0 | 0 |
| 5.4 | Reports and Vouchers | 1618 | 1 | 4 | 0 | 0 |
| 5.5 | Share Options and Printers | 1041 | 2 | 12 | 29 | 15 |
| 5.6 | Service Reminder Sticker | 1624 | 3 | 26 | 20 | 6 |
| 5.7 | POS Dashboard | 214 | 5 | 25 | 55 | 3 |
| 5.8 | Portal | 1632 and others | 3 | 4 | 0 | 0 |
| 5.9 | Portal and MacOne Integration | none | 3 | 6 | 0 | 0 |
| | Total | | 39 | 107 | 116 | 31 |

For 5.7, after Run 80 (22 and 23/11/2026, build 1.2.498) the 87 TC-POS cases split as in the DevOps suites: 5 Smoke, 19 Core, 55 Full and 8 Excluded (TC-009 added to Full on 24/11/2026). The Core column adds 1 for the stock tables DB check. Changed on 23/11/2026 with the user's approval: 13 cases added (Core 1922, 1927, 1968; Full 1891, 1914, 1952, 1924, 1925, 1967, 1969, 1942, 1965, 1950) and 3 removed from Full (1936, 1953, 1966, Bug 2288).

## 6. MacOne App

### 6.1 Login, Opening Day and Sync (Story 431)

| ID | Level | Test | Source |
|---|---|---|---|
| REG-APP-001 (2263) | Smoke | Log in to the company with a valid user | Bug 1863 |
| REG-APP-002 (2264) | Smoke | Open the business day with an opening balance, then view the Opening Balance Summary with its details and delete icon | Story 431, Bug 1787 |
| REG-APP-003 (2265) | Smoke | Run Sync. A change made in the Portal appears in the app | Bug 689 |
| REG-APP-004 | Core | Close the day and print the End of Day report with data | Bug 1851 |
| REG-APP-005 | Core | Log in again after a company clean | Bug 1699 |
| REG-APP-006 | Full | Login and Opening Day screens display correctly at 1920x1080 and at a smaller resolution | Bugs 1782, 1785, 1781 |

### 6.2 Workorder, Invoice and Printing (Story 493, not complete)

Cases come from QA's own Workorder test plan on DevOps, "MAC1 - Workorder (QA)" plan 2184 (not linked to the story), written in [WO_Test_Cases.md](../workorder/WO_Test_Cases.md). TC-WO-xxx numbers map to DevOps IDs 2198 to 2258. The story is not complete, so the cases carry the tag `Provisional`. They replace the local REG-WO-001 to REG-WO-021 of [WO_Smoke_Regression.md](WO_Smoke_Regression.md).

| Level | Cases (TC-WO) | What they cover |
|---|---|---|
| Smoke | 001, 002, 007, 010, 020, 022, 031, 040, 041, 050, 051, 052, 053, 054, 055, 060, 080, 081 | Open a WO, find the vehicle, assign a bay, add an item at the branch price, invoice discount, totals and VAT, Cash and Mada payment, invoice number, print with header, lines, totals and QR, reprint, Void, WO and invoice in the Portal, voided WO Cancelled in the Portal |
| Core | 004, 011, 012, 021, 023, 030, 032, 033, 034, 042, 043, 045, 046, 061, 062, 063, 065, 070, 071, 072, 073, 075, 082, 083, 084 | New vehicle, product line, quantity, customer price list, line discount, totals with quantity and discount, payment breakdown, Master, Cash + Mada on one invoice, partial payment refused, removed payment line, pending WO continued and completed (also on the next day), return, stock out for a product, no stock for a service or a voided WO, stock back on return, invoice cost, items synced from and cancelled in the Portal, return in the Portal |
| Core | REG-WO-022 (local, not on DevOps) | Invoice printed in the company localized language (Bug 1799) and with the right company image (Bug 1822) |
| Full | 003, 005, 013, 014, 015, 024, 047, 048, 056, 057, 064 | VIN search, mileage entry, remove a line, catalog search and group filter, max discount, method switch, card reference, print current cart, Sales list, two open WOs |
| Excluded | 006, 008, 016, 017, 018, 044, 074 | See section 8 (8.2, 8.2a, 8.2b) |

### 6.3 Return Invoice

| ID | Level | Test | Source |
|---|---|---|---|
| REG-APP-010 (2266) | Smoke | Full return of an invoice with Cash refund, then print the return invoice with no error | Bug 1858 |
| REG-APP-011 | Core | Returnable item list scrolls and shows the full item name | Bug 1786 |
| REG-APP-012 | Core | Return of an invoice paid by card updates Daily Sales on the dashboard | Bug 1854 |

### 6.4 Reports and Vouchers (Story 1618)

| ID | Level | Test | Source |
|---|---|---|---|
| REG-APP-020 | Smoke | Print any voucher with no error | Bug 1876 |
| REG-APP-021 | Core | Print a completed WO voucher from the Voucher List. It prints the WO report, not the invoice | Bug 1801 |
| REG-APP-022 | Core | Print the Opening Balance report with no error | Bug 1797 |
| REG-APP-023 | Core | Open the Return Invoice report with no Application Error | Bug 1849 |
| REG-APP-024 | Core | Invoice is not printed automatically unless configured | Bug 1833 |

### 6.5 Share Options and Printers (Story 1041, plan cases TC-SOC)

| Level | Cases (DevOps ID) | What they cover |
|---|---|---|
| Smoke | 036 (2071), 039 (2074) | Print a document with its configured printer, layout and count. Nothing prints by itself |
| Core | 003 (2038), 010 (2045), 016 (2051), 021 (2056), 023 (2058), 026 (2061), 032 (2067), 038 (2073), 040 (2075), 043 (2078), 047 (2082), 049 (2084) | Add a printer, test print, assign documents, multiple share options, Hard Copy, default printer per document, Email share, unavailable printer and choosing another |
| Full | 002, 004 to 009, 011 to 013, 017 to 020, 024, 025, 027 to 031, 035, 042, 044, 045, 053, 054, 056, 058 | Field rules, required and unique names, edit printer, layouts, print count validation, SMS, activation |

### 6.6 Service Reminder Sticker (Story 1624, plan cases TC-SST)

| Level | Cases (DevOps ID) | What they cover |
|---|---|---|
| Smoke | 011 (1989), 013 (1991), 038 (2016) | Sticker action in the WO menu, manual print with mileage and date, automatic print after the invoice |
| Core | 003 (1981), 012 (1990), 015 (1993), 016 (1994), 017 (1995), 029 (2007), 031 (2009), 032 (2010), 033 (2011), 045 (2023), 047 (2025), 048 (2026), 021 (1999), 022 (2000), 023 (2001), 024 (2002), 018 (1996), 014 (1992), 034 (2012), 035 (2013), 051 (2029), 053 (2031), 039 (2017), 052 (2030), 049 (2027), 050 (2028) | Item setup, only configured items listed, select items, preview, cancel, next date calculation, mileage only and date only stickers, reprint, package values, missing template message, printer offline, sticker pencil updates the item definition (business confirmed 17/11/2026), a product gets a sticker only inside a package with a service (business rule, 17/11/2026), mileage entered later from Customer actions, Service Reminder Sticker permissions (Print and Edit), no automatic print when Auto print is off in Share Options (passed 18/11/2026 on 1.2.494), My Items Edit permission (bug 2168, passed 18/11/2026 on 1.2.495), retest of fixed bugs 1824 (long service name wraps on the sticker), 1830 (prompt after invoice) and 2167 (sticker texts), 2165 (a pencil change updates the next date on other open WOs, passed 20/11/2026 on 1.2.498), package with product values: the item's own data always wins over the service (business confirmed 19/11/2026) |
| Full | 001, 002, 004 to 010, 025, 026, 027, 028, 030, 036, 037, 040 to 043 | Item form fields, units, validation, missing configuration, long names, default template, miles converted to km (business confirmed 17/11/2026), sticker after invoice |

### 6.7 POS Dashboard (Story 214, plan cases TC-POS)

| Level | Cases (DevOps ID) | What they cover |
|---|---|---|
Since the review of 20/11/2026 the DevOps suites are the source. Updated after Run 80 (23/11/2026).

| Level | Cases (DevOps ID) | What they cover |
|---|---|---|
| Smoke | 005 (1890), 022 (1907), 031 (1926), 034 (1929), 036 (1931) | Daily Sales, expected cash, Executive Summary: Gross Profit, Output VAT, Net VAT Payable (moved from Core on 23/11/2026) |
| Core | 002 (1887), 007 (1892), 013 (1898), 017 (1902), 023 (1908), 027 (1912), 028 (1913), 068 (1915), 072 (1919), 074 (1921), 075 (1922), 076 (1923), 032 (1927), 035 (1930), 077 (1932), 043 (1939), 084 (1960), 058 (1961), 063 (1968) | Tabs, voided WO excluded, invoice and WO counts, electronic payments outside cash, payment methods, removed payment line, split payment, Overview and Inventory counts equal, cash sales and refunds, cash deposit reduces Expected Cash (075), refresh, Gross Margin, Input VAT, Daily Sales and Net Sales in the Executive Summary, Sales totals, Complete a WO from WO Info, Cash tab totals, Low Stock levels (063) |
| Core (bug retests) | 019 (1904) Bug 2286, 040 (1936), 052 (1953), 086 (1966) Bug 2288, 071 (1918) Bug 2294 | Store filter and stock categories per branch store; invalid From/To range cannot be chosen on Sales, WO Info, Cash; completing an earlier-day WO keeps its creation date. Passed in Run 82 (25/11/2026) |
| Core (DB check) | Stock tables chain, queries H11 to H14, H22, H24, H27, H30, H32 of [US-214-POS-Dashboard.sql](../../QA-Database-Reference/Database-Queries/US-214-POS-Dashboard.sql) | Every sale of a product writes a Stock Out with its line and store transaction at the item cost; returns, purchases, purchase returns and adjustments write the matching Stock In or Stock Out. Checked in Run 80 |
| Full | 1886, 1891, 1893, 1894, 1895, 1896, 1897, 1899, 1900, 1901, 1903, 1905, 1906, 1909, 1910, 1911, 1914, 1916, 1917, 1920, 1924, 1925, 1928, 1933, 1934, 1935, 1937, 1938, 1940, 1941, 1942, 1943, 1944, 1945, 1946, 1947, 1948, 1949, 1950, 1951, 1952, 1954, 1955, 1956, 1957, 1958, 1959, 1962, 1964, 1965, 1967, 1969, 1970, 1971, 1972 | Date periods and custom ranges, report links, growth cases, export, search, boundary dates, empty states, Inventory Value (feature not finished), Return Rate and Cash Sales % (questions 157 and 158 answered 25/11/2026: current behaviour is correct) |


## 7. Portal

### 7.1 Portal screens and reports

| ID | Level | Test | Source |
|---|---|---|---|
| REG-PRT-001 (2267) | Smoke | Portal opens with no Application Error and the Item list loads (automated: `npm run test:portal:smoke`) | Bug 1864 |
| REG-PRT-002 (2268) | Smoke | Invoice report layout is correct and its QR code scans | Bugs 1976, 1857, Story 1632 |
| REG-PRT-003 (2269) | Smoke | Return Invoice report layout is correct | Bug 1865 |
| REG-PRT-004 | Core | End of Day report works and shows data | Bug 1850 |
| REG-PRT-005 | Core | Create a new E-Invoice Certificate, and a clear message is shown on error | Bug 1696 |
| REG-PRT-006 | Core | Only items whose status is assigned to a document type are offered | Bug 1750 |
| REG-PRT-007 | Core | Company data and image match the app Company Profile | Bug 1822 |

### 7.2 Portal and MacOne Integration

Based on [Portal_MacOne_Integration_Report.md](../integration/Portal_MacOne_Integration_Report.md), section 4.

| ID | Level | Test | Report ref |
|---|---|---|---|
| REG-INT-001 (2270) | Smoke | New customer and vehicle reach the app after Sync | 4.1, 4.2 |
| REG-INT-002 | Smoke | New item reaches My items and the WO catalog with the right price | 4.3, 4.4, 4.18 |
| REG-INT-003 | Smoke | WO, invoice and return made in the app appear in the Portal at once | Section 5 |
| REG-INT-004 | Core | New discount reaches the app and applies correctly | 4.12, 4.13 |
| REG-INT-005 | Core | New bay reaches the app with its capacity | 4.9 |
| REG-INT-006 | Core | Branch payment methods appear on the Payment screen | 4.10 |
| REG-INT-007 | Core | Cancelled item disappears from the app after Sync | 4.5 |
| REG-INT-008 | Core | New vehicle make and bank reach the app | 4.6, 4.7 |
| REG-INT-009 | Core | Tax procedure 15 percent applies on taxable items | 4.15 |

## 8. Excluded for now

These join the plan when the bug is fixed, the feature is complete, or the business answers.

| No | Area | Cases | Reason |
|---|---|---|---|
| 8.1 | Workorder | Discount label | Bug 1975 open |
| 8.2 | Workorder | TC-WO-017 (package added with qty 1), TC-WO-018 (Clear cart removes the discount); also package oil in Portal, package lines and Sync | Bug drafts not yet opened |
| 8.2a | Workorder | TC-WO-006 (lower mileage), TC-WO-008 (full bay), TC-WO-016 (out of stock product), TC-WO-044 (change shown) | Expected result not confirmed by QA lead yet (open points in WO_Test_Cases.md section 5) |
| 8.2b | Workorder | TC-WO-074 (return of a service adds no stock) | Fails: bug draft e-20261120-007 |
| 8.3 | Workorder | Promotion, store item assignment | Feature not finished (6.12), finding 6.6 |
| 8.4 | Share Options | TC-SOC 001, 022, 033, 034, 037, 052 | Fail in the last run |
| 8.5 | Share Options | TC-SOC 041, 046, 048, 050, 051, 055, 057 | Open bug drafts |
| 8.6 | Share Options | TC-SOC 014, 015 | Need a second POS terminal |
| 8.8 | Service Sticker | TC-SST 019, 020 | Not needed: the business dropped the template Active flag and Branch link (18/11/2026) |
| 8.9 | Service Sticker | TC-SST 044 | Out of scope: "Mark the sticker as printed" struck out in the story (revision of 17/11/2026) |
| 8.10 | Service Sticker | TC-SST 046, 054, 055 | Print History not supported yet |
| 8.11 | POS Dashboard | TC-POS 003 (1888), 004 (1889) | Blocked in Run 80: a second account with other permissions and a second branch, terminal and session are needed. Checked by the tester on 25/11/2026 (OK), kept here until evidence is attached |
| 8.11a | POS Dashboard | TC-POS 060 (1963) | Not applicable: the Cash Deposit button was removed from the story |
| 8.12d | Stock tables | Sales Return of a service item; duplicate Stock Out header (H25); duplicate Stock Adjustment number | Bug draft e-20261120-007, bug draft for H25, Bug 2287 (Story 990) |
| 8.13 | Version update | Update environment | Bug 1861 open (Story 928) |
| 8.14 | Company Profile | Story 1046 | Story still active, no cases yet |

## 9. Run record

| Run | Date | App build | Portal version | Level | Pass | Fail | Blocked | Not run | Decision |
|---|---|---|---|---|---|---|---|---|---|
| 1 | | | | | | | | | |

## 10. Suggestions

| No | Suggestion | Benefit |
|---|---|---|
| 10.1 | Create a Test Plan "Release Regression" on DevOps with three suites (Smoke, Core, Full), built as query based suites on the tags `Regression-Smoke`, `Regression-Core`, `Regression-Full` | Each run is saved on DevOps with the build number, and a newly tagged case joins by itself |
| 10.2 | Create the REG-APP, REG-WO, REG-PRT and REG-INT cases on DevOps after review (with your approval) | All regression cases live in one place |
| 10.3 | Automate the Portal parts first with Playwright (REG-PRT and the Portal checks of REG-INT) | Saves time on every release |
| 10.4 | After each release, move fixed bugs from section 8 into Core | The plan stays current |

## 11. Adding a new story

Every story that QA tests joins this plan. The steps below are done when the first execution run of the story finishes.

| No | Step | Details |
|---|---|---|
| 11.1 | Choose the cases | Apply the rules of section 3 to the story's cases: the main daily flow goes to Smoke, the happy scenarios and calculations go to Core, validation and edge cases go to Full |
| 11.2 | Add the story section | Add a subsection under section 6 (MacOne App) or section 7 (Portal) with the story ID, and list the cases per level with their DevOps IDs |
| 11.3 | Record the exclusions | Cases that fail, have an open bug, are not applicable or wait for a business answer go to section 8 with the reason |
| 11.4 | Update the summary | Update the counts in section 5 |
| 11.5 | Add on DevOps | After approval, add the chosen cases to suite Smoke 2181, Core 2182 or Full 2183 in Test Plan 2115 (no tags; the case itself is not edited). Remove a case from its suite when it moves to section 8 |
| 11.6 | Story not complete | If the main flow is important but the story is not complete, add its cases with the tag `Provisional`, as done for the Workorder |

The plan is also updated when:

| No | Event | Action |
|---|---|---|
| 11.7 | A bug is closed | Add a retest case for it to Core, and remove its line from section 8 |
| 11.8 | A story changes scope | Review its cases in the plan and move the ones no longer valid to section 8 |
| 11.9 | A story is complete | Remove the `Provisional` tag after its cases are checked against the final story |

## 12. Review of 20 November 2026

| No | Change | Applied |
|---|---|---|
| 12.1 | 44 cases moved between suites and 4 put on hold, by priority (P0 Smoke, P1 Core, P2 and P3 Full) and business flow. The DevOps suites now take precedence over the level lists of sections 6.2 and 6.5 to 6.7 | 20/11/2026 |
| 12.2 | Priority field set on 132 test cases to match the review | 20/11/2026 |
| 12.3 | TC number added to the titles of the 92 Share Options and Service Sticker cases (from the AzureDevOps_Map.csv files) | 20/11/2026 |
| 12.4 | Release day runs by business flow: before start, Start WO, cart and pricing, totals and VAT, payment, invoice and printing, share options, sticker, WO lifecycle, stock, returns, Portal, dashboard, close day | Run order in the review page, section 3 |
| 12.5 | On hold until the answer or fix: 1904 and 1968 (inventory counting rule, question e-20261120-075), 1950 (expected result not confirmed), 2014 (outdated: miles are converted to km) | 20/11/2026 |
| 12.6 | 8 Smoke cases created on DevOps and added to Smoke 2181: REG-APP-001 (2263), 002 (2264), 003 (2265), 010 (2266), REG-PRT-001 (2267), 002 (2268), 003 (2269), REG-INT-001 (2270). Text in [Smoke_Gap_Cases_Draft.md](Smoke_Gap_Cases_Draft.md) | 20/11/2026 |
| 12.7 | TC-POS-010 (1895) and TC-POS-033 (1928) added to Full 2183 after their pass in Run 77, approved by the user | 22/11/2026 |
| 12.8 | After Run 80 of Story 214: 13 TC-POS cases added (Core 1922, 1927, 1968; Full 1891, 1914, 1952, 1924, 1925, 1967, 1969, 1942, 1965, 1950), 3 removed from Full (1936, 1953, 1966, Bug 2288). On hold now only 1904 (Bug 2286) and 2014. Approved by the user | 23/11/2026 |
| 12.10 | TC-POS-009 (1894) added to Full 2183 after its pass in Demo Company on 24/11/2026 (Run 80). Approved by the user | 24/11/2026 |
| 12.11 | Bugs 2286, 2288 and 2294 Closed: retest cases 1904, 1936, 1953, 1966, 1918 added to Core and removed from Excluded (8.12a, b, c). Passed in Run 82. Added to Core suite 2182 on DevOps with the user's approval (Core 78 cases) | 25/11/2026 |
| 12.9 | Executive Summary in Smoke: TC-POS 031 (1926), 034 (1929), 036 (1931) moved from Core to Smoke, Priority set to 1. Approved by the user | 23/11/2026 |

## 13. Release day runbook

Trigger: the user says "run regression" (or "run the regression test"). Follow these steps in order.

### 13.1 Preparation

| No | Step | Purpose |
|---|---|---|
| 13.1.1 | Read the app build from System & Devices > About, and the Portal version | Every result and bug is tied to a build |
| 13.1.2 | Run the dashboard sync and list bugs whose status changed since the last run | A closed bug means a retest; an open bug means a known, expected failure |
| 13.1.3 | Read section 8 (Excluded) and `QA-Database-Reference/Relationship-Knowledge-Base.md` | Know what is out and why |
| 13.1.4 | Check prerequisites: vehicles 5281DRB and 5282GZT, branch price list items, a real printer and a PDF printer, users with and without sticker permissions, QA database access, a Purchase Invoice in the Portal for Input VAT | Report anything missing before the run starts, not halfway |
| 13.1.5 | Create a Test Run on DevOps from Plan 2115 with the build number, and log it on the dashboard (test_run) | Every result is stored in one place |
| 13.1.6 | Take a dashboard baseline screenshot and run the baseline DB queries | Final figures are compared with the change the run made |

### 13.2 Execution

| No | Level | Order | Stop rule |
|---|---|---|---|
| 13.2.1 | Smoke 2181 | Business flow order of the review page, section 3: Login, Open Day, Sync, Work Order, pricing and discount, totals and VAT, Cash and Mada, invoice with print and QR, void, return, stock, Portal and reports, dashboard figures | Any failure: stop, report the build as rejected, do not start Core |
| 13.2.2 | Core 2182 | Same flow order with more detail, then the stock DB check (Stock_chain_check.sql), then Close Day | Continue on failure; report any P1 failure to the user at once |
| 13.2.3 | Full 2183 | Only when the user asks (major release or go live) | |

For every case:
1. Execute it in the visible app.
2. Take real UI and SSMS screenshots, named `TC-xxx_ui_*.png` and `TC-xxx_db_Qn.png`.
3. Save each query in the story SQL file and the indexes.
4. Record the outcome in the Test Run and attach the screenshots.
5. Use one customer and vehicle through the flows, so the dashboard checks at the end verify the run's own transactions.

### 13.3 On failure

1. Repeat once and confirm the build number.
2. Check for an existing open bug or draft on the same issue.
3. New failure: log a `bug_draft` on the dashboard and describe the finding to the user. Never open a bug on DevOps; the user writes and opens it.

### 13.4 Close

1. Update the test_run on the dashboard and the run record in section 9.
2. Write a short report: results per level and flow, new bugs, known failures, cases not run with the reason, and a Go or No-Go recommendation with its reason.
3. Hand to the user: the QR scan on a phone (REG-PRT-002), the real printer check, and the Go or No-Go decision when a Core case fails.

Expected time: Smoke 2 to 3 hours, Core 1 to 2 days.
