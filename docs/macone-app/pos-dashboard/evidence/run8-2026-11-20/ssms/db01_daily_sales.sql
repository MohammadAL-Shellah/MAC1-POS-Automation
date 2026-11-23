-- DB check: Daily Sales, Net Sales, VAT, Invoices 20/11/2026 (TC-005, 013, 034, 043, 077)
SELECT 'Invoices' AS doc, COUNT(*) AS n,
       SUM(InvoiceTotalAmount)     AS total_incl_vat,
       SUM(InvoiceBeforeTaxAmount) AS net_excl_vat,
       SUM(InvoiceTaxAmount)       AS vat,
       SUM(InvoiceDiscountAmount)  AS discount
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-20'
UNION ALL
SELECT 'Returns', COUNT(*), SUM(ReturnTotalAmount), SUM(ReturnBeforeTaxAmount),
       SUM(ReturnTaxAmount), SUM(ReturnDiscountAmount)
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-20';
