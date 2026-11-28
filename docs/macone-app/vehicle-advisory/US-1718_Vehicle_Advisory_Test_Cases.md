# US-1718 Vehicle Advisory (VIS) in Work Order: Test Cases

## Document purpose

Manual test cases for User Story 1718 "myShop POS - Vehicle Advisory (VIS) in Work Order".

| Item | Value |
|---|---|
| Target | MAC One desktop application, QA environment |
| Azure DevOps | Not uploaded. Upload only after approval |
| Created | 2026-11-28 |
| Not applicable | License validation BR-1.1 and AC-02 (Development field: license not supported now) |
| QA vehicles | 5281DRB Sportage, 5282GZT Tahoe |
| SQL file | [US-1718-Vehicle-Advisory-VIS.sql](../../../QA-Database-Reference/Database-Queries/US-1718-Vehicle-Advisory-VIS.sql) |

## Evidence rule

1. Each case lists the screenshots it needs, each with the English caption to print on it.
2. Screenshots are taken during execution only. No image is attached before the case runs, and none is mock-up or edited.
3. File names: `TC-VIS-xxx_ui_<name>.png` and `TC-VIS-xxx_db_<query>.png`, saved in `QA-Database-Reference/Screenshots/US-1718-Vehicle-Advisory-VIS/`.
4. The caption band goes outside the captured area and shows: case ID, the caption below, date, build and environment. A red box marks the checked field. The raw original is kept beside it.

## 1. Access and vehicle eligibility

### TC-VIS-001: Show the Vehicle Advisory (VIS) icon on the Work Order

| Field | Value |
|---|---|
| Story section | Scope, BR-01 |
| Category | Positive / UI |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Work Order display. | The Vehicle Advisory (VIS) icon is shown on the Work Order. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-001_ui_vis_icon.png | TC-VIS-001: Work Order display with the VIS icon highlighted (red box) |

### TC-VIS-002: Open the Vehicle Advisory screen with its sections

| Field | Value |
|---|---|
| Story section | Scope, BR-1, BR-2 |
| Category | Positive / UI |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon. | The Vehicle Advisory screen opens with VIS Compatible Items, Last Visit Details, Vehicle History and Maintenance. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-002_ui_vis_screen.png | TC-VIS-002: Vehicle Advisory screen open: all sections boxed and labelled |

**Note:** Needs Clarification (Q12, final list of tabs): expected result pending the business answer; executed after the answer.

### TC-VIS-003: Open VIS directly for a vehicle that has full details

| Field | Value |
|---|---|
| Story section | BR-01, AC-01 |
| Category | Positive |
| DB check | Query B1 |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon. | No VIN prompt is shown; the fitment lookup starts for 5281DRB. |
| 2 | Review the vehicle shown on the screen. | Make, Model and Year match the vehicle on the Work Order. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-003_ui_vehicle_header.png | TC-VIS-003: VIS screen header: vehicle Make/Model/Year boxed next to WO vehicle |
| TC-VIS-003_db_Q_B1.png | TC-VIS-003: SSMS: AutVehicle row of 5281DRB, Make/Model/Year columns boxed |

### TC-VIS-004: Block VIS when no vehicle is on the Work Order

| Field | Value |
|---|---|
| Story section | BR-01, UI messages |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A new Work Order with no vehicle selected.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon. | Message: "Please select a vehicle before checking product compatibility." The user is asked to enter vehicle details; no lookup starts. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-004_ui_no_vehicle_msg.png | TC-VIS-004: Message for a Work Order without a vehicle, message text boxed |

### TC-VIS-005: Show a message when the vehicle details are incomplete

| Field | Value |
|---|---|
| Story section | BR-01, UI messages |
| Category | Negative |
| DB check | Query B1 |

**Preconditions**

1. A Work Order with a vehicle missing Make, Model or Year (prepared test vehicle).

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon. | Message: "The vehicle details are incomplete. Please complete the required information to check compatibility." |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-005_ui_incomplete_msg.png | TC-VIS-005: Incomplete-details message, missing vehicle field boxed |
| TC-VIS-005_db_Q_B1.png | TC-VIS-005: SSMS: vehicle row showing the empty column |

**Note:** Needs Clarification (Q3, minimum required fields): expected result pending the business answer; executed after the answer.

### TC-VIS-006: Retrieve Make, Model and Year from a valid VIN

