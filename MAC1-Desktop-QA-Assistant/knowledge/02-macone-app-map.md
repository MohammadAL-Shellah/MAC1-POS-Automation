# 2. MacOne desktop app map (POS, QA)

The app is native Windows (.NET MAUI). It has no URLs. Navigation is only by clicking visible labels. Use these labels exactly as written. Labels with a number in brackets, such as "All (21)", change with the data; target them by the text before the bracket, for example "All".

## 2.1 Header and side menu
1. Dashboard header: branch name, date and time, "QA - Company", "Hide Data".
2. The top-left icon has no text; on the screen list it shows as "(icon, no text)" at about x 20 to 75, y 50 to 140. On the dashboard it is the menu (three lines, an Image at about 48,111) and opens the side menu; on other screens it is the back arrow (a Button at about 20,53).
3. Side menu: "Search", "Quick Access" with "Open Day", "Close Day", "Workorder"; groups "Operations", "Cash & Stock", "Customers & Vehicles", "Reports", "Administration", "System & Devices" (click a group to open it).

## 2.1.1 Work order flow (tested 2026-11-14)
1. Click "Menu", then "Workorder". Screen "Vehicles List".
2. Type the plate with fill into the box with placeholder "1234ABC" (for example 1111AAA), then click "Search". Results show plate, make, model, and VIN; several vehicles may share a plate, so click the make or model text, for example "Song Plus" or "BMW".
3. Right after a vehicle is clicked, a side panel "Enter mileage" may open on the left (with "Last mileage", a "Current mileage (km)" box, and the buttons "Skip" and "Save Mileage"). It blocks the screen, so click "Skip" (with "optional": true) BEFORE "Continue". To record mileage instead, fill the number and click "Save Mileage".
4. Click "Continue". If the vehicle already has an open (pending) work order, the app skips the "Bay" screen and opens that work order directly, with its bay and earlier items in the cart; then skip the bay steps and check the cart before adding items, so an item is not added twice. The work order screen shows "Workorder" and "WO No. #WO - TO_..." at the top; cart tabs "New", "1", "2", "3" are separate open carts.
5. Screen "Bay": click a bay such as "Bay - 01", then click "Assign Bay" (its text becomes "Assign to Bay - 01").
6. Work order screen: item groups at the top ("All", "Services Group", ...); items as cards with name and price, for example "Car Wash", "RService", "Tire - Item". Click an item name to add it to the cart.
7. Cart (right side): item lines with quantity, then "Total", "Sub-total", "Discount", "Tax", buttons "Promotion", "Discount", "Clear cart", "Payment". Read cart amounts with readValue ("Total", "Tax").
8. Click "Payment". Screen "Payment" shows "WO No. #WO - TO_...", "Total With VAT", "Grand Total With Tax", "Total Paid", "Remaining", methods "Hala", "Credit Card", "Cash", "Mada Pay", "Master", a keypad with buttons "0" to "9" and ".", and "Confirm Payment".
9. To pay: click the method (for example "Cash"), click the keypad digits of the amount one by one (100 = "1", "0", "0"), check "Remaining" is 0, then click "Confirm Payment".
10. A popup asks "Do you want to print invoice INV - TO_...?" with "Ok" and "Cancel". Click "Cancel" to skip printing. The app returns to the dashboard and the work order shows as Completed.

## 2.2 Dashboard tabs
The dashboard is the home screen. Tabs: "Overview", "Sales", "WO info", "Cash", "Inventory".

## 2.3 Overview tab
Cards and labels:
1. "Daily Sales Amount (Incl. VAT)", growth text such as "+12.5% vs yesterday", "Refunds".
2. "Invoices Today", "Fully Paid", "Fully Refunded".
3. "Total Work Orders" with Pending, Completed, Voided counts.
4. "Total Inventory Items" with Low stock, Out of stock, Negative Stock counts.
5. "Top Selling (Today) (Incl. VAT)" with "View All".
6. "Value per payment method", "TRANSACTIONS NO", payment method names (Hala, Mada, Visa, Cash, Master).
7. "Cash Register": "Opening Date and Time", "Opening Cash Balance", "Expected Cash Balance".
8. "Executive Summary": "Inventory Value", "Daily Sales (Incl. VAT)", "Daily Net Sales (Excl. VAT)", "Gross Profit (Excl. VAT)", "Gross Margin", "Output VAT", "Input VAT", "Net VAT Payable".

## 2.4 Sales tab
1. Period buttons: "Daily", "MTD", "QTD", "YTD". Date range: "From", "To", "Apply".
2. Cards: "Total Sales Amount (Incl. VAT)", "Invoices No", "Total Net Sales Amount (Excl. VAT)", "Avg. Invoice (Incl. VAT)", "Refunds (Incl. VAT)", "Return Rate".
3. List filters: "All", "Refunds", "Invoices". Search box placeholder: "Search by Invoice #, Customer, Method, ZATCA Status, Plate...". Button "Export".
4. Columns: "Invoice #", "Customer", "Customer Type", "Plate Number", "Items", "Amount (Incl. VAT)", "Method", "Status", "ZATCA Status", "ZATCA Status Time". Rows look like "INV - TO_11000093".

## 2.5 WO info tab
1. Period buttons and date range as in Sales.
2. Cards: "Total WOs", "Total Customers Served", "Pending", "Pending Rate", "Completed", "Completion Rate", "Voided", "Void Rate".
3. List filters: "All", "Pending", "Completed", "Voided". Search placeholder: "Search by WO #, Customer, Tech, Bay, VIN...". Button "Export".
4. Columns: "WO No.", "Customer", "Plate Number", "Bay Name", "Amount (Incl. VAT)", "Status", "Actions". Pending rows have a "Complete" action; it opens the work order for payment, so use it to complete a pending work order.

## 2.6 Cash tab
1. "Current Cash Register": "Opening Date and Time", "Opening Cash Balance", "Cash Sales Balance", "Cash Refunds Balance", "Expected Cash Balance".
2. Period buttons and date range.
3. "Total Net Payment Received", "Net Cash Received", "Cash Sales %", "Net Electronic Payments Received", "Other Payments %", "Payment Methods".

## 2.7 Inventory tab
1. Cards: "Stock Value", "In Stock", "Low Stock", "Out of Stock", "Negative Stock".
2. List filters: "All", "In Stock", "Low Stock", "Out of Stock", "Negative". Search placeholder: "Search for item name, item number ...".
3. Columns: "Item Name", "Item Number", "Store Name", "CURRENT Qty", "Min Qty", "Max Qty", "Status". An empty Min Qty shows "--".

## 2.8 Limits of automation
1. Popups such as "Sync Completed", the mileage prompt, and the print prompt are found by reading the screen image, so click their buttons by their visible text ("Ok", "Cancel", "Skip").
2. Only one terminal exists, so nothing can change data from another device while a screen is open.
3. The header clock shows the time the screen was opened (known defect), so do not use it as the current time.
4. "Export" saves a CSV file and opens the Windows Share window; close that window with the key {ESC} (or look at the screen and click its close button) before going on.
5. Lists show only the rows on screen. Search for a row before reading its cells.

## 2.9 Reading numbers
Each number sits to the right of its label on the same row, or below it inside its card. Amounts are read as one number (for example 17,725.11). Card counts such as "2 Pending" and list filters such as "All (21)" are read by their label alone ("Pending", "All").
