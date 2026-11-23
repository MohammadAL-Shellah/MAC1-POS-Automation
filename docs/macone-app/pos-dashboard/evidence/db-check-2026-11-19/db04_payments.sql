-- DB check: Payment methods today, received and refunded (TC-022, 027, 074)
SELECT pm.PaymentMethodName AS method, SUM(p.PaymentAmount) AS received,
       ISNULL((SELECT SUM(rp.PaymentAmount)
               FROM SalReturnReceiptPayment rp
               JOIN SalReturnReceipt rr ON rr.ID = rp.ReturnReceiptID
               WHERE rr.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND rr.ReturnReceiptDate >= '2026-11-19'
                 AND rp.PaymentMethodID = pm.ID), 0) AS refunded
FROM SalInvoiceReceiptPayment p
JOIN SalInvoiceReceipt r    ON r.ID = p.InvoiceReceiptID
JOIN GenLkpPaymentMethod pm ON pm.ID = p.PaymentMethodID
WHERE r.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND r.InvoiceReceiptDate >= '2026-11-19'
GROUP BY pm.PaymentMethodName, pm.ID;