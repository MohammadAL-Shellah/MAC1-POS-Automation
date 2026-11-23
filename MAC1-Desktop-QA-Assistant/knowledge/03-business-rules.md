# 3. Confirmed business rules and decisions

Treat these as correct behaviour, not bugs.

## 3.1 POS documents
1. POS sales invoices and returns are submitted directly. Draft, cancelled, and rejected states do not exist in the POS.
2. Only Full Return exists. Partial return is not supported.
3. Refunds are Cash only, whatever the original payment method. A cash refund needs enough cash in the drawer.
4. Unpaid and partially paid invoices are not supported at present.
5. "In progress" and "Pending" are the same work order status.

## 3.2 Dashboard
1. QA uses one admin user with all permissions. Each branch works on one terminal.
2. "Invoices Today" opening the Sales "All" list is accepted.
3. The dashboard must refresh automatically while open (today it does not: known defect POS-D09).
4. The date picker clearing the selected date with no message is not acceptable (known defect POS-D08).
5. No screen shows Inventory Value by date.
6. The QA branch has 2 stores, Branch Store and Branch-2. Dashboard inventory counts and Stock Value cover both stores.
7. An item with positive stock and no Min Qty shows "In Stock".

## 3.3 Portal and MacOne link
1. Portal changes reach the app only after Sync.
2. The store marked Is Default on the portal Branch form is the store the app uses for work orders.
3. An item shows in the work order catalog only when it has a Business Category (or Is Apply To All Business Category is true).
4. Work order prices come from the customer's default price list, otherwise from the branch default price list.
5. A discount with Is Mandatory Reason needs a reason row; a transaction discount needs a Tax Procedure to be selectable in the app.
6. Promotion is not finished yet. If the user asks, test it anyway and report what happens; do not log it as a bug.
7. An item is deactivated from the portal with the Item "Cancel" action (status Cancelled).

## 3.4 Dashboard formulas (verified on QA data)
Values read on the same business day and the same branch:
1. Overview "Daily Sales Amount (Incl. VAT)" = Executive Summary "Daily Sales (Incl. VAT)" = Sales tab "Total Sales Amount (Incl. VAT)" (Daily).
2. "Output VAT" = "Daily Sales (Incl. VAT)" − "Daily Net Sales (Excl. VAT)".
3. "Net VAT Payable" = "Output VAT" − "Input VAT".
4. "Gross Margin" = "Gross Profit (Excl. VAT)" / "Daily Net Sales (Excl. VAT)" × 100 (shown with 2 decimals).
5. "Avg. Invoice (Incl. VAT)" = "Total Sales Amount (Incl. VAT)" / "Invoices No".
6. "Total Work Orders" = Pending + Completed + Voided. On WO info: "Total WOs" = "Pending" + "Completed" + "Voided"; "Pending Rate" = Pending / Total WOs × 100 (one decimal); the same for "Completion Rate" and "Void Rate".
7. "Invoices Today" = "Fully Paid" (unpaid invoices are not supported).
8. "Expected Cash Balance" = "Opening Cash Balance" + "Cash Sales Balance" − "Cash Refunds Balance" (Cash tab; deposits of the open session would also be subtracted).
9. Cash tab: "Cash Sales %" = "Net Cash Received" / "Total Net Payment Received" × 100 (one decimal). "Other Payments %" = 100 − "Cash Sales %".
10. Overview: "TRANSACTIONS NO" = "Invoices Today". The payment method amounts add up to "Daily Sales Amount (Incl. VAT)".
11. Sales tab: "All" count = "Refunds" count + "Invoices" count; "Invoices" count = "Invoices No".
12. Overview "Total Inventory Items" = Inventory "All" count; Overview "Low stock", "Out of stock", "Negative Stock" = Inventory cards "Low Stock", "Out of Stock", "Negative Stock". Overview "Inventory Value" = Inventory "Stock Value".

## 3.5 Still waiting for a business decision (check them when asked, and report the result as "waiting for a business decision", not as pass or fail)
Inventory Value with negative stock and the unit cost method; inventory category counts per item or per item and store; Gross Profit and Total Sales in a refunds-only period; the Return Rate base; the Cash Sales % base; Top Selling with returns and on an empty day; the amount shown for a voided work order.

## 3.6 Known open defects (already reported or drafted)
Fully Refunded list (Bug 1973), Sales search counts (Bug 1974), missing ZATCA Rejection Reason column (POS-D01), no Cash Deposit button on the Cash tab (POS-D02), Inventory Value calculation (POS-D06), date picker (POS-D08), no automatic refresh (POS-D09). Service packages added with a wrong quantity such as 64 (integration 6.14). Sync failing while package work orders are pending (6.17, 6.18).
