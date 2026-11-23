-- DB check: Top Selling today by sales value (TC-025, 026, 073)
SELECT i.ItemName, SUM(si.ItemQuantity) AS qty_sold, SUM(si.ItemTotalAmount) AS sold_value
FROM SalInvoiceItem si
JOIN SalInvoice s ON s.ID = si.InvoiceID
JOIN InvItem i    ON i.ID = si.ItemID
WHERE s.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND s.InvoiceDate >= '2026-11-20'
GROUP BY i.ItemName
ORDER BY sold_value DESC;