| Field | Value |
|---|---|
| Story section | Scope, BR-01 |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order with a vehicle that has no Make/Model/Year (or vehicle tracking off), a valid VIN known to the provider.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon. | The user is forced to enter the VIN before continuing. |
| 2 | Enter the valid VIN and confirm. | Make, Model and Year are retrieved and the vehicle advisory details are displayed. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-006_ui_vin_prompt.png | TC-VIS-006: VIN entry prompt shown before VIS opens |
| TC-VIS-006_ui_vin_result.png | TC-VIS-006: Retrieved Make/Model/Year after entering the VIN, values boxed |

**Note:** Needs Clarification (Q2, known VIN in QA): expected result pending the business answer; executed after the answer.

### TC-VIS-007: Reject an invalid VIN

| Field | Value |
|---|---|
| Story section | BR-01 |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Same as the previous case.

| # | Action | Expected result |
|---|---|---|
| 1 | Enter a VIN with wrong length or invalid characters and confirm. | No vehicle details are retrieved and the user is informed; the lookup does not start. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-007_ui_invalid_vin.png | TC-VIS-007: Invalid VIN entered and the system response, VIN field boxed |

**Note:** Needs Clarification (Q3, exact message): expected result pending the business answer; executed after the answer.

### TC-VIS-008: Require the VIN when it is left empty

| Field | Value |
|---|---|
| Story section | BR-01 |
| Category | Negative / Boundary |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Same as the previous case.

| # | Action | Expected result |
|---|---|---|
| 1 | Leave the VIN empty and confirm. | The user cannot continue without a VIN. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-008_ui_empty_vin.png | TC-VIS-008: Empty VIN field and the blocking behaviour |

### TC-VIS-009: Save the vehicle details retrieved by the VIN

| Field | Value |
|---|---|
| Story section | BR-01 |
| Category | Integration / Data integrity |
| DB check | Query B1 before and after |

**Preconditions**

1. VIN case above completed; AutVehicle row read before (query B1).

| # | Action | Expected result |
|---|---|---|
| 1 | Run query B1 after the VIN lookup. | The database change matches the business answer (VIN and Make/Model/Year stored or not stored). |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-009_db_Q_B1_before.png | TC-VIS-009: SSMS before: vehicle row without details |
| TC-VIS-009_db_Q_B1_after.png | TC-VIS-009: SSMS after: vehicle row, changed columns boxed |

**Note:** Needs Clarification (Q4, where the details are saved): expected result pending the business answer; executed after the answer.

### TC-VIS-010: Use VIS with no license check

| Field | Value |
|---|---|
| Story section | BR-1.1, Development field |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon with the standard QA user. | VIS opens without any license message (license is not supported in this release). |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-010_ui_no_license_msg.png | TC-VIS-010: VIS opened with no license prompt |

**Note:** Needs Clarification (Q1, VIS open to every user): expected result pending the business answer; executed after the answer.

## 2. VIS compatible items

### TC-VIS-011: Retrieve compatible items with Item Code, Kind and OEM tag

| Field | Value |
|---|---|
| Story section | BR-1, AC-03 |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS Compatible Items. | Compatible products from the Fitment Database are listed with Item Code, Item type (Kind) and an OEM tag on OEM items. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-011_ui_vis_list.png | TC-VIS-011: VIS compatible items list: Code, Kind and OEM tag columns boxed |

**Note:** Needs Clarification (Q2 expected list, Q8 OEM rule): expected result pending the business answer; executed after the answer.

### TC-VIS-012: Show the Add button only beside matching customer items

| Field | Value |
|---|---|
| Story section | BR-1, AC-05 |
| Category | Positive |
| DB check | Item match query (to write after query A4) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.
2. At least one VIS item code exists in InvItem.

| # | Action | Expected result |
|---|---|---|
| 1 | Review the VIS list. | Items whose code matches a customer item show the related customer item and an Add button. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-012_ui_add_button.png | TC-VIS-012: Matched customer item with its Add button boxed |
| TC-VIS-012_db_Q_match.png | TC-VIS-012: SSMS: InvItem row with the same Item Code |

### TC-VIS-013: Show external items as references that cannot be added

| Field | Value |
|---|---|
| Story section | BR-1, BR-07, AC-04 |
| Category | Negative |
| DB check | Item match query |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.
2. VIS returns at least one code not in InvItem.

