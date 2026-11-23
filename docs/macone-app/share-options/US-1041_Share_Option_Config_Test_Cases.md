# MAC One Share Option Configurations: Test Cases

## Document purpose

Manual test cases for User Story 1041 "myShop POS - Share option Configurations & document assignment".

| Item | Value |
|---|---|
| Target | MAC One desktop application, QA environment |
| Screen | Administration > Share Option Configurations (story path: POS Settings > Share option Configurations) |
| Story revision | Rev 47 (description updated 2026-11-15) |
| Azure DevOps | Plan 1882 "MAC1 - POS", Tested By User Story 1041. IDs 2036 to 2093 in order, map in [Share_Option_Config_AzureDevOps_Map.csv](./Share_Option_Config_AzureDevOps_Map.csv) |
| Created | 2026-11-15 |
| Order | Related ideas are grouped together in a logical flow. The "Story section" field on each case links it back to the story |
| Not testable (no report) | Credit Note, Customer Statement, Payment Receipt, Barcode / Item Label (comment on the story) |

## General test data

1. QA POS terminal "POS 01" (main QA machine) and a second terminal "POS 02" of the same company.
2. Windows printers on POS 01: "Microsoft Print to PDF" plus at least one physical USB printer (receipt or A4) that can be unplugged or switched off.
3. Documents with a report: Sales Invoice, Work Order, Cash Deposit, Stock Adjustment.
4. A customer with a mobile number and an email, for the SMS, WhatsApp and Email cases.

## Open questions

1. Hard Copy: the story says "force user to select the printer" and also "Allow null" (TC-SOC-028).
2. Section 2.6 talks about one default printer per document, while section 1 now allows multiple printers per document (TC-SOC-027, TC-SOC-032).
3. Is Auto flag is struck out, but the line "configure if this is an auto option" is still there. Is there any automatic printing (TC-SOC-039)?
4. Export type: how does it apply to Hard Copy compared with SMS, WhatsApp and Email (TC-SOC-031)?
5. The printer list has two columns named Status (connection status and Active/Inactive).
6. Connection values "USB / Cable" are the same thing. Are network printers in scope?
7. Reassign & Deactivate: the story does not describe the reassign flow (TC-SOC-057).
8. Section 2.11 title says "Remove / Deactivate" but only deactivation is described. The app has Delete (bug 1827, TC-SOC-058).
9. Print Count limits (0, negative, maximum) are not defined (TC-SOC-030).
10. The rev 47 changes (multiple printers, section 2.7) may not be in build 1.2.457. Confirm the build that includes them.

## Test cases

### 1. Printer Registration and Printer Name

#### TC-SOC-001: Open Share Option Configurations and show the printer list

| Field | Value |
|---|---|
| Azure DevOps ID | 2036 |
| Story section | 2 Printer Management |
| Category | Positive / UI |

**Preconditions/data**

1. At least one printer is registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Log in to MAC One on POS 01 as an administrator. |  |
| 2 | Open Administration > Share Option Configurations. | The screen opens with a Printer Management section. |
| 3 | Review the printer list columns. | Columns shown: Printer Name, System Printer Name, Printer Type, Connection, Status, Default Documents, Active/Inactive status. |
| 4 | Review the registered printer row. | The row shows the correct values for the registered printer. |

#### TC-SOC-002: No manual IP entry is required to register a printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2037 |
| Story section | 2 Printer Management |
| Category | Positive / UI |

**Preconditions/data**

1. None.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Administration > Share Option Configurations and click Add Printer. |  |
| 2 | Review the Add Printer screen. | Printers are detected from the operating system. No IP address or port field is required. |

#### TC-SOC-003: Add Printer shows the printers installed on the terminal

| Field | Value |
|---|---|
| Azure DevOps ID | 2038 |
| Story section | 2.1, 2.1.1 Add Printer / Detect Connected Printers |
| Category | Positive |

**Preconditions/data**

