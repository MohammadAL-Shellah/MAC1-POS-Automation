-- Stock chain check 1: every Stock In / Stock Out of the day -> source document -> item lines -> store transactions
-- Branch Alshellah, date 2026-11-20 (change both values for another day). Read only.
WITH h AS (
  SELECT 'IN' AS dir, ID, StockInNumber AS num, RefDocumentID AS ref, StockInDate AS d, StoreID
  FROM InvStockIn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockInDate  >= '2026-11-20'
  UNION ALL
  SELECT 'OUT', ID, StockOutNumber, RefDocumentID, StockOutDate, StoreID
  FROM InvStockOut WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOutDate >= '2026-11-20')
SELECT h.dir, h.num AS stock_doc,
       COALESCE(si.InvoiceNumber, sr.ReturnNumber, wo.WorkOrderNumber, pi.InvoiceNumber, '?') AS source_doc,
       CASE WHEN si.ID IS NOT NULL THEN 'Sales Invoice' WHEN sr.ID IS NOT NULL THEN 'Sales Return'
            WHEN wo.ID IS NOT NULL THEN 'Work Order'    WHEN pi.ID IS NOT NULL THEN 'Purchase Invoice' ELSE 'NOT LINKED' END AS source_type,
       ds.DocumentStatusName AS wo_status, st.StoreName,
       (SELECT COUNT(*) FROM InvStockInItem x WHERE x.StockInID = h.ID) + (SELECT COUNT(*) FROM InvStockOutItem x WHERE x.StockOutID = h.ID) AS item_lines,
       (SELECT SUM(x.BaseItemQuantity) FROM InvStockInItem  x WHERE x.StockInID  = h.ID) AS in_base_qty,
       (SELECT SUM(x.BaseItemQuantity) FROM InvStockOutItem x WHERE x.StockOutID = h.ID) AS out_base_qty,
       (SELECT SUM(t.BaseItemQuantity) FROM InvStoreTransaction t WHERE t.DocumentID = h.ref) AS store_tx_base_qty
FROM h
LEFT JOIN SalInvoice   si ON si.ID = h.ref
LEFT JOIN SalReturn    sr ON sr.ID = h.ref
LEFT JOIN SalWorkOrder wo ON wo.ID = h.ref
LEFT JOIN GenLkpDocumentStatus ds ON ds.ID = wo.DocumentStatusID
LEFT JOIN ProInvoice   pi ON pi.ID = h.ref
LEFT JOIN InvStore     st ON st.ID = h.StoreID
ORDER BY h.d;