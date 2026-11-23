# MAC One Service Reminder Sticker: Test Cases

## Document purpose

Manual test cases for User Story 1624 "myShop POS - Vehicle Service Reminder (Sticker Printing)".

| Item | Value |
|---|---|
| Target | MAC One desktop application, QA environment |
| Azure DevOps | Plan 1882 "MAC1 - POS", suite 1979 (requirement-based, Tested By User Story 1624). IDs in [Service_Sticker_AzureDevOps_Map.csv](./Service_Sticker_AzureDevOps_Map.csv) |
| Created | 2026-11-15 |
| Sync | Edits made in this file are not synced to Azure DevOps automatically |
| Not applicable | Group 8: Permissions, Audit and Print History are not supported yet (development note on the story) |

## Open questions

1. Mileage unit: the story says it follows the vehicle; the analysis task says it follows the company (TC-SST-036).
2. Service package: one sticker with the minimum interval, or one sticker per component (TC-SST-049).
3. Action name: "Service Reminder Sticker" (section 4) or "Print Service Sticker" (acceptance criteria).
4. Field names will be updated by the BA (comment on the story). The cases use the names from the story.

## Test cases

### 1. Item Form Configuration

#### TC-SST-001: Show the service reminder fields on the Service item form

| Field | Value |
|---|---|
| Azure DevOps ID | 1978 |
| Story section | 3 Item Form Configuration |
| Category | Positive / UI |

**Preconditions/data**

1. A QA user can open Add Item and Edit Item on the POS.

**Note:** Story 1624 was edited on 16/11/2026: "Auto Print Service Sticker" is struck out. The Auto Print field is no longer expected.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Item on the POS and select item type Service. |  |
| 2 | Review the item form. | Next Reminder Period, Period Unit, Next Reminder Mileage and Mileage Unit are shown. |

#### TC-SST-002: Show the service reminder fields on the Product item form

| Field | Value |
|---|---|
| Azure DevOps ID | 1980 |
| Story section | 3 Item Form Configuration |
| Category | Positive / UI |

**Preconditions/data**

1. A QA user can open Add Item and Edit Item on the POS.

**Note:** Story 1624 was edited on 16/11/2026: "Auto Print Service Sticker" is struck out. The Auto Print field is no longer expected.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Item on the POS and select item type Product. |  |
| 2 | Review the item form. | Next Reminder Period, Period Unit, Next Reminder Mileage and Mileage Unit are shown. |

#### TC-SST-003: Save an item with mileage and period reminders

| Field | Value |
|---|---|
| Azure DevOps ID | 1981 |
| Story section | 3 Item Form Configuration |
| Category | Positive |

**Preconditions/data**

1. Service item "Oil Change Service" exists with no reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "Oil Change Service" in Edit Item on the POS. |  |
| 2 | Enter Next Reminder Mileage = 5,000 KM, Next Reminder Period = 6, Period Unit = Months, and save. | The item is saved with no validation error. |
| 3 | Close and reopen the item. | The saved values are shown: 5,000 KM and 6 Months. |

#### TC-SST-004: Save an item with a mileage reminder only

| Field | Value |
|---|---|
| Azure DevOps ID | 1982 |
| Story section | 3 Item Form Configuration |
| Category | Positive |

**Preconditions/data**

1. Service item "Tire Rotation" exists with no reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "Tire Rotation" in Edit Item on the POS. |  |
| 2 | Enter Next Reminder Mileage = 10,000 KM, leave the period empty, and save. | The item is saved with no validation error. |
| 3 | Close and reopen the item. | Mileage shows 10,000 KM. The period fields are empty. |

#### TC-SST-005: Save an item with a period reminder only

| Field | Value |
|---|---|
| Azure DevOps ID | 1983 |
| Story section | 3 Item Form Configuration |
| Category | Positive |

**Preconditions/data**

1. Service item "AC Check" exists with no reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "AC Check" in Edit Item on the POS. |  |
| 2 | Enter Next Reminder Period = 12, Period Unit = Months, leave the mileage empty, and save. | The item is saved with no validation error. |
| 3 | Close and reopen the item. | Period shows 12 Months. The mileage field is empty. |

#### TC-SST-006: Save an item without reminder configuration

| Field | Value |
|---|---|
| Azure DevOps ID | 1984 |
| Story section | 3 Item Form Configuration |
| Category | Positive |

**Preconditions/data**