1. Note the printers listed in Windows Settings > Bluetooth & devices > Printers & scanners on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Administration > Share Option Configurations. |  |
| 2 | Click Add Printer. | The Add Printer screen/popup opens. |
| 3 | Review the detected printers list. | Each row shows Printer Name, Printer Driver, Printer Type (if detectable) and Connection Status. |
| 4 | Compare the list with the Windows printers noted before. | All printers installed in Windows are listed, with no missing or extra printers. |

#### TC-SOC-004: A printer installed in Windows later appears in the detected list

| Field | Value |
|---|---|
| Azure DevOps ID | 2039 |
| Story section | 2.1.1 Detect Connected Printers |
| Category | Positive |

**Preconditions/data**

1. MAC One is open on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Install a new printer in Windows (for example add "Microsoft XPS Document Writer" or connect a USB printer). |  |
| 2 | In MAC One, open Add Printer. | The new printer is shown in the detected list. |

#### TC-SOC-005: Select a detected printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2040 |
| Story section | 2.1.1 Detect Connected Printers |
| Category | Positive |

**Preconditions/data**

1. "Microsoft Print to PDF" is not registered yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer. |  |
| 2 | Select "Microsoft Print to PDF" from the detected list. | The printer is selected and its system information is filled in automatically. |

#### TC-SOC-006: Show the detected printer details

| Field | Value |
|---|---|
| Azure DevOps ID | 2041 |
| Story section | 2.3 Printer Details |
| Category | Positive / UI |

**Preconditions/data**

1. A physical USB printer is installed on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select the USB printer. |  |
| 2 | Review the printer information. | MAC One Printer Name, System Printer Name, Manufacturer, Model, Driver, Connection Type, Printer Status, Paper Size (if available) and Printer Type are shown. |
| 3 | Compare the values with the printer properties in Windows. | System Printer Name, Driver and Connection Type match Windows. |

#### TC-SOC-007: Operating system fields are read only

| Field | Value |
|---|---|
| Azure DevOps ID | 2042 |
| Story section | 2.3 Printer Details |
| Category | Negative / UI |

**Preconditions/data**

1. None.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select a detected printer. |  |
| 2 | Try to edit System Printer Name, Manufacturer, Model, Driver, Connection Type and Printer Status. | These fields are read only. |
| 3 | Edit MAC One Printer Name. | MAC One Printer Name is editable. |

#### TC-SOC-008: Printer Type values

| Field | Value |
|---|---|
| Azure DevOps ID | 2043 |
| Story section | 2.4 Printer Type |
| Category | Positive / UI |

**Preconditions/data**

1. None.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select a detected printer. |  |
| 2 | Open the Printer Type list. | The values are Receipt Printer, A4 Printer, Label Printer and Other. |

#### TC-SOC-009: Printer Type is suggested and can be changed

| Field | Value |
|---|---|
| Azure DevOps ID | 2044 |
| Story section | 2.4 Printer Type |
| Category | Positive |

**Preconditions/data**

1. A receipt printer (or another printer with a known type) is installed on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select the printer. | Printer Type is suggested from the detected printer or driver, when detectable. |
| 2 | Change Printer Type to "Other", enter a name and save. | The printer is saved. |
| 3 | Review the printer list. | Printer Type shows "Other". |

#### TC-SOC-010: Register a printer with a MAC One Printer Name

| Field | Value |
|---|---|
| Azure DevOps ID | 2045 |
| Story section | 2.2 Printer Name |
| Category | Positive |

**Preconditions/data**

1. "Microsoft Print to PDF" is not registered yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select "Microsoft Print to PDF". |  |
| 2 | Enter MAC One Printer Name "QA PDF Printer" and save. | The printer is saved with no error. |
| 3 | Review the printer list. | The row shows Printer Name "QA PDF Printer" and System Printer Name "Microsoft Print to PDF". |
| 4 | Open a document assignment and open the printer list for Hard Copy. | "QA PDF Printer" is available for selection by its MAC One name. |

#### TC-SOC-011: Printer Name is required

| Field | Value |
|---|---|
| Azure DevOps ID | 2046 |
| Story section | 2.2 Printer Name / Validation |
| Category | Negative |

**Preconditions/data**

