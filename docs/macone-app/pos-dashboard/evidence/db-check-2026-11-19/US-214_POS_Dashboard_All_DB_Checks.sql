-- Story 214 POS Dashboard: DB checks (read only), branch ff31fb19, run on 19/11/2026
-- Select one query and press F5, or F5 for all (one result grid per query)

-- 1. Daily Sales, Net Sales, VAT, Invoices 19/11/2026 (TC-005, 013, 034, 043, 077)
SELECT 'Invoices' AS doc, COUNT(*) AS n,
       SUM(InvoiceTotalAmount)     AS total_incl_vat,
       SUM(InvoiceBeforeTaxAmount) AS net_excl_vat,
       SUM(InvoiceTaxAmount)       AS vat,
       SUM(InvoiceDiscountAmount)  AS discount
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-19'
UNION ALL
SELECT 'Returns', COUNT(*), SUM(ReturnTotalAmount), SUM(ReturnBeforeTaxAmount),
       SUM(ReturnTaxAmount), SUM(ReturnDiscountAmount)
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-19';

-- 2. Refunds today (TC-012, 016, 069)
SELECT ReturnNumber, ReturnDate,
       ReturnBeforeTaxAmount AS net,
       ReturnTaxAmount       AS vat,
       ReturnTotalAmount     AS total
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND ReturnDate >= '2026-11-19'
ORDER BY ReturnDate;

-- 3. Yesterday sales 18/11/2026 (TC-008, 039, 078)
SELECT InvoiceNumber, InvoiceDate, InvoiceTotalAmount AS total
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND InvoiceDate >= '2026-11-18' AND InvoiceDate < '2026-11-19'
ORDER BY InvoiceDate;

-- 4. Payment methods today, received and refunded (TC-022, 027, 074)
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

-- 5. Working day and opening cash today (TC-021, 022, 061)
SELECT w.OpenDate, w.OpenBalanceCashAmount AS opening_cash, w.IsClosed,
       (SELECT COUNT(*) FROM SalInvoice s WHERE s.WorkingDayID = w.ID) AS invoices
FROM SalWorkingDay w
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.OpenDate >= '2026-11-19'
ORDER BY w.OpenDate;

-- 6. Sales MTD 01/11 - 19/11/2026 (TC-038, 042, 045)
SELECT 'Invoices' AS doc, COUNT(*) AS n,
       SUM(InvoiceTotalAmount) AS total_incl_vat, SUM(InvoiceBeforeTaxAmount) AS net_excl_vat
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-01'
UNION ALL
SELECT 'Returns', COUNT(*), SUM(ReturnTotalAmount), SUM(ReturnBeforeTaxAmount)
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-01';

-- 7. Cash tab MTD, cash vs electronic (TC-058, 059)
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

-- 8. Work Orders by status, today and MTD (TC-017, 018, 052, 053, 054)
SELECT CASE WHEN w.WorkOrderDate >= '2026-11-19' THEN 'Today' ELSE 'Before today' END AS period,
       ds.DocumentStatusName AS status, COUNT(*) AS n, COUNT(DISTINCT w.CustomerID) AS customers
FROM SalWorkOrder w
JOIN GenLkpDocumentStatus ds ON ds.ID = w.DocumentStatusID
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.WorkOrderDate >= '2026-11-01'
GROUP BY CASE WHEN w.WorkOrderDate >= '2026-11-19' THEN 'Today' ELSE 'Before today' END,
         ds.DocumentStatusName;

-- 9. Top Selling today by sales value (TC-025, 026, 073)
SELECT i.ItemName, SUM(si.ItemQuantity) AS qty_sold, SUM(si.ItemTotalAmount) AS sold_value
FROM SalInvoiceItem si
JOIN SalInvoice s ON s.ID = si.InvoiceID
JOIN InvItem i    ON i.ID = si.ItemID
WHERE s.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND s.InvoiceDate >= '2026-11-19'
GROUP BY i.ItemName
ORDER BY sold_value DESC;

-- 10. COGS of INV-TO_11000128, stock out x cost (TC-031, 032)
SELECT i.ItemName, -t.BaseItemQuantity AS base_qty, t.ItemCost AS unit_cost,
       -t.BaseItemQuantity * t.ItemCost AS cost
FROM InvStoreTransaction t
JOIN InvItem i ON i.ID = t.ItemID
WHERE t.DocumentDate >= '2026-11-19 15:13' AND t.DocumentDate < '2026-11-19 15:14'
  AND t.BaseItemQuantity < 0
UNION ALL
SELECT 'TOTAL', -SUM(BaseItemQuantity), NULL, -SUM(BaseItemQuantity * ItemCost)
FROM InvStoreTransaction
WHERE DocumentDate >= '2026-11-19 15:13' AND DocumentDate < '2026-11-19 15:14'
  AND BaseItemQuantity < 0;

-- 11. Inventory counts in branch stores (TC-019, 020, 064, 072)
WITH bal AS (
  SELECT StoreID, ItemID, SUM(BaseItemQuantity) AS q
  FROM InvStoreTransaction
  WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
  GROUP BY StoreID, ItemID),
x AS (
  SELECT bal.q,
         CASE WHEN i.IsApplyToAllBranch = 1
                OR EXISTS (SELECT 1 FROM InvItemBranch b WHERE b.ItemID = i.ID AND b.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
              THEN 'Applied to branch' ELSE 'Not applied' END AS scope
  FROM bal
  JOIN InvItem i ON i.ID = bal.ItemID
  JOIN GenLkpDocumentStatus ds ON ds.ID = i.DocumentStatusID
  WHERE ds.DocumentStatusName = 'Submitted')
SELECT scope,
       SUM(CASE WHEN q < 0 THEN 1 ELSE 0 END) AS negative,
       SUM(CASE WHEN q > 0 THEN 1 ELSE 0 END) AS positive,
       COUNT(*) AS rows_with_movement
FROM x
GROUP BY scope;

-- 12. Tire - Item stock per store (TC-063, 065, 066)
SELECT st.StoreName, SUM(t.BaseItemQuantity) AS qty,
       MAX(si.ItemMinQuantity) AS min_qty, MAX(si.ItemMaxQuantity) AS max_qty
FROM InvStoreTransaction t
JOIN InvItem i   ON i.ID = t.ItemID
JOIN InvStore st ON st.ID = t.StoreID
LEFT JOIN InvStoreItem si ON si.StoreID = t.StoreID AND si.ItemID = t.ItemID
WHERE i.ItemNumber = 'TO_1000001' AND t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY st.StoreName;

-- 13. Inventory Value, qty x transaction cost, items applied to the branch (TC-029, 062)
WITH bal AS (
  SELECT t.StoreID, t.ItemID, SUM(t.BaseItemQuantity) AS q,
         SUM(t.BaseItemQuantity * t.ItemCost) AS v
  FROM InvStoreTransaction t
  WHERE t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
  GROUP BY t.StoreID, t.ItemID)
SELECT st.StoreName, SUM(bal.v) AS value_qty_x_cost, SUM(CASE WHEN bal.q > 0 THEN bal.q END) AS positive_qty
FROM bal
JOIN InvItem i   ON i.ID = bal.ItemID
JOIN InvStore st ON st.ID = bal.StoreID
WHERE i.IsApplyToAllBranch = 1
   OR EXISTS (SELECT 1 FROM InvItemBranch b WHERE b.ItemID = i.ID AND b.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
GROUP BY st.StoreName;