1. A QA user can open Add Item on the POS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Item on the POS and fill in the required item fields only. |  |
| 2 | Leave all reminder fields empty and save. | The item is saved. The reminder fields are optional. |

#### TC-SST-007: Reject a zero or negative reminder period

| Field | Value |
|---|---|
| Azure DevOps ID | 1985 |
| Story section | 3 Item Form Configuration |
| Category | Negative / validation |

**Preconditions/data**

1. Service item "Oil Change Service" is open in Edit Item on the POS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enter Next Reminder Period = 0, Period Unit = Months, and save. | A validation message states the period must be positive. The item is not saved. |
| 2 | Enter Next Reminder Period = -3 and save. | A validation message states the period must be positive. The item is not saved. |

#### TC-SST-008: Reject a zero or negative reminder mileage

| Field | Value |
|---|---|
| Azure DevOps ID | 1986 |
| Story section | 3 Item Form Configuration |
| Category | Negative / validation |

**Preconditions/data**

1. Service item "Oil Change Service" is open in Edit Item on the POS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enter Next Reminder Mileage = 0 and save. | A validation message states the mileage must be positive. The item is not saved. |
| 2 | Enter Next Reminder Mileage = -5,000 and save. | A validation message states the mileage must be positive. The item is not saved. |

#### TC-SST-009: Require the period unit when a reminder period is entered

| Field | Value |
|---|---|
| Azure DevOps ID | 1987 |
| Story section | 3 Item Form Configuration |
| Category | Negative / validation |

**Preconditions/data**

1. Service item "Oil Change Service" is open in Edit Item on the POS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enter Next Reminder Period = 6, leave Period Unit empty, and save. | A validation message states Period Unit is required. The item is not saved. |
| 2 | Select Period Unit = Months and save. | The item is saved. |

#### TC-SST-010: Offer the supported period and mileage units

| Field | Value |
|---|---|
| Azure DevOps ID | 1988 |
| Story section | 3 Item Form Configuration |
| Category | Positive / UI |

**Preconditions/data**

1. Service item "Oil Change Service" is open in Edit Item on the POS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Period Unit list. | The list offers Days, Weeks, and Months. |
| 2 | Open the Mileage Unit list. | The list offers KM and Miles. |

### 2. Sticker Printing from the Work Order

#### TC-SST-011: Show the Service Reminder Sticker action in the Work Order menu

| Field | Value |
|---|---|
| Azure DevOps ID | 1989 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Positive / UI |

**Preconditions/data**

1. A Work Order is open for a QA vehicle.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Work Order menu (three dots next to the WO number) and select Other Actions. | The list contains the Service Reminder Stickers action. |
| 2 | Select Service Reminder Stickers. | The sticker screen opens. |

#### TC-SST-012: List only configured items from the Work Order cart

| Field | Value |
|---|---|
| Azure DevOps ID | 1990 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Positive |

**Preconditions/data**

1. "Oil Change Service" (service) and "Engine Oil" (product) have reminder configuration.
2. A service item with no reminder configuration exists (Car Wash has 1 km / 1 Year in QA since 16/11/2026, so create or pick another service).
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order for a QA vehicle with current mileage 120,000 KM. |  |
| 2 | Add "Oil Change Service", "Engine Oil", and the unconfigured service to the cart. |  |
| 3 | Open the Work Order menu and select Service Reminder Sticker. | "Oil Change Service" and "Engine Oil" are listed as eligible items. The unconfigured service is not selected for printing. |

#### TC-SST-013: Print a manual sticker with mileage and date reminder

| Field | Value |
|---|---|
| Azure DevOps ID | 1991 |
| Story section | 4 Sticker Printing from the Work Order; 9 Sticker Content and Calculation |
| Category | Positive / calculation |

**Preconditions/data**

1. Service item "Oil Change Service" is configured with Next Reminder Mileage = 5,000 KM, Next Reminder Period = 6 Months.
2. An active sticker template and a connected printer exist for the branch.
3. The QA vehicle uses KM as its mileage unit.
4. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a new Work Order for the vehicle with current mileage 120,000 KM. |  |
| 2 | Add "Oil Change Service" to the cart. |  |
| 3 | Open the Work Order menu and select Service Reminder Sticker. | "Oil Change Service" is listed as an eligible item. |
| 4 | Select the active sticker template and the "Oil Change Service" line. |  |
| 5 | Review the calculated values. | Current Mileage = 120,000 KM. Next Mileage = 125,000 KM. Next Date = service completion date + 6 months. |
| 6 | Confirm printing and check the printed sticker. | One sticker prints with no error. It shows Service Name, Current Mileage, Next Mileage, and Next Date with the values from step 5. |