1. None.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select a detected printer. |  |
| 2 | Leave MAC One Printer Name empty and try to save. | The printer is not saved and a required field message is shown. |
| 3 | Enter only spaces in MAC One Printer Name and try to save. | The printer is not saved and a required field message is shown. |

#### TC-SOC-012: Printer Name must be unique within the terminal

| Field | Value |
|---|---|
| Azure DevOps ID | 2047 |
| Story section | 2.2 Printer Name / Validation |
| Category | Negative |

**Preconditions/data**

1. "QA PDF Printer" is registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select another detected printer. |  |
| 2 | Enter MAC One Printer Name "QA PDF Printer" and save. | The message "This printer name already exists. Please enter a different name." is shown and the printer is not saved. |
| 3 | Enter "qa pdf printer" (different letter case) and save. | The duplicate message is shown and the printer is not saved. |

#### TC-SOC-013: Duplicate name validation on Edit Printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2048 |
| Story section | 2.2 / 2.10 |
| Category | Negative |

**Preconditions/data**

1. Two printers are registered on POS 01: "QA PDF Printer" and "QA Printer B".

| # | Action | Expected result |
|---|---|---|
| 1 | Open "QA Printer B" in Edit Printer, change the name to "QA PDF Printer" and save. | The message "This printer name already exists. Please enter a different name." is shown and the change is not saved. |
| 2 | Save "QA Printer B" without changing its name. | The printer is saved with no duplicate message. |

#### TC-SOC-014: The same Printer Name is allowed on a different terminal

| Field | Value |
|---|---|
| Azure DevOps ID | 2049 |
| Story section | 2.9 Printer Availability Per POS / 2.2 Printer Name |
| Category | Positive |

**Preconditions/data**

1. "QA PDF Printer" is registered on POS 01.
2. POS 02 of the same company has no printer with this name.

| # | Action | Expected result |
|---|---|---|
| 1 | Log in to MAC One on POS 02 and open Add Printer. |  |
| 2 | Select a detected printer, enter MAC One Printer Name "QA PDF Printer" and save. | The printer is saved with no duplicate message. |

#### TC-SOC-015: Printer configuration is saved per terminal

| Field | Value |
|---|---|
| Azure DevOps ID | 2050 |
| Story section | 2.9 Printer Availability Per POS |
| Category | Positive |

**Preconditions/data**

1. POS 01 and POS 02 belong to the same company.
2. POS 01 has "QA PDF Printer" assigned to Sales Invoice.

| # | Action | Expected result |
|---|---|---|
| 1 | Log in on POS 02 and open the printer list. | Printers registered on POS 01 are not shown on POS 02. |
| 2 | On POS 02, register a different printer and assign it to Sales Invoice. |  |
| 3 | Print a Sales Invoice on each terminal. | POS 01 prints on its own printer and POS 02 prints on its own printer. |
| 4 | Go back to POS 01 and open the printer list. | The POS 01 configuration is unchanged. |

### 2. Test Print

#### TC-SOC-016: Test Print from Add Printer succeeds

| Field | Value |
|---|---|
| Azure DevOps ID | 2051 |
| Story section | 2.5 Test Printer |
| Category | Positive |

**Preconditions/data**

1. A connected printer is installed on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer and select the connected printer. |  |
| 2 | Click Test Print. | The message "Test print was sent successfully to the printer." is shown, together with the printer status. |
| 3 | Check the printer output. | A test page is printed (or saved as PDF for Microsoft Print to PDF). |

#### TC-SOC-017: Test Print from Edit Printer succeeds

| Field | Value |
|---|---|
| Azure DevOps ID | 2052 |
| Story section | 2.5 Test Printer |
| Category | Positive / Regression (bug 1838) |

**Preconditions/data**

1. A connected printer is registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the registered printer in Edit Printer. |  |
| 2 | Click Test Print. | A test print is sent to the printer and the success message is shown. No upload file form opens. |

#### TC-SOC-018: Test Print fails when the printer is unavailable

| Field | Value |
|---|---|
| Azure DevOps ID | 2053 |
| Story section | 2.5 Test Printer |
| Category | Negative |

**Preconditions/data**

