# Share Option Configurations: Execution Log

| Item | Value |
|---|---|
| Story | 1041 |
| Build | MAC1 1.2.488 |
| Date | 2026-11-15 |
| Terminal | M-ALSHELLAH (POS 01), QA - Company |
| Printers in Windows | Microsoft Print to PDF, OneNote (Desktop), AnyDesk Printer, QA SOC Test Printer (added for the test, Print To PDF driver on FILE:) |
| Evidence | Session scratchpad desk\soc_*.png, pdf\ |

## Summary (run finished 2026-11-15 18:57)

| Result | Count | Cases |
|---|---|---|
| Pass | 50 | All others (some with observations, see Results) |
| Fail | 6 | 001, 022, 033, 034, 037, 052 |
| Not run | 2 | 014, 015 (need a second POS of the same company) |

Method for unavailable printer cases (018, 046 to 051): Sales Invoice Hard Copy was set to "QA PDF Printer 2" only, then its Windows printer "QA SOC Test Printer" was removed (Remove-Printer) to simulate an unplugged printer and added back to simulate reconnecting.

## Current state after the run

1. Work Order: Hard Copy, layout Work Order Detail, printer Microsoft Print to PDF (16 documents configured).
2. Sales Invoice: Hard Copy (Invoice, Print Count empty, Microsoft Print to PDF), SMS, WhatsApp, Email.
3. MAC1 printer "QA PDF Printer 2" deleted; Windows printer "QA SOC Test Printer" removed. Windows default printer is Microsoft Print to PDF.
4. WO-TO_11000133 (1111AAA BMW) is still open with QA_SST AC Check 30.00 (test data, not voided).

## Findings so far

| # | Finding | Cases |
|---|---|---|
| 1 | Documents without a report (Credit Note, Payment Receipt, Customer Statement, Barcode / Item Label) are configured with Hard Copy and a printer, and their configuration cannot be removed ("No report is linked to this document...") | 022 |
| 2 | Work Order printed with the Work Order Detail layout has an empty item table, Grand Total .00, empty Vehicle Info and VIN, while the cart has QA_SST Oil Change Service 50.00 | 037 |
| 3 | Multiple printers per document: the user picks one printer, the document is not printed on all of them (story wording unclear) | 037 |
| 4 | No Active/Inactive column in the printer list | 001 |
| 5 | Edit Printer has no document assignment section (story 2.10) | 034 |
| 6 | 0-byte "RAW POS Print" files saved by the default printer on payment | 039 |
| 7 | WhatsApp "Shared successfully" shown before anything is sent | 041 |
| 8 | Inactive printer keeps Status "Connected" in the printer list; the row is only greyed, no Inactive status | 052, 001 |
| 9 | Printer status in the list is not refreshed while the screen is open; Disconnected shows only after leaving and reopening the screen | 046 |
| 10 | Cancel on "Printer Unavailable" is followed by a second popup "Printing failed. Check that the printer is connected and available." although the user cancelled | 050 |
| 11 | After the printer is reconnected, the first Retry still shows "Printer Unavailable"; the second Retry prints | 048 |
| 12 | "Printer Unavailable" offers the alternative printer regardless of printer type (Receipt printer replaced by "Other" type Microsoft Print to PDF); story 2.8 says a compatible printer | 051 |
| 13 | "Printer Unavailable" dialog UI: the Select Printer field is clipped (selected name cut in half) and the button label is truncated "Print With Selecte..." | 047 |
| 14 | Deactivate Printer dialog opens as soon as the Active switch is turned off (before Save). While choosing the second document's printer the dialog closed and, after Save, the printer was deactivated with Sales Invoice moved to Microsoft Print to PDF and Work Order left on its other printer. Needs a manual recheck of whether the dialog can close without pressing Reassign & Deactivate | 057 |
| 15 | Printers of type Receipt receive a RAW print job; with a PDF driver this gives a 0-byte "RAW POS Print (n).pdf" in Documents. Explains finding 6 | 048, 039 |

## Results