#### TC-SST-014: Print a manual sticker for a product item

| Field | Value |
|---|---|
| Azure DevOps ID | 1992 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Positive |

**Preconditions/data**

1. Product item "QA_SST Engine Oil" (TO_11000005) is configured with Next Reminder Mileage = 5,000 KM and Next Reminder Period = 6 Months.
2. An active sticker template and a connected printer exist for the branch.
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order for a QA vehicle with current mileage 80,000 KM and add "QA_SST Engine Oil" to the cart. |  |
| 2 | Open Service Reminder Sticker and select the template and the "QA_SST Engine Oil" line. | "QA_SST Engine Oil" is listed as an eligible item. |
| 3 | Confirm printing and check the printed sticker. | One sticker prints for "QA_SST Engine Oil" with Next Mileage = 85,000 KM and Next Date = service completion date + 6 months. |

#### TC-SST-015: Print only the selected items when several are eligible

| Field | Value |
|---|---|
| Azure DevOps ID | 1993 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Positive |

**Preconditions/data**

1. "Oil Change Service", "Engine Oil", and "Tire Rotation" have reminder configuration.
2. An active sticker template and a connected printer exist for the branch.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order for a QA vehicle and add the three items to the cart. |  |
| 2 | Open Service Reminder Sticker. | All three items are listed as eligible. |
| 3 | Select "Oil Change Service" and "Engine Oil" only, then confirm printing. | Two stickers print, one per selected item. No sticker prints for "Tire Rotation". |

#### TC-SST-016: Show a print preview that matches the sticker values

| Field | Value |
|---|---|
| Azure DevOps ID | 1994 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Positive / UI |

**Preconditions/data**

1. "Oil Change Service" is configured with 5,000 KM and 6 Months.
2. An active sticker template and a connected printer exist for the branch.
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 120,000 KM, add "Oil Change Service", and open Service Reminder Sticker. |  |
| 2 | Select the template and the item, then open the preview. | The preview shows the selected template with Service Name, Current Mileage 120,000 KM, Next Mileage 125,000 KM, and the Next Date. |
| 3 | Confirm printing. | The printed sticker matches the preview. |

#### TC-SST-017: Cancel sticker printing before confirmation

| Field | Value |
|---|---|
| Azure DevOps ID | 1995 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Negative |

**Preconditions/data**

1. A Work Order contains "Oil Change Service" with reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Service Reminder Sticker and select the template and the item. |  |
| 2 | Close or cancel the sticker screen without confirming. | No sticker prints. The Work Order is unchanged. |

#### TC-SST-018: Show a message when the Work Order has no eligible items

| Field | Value |
|---|---|
| Azure DevOps ID | 1996 |
| Story section | 4 Sticker Printing from the Work Order |
| Category | Negative |

**Preconditions/data**

1. An item with no reminder configuration exists (for example Tire - Item, TO_1000001).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order for a QA vehicle and add only the unconfigured item. |  |
| 2 | Open the Work Order menu and select Service Reminder Sticker. | A clear message states that the Work Order has no items configured for a service sticker. Nothing prints. |

### 3. Sticker Template Selection

#### TC-SST-019: Offer only active sticker templates

| Field | Value |
|---|---|
| Azure DevOps ID | 1997 |
| Story section | 5 Sticker Template Selection |
| Category | Positive |

**Preconditions/data**

1. The branch has one active sticker template and one inactive sticker template.
2. Sticker templates are linked on the portal: General > Print Document > Work Order Sticker > Reports tab.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and open Service Reminder Sticker. |  |
| 2 | Open the template list. | Only the active template is offered. The inactive template is not listed. |

#### TC-SST-020: Offer only templates configured for the company or branch

| Field | Value |
|---|---|
| Azure DevOps ID | 1998 |
| Story section | 5 Sticker Template Selection |
| Category | Positive / data isolation |

**Preconditions/data**

1. A sticker template is configured for the user's branch.
2. Another template is configured for a different branch only.
3. Sticker templates are linked on the portal: General > Print Document > Work Order Sticker > Reports tab.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and open Service Reminder Sticker. |  |
| 2 | Open the template list. | The list shows the company template and the user's branch template. The other branch's template is not listed. |

#### TC-SST-021: Block printing when no active template is available