1. A physical USB printer is registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Unplug the printer or switch it off. |  |
| 2 | Open the printer in Edit Printer and click Test Print. | The message "Unable to print. Please check that the printer is connected, turned on, and available on this POS terminal." is shown. |
| 3 | Review the printer status on the screen. | The detected status shows Disconnected or Error. |

### 3. Edit Printer

#### TC-SOC-019: Edit printer name, type and status

| Field | Value |
|---|---|
| Azure DevOps ID | 2054 |
| Story section | 2.10 Edit Printer |
| Category | Positive |

**Preconditions/data**

1. "QA PDF Printer" is registered and assigned to Sales Invoice.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "QA PDF Printer" in Edit Printer. |  |
| 2 | Change the name to "QA PDF Printer 2" and Printer Type to A4 Printer, then save. | The changes are saved. |
| 3 | Review the printer list and the Sales Invoice configuration. | Both show "QA PDF Printer 2" with type A4 Printer. Sales Invoice is still assigned to it. |

#### TC-SOC-020: System printer cannot be changed on Edit Printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2055 |
| Story section | 2.10 Edit Printer |
| Category | Negative / UI |

**Preconditions/data**

1. A printer is registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the printer in Edit Printer. |  |
| 2 | Try to change the System Printer Name or select another detected printer. | The system printer cannot be changed. |

### 4. Document Assignment and Share Options

#### TC-SOC-021: Add a document to the share configuration

| Field | Value |
|---|---|
| Azure DevOps ID | 2056 |
| Story section | 1 Document Assignment / 2.6 |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice has no share configuration yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Administration > Share Option Configurations. |  |
| 2 | Click the Add button in the document section. | A list of supported documents is shown. |
| 3 | Review the documents in the list. | Only documents supported by MAC One for the company business category are listed. |
| 4 | Select Sales Invoice. | Sales Invoice is added with fields for Share Option, Layout, Printer, Print Count and Export Type. |

#### TC-SOC-022: Documents without a report cannot be assigned

| Field | Value |
|---|---|
| Azure DevOps ID | 2057 |
| Story section | 1 Document Assignment / comment on the story |
| Category | Negative / Regression (bug 1825) |

**Preconditions/data**

1. Credit Note, Customer Statement, Payment Receipt and Barcode / Item Label have no report.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the document list from Add in the document section. | Documents without a report are not offered. |
| 2 | Open a printer in Edit Printer and open its document assignment list. | Documents without a report are not offered. |

#### TC-SOC-023: Select multiple share options for one document

| Field | Value |
|---|---|
| Azure DevOps ID | 2058 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice is added to the share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | For Sales Invoice, select Hard Copy, SMS, WhatsApp and Email. | All four options can be selected together. |
| 2 | Save, then close and reopen the screen. | All four options are still selected for Sales Invoice. |

#### TC-SOC-024: Select a different layout for each share option

| Field | Value |
|---|---|
| Azure DevOps ID | 2059 |
| Story section | 1 Document Assignment |
| Category | Positive / Regression (bug 1836) |

**Preconditions/data**

1. Sales Invoice has Hard Copy and Email selected.
2. Sales Invoice has at least two layouts.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Layout list for Hard Copy. | The Layout field is editable and lists the available layouts. |
| 2 | Select layout A for Hard Copy and layout B for Email, then save. | The configuration is saved. |
| 3 | Reopen the screen. | Hard Copy shows layout A and Email shows layout B. |

#### TC-SOC-025: Layout list shows only the layouts of the selected document

| Field | Value |
|---|---|
| Azure DevOps ID | 2060 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice and Work Order are added to the share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Layout list for Sales Invoice. | Only Sales Invoice layouts are listed. |
| 2 | Open the Layout list for Work Order. | Only Work Order layouts are listed. |

#### TC-SOC-026: Configure Hard Copy for a document