| TC | ID | Result | Notes |
|---|---|---|---|
| 001 | 2036 | Fail (minor) | Columns: Printer Name, System Printer Name, Printer Type, Connection, Status (Connected), Documents. No Active/Inactive column. Info banner "New printer detected: OneNote (Desktop)" mentions only one of the unregistered printers (AnyDesk Printer not mentioned) |
| 002 | 2037 | Pass | Printers are detected from Windows; no IP or port field |
| 003 | 2038 | Pass | "3 printers found in Windows on M-ALSHELLAH", same as Windows. Columns Printer, Driver, Printer Type, Connection, Status. Registered printer marked "Already registered" and not selectable |
| 004 | 2039 | Pass | Added "QA SOC Test Printer" in Windows, Scan again shows 4 printers |
| 005 | 2040 | Pass | Step 2 of 2 opens with System Printer Name and printer information filled |
| 006 | 2041 | Pass | Manufacturer Microsoft, Model Print To PDF, Driver, Connection Other, Status Connected, Paper Size Letter (216 x 279 mm) |
| 007 | 2042 | Pass | System Printer Name (lock icon) and printer information are read only; Printer Name is editable |
| 008 | 2043 | Pass | Receipt Printer, A4 Printer, Label Printer, Other |
| 009 | 2044 | Pass | Suggested "Other" from the driver, changed to A4 Printer, list shows A4 |
| 010 | 2045 | Pass | Registered "QA PDF Printer" (system QA SOC Test Printer). No success message after Add printer, the list opens directly. Printer offered in the Hard Copy printer list by its MAC One name |
| 011 | 2046 | Pass | Empty and spaces only: "Printer name is required." Message disappears after about 2 seconds |
| 012 | 2047 | Pass | "Microsoft Print to PDF" and "microsoft print to pdf": "This printer name already exists. Please enter a different name." |
| 013 | 2048 | Pass | Edit to "Microsoft Print to PDF": duplicate message. Save with own name: saved, no message |
| 016 | 2051 | Pass | "Test print was sent successfully to the printer." shown next to the button. Windows "Save Print Output As" dialog opened (virtual printer), PDF saved: pdf\soc_016_testprint.pdf (1 page) |
| 017 | 2052 | Pass | Test Print from Edit Printer: success message, PDF saved, no upload form (bug 1838 not reproduced). Note: the Windows "Save Print Output As" dialog of a PDF printer may look like a file form |
| 019 | 2054 | Pass | Renamed to "QA PDF Printer 2", type Receipt. List and Work Order Hard Copy printers show the new name; Work Order link kept. Edit Printer has Active toggle ("Inactive printers cannot be used for printing") |
| 020 | 2055 | Pass | System Printer Name locked (lock icon), no option to pick another detected printer |
| 021 | 2056 | Pass | Add list shows only "Supported by MAC One, not yet configured" documents (empty while all 16 are configured). After removing Stock Adjustment it was offered; Hard Copy checked and layout auto-selected; Confirm: "Document assignments saved successfully.", count 16. Re-added document moves to the end of the list |
| 022 | 2057 | Fail | Credit Note, Payment Receipt, Customer Statement, Barcode / Item Label have no report (empty Layout list) but are configured with Hard Copy + Microsoft Print to PDF and counted in its "16 documents". Unchecking Hard Copy on Credit Note and saving shows "No report is linked to this document. Please add a report to the document to continue." and the configuration cannot be removed. Related to bug 1825 |
| 023 | 2058 | Pass | Sales Invoice has Hard Copy, SMS, WhatsApp, Email together |
| 024 | 2059 | Pass | Work Order: Hard Copy = Work Order Detail, Email = Work Order Sticker, saved and kept after leaving the screen. Layout field editable (bug 1836 not reproduced) |
| 025 | 2060 | Pass (observation) | Sales Invoice layouts: Invoice only. Work Order layouts: Work Order Detail, Service Reminder Sticker, Work Order Sticker. Work Order Hard Copy was saved before with no layout ("Select layout") |
| 026 | 2061 | Pass | Sales Invoice Hard Copy: layout Invoice, printer, Print Count 2 saved and kept after reopening |
| 033 | 2068 | Fail | Add Printer has no document assignment section, documents cannot be added from Add Printer (bug 1831 flow not available) |
| 034 | 2069 | Fail | Edit Printer has no document assignment section (story 2.10 "Document Assignments"); assignment only from the document side |
| 027 | 2062 | Pass | Work Order Hard Copy printers: Microsoft Print to PDF + QA PDF Printer, kept after reload. Hint under the list: "Leave empty to let the user choose any printer when printing. With several printers, the user picks one of them." |
| 028 | 2063 | Pass | Stock Adjustment saved with Hard Copy and no printer |
| 029 | 2064 | Pass | Print Count empty ("–") is saved (bug 1839 not reproduced) |
| 030 | 2065 | Pass | Print Count uses - / + only; minus from 1 goes back to empty; no 0 or negative; typing letters or decimals is ignored |
| 031 | 2066 | Pass | Export Type is multi select (PDF + Excel + PNG saved and kept). No export type: "Select at least one export type." Hard Copy has no Export Type |
| 032 | 2067 | Pass (observation) | Printer list Documents column: QA PDF Printer "1 document". The link opens the Share Options screen without showing or filtering the documents |
| 036 | 2071 | Pass (step 3 not verifiable) | WO-TO_11000131 menu "Print last invoice" opens Share Options panel with exactly the configured options: Send to Email, Print, Send via SMS, Send via WhatsApp. Print (single printer) goes straight to the printer: INV-TO_11000105 printed with the Invoice layout (2 pages: invoice + QR/warranty). Print Count 2 gave one copy, but Microsoft Print to PDF ignores copies, needs a physical printer. Note: "Send via SMS" row is highlighted by default when the panel opens |
| 037 | 2072 | Fail (behaviour differs) | Work Order with 2 printers: "Print Current Cart" shows "Select a printer: Work Order is set to print on more than one printer. Select the printer to use." (list = only the 2 configured printers, Printer Settings, Cancel, Print). It prints on the chosen printer only, not on both. Matches the hint in configuration; story wording unclear (open question 2) |
| 038 | 2073 | Pass (partial) | Sales Invoice (single printer) printed directly on Microsoft Print to PDF; Work Order offered only its own 2 printers. Cash Deposit not printed |
| 039 | 2074 | Pass (observation) | Paid WO-TO_11000131 (cash 50): invoice INV-TO_11000106 not printed automatically, prompt "Do you want to print invoice INV - TO_11000106?" Ok / Cancel; Ok opens the Share Options panel. Observation: on payment two 0-byte files "RAW POS Print (62).pdf" and "(63).pdf" were saved to Documents by the default printer (Windows notification "File saved to the Documents folder"); older ones exist from 27/10. Looks like a RAW command (cash drawer?) sent to the default Windows printer |
| 040 | 2075 | Pass (step 2 pending) | Send to Email: "Shared successfully. Your document details have been shared via email." No recipient shown; received email and attachment not checked |
| 041 | 2076 | Pass (observation) | Send via WhatsApp opens Chrome api.whatsapp.com/send?phone=962771367208 with text "QA - Company : Sales Invoice INV - TO_11000106 Total: 50.00" + document link on qa.minerets.com. The app shows "Shared successfully ... via WhatsApp" as soon as the browser opens, before anything is sent |
| 042 | 2077 | Pass | Send via SMS (INV-TO_11000105, sent by a misclick during 036): "Shared successfully. Your document details have been shared via SMS." Delivery not checked |
| 043 | 2078 | Pass | Work Order configuration removed, Print Current Cart (cart with 1 item): "No share option has been configured for this document. Please select at least one share option." with Set Share Configurations / Cancel. With an empty cart nothing happens |
| 044 | 2079 | Pass | Set Share Configurations opens the Share Options screen (general list, Work Order not preselected). Work Order added (Hard Copy, Work Order Detail, Microsoft Print to PDF): "Document assignments saved successfully.", count 16. Back arrow returns to WO-TO_11000133 with the menu open; Print Current Cart prints directly (pdf\soc_044_wo_print.pdf) |
| 045 | 2080 | Pass | Cancel closes the popup, user stays on WO-TO_11000133, nothing printed |
| 018 | 2053 | Pass | Windows printer removed: Edit Printer shows Status Disconnected, Paper Size "-"; Test Print shows "Unable to print. Please check that the printer is connected, turned on, and available on this POS terminal." |
| 046 | 2081 | Pass (observation) | Printer removed: list shows Disconnected only after leaving and reopening the Printers screen (still Connected while open). Printer added back: Connected after reopening |
| 047 | 2082 | Pass (observation) | Print last invoice with Sales Invoice on the unavailable printer: dialog "Printer Unavailable", "QA PDF Printer 2 is currently unavailable.", "Would you like to print using Microsoft Print to PDF?", Select Printer field, buttons Cancel, Retry, Print With Selected (replaces "Select Another Printer"). UI: field clipped, button label truncated |
| 048 | 2083 | Pass (observation) | Retry while unavailable: dialog shown again. After adding the printer back, first Retry still showed the dialog, second Retry printed (RAW job, 0-byte "RAW POS Print (64).pdf" because the PDF driver cannot render RAW) |
| 049 | 2084 | Pass | Printer list offers only the available registered printers (Microsoft Print to PDF). Print With Selected printed the invoice on it (pdf\soc_049_select_another.pdf). Sales Invoice configuration not changed (still listed on QA PDF Printer 2 in the deactivate dialog of 055) |
| 050 | 2085 | Pass (observation) | Cancel closes the dialog and nothing is printed, but a second popup "Printing failed. Check that the printer is connected and available." is shown |
| 051 | 2086 | Pass (observation) | Executed with Sales Invoice instead of Cash Deposit. The alternative is offered inside the same dialog ("Would you like to print using Microsoft Print to PDF?") and printed after accepting. Offered printer is type Other while the configured one is Receipt (not the same type) |
| 055 | 2090 | Pass | QA PDF Printer 2 assigned to Sales Invoice and Work Order. Turning Active off opens "Deactivate Printer": "This printer is assigned to one or more documents. Please assign another printer before deactivating it." "This printer is assigned to:" Sales Invoice, Work Order, each with a printer field (default Not Assigned), buttons Cancel and Reassign & Deactivate. Clicking outside closes it |
| 056 | 2091 | Pass | Cancel closes the dialog, switch stays Active, documents unchanged |
| 057 | 2092 | Pass (observation) | Sales Invoice set to Microsoft Print to PDF. Dialog closed while opening the Work Order field (see finding 14); Save deactivated the printer: row greyed, Documents "-", Microsoft Print to PDF 16 documents. Sales Invoice and Work Order on Microsoft Print to PDF. Print last invoice prints directly on Microsoft Print to PDF (pdf\soc_057_after_reassign.pdf). No success message after Save |
| 053 | 2088 | Pass | Sales Invoice Hard Copy printer list shows only Microsoft Print to PDF while QA PDF Printer 2 is inactive |
| 054 | 2089 | Pass | Active switched on and saved: row no longer greyed; QA PDF Printer 2 offered again in the Sales Invoice printer list |
| 052 | 2087 | Fail (minor) | Printer with no documents deactivated with no warning (step 1 pass). List still shows Status "Connected", row greyed only; no Inactive status (step 2) |
| 058 | 2093 | Pass | Delete: "Are you sure you want to delete this printer?" Ok: removed, banner "New printer detected on this terminal: QA SOC Test Printer". Add Printer lists it as selectable; registered again as "QA PDF Printer 2" with no error (bug 1827 not reproduced) |
| 014 | 2049 | Not run | Needs a second POS of the same company |
| 015 | 2050 | Not run | Needs a second POS of the same company |
| 035 | 2070 | Pass | Added printer to Work Order; removed Email from Work Order (Hard Copy kept); removed Stock Adjustment (unchecked all, confirm "No share option is selected. Remove this document's share options from this POS?" Ok): count 15, offered again in Add list. Not possible for documents without a report (see 022) |
