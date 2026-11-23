-- Story 214 DB checks, run 20/11/2026 (read only). Branch Alshellah = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'

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

-- DB check: Yesterday sales 18/11/2026 (TC-008, 039, 078)
SELECT InvoiceNumber, InvoiceDate, InvoiceTotalAmount AS total
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND InvoiceDate >= '2026-11-18' AND InvoiceDate < '2026-11-20'
ORDER BY InvoiceDate;

-- DB check: Payment methods today, received and refunded (TC-022, 027, 074)
SELECT pm.PaymentMethodName AS method, SUM(p.PaymentAmount) AS received,
       ISNULL((SELECT SUM(rp.PaymentAmount)
               FROM SalReturnReceiptPayment rp
               JOIN SalReturnReceipt rr ON rr.ID = rp.ReturnReceiptID
               WHERE rr.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND rr.ReturnReceiptDate >= '2026-11-20'
                 AND rp.PaymentMethodID = pm.ID), 0) AS refunded
FROM SalInvoiceReceiptPayment p
JOIN SalInvoiceReceipt r    ON r.ID = p.InvoiceReceiptID
JOIN GenLkpPaymentMethod pm ON pm.ID = p.PaymentMethodID
WHERE r.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND r.InvoiceReceiptDate >= '2026-11-20'
GROUP BY pm.PaymentMethodName, pm.ID;

-- DB check: Working day and opening cash today (TC-021, 022, 061)
SELECT w.OpenDate, w.OpenBalanceCashAmount AS opening_cash, w.IsClosed,
       (SELECT COUNT(*) FROM SalInvoice s WHERE s.WorkingDayID = w.ID) AS invoices
FROM SalWorkingDay w
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.OpenDate >= '2026-11-20'
ORDER BY w.OpenDate;

-- DB check: Sales MTD 01/11 - 20/11/2026 (TC-038, 042, 045)
SELECT 'Invoices' AS doc, COUNT(*) AS n,
       SUM(InvoiceTotalAmount) AS total_incl_vat, SUM(InvoiceBeforeTaxAmount) AS net_excl_vat
FROM SalInvoice
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-01'
UNION ALL
SELECT 'Returns', COUNT(*), SUM(ReturnTotalAmount), SUM(ReturnBeforeTaxAmount)
FROM SalReturn
WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-01';

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

-- DB check: Work Orders by status, today and MTD (TC-017, 018, 052, 053, 054)
SELECT CASE WHEN w.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END AS period,
       ds.DocumentStatusName AS status, COUNT(*) AS n, COUNT(DISTINCT w.CustomerID) AS customers
FROM SalWorkOrder w
JOIN GenLkpDocumentStatus ds ON ds.ID = w.DocumentStatusID
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.WorkOrderDate >= '2026-11-01'
GROUP BY CASE WHEN w.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END,
         ds.DocumentStatusName;

-- DB check: Top Selling today by sales value (TC-025, 026, 073)
SELECT i.ItemName, SUM(si.ItemQuantity) AS qty_sold, SUM(si.ItemTotalAmount) AS sold_value
FROM SalInvoiceItem si
JOIN SalInvoice s ON s.ID = si.InvoiceID
JOIN InvItem i    ON i.ID = si.ItemID
WHERE s.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND s.InvoiceDate >= '2026-11-20'
GROUP BY i.ItemName
ORDER BY sold_value DESC;

-- DB check: COGS today, cost per invoice line (TC-031)
SELECT i.InvoiceNumber, c.ItemCost, i.InvoiceBeforeTaxAmount AS net_excl_vat
FROM SalInvoiceItemCost c
JOIN SalInvoice i ON i.ID = c.InvoiceID
WHERE i.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND i.InvoiceDate >= '2026-11-20';

-- DB check: Inventory counts in branch stores (TC-019, 020, 064, 072)
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

-- DB check: Tire - Item stock per store (TC-063, 065, 066)
SELECT st.StoreName, SUM(t.BaseItemQuantity) AS qty,
       MAX(si.ItemMinQuantity) AS min_qty, MAX(si.ItemMaxQuantity) AS max_qty
FROM InvStoreTransaction t
JOIN InvItem i   ON i.ID = t.ItemID
JOIN InvStore st ON st.ID = t.StoreID
LEFT JOIN InvStoreItem si ON si.StoreID = t.StoreID AND si.ItemID = t.ItemID
WHERE i.ItemNumber = 'TO_1000001' AND t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY st.StoreName;

-- DB check: Inventory Value, qty x transaction cost, items applied to the branch (TC-029, 062)
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

-- Extra check: today's stock movements (Purchase Invoice and sales, TC-029 / 035)
SELECT TOP 8 i.ItemNumber, t.BaseItemQuantity AS qty, t.ItemCost, t.DocumentDate, s.StoreName
FROM InvStoreTransaction t
JOIN InvItem i  ON i.ID = t.ItemID
JOIN InvStore s ON s.ID = t.StoreID
WHERE t.DocumentDate >= '2026-11-20'
ORDER BY t.DocumentDate DESC;

-- Extra check: Air Filter 041 balance per store, before and after PR-TO_11000003 (TC-029)
SELECT s.StoreName, SUM(t.BaseItemQuantity) AS qty, SUM(t.BaseItemQuantity * t.ItemCost) AS value,
       SUM(CASE WHEN t.DocumentDate < '2026-11-20 15:48' THEN t.BaseItemQuantity ELSE 0 END) AS qty_before
FROM InvStoreTransaction t
JOIN InvItem i  ON i.ID = t.ItemID
JOIN InvStore s ON s.ID = t.StoreID
WHERE i.ItemNumber = 'NEW-ITEM-0041' AND t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY s.StoreName;

-- Extra check: Air Filter 041 units (packing size) and price (TC-029)
SELECT iu.PackingSize, iu.IsDefault, p.ItemPrice
FROM InvItem i
JOIN InvItemUnit iu ON iu.ItemID = i.ID
LEFT JOIN SalPriceListItem p ON p.ItemUnitID = iu.ID
WHERE i.ItemNumber = 'NEW-ITEM-0041';