| Field | Value |
|---|---|
| Azure DevOps ID | 1999 |
| Story section | 5 Sticker Template Selection |
| Category | Negative |

**Preconditions/data**

1. All sticker templates for the company and branch are inactive.
2. Sticker templates are linked on the portal: General > Print Document > Work Order Sticker > Reports tab.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and open Service Reminder Sticker. |  |
| 2 | Try to print the sticker. | A clear message states that no active sticker template is available. Nothing prints, and the sticker is not reported as printed. |

#### TC-SST-022: Show a clear message when the printer is unavailable

| Field | Value |
|---|---|
| Azure DevOps ID | 2000 |
| Story section | 5 Sticker Template Selection; 12 Acceptance Criteria |
| Category | Negative / printer |

**Preconditions/data**

1. An active sticker template exists.
2. The sticker printer is disconnected or switched off.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and open Service Reminder Sticker. |  |
| 2 | Select the template and the item, then confirm printing. | A clear printer error message is shown. The sticker is not reported as printed. |
| 3 | Reconnect the printer and print again. | The sticker prints successfully. |

### 4. Manual Data Entry

#### TC-SST-023: Edit sticker values before printing when manual entry is allowed

| Field | Value |
|---|---|
| Azure DevOps ID | 2001 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Positive |

**Preconditions/data**

1. AllowManualServiceStickerDataEntry is enabled for the QA user.
2. "Oil Change Service" is configured with 5,000 KM and 6 Months.
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 120,000 KM, add "Oil Change Service", and open Service Reminder Sticker. | The values are calculated from the item: Next Mileage 125,000 KM, Next Date + 6 months. |
| 2 | Change Next Mileage to 124,000 KM and the Next Date to a different valid date. | The fields accept the new values. |
| 3 | Confirm printing. | The sticker prints with the edited values. |

#### TC-SST-024: Keep manual edits on the current sticker only

| Field | Value |
|---|---|
| Azure DevOps ID | 2002 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Positive |

**Preconditions/data**

1. TC-SST-023 was executed: the sticker was printed with edited values.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "Oil Change Service" in Edit Item. | The item still shows 5,000 KM and 6 Months. |
| 2 | Create a new Work Order with "Oil Change Service" and open Service Reminder Sticker. | The values are calculated from the item configuration, not from the earlier manual edits. |

#### TC-SST-025: Notify that configuration is required when manual entry is allowed

| Field | Value |
|---|---|
| Azure DevOps ID | 2003 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Negative |

**Preconditions/data**

1. AllowManualServiceStickerDataEntry is enabled for the QA user.
2. An item selected for the sticker has no reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with the unconfigured item and open Service Reminder Sticker. |  |
| 2 | Select the unconfigured item. | The system notifies the user that the item requires service sticker configuration. |

#### TC-SST-026: Show sticker values as read-only when manual entry is not allowed

| Field | Value |
|---|---|
| Azure DevOps ID | 2004 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Positive |

**Preconditions/data**

1. AllowManualServiceStickerDataEntry is disabled for the QA user.
2. "Oil Change Service" is configured with 5,000 KM and 6 Months.
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 120,000 KM, add "Oil Change Service", and open Service Reminder Sticker. | The configured values are shown: Next Mileage 125,000 KM and Next Date + 6 months. |
| 2 | Try to edit Next Mileage and Next Date. | Both fields are read-only and cannot be changed. |

#### TC-SST-027: Block printing of an unconfigured item when manual entry is not allowed

| Field | Value |
|---|---|
| Azure DevOps ID | 2005 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Negative |

**Preconditions/data**

1. AllowManualServiceStickerDataEntry is disabled for the QA user.
2. An item in the Work Order requires a sticker but has no reminder configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Service Reminder Sticker for the Work Order and select the unconfigured item. |  |
| 2 | Try to print the sticker. | The message "Please configure the service sticker data for this item or service and set the required details to continue." is shown. Printing does not proceed. |

#### TC-SST-028: Configure missing values from the item definition and retry printing

| Field | Value |
|---|---|
| Azure DevOps ID | 2006 |
| Story section | 6 Manual Data Entry and Editing Permission |
| Category | Positive |

**Preconditions/data**

1. TC-SST-027 state: printing was blocked for an unconfigured item.
2. The QA user can maintain items.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the item definition from the POS and enter Next Reminder Mileage = 5,000 KM and Next Reminder Period = 6 Months, then save. | The item is saved. |
| 2 | Return to the Work Order and open Service Reminder Sticker again. | The item is now eligible with calculated values. |
| 3 | Confirm printing. | The sticker prints with the new configuration. |