| Field | Value |
|---|---|
| Azure DevOps ID | 2061 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. "QA PDF Printer" is registered and active (see TC-SOC-010).
2. Sales Invoice is added to the share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | For Sales Invoice, select Share Option Hard Copy. | Printer and Print Count fields are shown for Hard Copy. |
| 2 | Select a Layout, select printer "QA PDF Printer", enter Print Count 2 and save. | The configuration is saved with no error. |
| 3 | Close and reopen the screen. | Sales Invoice shows Hard Copy, the selected Layout, "QA PDF Printer" and Print Count 2. |

#### TC-SOC-027: Select multiple printers for Hard Copy

| Field | Value |
|---|---|
| Azure DevOps ID | 2062 |
| Story section | 1 Document Assignment (rev 47) |
| Category | Positive |

**Preconditions/data**

1. Two active printers are registered on POS 01: "QA PDF Printer" and a second printer.

| # | Action | Expected result |
|---|---|---|
| 1 | For Sales Invoice Hard Copy, select both printers and save. | The configuration is saved with both printers. |
| 2 | Reopen the screen. | Both printers are shown for Sales Invoice Hard Copy. |

#### TC-SOC-028: Hard Copy can be saved without a printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2063 |
| Story section | 1 Document Assignment |
| Category | Positive / Boundary |

**Preconditions/data**

1. Work Order is added to the share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | For Work Order, select Hard Copy and a Layout, leave the printer empty and save. | The configuration is saved (printer allows null). |

#### TC-SOC-029: Print Count can be empty

| Field | Value |
|---|---|
| Azure DevOps ID | 2064 |
| Story section | 1 Document Assignment |
| Category | Positive / Regression (bug 1839) |

**Preconditions/data**

1. Sales Invoice has Hard Copy selected with a printer.

| # | Action | Expected result |
|---|---|---|
| 1 | Clear Print Count and save. | The configuration is saved with no validation error. |
| 2 | Reopen the screen. | Print Count is empty. |

#### TC-SOC-030: Print Count rejects invalid values

| Field | Value |
|---|---|
| Azure DevOps ID | 2065 |
| Story section | 1 Document Assignment |
| Category | Negative |

**Preconditions/data**

1. Sales Invoice has Hard Copy selected with a printer.

| # | Action | Expected result |
|---|---|---|
| 1 | Enter Print Count 0 and save. | The value is not accepted, or a clear validation message is shown. |
| 2 | Enter Print Count -1 and save. | The value is not accepted, or a clear validation message is shown. |
| 3 | Enter Print Count 1.5 and then letters. | Decimals and letters are not accepted. |

#### TC-SOC-031: Select an export type for a share option

| Field | Value |
|---|---|
| Azure DevOps ID | 2066 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice has Hard Copy and Email selected.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Export Type list for Email. | Export types such as PDF, CSV, PNG and XLS are listed. |
| 2 | Select PDF and save, then reopen the screen. | PDF is saved for Email. |

#### TC-SOC-032: Assign a default printer per document

| Field | Value |
|---|---|
| Azure DevOps ID | 2067 |
| Story section | 2.6 Default Printer by Document |
| Category | Positive |

**Preconditions/data**

1. A receipt printer and an A4 printer (or "QA PDF Printer") are registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Assign Sales Invoice to the receipt printer and Cash Deposit to the A4 printer, then save. | The configuration is saved. |
| 2 | Review the printer list. | Default Documents shows Sales Invoice for the receipt printer and Cash Deposit for the A4 printer. |

#### TC-SOC-033: Export types are set when a document is added from Add Printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2068 |
| Story section | 2.6 Default Printer by Document |
| Category | Positive / Regression (bug 1831) |

**Preconditions/data**

1. A detected printer is not registered yet.

| # | Action | Expected result |
|---|---|---|
| 1 | Open Add Printer, select the printer and enter a name. |  |
| 2 | Add Sales Invoice to the printer document assignments and save. |  |
| 3 | Open Sales Invoice in the document configuration. | The export type is selected automatically, the same as when the document is added from the document section. |

#### TC-SOC-034: Edit document assignments from Edit Printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2069 |
| Story section | 2.10 Edit Printer |
| Category | Positive |

**Preconditions/data**