| # | Action | Expected result |
|---|---|---|
| 1 | Review an item not in the customer database. | It is shown as a fitment reference with no Add button and cannot be added to the Work Order. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-013_ui_external_item.png | TC-VIS-013: External reference row without Add button, boxed |
| TC-VIS-013_db_Q_match.png | TC-VIS-013: SSMS: no InvItem row for that code |

### TC-VIS-014: Add a compatible customer item to the Work Order

| Field | Value |
|---|---|
| Story section | BR-1, AC-05, Workflow A |
| Category | Positive / Integration |
| DB check | WO lines query (to write after query A3) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Add beside a matched customer item. | The item is added to the Work Order cart with its normal price. |
| 2 | Save the Work Order. | The Work Order line is saved for that item. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-014_ui_added_to_wo.png | TC-VIS-014: Work Order cart with the item added from VIS, line boxed |
| TC-VIS-014_db_Q_wo_lines.png | TC-VIS-014: SSMS: Work Order line row for the item |

### TC-VIS-015: Add the same compatible item twice

| Field | Value |
|---|---|
| Story section | BR-07 |
| Category | Negative / Duplicate |
| DB check | WO lines query |

**Preconditions**

1. Item from the previous case already in the cart.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Add on the same item again. | The Work Order follows its existing rule for a repeated item (quantity or line), same as adding it from the normal item list. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-015_ui_add_twice.png | TC-VIS-015: Cart after the second Add, quantity or lines boxed |
| TC-VIS-015_db_Q_wo_lines.png | TC-VIS-015: SSMS: Work Order lines after save |

### TC-VIS-016: Match VIS items by Item Code, not by description

| Field | Value |
|---|---|
| Story section | BR-07 |
| Category | Negative |
| DB check | Item match query |

**Preconditions**

1. A customer item with a description similar to a VIS item but a different code.

| # | Action | Expected result |
|---|---|---|
| 1 | Review the VIS list. | The customer item is not shown as matched; no Add button for it. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-016_ui_no_desc_match.png | TC-VIS-016: VIS row and customer item with similar names, not matched |
| TC-VIS-016_db_Q_match.png | TC-VIS-016: SSMS: codes differ |

### TC-VIS-017: Match Item Code with case, space and dash differences

| Field | Value |
|---|---|
| Story section | BR-07 |
| Category | Boundary |
| DB check | Item match query |

**Preconditions**

1. Customer items whose codes differ from a VIS code only by case, spaces or dashes.

| # | Action | Expected result |
|---|---|---|
| 1 | Review the VIS list. | Matching follows the business rule for code format. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-017_ui_code_format.png | TC-VIS-017: VIS code and customer code shown side by side |
| TC-VIS-017_db_Q_match.png | TC-VIS-017: SSMS: exact stored codes |

**Note:** Needs Clarification (Q7): expected result pending the business answer; executed after the answer.

### TC-VIS-018: Block adding a compatible item that breaks Work Order rules

| Field | Value |
|---|---|
| Story section | BR-07, AC-13 |
| Category | Negative |
| DB check | Item eligibility query (to write after query A4) |

**Preconditions**

1. Matched customer items that are inactive, not in the branch, or without a price in the customer price list.

| # | Action | Expected result |
|---|---|---|
| 1 | Try to add each item from VIS. | The item stays unavailable for selection or addition, same as in the normal item list. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-018_ui_ineligible_item.png | TC-VIS-018: Ineligible matched item, blocked Add or message boxed |
| TC-VIS-018_db_Q_item_state.png | TC-VIS-018: SSMS: item status, branch and price rows |

### TC-VIS-019: Show a message when no compatible products are found

| Field | Value |
|---|---|
| Story section | BR-1, UI messages |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A vehicle for which the provider returns no products.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS Compatible Items. | Message: "No compatible products were found for the selected vehicle". |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-019_ui_no_products.png | TC-VIS-019: No compatible products message boxed |

**Note:** Needs Clarification (Q2, vehicle with no results): expected result pending the business answer; executed after the answer.

### TC-VIS-020: Show a message when no compatible items exist in the customer database

| Field | Value |
|---|---|
| Story section | BR-05, UI messages |
| Category | Negative |
| DB check | Item match query |

**Preconditions**