### 5. Sticker Content and Calculation

#### TC-SST-029: Calculate the next date for a period in days

| Field | Value |
|---|---|
| Azure DevOps ID | 2007 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / calculation |

**Preconditions/data**

1. "AC Check" is configured with Next Reminder Period = 30 Days and no mileage.

**Note:** The example dates assume the service is completed on 15/11/2026. On another date, apply the same offset.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "AC Check", complete the service, and open Service Reminder Sticker. |  |
| 2 | Review the Next Date. | Next Date = 15/12/2026 (completion date + 30 days). |

#### TC-SST-030: Calculate the next date for a period in weeks

| Field | Value |
|---|---|
| Azure DevOps ID | 2008 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / calculation |

**Preconditions/data**

1. "AC Check" is configured with Next Reminder Period = 2 Weeks and no mileage.

**Note:** The example dates assume the service is completed on 15/11/2026. On another date, apply the same offset.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "AC Check", complete the service, and open Service Reminder Sticker. |  |
| 2 | Review the Next Date. | Next Date = 29/11/2026 (completion date + 14 days). |

#### TC-SST-031: Calculate the next date for a period in months across the year end

| Field | Value |
|---|---|
| Azure DevOps ID | 2009 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / calculation |

**Preconditions/data**

1. "AC Check" is configured with Next Reminder Period = 3 Months and no mileage.

**Note:** The example dates assume the service is completed on 15/11/2026. On another date, apply the same offset.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "AC Check", complete the service, and open Service Reminder Sticker. |  |
| 2 | Review the Next Date. | Next Date = 15/02/2027. The year rolls over correctly. |

#### TC-SST-032: Print a mileage-only sticker without inventing a date

| Field | Value |
|---|---|
| Azure DevOps ID | 2010 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / missing data |

**Preconditions/data**

1. "Tire Rotation" is configured with Next Reminder Mileage = 10,000 KM and no period.
2. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 60,000 KM, add "Tire Rotation", and open Service Reminder Sticker. |  |
| 2 | Review the values and print. | Next Mileage = 70,000 KM. Next Date is empty or shows an approved equivalent such as "Not configured". No calculated date is shown. |

#### TC-SST-033: Print a date-only sticker without inventing a mileage

| Field | Value |
|---|---|
| Azure DevOps ID | 2011 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / missing data |

**Preconditions/data**

1. "AC Check" is configured with Next Reminder Period = 12 Months and no mileage.
2. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 60,000 KM, add "AC Check", and open Service Reminder Sticker. |  |
| 2 | Review the values and print. | Next Date = completion date + 12 months. Next Mileage is empty or shows an approved equivalent such as "Not configured". No calculated mileage is shown. |

#### TC-SST-034: Request the current mileage when it is missing

| Field | Value |
|---|---|
| Azure DevOps ID | 2012 |
| Story section | 9 Sticker Content and Calculation |
| Category | Negative / missing data |

**Preconditions/data**

1. Administration > Operational Setting > Mileage entry = Optional.
2. "Oil Change Service" is configured with 5,000 KM and 6 Months.

| # | Action | Expected result |
|---|---|---|
| 1 | Select a QA vehicle that has no open WO. In the "Enter mileage" panel press Skip, then open the Work Order. |  |
| 2 | Add "Oil Change Service" and open Service Reminder Stickers. | The system asks for the current mileage and gives a place to enter it before it prints the mileage reminder. |
| 3 | Enter current mileage 90,000 KM and continue. | Next Mileage = 95,000 KM. |

#### TC-SST-035: Use the latest mileage recorded on the Work Order

| Field | Value |
|---|---|
| Azure DevOps ID | 2013 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / calculation |

**Preconditions/data**

1. "Oil Change Service" is configured with 5,000 KM and 6 Months.
2. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 120,000 KM and add "Oil Change Service". |  |
| 2 | Update the Work Order mileage to 120,500 KM. |  |
| 3 | Open Service Reminder Sticker and review the values. | Current Mileage = 120,500 KM. Next Mileage = 125,500 KM. |

#### TC-SST-036: Validate the mileage unit against the vehicle unit

| Field | Value |
|---|---|
| Azure DevOps ID | 2014 |
| Story section | 9 Sticker Content and Calculation |
| Category | Negative / validation |