1. "QA PDF Printer" is registered.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the printer in Edit Printer and add Work Order to its documents, then save. | Default Documents of the printer shows Work Order. |
| 2 | Open the Work Order share configuration. | Hard Copy uses this printer. |
| 3 | Remove Work Order from the printer and save. | Work Order is no longer in Default Documents of the printer. |

#### TC-SOC-035: Change and remove a document configuration

| Field | Value |
|---|---|
| Azure DevOps ID | 2070 |
| Story section | 1 Document Assignment / 2.6 |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice has Hard Copy and Email with "QA PDF Printer".

| # | Action | Expected result |
|---|---|---|
| 1 | Change the Sales Invoice Hard Copy printer to another printer and save. | The new printer is saved and shown in Default Documents of the new printer. |
| 2 | Unselect Email for Sales Invoice and save. | Email is removed and Hard Copy is kept. |
| 3 | Remove Sales Invoice from the document configuration and save. | Sales Invoice is removed and no longer shown in Default Documents of any printer. |

### 5. Printing and Sharing from Documents

#### TC-SOC-036: Print a document with the configured printer, layout and print count

| Field | Value |
|---|---|
| Azure DevOps ID | 2071 |
| Story section | 1 Document Assignment / 2.6 |
| Category | Positive / Regression (bug 1268) |

**Preconditions/data**

1. Sales Invoice: Hard Copy, layout A, printer "QA PDF Printer", Print Count 2.
2. A confirmed Sales Invoice exists.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the confirmed Sales Invoice and click the share option button. | Only the configured share options for Sales Invoice are shown. |
| 2 | Choose Hard Copy. | The invoice is printed to "QA PDF Printer" using layout A. |
| 3 | Check the output. | Two copies are printed. |

#### TC-SOC-037: Print to multiple printers

| Field | Value |
|---|---|
| Azure DevOps ID | 2072 |
| Story section | 1 Document Assignment (rev 47) |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice Hard Copy has two printers selected.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a confirmed Sales Invoice and choose Hard Copy. | The invoice is printed on both printers. |

#### TC-SOC-038: Each document prints on its own printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2073 |
| Story section | 2.6 Default Printer by Document |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice is assigned to the receipt printer and Cash Deposit to the A4 printer.

| # | Action | Expected result |
|---|---|---|
| 1 | Print a Sales Invoice with Hard Copy. | It prints on the receipt printer only. |
| 2 | Print a Cash Deposit with Hard Copy. | It prints on the A4 printer only. |

#### TC-SOC-039: Documents are not printed automatically

| Field | Value |
|---|---|
| Azure DevOps ID | 2074 |
| Story section | 1 Document Assignment (Is Auto flag removed) |
| Category | Negative / Regression (bug 1833) |

**Preconditions/data**

1. Sales Invoice has Hard Copy with a printer.

| # | Action | Expected result |
|---|---|---|
| 1 | Create a Sales Invoice on the POS and confirm the payment. | The invoice is not printed automatically. It prints only when the user chooses a share option. |

#### TC-SOC-040: Share a document by Email

| Field | Value |
|---|---|
| Azure DevOps ID | 2075 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice: Email with layout B and export type PDF.
2. The invoice customer has an email.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a confirmed Sales Invoice, click the share option button and choose Email. | The email is sent to the customer email. |
| 2 | Open the received email. | The invoice is attached as PDF using layout B. |

#### TC-SOC-041: Share a document by WhatsApp

| Field | Value |
|---|---|
| Azure DevOps ID | 2076 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice has WhatsApp configured with a layout and export type.
2. The invoice customer has a mobile number.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a confirmed Sales Invoice, click the share option button and choose WhatsApp. | The document is shared by WhatsApp to the customer mobile number using the configured layout and export type. |

#### TC-SOC-042: Share a document by SMS

| Field | Value |
|---|---|
| Azure DevOps ID | 2077 |
| Story section | 1 Document Assignment |
| Category | Positive |

**Preconditions/data**

1. Sales Invoice has SMS configured with a layout.
2. The invoice customer has a mobile number.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a confirmed Sales Invoice, click the share option button and choose SMS. | An SMS with the document is sent to the customer mobile number. |

