-- DB check: Cash tab MTD, cash vs electronic (TC-058, 059)
SELECT 'Received' AS movement,
       CASE WHEN pm.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END AS kind,
       SUM(p.PaymentAmount) AS amount
FROM SalInvoiceReceiptPayment p
JOIN SalInvoiceReceipt r    ON r.ID = p.InvoiceReceiptID
JOIN GenLkpPaymentMethod pm ON pm.ID = p.PaymentMethodID
WHERE r.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND r.InvoiceReceiptDate >= '2026-11-01'
GROUP BY CASE WHEN pm.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END
UNION ALL
SELECT 'Refunded',
       CASE WHEN pm.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END,
       SUM(p.PaymentAmount)
FROM SalReturnReceiptPayment p
JOIN SalReturnReceipt r     ON r.ID = p.ReturnReceiptID
JOIN GenLkpPaymentMethod pm ON pm.ID = p.PaymentMethodID
WHERE r.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND r.ReturnReceiptDate >= '2026-11-01'
GROUP BY CASE WHEN pm.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END;