**Preconditions/data**

1. A QA vehicle uses Miles as its mileage unit.
2. "Oil Change Service" is configured with Next Reminder Mileage = 5,000 KM.

**Note:** Open question: the story says the unit follows the vehicle, while the analysis task says it follows the company. Confirm the expected behavior with the BA.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order for the Miles vehicle and add "Oil Change Service". |  |
| 2 | Open Service Reminder Sticker. | The system flags the mileage unit mismatch and does not print a sticker with mixed units. |

#### TC-SST-037: Fit a long service name on the sticker

| Field | Value |
|---|---|
| Azure DevOps ID | 2015 |
| Story section | 9 Sticker Content and Calculation |
| Category | Positive / UI (regression Bug 1824) |

**Preconditions/data**

1. A service item with a long name (60 characters or more) is configured with 5,000 KM and 6 Months.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with the long-name service and open Service Reminder Sticker. |  |
| 2 | Print the sticker and check it. | The full service name is readable. Current Mileage, Next Mileage, and Next Date all appear on the same sticker. |

### 6. Automatic Sticker Printing

#### TC-SST-038: Print stickers automatically after the invoice is confirmed

| Field | Value |
|---|---|
| Azure DevOps ID | 2016 |
| Story section | 7 Automatic Sticker Printing |
| Category | Positive (regression Bug 1830) |

**Preconditions/data**

1. "Oil Change Service" is configured with 5,000 KM and 6 Months.
2. A default sticker template and a connected printer exist for the branch.
3. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

**Note:** Story 1624 was edited on 16/11/2026: "Auto Print Service Sticker" is struck out. No prompt is required before automatic printing.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 120,000 KM and add "Oil Change Service". |  |
| 2 | Complete the invoice and print it. | The invoice is confirmed. |
| 3 | Check the output that prints after the invoice. | The sticker prints automatically with Next Mileage 125,000 KM and Next Date + 6 months. |

#### TC-SST-039: [Out of scope] Do not print automatically for items with Auto Print set to No

| Field | Value |
|---|---|
| Azure DevOps ID | 2017 |
| Story section | 7 Automatic Sticker Printing |
| Category | Negative |

**Preconditions/data**

1. "Tire Rotation" is configured with 10,000 KM and Auto Print = No.

**Note:** Story 1624 was edited on 16/11/2026: "Auto Print Service Sticker" is struck out. This case depends on Auto Print = No and is closed.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Tire Rotation" and complete the invoice. |  |
| 2 | Observe the flow after the invoice print. | No sticker prompt appears and no sticker prints automatically. |

#### TC-SST-040: Do not print automatically before the invoice is confirmed

| Field | Value |
|---|---|
| Azure DevOps ID | 2018 |
| Story section | 7 Automatic Sticker Printing |
| Category | Negative |

**Preconditions/data**

1. "Oil Change Service" is configured with 5,000 KM and 6 Months.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and save it without completing the invoice. | No sticker prints. |
| 2 | Start the invoice and cancel it at the payment step. | The invoice is not confirmed and no sticker prints. |

#### TC-SST-041: Print all eligible stickers automatically from one invoice

| Field | Value |
|---|---|
| Azure DevOps ID | 2019 |
| Story section | 7 Automatic Sticker Printing |
| Category | Positive |

**Preconditions/data**

1. "Oil Change Service", "Engine Oil", and "Tire Rotation" have reminder configuration.
2. A default sticker template and a connected printer exist for the branch.

**Note:** Story 1624 was edited on 16/11/2026: "Auto Print Service Sticker" is struck out. Every configured item now prints automatically.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with the three items and complete the invoice. | The invoice is confirmed. |
| 2 | Check the output that prints after the invoice. | Three stickers print automatically, one for each configured item. |

#### TC-SST-042: Use the default template for automatic printing

| Field | Value |
|---|---|
| Azure DevOps ID | 2020 |
| Story section | 7 Automatic Sticker Printing; 5 Sticker Template Selection |
| Category | Positive |

**Preconditions/data**

1. The branch has two active templates, and one of them is the default.
2. "Oil Change Service" is configured with 5,000 KM and 6 Months.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and complete the invoice. |  |
| 2 | Check the sticker that prints automatically after the invoice. | The sticker prints with the default template layout. |

#### TC-SST-043: Report missing data during automatic printing

| Field | Value |
|---|---|
| Azure DevOps ID | 2021 |
| Story section | 7 Automatic Sticker Printing |
| Category | Negative |