1. A vehicle whose VIS items have no matching code in InvItem.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS Compatible Items. | External references only; message: "No compatible products available in your item database match the selected vehicle." |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-020_ui_no_customer_items.png | TC-VIS-020: Message and list with no Add buttons |
| TC-VIS-020_db_Q_match.png | TC-VIS-020: SSMS: no matches |

### TC-VIS-021: Do not create or change customer items from VIS results

| Field | Value |
|---|---|
| Story section | BR-07 |
| Category | Data integrity |
| DB check | InvItem count query (to write) |

**Preconditions**

1. InvItem count and the matched items read before opening VIS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS, add an item, close VIS. | No new item is created and no item data changes. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-021_db_Q_items_before.png | TC-VIS-021: SSMS before: InvItem count and matched rows |
| TC-VIS-021_db_Q_items_after.png | TC-VIS-021: SSMS after: same count and values |

### TC-VIS-022: Show the engine oil recommendation with related customer items

| Field | Value |
|---|---|
| Story section | BR-1, Objective |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Review the oil recommendation section. | Recommended engine oil grade, type, viscosity, quantity and related customer items are shown. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-022_ui_oil.png | TC-VIS-022: Oil recommendation: grade, type, viscosity, quantity boxed |

**Note:** Needs Clarification (Q2, expected values): expected result pending the business answer; executed after the answer.

### TC-VIS-023: Close VIS without adding items

| Field | Value |
|---|---|
| Story section | Lifecycle |
| Category | Alternative / Cancel |
| DB check | WO lines query |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS and close it without clicking Add. | The Work Order cart and totals are unchanged. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-023_ui_close_no_change.png | TC-VIS-023: Cart before and after closing VIS |
| TC-VIS-023_db_Q_wo_lines.png | TC-VIS-023: SSMS: no new Work Order lines |

## 3. Fitment service failure and recovery

### TC-VIS-024: Show an error and Retry when the Fitment Database is unavailable

| Field | Value |
|---|---|
| Story section | BR-1, AC-11 |
| Category | Failure |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.
2. Fitment service made unavailable (method from Q13).

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS Compatible Items. | Message: "The Fitment Database is currently unavailable. Please try again later." A Retry option is available. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-024_ui_service_down.png | TC-VIS-024: Service unavailable message and Retry boxed |

**Note:** Needs Clarification (Q13): expected result pending the business answer; executed after the answer.

### TC-VIS-025: Load the results with Retry after the service is back

| Field | Value |
|---|---|
| Story section | AC-11 |
| Category | Recovery |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Previous case state; service restored.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Retry. | The request is sent again and the compatible items are shown. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-025_ui_retry_ok.png | TC-VIS-025: Results loaded after Retry |

### TC-VIS-026: Do not flag items as compatible when the request fails

| Field | Value |
|---|---|
| Story section | AC-11, BR-05, BR-06 |
| Category | Failure / Data integrity |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Fitment service unavailable.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Work Order item list and enable Compatibility. | No item is flagged or listed as compatible. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-026_ui_no_false_flags.png | TC-VIS-026: Item list during the failure, no compatibility indicators |

### TC-VIS-027: Handle a connection loss during the fitment request

| Field | Value |
|---|---|
| Story section | Failure and recovery |
| Category | Failure |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Disconnect the network right after opening VIS. | An error is shown, MAC1 stays usable and no partial results are shown as compatible. |
| 2 | Reconnect and Retry. | Results load normally. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-027_ui_conn_loss.png | TC-VIS-027: Error after network loss |
| TC-VIS-027_ui_conn_retry.png | TC-VIS-027: Results after reconnect and Retry |

### TC-VIS-028: Click VIS repeatedly

| Field | Value |
|---|---|
| Story section | BR-1.2, Lifecycle |
| Category | Negative / Repeat |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Click the VIS icon several times quickly. | Only one VIS screen opens and no duplicate lines are added to the Work Order. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-028_ui_repeat_click.png | TC-VIS-028: Single VIS screen after repeated clicks |

## 4. Compatibility filter

### TC-VIS-029: Show the Compatibility filter in Work Order item selection

| Field | Value |
|---|---|
| Story section | BR-05 |
| Category | Positive / UI |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the item-selection filters. | A filter named Compatibility is in the list. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-029_ui_filter_present.png | TC-VIS-029: Filter list with Compatibility boxed |

### TC-VIS-030: Show only compatible items when the filter is enabled