### 6. No Share Option Configured

#### TC-SOC-043: Message when a document has no share option

| Field | Value |
|---|---|
| Azure DevOps ID | 2078 |
| Story section | 2.7 No share options are configured |
| Category | Negative |

**Preconditions/data**

1. Work Order has no share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a Work Order and click the share option button. | The message "No share option has been configured for this document. Please select at least one share option." is shown with "Set Share Configurations" and "Cancel" buttons. Nothing fails silently. |

#### TC-SOC-044: Set Share Configurations opens the configuration screen

| Field | Value |
|---|---|
| Azure DevOps ID | 2079 |
| Story section | 2.7 No share options are configured |
| Category | Positive |

**Preconditions/data**

1. Work Order has no share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a Work Order and click the share option button. |  |
| 2 | Click "Set Share Configurations". | The Share Option Configurations screen opens. |
| 3 | Configure Hard Copy for Work Order, save and go back to the Work Order. |  |
| 4 | Click the share option button again. | Hard Copy is offered and the Work Order prints. |

#### TC-SOC-045: Cancel closes the no share option message

| Field | Value |
|---|---|
| Azure DevOps ID | 2080 |
| Story section | 2.7 No share options are configured |
| Category | Positive |

**Preconditions/data**

1. Work Order has no share configuration.

| # | Action | Expected result |
|---|---|---|
| 1 | Open a Work Order and click the share option button. |  |
| 2 | Click "Cancel". | The popup closes. The user stays on the Work Order and nothing is printed or shared. |

### 7. Printer Status and Disconnected Printer

#### TC-SOC-046: Printer status in the list follows the physical printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2081 |
| Story section | 2 Printer Management / 2.8 |
| Category | Positive |

**Preconditions/data**

1. A physical USB printer is registered on POS 01 and connected.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the printer list. | The printer status is Connected. |
| 2 | Unplug the printer and refresh the list. | The printer status is Disconnected or Error. |
| 3 | Plug the printer back in and refresh the list. | The printer status is Connected. |

#### TC-SOC-047: Message when the default printer is unavailable

| Field | Value |
|---|---|
| Azure DevOps ID | 2082 |
| Story section | 2.8 Printer Disconnected |
| Category | Negative |

**Preconditions/data**

1. Sales Invoice Hard Copy uses the physical USB printer, for example "Counter 1 Receipt Printer".

| # | Action | Expected result |
|---|---|---|
| 1 | Unplug the printer. |  |
| 2 | Open a confirmed Sales Invoice and choose Hard Copy. | The message "Counter 1 Receipt Printer is currently unavailable." is shown with Retry, Select Another Printer and Cancel. |

#### TC-SOC-048: Retry prints after the printer is reconnected

| Field | Value |
|---|---|
| Azure DevOps ID | 2083 |
| Story section | 2.8 Printer Disconnected |
| Category | Positive |

**Preconditions/data**

1. The unavailable printer message from TC-SOC-047 is shown.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Retry while the printer is still unplugged. | The unavailable message is shown again. |
| 2 | Plug the printer back in and click Retry. | The invoice is printed. |

#### TC-SOC-049: Select Another Printer prints on the chosen printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2084 |
| Story section | 2.8 Printer Disconnected |
| Category | Positive |

**Preconditions/data**

1. The unavailable printer message from TC-SOC-047 is shown.
2. "QA PDF Printer" is registered and active.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Select Another Printer. | A list of available printers is shown. |
| 2 | Select "QA PDF Printer". | The invoice is printed on "QA PDF Printer". |
| 3 | Open the share configuration of Sales Invoice. | The configured printer is not changed. |

#### TC-SOC-050: Cancel on the unavailable printer message

| Field | Value |
|---|---|
| Azure DevOps ID | 2085 |
| Story section | 2.8 Printer Disconnected |
| Category | Positive |

**Preconditions/data**

1. The unavailable printer message from TC-SOC-047 is shown.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Cancel. | The message closes, nothing is printed and the invoice stays unchanged. |

#### TC-SOC-051: Offer an alternative compatible printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2086 |
| Story section | 2.8 Printer Disconnected |
| Category | Positive |