**Preconditions/data**

1. "Oil Change Service" is configured with 5,000 KM and 6 Months.
2. The sticker printer is disconnected.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with "Oil Change Service" and complete the invoice. | The invoice is confirmed. |
| 2 | Check the automatic sticker print after the invoice. | A clear message reports the problem and the corrective action. The sticker is not reported as printed. |

#### TC-SST-044: [Out of scope] Mark automatically printed stickers as printed

| Field | Value |
|---|---|
| Azure DevOps ID | 2022 |
| Story section | 7 Automatic Sticker Printing |
| Category | Positive |

**Preconditions/data**

1. TC-SST-038 was executed: a sticker printed automatically.

**Note:** Story 1624 was edited on 16/11/2026: "Mark the sticker as printed" is struck out. This case is closed.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the same Work Order and select Service Reminder Sticker. | The "Oil Change Service" sticker is marked as printed. |

#### TC-SST-045: Reprint a sticker

| Field | Value |
|---|---|
| Azure DevOps ID | 2023 |
| Story section | 7 Automatic Sticker Printing |
| Category | Positive |

**Preconditions/data**

1. A Work Order has a sticker already printed for "Oil Change Service".

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Work Order and select Service Reminder Sticker. |  |
| 2 | Use the reprint action for "Oil Change Service". | The sticker reprints with the same values as the original print. |

#### TC-SST-046: Keep the original values when reprinting after the item configuration changes

| Field | Value |
|---|---|
| Azure DevOps ID | 2024 |
| Story section | 3 Item Form Configuration; 11 Audit and Print History |
| Category | Positive / history |

**Preconditions/data**

1. A Work Order has a sticker printed for "Oil Change Service" with 5,000 KM and 6 Months.

| # | Action | Expected result |
|---|---|---|
| 1 | Change "Oil Change Service" to 10,000 KM and 12 Months and save. |  |
| 2 | Open the earlier Work Order and reprint the sticker. | The reprinted sticker shows the original values (5,000 KM interval and 6 months), not the new configuration. |

### 7. Service Package Handling

#### TC-SST-047: Use the product value over the service value in a package

| Field | Value |
|---|---|
| Azure DevOps ID | 2025 |
| Story section | 8 Service Package Handling |
| Category | Positive / calculation |

**Preconditions/data**

1. Package "Oil Package" contains product "Engine Oil" (5,000 KM) and service "Oil Change Service" (7,500 KM).
2. Both have Next Reminder Period = 6 Months.
3. The package is created on the portal (Item Type Service Package) with a Business Category, so it shows in the WO catalog. A package created on the POS does not show in the WO.
4. For a package, the sticker screen shows a Calculation table for each service in it.
5. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 100,000 KM and add "Oil Package". |  |
| 2 | Open Service Reminder Sticker and review the values. | Next Mileage uses the product value: 105,000 KM. |

#### TC-SST-048: Fall back to the service value when the product has no value

| Field | Value |
|---|---|
| Azure DevOps ID | 2026 |
| Story section | 8 Service Package Handling |
| Category | Positive / calculation |

**Preconditions/data**

1. Package "Oil Package" contains product "Engine Oil" with 5,000 KM and no period, and service "Oil Change Service" with 7,500 KM and 6 Months.
2. The package is created on the portal (Item Type Service Package) with a Business Category, so it shows in the WO catalog. A package created on the POS does not show in the WO.
3. For a package, the sticker screen shows a Calculation table for each service in it.
4. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 100,000 KM and add "Oil Package". |  |
| 2 | Open Service Reminder Sticker and review the values. | Next Mileage = 105,000 KM from the product. Next Date = completion date + 6 months from the service. |

#### TC-SST-049: Apply the minimum interval in a package

| Field | Value |
|---|---|
| Azure DevOps ID | 2027 |
| Story section | 8 Service Package Handling |
| Category | Positive / calculation |

**Preconditions/data**

1. Package "Full Oil Package" contains Engine Oil (5,000 KM, 6 Months), Oil Filter (10,000 KM, 12 Months), and Oil Change Service (7,500 KM, 6 Months).
2. The package is created on the portal (Item Type Service Package) with a Business Category, so it shows in the WO catalog. A package created on the POS does not show in the WO.
3. For a package, the sticker screen shows a Calculation table for each service in it.
4. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