| Field | Value |
|---|---|
| Story section | BR-05, AC-06, Workflow B |
| Category | Positive |
| DB check | Item match query |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enable Compatibility. | Only customer items whose code matches VIS results are listed. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-030_ui_filter_on.png | TC-VIS-030: Filtered list with Compatibility enabled |
| TC-VIS-030_db_Q_match.png | TC-VIS-030: SSMS: matched codes equal the listed items |

### TC-VIS-031: Show the normal list when the filter is disabled

| Field | Value |
|---|---|
| Story section | BR-05, AC-07 |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Compatibility enabled with another filter active.

| # | Action | Expected result |
|---|---|---|
| 1 | Disable Compatibility. | The normal item list is shown with the other active filter still applied. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-031_ui_filter_off.png | TC-VIS-031: List after disabling Compatibility, other filter boxed |

### TC-VIS-032: Combine Compatibility with name, number, brand and kind filters

| Field | Value |
|---|---|
| Story section | BR-05, AC-14 |
| Category | Alternative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enable Compatibility and add each of the other filters in turn. | All active filters are applied together. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-032_ui_filter_combo.png | TC-VIS-032: List with Compatibility plus another filter, both boxed |

### TC-VIS-033: Use Compatibility on Service, Package and Item screens

| Field | Value |
|---|---|
| Story section | BR-05 |
| Category | Alternative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Enable Compatibility on each item-selection screen. | The filter works on every screen named by the business. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-033_ui_filter_service.png | TC-VIS-033: Service screen with Compatibility on |
| TC-VIS-033_ui_filter_package.png | TC-VIS-033: Package screen with Compatibility on |

**Note:** Needs Clarification (Q9): expected result pending the business answer; executed after the answer.

### TC-VIS-034: Hide or disable Compatibility when no vehicle is selected

| Field | Value |
|---|---|
| Story section | BR-05 |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order without a vehicle.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the item-selection filters. | Compatibility is not available. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-034_ui_filter_no_vehicle.png | TC-VIS-034: Filter list without a vehicle, Compatibility state boxed |

### TC-VIS-035: Show a clear indication when the filter finds no customer items

| Field | Value |
|---|---|
| Story section | BR-05 |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A vehicle with no matching customer items.

| # | Action | Expected result |
|---|---|---|
| 1 | Enable Compatibility. | A clear indication that no products are available is shown. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-035_ui_filter_empty.png | TC-VIS-035: Empty filtered list with its message |

## 5. Compatibility indicator

### TC-VIS-036: Show the compatibility indicator on compatible item cards

| Field | Value |
|---|---|
| Story section | BR-06, AC-08 |
| Category | Positive |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the normal item list. | Items confirmed compatible show the indicator. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-036_ui_indicator.png | TC-VIS-036: Item card with the compatibility indicator boxed |

### TC-VIS-037: Show the same indicator in VIS results and the item list

| Field | Value |
|---|---|
| Story section | BR-06 |
| Category | Integration / UI |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Compare the same item in VIS results and in the item list. | The indicator is consistent in both places. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-037_ui_indicator_vis.png | TC-VIS-037: Item in VIS results |
| TC-VIS-037_ui_indicator_list.png | TC-VIS-037: Same item in the item list |

### TC-VIS-038: Do not show the indicator on items without confirmed compatibility

| Field | Value |
|---|---|
| Story section | BR-06 |
| Category | Negative |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Review items not returned by VIS. | No positive compatibility indicator is shown. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-038_ui_no_indicator.png | TC-VIS-038: Non-compatible item card without indicator |

## 6. Vehicle change

### TC-VIS-039: Refresh results and indicators when the vehicle changes

| Field | Value |
|---|---|
| Story section | BR-01, BR-06, AC-10 |
| Category | State |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Work Order where the vehicle can be changed (vehicle not tracked); VIS opened for 5281DRB.

| # | Action | Expected result |
|---|---|---|
| 1 | Change the vehicle to 5282GZT Tahoe. | Old compatibility results and indicators are cleared. |
| 2 | Open VIS and the item list again. | Results and indicators belong to 5282GZT. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-039_ui_vehicle_a.png | TC-VIS-039: Results for 5281DRB |
| TC-VIS-039_ui_vehicle_b.png | TC-VIS-039: Results for 5282GZT after the change |

### TC-VIS-040: Refresh compatibility when the vehicle changes on Quick Sales

| Field | Value |
|---|---|
| Story section | BR-05 |
| Category | Integration |
| DB check | No DB impact (UI only) |

