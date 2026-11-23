-- 21/11 Q3: daily net sales 20/11 vs 21/11 for growth (TC-067): (100 - 2270) / 2270 = -95.6%
SELECT CAST(InvoiceDate AS date) AS day, COUNT(*) AS invoices, SUM(InvoiceTotalAmount) AS invoiced,
       (SELECT ISNULL(SUM(r.ReturnTotalAmount),0) FROM SalReturn r WHERE CAST(r.ReturnDate AS date) = CAST(s.InvoiceDate AS date) AND r.DocumentStatusID = 2) AS returned
FROM SalInvoice s WHERE s.DocumentStatusID = 2 AND s.InvoiceDate >= '2026-11-20' AND s.InvoiceDate < '2026-11-22'
GROUP BY CAST(InvoiceDate AS date);