**Note:** Story example from section 8. The story says "Each Service will print separately": the POS splits the package into one sticker per service.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 100,000 KM and add "Full Oil Package". |  |
| 2 | Open Service Reminder Sticker and review the values. | The package is split into one sticker per service. Each service uses the shortest interval: 5,000 KM and 6 months, so Next Mileage = 105,000 KM and Next Date = completion date + 6 months. |

#### TC-SST-050: Evaluate the mileage and period intervals separately

| Field | Value |
|---|---|
| Azure DevOps ID | 2028 |
| Story section | 8 Service Package Handling |
| Category | Positive / calculation |

**Preconditions/data**

1. Package "Mixed Package" contains product A (5,000 KM, 12 Months) and product B (10,000 KM, 6 Months).
2. The package is created on the portal (Item Type Service Package) with a Business Category, so it shows in the WO catalog. A package created on the POS does not show in the WO.
3. For a package, the sticker screen shows a Calculation table for each service in it.
4. Mileage is entered in the "Enter mileage" panel when the vehicle is selected (the vehicle must have no open WO; do not press Skip).

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Work Order with current mileage 100,000 KM and add "Mixed Package". |  |
| 2 | Open Service Reminder Sticker and review the values. | Next Mileage = 105,000 KM (shortest mileage, from A). Next Date = completion date + 6 months (shortest period, from B). |

### 8. Permissions, Audit and Print History

#### TC-SST-051: Allow sticker printing only with the Print Service Sticker permission

| Field | Value |
|---|---|
| Azure DevOps ID | 2029 |
| Story section | 10 Permissions |
| Category | Negative / permissions |

**Preconditions/data**

1. A QA user without the Print Service Sticker permission.

**Note:** Not applicable at present: the development note on Story 1624 states that permissions are not supported yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Sign in with the restricted user and open a Work Order with a configured item. |  |
| 2 | Try to open Service Reminder Sticker. | The action is unavailable or blocked. No sticker prints. |

#### TC-SST-052: Allow configuration changes only with the Edit Service Sticker Configuration permission

| Field | Value |
|---|---|
| Azure DevOps ID | 2030 |
| Story section | 10 Permissions |
| Category | Negative / permissions |

**Preconditions/data**

1. A QA user without the Edit Service Sticker Configuration permission.

**Note:** Not applicable at present: the development note on Story 1624 states that permissions are not supported yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Sign in with the restricted user and open an item in Edit Item. |  |
| 2 | Try to change the reminder fields. | The reminder fields cannot be changed. |

#### TC-SST-053: Prevent item definition changes without item-maintenance permission

| Field | Value |
|---|---|
| Azure DevOps ID | 2031 |
| Story section | 6 Manual Data Entry and Editing Permission; 10 Permissions |
| Category | Negative / permissions |

**Preconditions/data**

1. A QA user has AllowManualServiceStickerDataEntry but no item-maintenance permission.

**Note:** Not applicable at present: the development note on Story 1624 states that permissions are not supported yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Service Reminder Sticker for an unconfigured item. | The system states that configuration is required. |
| 2 | Try to open the item definition and save reminder values. | The item definition cannot be changed. Manual entry does not grant item-maintenance rights. |

#### TC-SST-054: Record print history for manual, automatic and reprint jobs

| Field | Value |
|---|---|
| Azure DevOps ID | 2032 |
| Story section | 11 Audit and Print History |
| Category | Positive / audit |

**Preconditions/data**

1. One manual print, one automatic print, and one reprint were done in QA.

**Note:** Not applicable at present: the development note on Story 1624 states that Audit and Print History are not supported yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the sticker print history. |  |
| 2 | Review the three records. | Each record shows Company, Branch, WO Number, Invoice Number, Vehicle and Plate, Item, Template, Current Mileage, Next Mileage, Next Date, Print Type (Manual, Automatic, Reprint), Printed By, date and time, Printer, and Status with any failure reason. |

#### TC-SST-055: Keep printed values in history after item configuration changes

| Field | Value |
|---|---|
| Azure DevOps ID | 2033 |
| Story section | 11 Audit and Print History |
| Category | Positive / audit |

**Preconditions/data**

1. A sticker was printed for "Oil Change Service" with 5,000 KM and 6 Months.

**Note:** Not applicable at present: the development note on Story 1624 states that Audit and Print History are not supported yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Change "Oil Change Service" to 10,000 KM and 12 Months and save. |  |
| 2 | Open the print history record of the earlier sticker. | The record still shows the values used at print time. |