**Preconditions**

1. Quick Sales screen with a vehicle and Compatibility enabled.

| # | Action | Expected result |
|---|---|---|
| 1 | Change the vehicle. | Compatibility results refresh for the new vehicle. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-040_ui_qs_before.png | TC-VIS-040: Quick Sales list before |
| TC-VIS-040_ui_qs_after.png | TC-VIS-040: Quick Sales list after the vehicle change |

**Note:** Needs Clarification (Q9): expected result pending the business answer; executed after the answer.

## 7. History

### TC-VIS-041: Show the last visits of the vehicle in History

| Field | Value |
|---|---|
| Story section | BR-2 |
| Category | Positive / Integration |
| DB check | Query B2 |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.
2. 5281DRB has earlier Work Orders (query B2).

| # | Action | Expected result |
|---|---|---|
| 1 | Open the History tab. | Each visit shows mileage, visit date, WO number, WO total, services/packages/products with kind, and user. |
| 2 | Compare with query B2. | Same visits, order and values. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-041_ui_history.png | TC-VIS-041: History tab, one visit row boxed |
| TC-VIS-041_db_Q_B2.png | TC-VIS-041: SSMS: Work Orders of 5281DRB, same row boxed |

**Note:** Needs Clarification (Q5, number of visits and statuses): expected result pending the business answer; executed after the answer.

### TC-VIS-042: Show History for a vehicle with no previous visits

| Field | Value |
|---|---|
| Story section | BR-2 |
| Category | Boundary |
| DB check | Query B2 |

**Preconditions**

1. A vehicle with its first Work Order.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the History tab. | An empty history is shown without errors. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-042_ui_history_empty.png | TC-VIS-042: Empty History tab |
| TC-VIS-042_db_Q_B2.png | TC-VIS-042: SSMS: no earlier Work Orders |

## 8. Maintenance

### TC-VIS-043: List services performed on the vehicle in Maintenance

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Positive |
| DB check | Maintenance query (to write after query A1, A4) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Maintenance tab. | Each service shows Service Name, Service Number, Last Service Date, Next Due Date, Next Due Mileage and status. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-043_ui_maint.png | TC-VIS-043: Maintenance tab with the columns boxed |
| TC-VIS-043_db_Q_maint.png | TC-VIS-043: SSMS: service lines of the vehicle |

**Note:** Needs Clarification (Q6): expected result pending the business answer; executed after the answer.

### TC-VIS-044: Show Overdue in red when the due date or mileage is exceeded

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Positive / State |
| DB check | Maintenance query |

**Preconditions**

1. A service whose next due date or mileage has passed.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Maintenance. | Status Overdue in red. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-044_ui_overdue.png | TC-VIS-044: Overdue row in red, boxed |

**Note:** Needs Clarification (Q6): expected result pending the business answer; executed after the answer.

### TC-VIS-045: Show Up to Date in black when the service is not due

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Positive / State |
| DB check | Maintenance query |

**Preconditions**

1. A service not yet due.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Maintenance. | Status Up to Date in black. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-045_ui_uptodate.png | TC-VIS-045: Up to Date row in black, boxed |

**Note:** Needs Clarification (Q6): expected result pending the business answer; executed after the answer.

### TC-VIS-046: Show Added to Current WO in green for services in this Work Order

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Positive / Integration |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A service added to the current Work Order.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Maintenance. | Status Added to Current WO in green. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-046_ui_added_green.png | TC-VIS-046: Service in the cart and green status in Maintenance |

### TC-VIS-047: Give priority to Overdue when date and mileage disagree

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Boundary |
| DB check | Maintenance query |

**Preconditions**

1. A service overdue by mileage but not by date (and the reverse).

| # | Action | Expected result |
|---|---|---|
| 1 | Open Maintenance. | Status is Overdue in both cases. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-047_ui_overdue_priority.png | TC-VIS-047: Row with one limit exceeded, Overdue boxed |

**Note:** Needs Clarification (Q6): expected result pending the business answer; executed after the answer.

### TC-VIS-048: Show Maintenance for a service with no interval configured

| Field | Value |
|---|---|
| Story section | BR-2 Maintenance |
| Category | Boundary |
| DB check | No DB impact (UI only) |

**Preconditions**

1. A service item without next reminder period or mileage.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Maintenance. | Status follows the business answer. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-048_ui_no_interval.png | TC-VIS-048: Service without interval in Maintenance |

