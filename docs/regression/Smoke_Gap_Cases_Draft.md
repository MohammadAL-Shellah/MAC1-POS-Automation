# Smoke Gap Cases (draft for review)

| Item | Value |
|---|---|
| Purpose | Smoke flows from the local plan that are not on Azure DevOps yet (review of 20/11/2026, section 7) |
| Target | Test Plan 2115 "Release Regression", suite Smoke 2181, Priority 1 |
| Status | Approved and created on DevOps 20/11/2026 (IDs 2263 to 2270) |
| Sources | The bug or story named on each case. Steps and expected results come from those items and the plan; anything not confirmed there is marked "To confirm" |

## 1. Cases

### REG-APP-001 (2263) Log in to the company
Source: Bug 1863 (Closed).

| No | Step | Expected result |
|---|---|---|
| 1 | Open MacOne and log in with a valid QA user | The company cards are shown |
| 2 | Click the company card | The app opens the company profile. No click is ignored (bug 1863) |

### REG-APP-002 (2264) Open the business day with an opening balance
Source: Story 431, Bug 1787 (Closed).

| No | Step | Expected result |
|---|---|---|
| 1 | Open Day and enter an opening cash balance | The day opens |
| 2 | Open the Opening Balance Summary | The summary shows the entered balance with its details list and the delete icon (bug 1787) |

To confirm: which payment methods the opening balance screen accepts on the current build.

### REG-APP-003 (2265) Sync brings a Portal change to the app
Source: Bug 689 (Closed).

| No | Step | Expected result |
|---|---|---|
| 1 | In the Portal, change a value the app shows (for example an item price on the branch price list) | Saved in the Portal |
| 2 | In the app, run Sync | Sync ends with no error |
| 3 | Open the screen that shows the value | The new value is shown |

### REG-APP-010 (2266) Full return with Cash refund and print the return invoice
Source: Bug 1858 (Closed).

| No | Step | Expected result |
|---|---|---|
| 1 | Make a full return of a cash invoice from today, refund in Cash | A return number is created. Refund equals the invoice amount |
| 2 | Print the return invoice | It prints with no error message (bug 1858) |
| 3 | Open the Overview | Refunds and Expected Cash reflect the refund |

### REG-PRT-001 (2267) Portal opens and the Item list loads
Source: Bug 1864 (Closed). Automated: `npm run test:portal:smoke`.

| No | Step | Expected result |
|---|---|---|
| 1 | Open the QA Portal and log in | No Application Error (bug 1864) |
| 2 | Open the Item list | Items load |

### REG-PRT-002 (2268) Invoice report layout and QR code
Source: Bugs 1976 and 1857 (Closed), Story 1632.

| No | Step | Expected result |
|---|---|---|
| 1 | Open the invoice made in the run in the Portal and print its report | All text is shown, including terms and conditions (bug 1976) |
| 2 | Scan the QR code | It shows the invoice details (bug 1857) |

### REG-PRT-003 (2269) Return invoice report layout
Source: Bug 1865 (Closed).

| No | Step | Expected result |
|---|---|---|
| 1 | Open the return made in REG-APP-010 in the Portal and print its report | The layout is correct and does not spread over several pages (bug 1865) |

### REG-INT-001 (2270) New customer and vehicle reach the app
Source: Portal_MacOne_Integration_Report.md, sections 4.1 and 4.2.

| No | Step | Expected result |
|---|---|---|
| 1 | In the Portal, create a customer with a vehicle | Saved |
| 2 | In the app, run Sync and search the plate | The vehicle is found with its customer |

## 2. Notes
1. This is 8 cases, not 6: the review counted Login, Open Day and Sync as one "before start" block.
2. REG-APP-004 (Close Day and End of Day report) is Core and follows after approval of these cases.