**Preconditions/data**

1. Two printers of the same type are registered, for example two A4 printers.
2. Cash Deposit Hard Copy uses the first one.

| # | Action | Expected result |
|---|---|---|
| 1 | Unplug the first printer. |  |
| 2 | Print a Cash Deposit with Hard Copy. | The system offers "Would you like to print using <second printer>?" |
| 3 | Accept the offer. | The document is printed on the second printer. |

### 8. Deactivate, Reactivate and Delete Printer

#### TC-SOC-052: Deactivate a printer with no assigned documents

| Field | Value |
|---|---|
| Azure DevOps ID | 2087 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Positive |

**Preconditions/data**

1. "QA Printer B" is registered and not assigned to any document.

| # | Action | Expected result |
|---|---|---|
| 1 | Deactivate "QA Printer B". | The printer is deactivated with no warning. |
| 2 | Review the printer list. | The printer status is Inactive. |

#### TC-SOC-053: Inactive printers are not offered in the Hard Copy printer list

| Field | Value |
|---|---|
| Azure DevOps ID | 2088 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Negative |

**Preconditions/data**

1. One active printer and one inactive printer are registered on POS 01.

| # | Action | Expected result |
|---|---|---|
| 1 | Open the Hard Copy printer list for Sales Invoice. | Only the active printer is listed. The inactive printer is not offered. |

#### TC-SOC-054: Reactivate an inactive printer

| Field | Value |
|---|---|
| Azure DevOps ID | 2089 |
| Story section | 2.11 Remove / Deactivate Printer / 2.10 Edit Printer |
| Category | Positive |

**Preconditions/data**

1. "QA Printer B" is Inactive.

| # | Action | Expected result |
|---|---|---|
| 1 | Open "QA Printer B" in Edit Printer, set it Active and save. | The printer status is Active. |
| 2 | Open the Hard Copy printer list of a document. | "QA Printer B" is offered again. |

#### TC-SOC-055: Deactivation is blocked for a printer with assigned documents

| Field | Value |
|---|---|
| Azure DevOps ID | 2090 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Negative |

**Preconditions/data**

1. "QA PDF Printer" is assigned to Sales Invoice and Work Order.

| # | Action | Expected result |
|---|---|---|
| 1 | Deactivate "QA PDF Printer". | The message "This printer is assigned to one or more documents. Please assign another printer before deactivating it." is shown. |
| 2 | Review the message. | It lists the affected documents (Sales Invoice, Work Order) with Cancel and Reassign & Deactivate buttons. |

#### TC-SOC-056: Cancel keeps the assigned printer active

| Field | Value |
|---|---|
| Azure DevOps ID | 2091 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Positive |

**Preconditions/data**

1. The deactivation message from TC-SOC-055 is shown.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Cancel. | The message closes. The printer stays Active and its document assignments do not change. |

#### TC-SOC-057: Reassign & Deactivate

| Field | Value |
|---|---|
| Azure DevOps ID | 2092 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Positive |

**Preconditions/data**

1. The deactivation message from TC-SOC-055 is shown.
2. Another active printer is registered.

| # | Action | Expected result |
|---|---|---|
| 1 | Click Reassign & Deactivate. | The user can choose another printer for the affected documents. |
| 2 | Select the other printer and confirm. | Sales Invoice and Work Order move to the other printer and "QA PDF Printer" becomes Inactive. |
| 3 | Print a Sales Invoice. | It prints on the new printer. |

#### TC-SOC-058: Register the same printer again after deleting it

| Field | Value |
|---|---|
| Azure DevOps ID | 2093 |
| Story section | 2.11 Remove / Deactivate Printer |
| Category | Positive / Regression (bug 1827) |

**Preconditions/data**

1. "QA Printer B" is registered with no assigned documents.

| # | Action | Expected result |
|---|---|---|
| 1 | Delete "QA Printer B". | The printer is removed from the list. |
| 2 | Open Add Printer and select the same system printer. | The printer is offered in the detected list. |
| 3 | Enter the name "QA Printer B" and save. | The printer is registered again with no error. |