**Note:** Needs Clarification (Q6): expected result pending the business answer; executed after the answer.

## 9. End to end and data integrity

### TC-VIS-049: Save and pay a Work Order with an item added from VIS

| Field | Value |
|---|---|
| Story section | Workflow A, BR-07 |
| Category | Integration |
| DB check | Stock chain queries (to write, as in US-214) |

**Preconditions**

1. Work Order with an item added from VIS.

| # | Action | Expected result |
|---|---|---|
| 1 | Complete and pay the Work Order. | Totals, price and VAT equal adding the same item from the normal list. |
| 2 | Check the stock chain. | Stock out, store transaction and invoice link exist as for any Work Order item. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-049_ui_wo_paid.png | TC-VIS-049: Paid Work Order with the VIS item boxed |
| TC-VIS-049_db_Q_stock_chain.png | TC-VIS-049: SSMS: stock out, store transaction and invoice link rows |

### TC-VIS-050: Show the completed Work Order in History on the next visit

| Field | Value |
|---|---|
| Story section | BR-2 |
| Category | Integration |
| DB check | Query B2 |

**Preconditions**

1. Previous case completed.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a new Work Order for the same vehicle and open History. | The completed Work Order is the latest visit. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-050_ui_history_new.png | TC-VIS-050: History with the new visit on top |
| TC-VIS-050_db_Q_B2.png | TC-VIS-050: SSMS: the same Work Order |

### TC-VIS-051: Record the VIS usage event

| Field | Value |
|---|---|
| Story section | BR-1.2, AC-12 |
| Category | Integration |
| DB check | Usage query (after query A1) |

**Preconditions**

1. A Work Order is open on MAC1 for QA customer vehicle 5281DRB Sportage (full vehicle details), company confirmed in MAC1 and SSMS.

| # | Action | Expected result |
|---|---|---|
| 1 | Open VIS once. | One usage record is created with the fields in BR-1.2. |

**Screenshots to capture**

| File | Caption on the image |
|---|---|
| TC-VIS-051_db_Q_usage.png | TC-VIS-051: SSMS: usage record row |

**Note:** Needs Clarification (Q1, usage counter in scope or not): expected result pending the business answer; executed after the answer.

## Case index

