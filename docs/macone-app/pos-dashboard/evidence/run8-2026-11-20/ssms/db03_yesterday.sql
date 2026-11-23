-- DB check: Yesterday sales 18/11/2026 (TC-008, 039, 078)
SELECT InvoiceNumber, InvoiceDate, InvoiceTotalAmount AS total
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND InvoiceDate >= '2026-11-18' AND InvoiceDate < '2026-11-20'
ORDER BY InvoiceDate;
