-- DB check: COGS today, cost per invoice line (TC-031)
SELECT i.InvoiceNumber, c.ItemCost, i.InvoiceBeforeTaxAmount AS net_excl_vat
FROM SalInvoiceItemCost c
JOIN SalInvoice i ON i.ID = c.InvoiceID
WHERE i.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND i.InvoiceDate >= '2026-11-20';