| ID | Title | Story section | Category | Status |
|---|---|---|---|---|
| TC-VIS-001 | Show the Vehicle Advisory (VIS) icon on the Work Order | Scope, BR-01 | Positive / UI | Ready |
| TC-VIS-002 | Open the Vehicle Advisory screen with its sections | Scope, BR-1, BR-2 | Positive / UI | Needs Clarification |
| TC-VIS-003 | Open VIS directly for a vehicle that has full details | BR-01, AC-01 | Positive | Ready |
| TC-VIS-004 | Block VIS when no vehicle is on the Work Order | BR-01, UI messages | Negative | Ready |
| TC-VIS-005 | Show a message when the vehicle details are incomplete | BR-01, UI messages | Negative | Needs Clarification |
| TC-VIS-006 | Retrieve Make, Model and Year from a valid VIN | Scope, BR-01 | Positive | Needs Clarification |
| TC-VIS-007 | Reject an invalid VIN | BR-01 | Negative | Needs Clarification |
| TC-VIS-008 | Require the VIN when it is left empty | BR-01 | Negative / Boundary | Ready |
| TC-VIS-009 | Save the vehicle details retrieved by the VIN | BR-01 | Integration / Data integrity | Needs Clarification |
| TC-VIS-010 | Use VIS with no license check | BR-1.1, Development field | Positive | Needs Clarification |
| TC-VIS-011 | Retrieve compatible items with Item Code, Kind and OEM tag | BR-1, AC-03 | Positive | Needs Clarification |
| TC-VIS-012 | Show the Add button only beside matching customer items | BR-1, AC-05 | Positive | Ready |
| TC-VIS-013 | Show external items as references that cannot be added | BR-1, BR-07, AC-04 | Negative | Ready |
| TC-VIS-014 | Add a compatible customer item to the Work Order | BR-1, AC-05, Workflow A | Positive / Integration | Ready |
| TC-VIS-015 | Add the same compatible item twice | BR-07 | Negative / Duplicate | Ready |
| TC-VIS-016 | Match VIS items by Item Code, not by description | BR-07 | Negative | Ready |
| TC-VIS-017 | Match Item Code with case, space and dash differences | BR-07 | Boundary | Needs Clarification |
| TC-VIS-018 | Block adding a compatible item that breaks Work Order rules | BR-07, AC-13 | Negative | Ready |
| TC-VIS-019 | Show a message when no compatible products are found | BR-1, UI messages | Negative | Needs Clarification |
| TC-VIS-020 | Show a message when no compatible items exist in the customer database | BR-05, UI messages | Negative | Ready |
| TC-VIS-021 | Do not create or change customer items from VIS results | BR-07 | Data integrity | Ready |
| TC-VIS-022 | Show the engine oil recommendation with related customer items | BR-1, Objective | Positive | Needs Clarification |
| TC-VIS-023 | Close VIS without adding items | Lifecycle | Alternative / Cancel | Ready |
| TC-VIS-024 | Show an error and Retry when the Fitment Database is unavailable | BR-1, AC-11 | Failure | Needs Clarification |
| TC-VIS-025 | Load the results with Retry after the service is back | AC-11 | Recovery | Ready |
| TC-VIS-026 | Do not flag items as compatible when the request fails | AC-11, BR-05, BR-06 | Failure / Data integrity | Ready |
| TC-VIS-027 | Handle a connection loss during the fitment request | Failure and recovery | Failure | Ready |
| TC-VIS-028 | Click VIS repeatedly | BR-1.2, Lifecycle | Negative / Repeat | Ready |
| TC-VIS-029 | Show the Compatibility filter in Work Order item selection | BR-05 | Positive / UI | Ready |
| TC-VIS-030 | Show only compatible items when the filter is enabled | BR-05, AC-06, Workflow B | Positive | Ready |
| TC-VIS-031 | Show the normal list when the filter is disabled | BR-05, AC-07 | Positive | Ready |
| TC-VIS-032 | Combine Compatibility with name, number, brand and kind filters | BR-05, AC-14 | Alternative | Ready |
| TC-VIS-033 | Use Compatibility on Service, Package and Item screens | BR-05 | Alternative | Needs Clarification |
| TC-VIS-034 | Hide or disable Compatibility when no vehicle is selected | BR-05 | Negative | Ready |
| TC-VIS-035 | Show a clear indication when the filter finds no customer items | BR-05 | Negative | Ready |
| TC-VIS-036 | Show the compatibility indicator on compatible item cards | BR-06, AC-08 | Positive | Ready |
| TC-VIS-037 | Show the same indicator in VIS results and the item list | BR-06 | Integration / UI | Ready |
| TC-VIS-038 | Do not show the indicator on items without confirmed compatibility | BR-06 | Negative | Ready |
| TC-VIS-039 | Refresh results and indicators when the vehicle changes | BR-01, BR-06, AC-10 | State | Ready |
| TC-VIS-040 | Refresh compatibility when the vehicle changes on Quick Sales | BR-05 | Integration | Needs Clarification |
| TC-VIS-041 | Show the last visits of the vehicle in History | BR-2 | Positive / Integration | Needs Clarification |
| TC-VIS-042 | Show History for a vehicle with no previous visits | BR-2 | Boundary | Ready |
| TC-VIS-043 | List services performed on the vehicle in Maintenance | BR-2 Maintenance | Positive | Needs Clarification |
| TC-VIS-044 | Show Overdue in red when the due date or mileage is exceeded | BR-2 Maintenance | Positive / State | Needs Clarification |
| TC-VIS-045 | Show Up to Date in black when the service is not due | BR-2 Maintenance | Positive / State | Needs Clarification |
| TC-VIS-046 | Show Added to Current WO in green for services in this Work Order | BR-2 Maintenance | Positive / Integration | Ready |
| TC-VIS-047 | Give priority to Overdue when date and mileage disagree | BR-2 Maintenance | Boundary | Needs Clarification |
| TC-VIS-048 | Show Maintenance for a service with no interval configured | BR-2 Maintenance | Boundary | Needs Clarification |
| TC-VIS-049 | Save and pay a Work Order with an item added from VIS | Workflow A, BR-07 | Integration | Ready |
| TC-VIS-050 | Show the completed Work Order in History on the next visit | BR-2 | Integration | Ready |
| TC-VIS-051 | Record the VIS usage event | BR-1.2, AC-12 | Integration | Needs Clarification |
