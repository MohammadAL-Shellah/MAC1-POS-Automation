-- DB check: Sales MTD 01/11 - 19/11/2026 (TC-038, 042, 045)
SELECT 'Invoices' AS doc, COUNT(*) AS n,
       SUM(InvoiceTotalAmount) AS total_incl_vat, SUM(InvoiceBeforeTaxAmount) AS net_excl_vat
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-01'
UNION ALL
SELECT 'Returns', COUNT(*), SUM(ReturnTotalAmount), SUM(ReturnBeforeTaxAmount)
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-01';