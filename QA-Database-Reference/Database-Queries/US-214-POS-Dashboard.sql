-- =====================================================================
-- Story US-214  POS Dashboard (MacOne app)
-- Environment: QA/Test database, read only (SELECT queries only)
-- Branch Alshellah = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
-- Stores = '621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596'
-- Format: every query has Test case, Purpose, Expected and Status (README.md, "Query block format").
-- Status: Written = in the file, Executed = run in SSMS, Verified = result matched the screen.
-- Reading tips: DocumentStatusID 2 = Submitted (confirmed). Returns are shown as negative amounts.
-- Layout rewritten for readability on 2026-11-21; logic and results unchanged (checked by running the file before and after).
-- =====================================================================

-- =====================================================================
-- Section A: Dashboard KPI checks   |   2026-11-20   |   Build 1.2.498 (Run 8)
-- =====================================================================

-- Test case: TC-005 Calculate Overview Daily Sales with discount and returns
--            TC-013 Count today's confirmed invoices and fully paid invoices
--            TC-034 Calculate Output VAT net of sales-return VAT
--            TC-043 Calculate Sales Total Sales, Net Sales, and invoice count
--            TC-077 Show Daily Sales including VAT and Daily Net Sales excluding VAT in the Executive Summary
-- Purpose  : Today's invoices and returns: count, total incl. VAT, net, VAT and discount.
-- Expected : Daily Sales = invoices total minus returns total; counts and VAT as on the Overview.
-- Status   : Verified (TC-005, Runs 73 and 74)
-- Invoices of today
SELECT 'Invoices'                   AS Document_Type,
       COUNT(*)                     AS Documents_Count,
       SUM(InvoiceTotalAmount)      AS Total_Incl_VAT,
       SUM(InvoiceBeforeTaxAmount)  AS Net_Excl_VAT,
       SUM(InvoiceTaxAmount)        AS VAT_Amount,
       SUM(InvoiceDiscountAmount)   AS Discount_Amount
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'   -- branch Alshellah
  AND  InvoiceDate >= '2026-11-20'

UNION ALL

-- Returns of today
SELECT 'Returns',
       COUNT(*),
       SUM(ReturnTotalAmount),
       SUM(ReturnBeforeTaxAmount),
       SUM(ReturnTaxAmount),
       SUM(ReturnDiscountAmount)
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-20';

-- Test case: TC-008 Calculate Overview sales growth for non-zero yesterday sales
--            TC-039 Apply a valid custom Sales date range
--            TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Invoices of 18/11 and 19/11, to check yesterday sales.
-- Expected : Yesterday total used by the growth percentage.
-- Status   : Executed
SELECT InvoiceNumber      AS Invoice_No,
       InvoiceDate        AS Invoice_Date,
       InvoiceTotalAmount AS Total_Incl_VAT
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-18'
  AND  InvoiceDate <  '2026-11-20'      -- 18/11 and 19/11
ORDER BY InvoiceDate;

-- Test case: TC-022 Calculate Expected Cash Balance from the current session's cash movements
--            TC-027 Show payment-method values and transaction count for the current business day
--            TC-074 Calculate Expected Cash using the refund example
-- Purpose  : Amounts received and refunded today per payment method.
-- Expected : Same amounts per method as the Overview chart and the Cash tab.
-- Status   : Verified (Run 74)
SELECT Method.PaymentMethodName   AS Payment_Method,
       SUM(Payment.PaymentAmount) AS Received_Amount,
       -- refunds paid back with the same method today
       ISNULL((SELECT SUM(RefundPayment.PaymentAmount)
               FROM   SalReturnReceiptPayment RefundPayment
               JOIN   SalReturnReceipt RefundReceipt ON RefundReceipt.ID = RefundPayment.ReturnReceiptID
               WHERE  RefundReceipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
                 AND  RefundReceipt.ReturnReceiptDate >= '2026-11-20'
                 AND  RefundPayment.PaymentMethodID = Method.ID), 0) AS Refunded_Amount
FROM   SalInvoiceReceiptPayment Payment
JOIN   SalInvoiceReceipt   Receipt ON Receipt.ID = Payment.InvoiceReceiptID
JOIN   GenLkpPaymentMethod Method  ON Method.ID  = Payment.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Receipt.InvoiceReceiptDate >= '2026-11-20'
GROUP BY Method.PaymentMethodName, Method.ID;

-- Test case: TC-021 Show cash register session details
--            TC-022 Calculate Expected Cash Balance from the current session's cash movements
--            TC-061 Show the Cash tab's current-session register summary
-- Purpose  : Today's working day with its opening cash and invoice count.
-- Expected : Opening cash as on the Cash Register card.
-- Status   : Verified (Run 74)
SELECT WorkDay.OpenDate              AS Opened_At,
       WorkDay.OpenBalanceCashAmount AS Opening_Cash,
       WorkDay.IsClosed              AS Is_Closed,
       (SELECT COUNT(*) FROM SalInvoice Inv WHERE Inv.WorkingDayID = WorkDay.ID) AS Invoices_Count
FROM   SalWorkingDay WorkDay
WHERE  WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  WorkDay.OpenDate >= '2026-11-20'
ORDER BY WorkDay.OpenDate;

-- Test case: TC-038 Populate MTD, QTD, and YTD date ranges
--            TC-042 Preserve Sales date range across All, Refunds, and Invoices
--            TC-045 Calculate Average Invoice Value
-- Purpose  : Sales MTD from 01/11: invoice and return totals.
-- Expected : Same MTD totals as the Sales tab.
-- Status   : Executed
SELECT 'Invoices'                  AS Document_Type,
       COUNT(*)                    AS Documents_Count,
       SUM(InvoiceTotalAmount)     AS Total_Incl_VAT,
       SUM(InvoiceBeforeTaxAmount) AS Net_Excl_VAT
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-01'      -- month to date

UNION ALL

SELECT 'Returns',
       COUNT(*),
       SUM(ReturnTotalAmount),
       SUM(ReturnBeforeTaxAmount)
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-01';

-- Test case: TC-058 Calculate Cash tab payment totals
--            TC-059 Apply Cash tab selected day or date range
-- Purpose  : Cash tab MTD: received and refunded, cash versus electronic.
-- Expected : Net Cash and Net Electronic as on the Cash tab.
-- Status   : Executed
-- Money received on invoices
SELECT 'Received' AS Movement,
       CASE WHEN Method.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END AS Payment_Kind,
       SUM(Payment.PaymentAmount) AS Amount
FROM   SalInvoiceReceiptPayment Payment
JOIN   SalInvoiceReceipt   Receipt ON Receipt.ID = Payment.InvoiceReceiptID
JOIN   GenLkpPaymentMethod Method  ON Method.ID  = Payment.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Receipt.InvoiceReceiptDate >= '2026-11-01'
GROUP BY CASE WHEN Method.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END

UNION ALL

-- Money refunded on returns
SELECT 'Refunded',
       CASE WHEN Method.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END,
       SUM(Payment.PaymentAmount)
FROM   SalReturnReceiptPayment Payment
JOIN   SalReturnReceipt    Receipt ON Receipt.ID = Payment.ReturnReceiptID
JOIN   GenLkpPaymentMethod Method  ON Method.ID  = Payment.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Receipt.ReturnReceiptDate >= '2026-11-01'
GROUP BY CASE WHEN Method.PaymentMethodName = 'Cash' THEN 'Cash' ELSE 'Electronic' END;

-- Test case: TC-017 Count total Work Orders for the current business day
--            TC-018 Calculate Work Order status counts and rates
--            TC-052 Apply WO Info period and custom date filters
--            TC-053 Calculate WO Info totals and customers served
--            TC-054 Calculate WO Info Pending, Completed, and Voided rates
-- Purpose  : Work Orders by status, today and earlier this month, with customers.
-- Expected : Same WO counts per status as the Overview and WO Info.
-- Status   : Executed
SELECT CASE WHEN WO.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END AS Period,
       Status.DocumentStatusName     AS WO_Status,
       COUNT(*)                      AS WO_Count,
       COUNT(DISTINCT WO.CustomerID) AS Customers_Count
FROM   SalWorkOrder WO
JOIN   GenLkpDocumentStatus Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  WO.WorkOrderDate >= '2026-11-01'
GROUP BY CASE WHEN WO.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END,
         Status.DocumentStatusName;

-- Test case: TC-025 Rank Top Selling items by sales value
--            TC-026 Open the Top Selling report from View All
--            TC-073 Show Top Selling when fewer than five items, or no items, were sold
-- Purpose  : Items sold today ranked by sales value (Top Selling).
-- Expected : Same items and order as Top Selling Today.
-- Status   : Verified (Run 74)
SELECT Item.ItemName             AS Item_Name,
       SUM(Line.ItemQuantity)    AS Quantity_Sold,
       SUM(Line.ItemTotalAmount) AS Sales_Value
FROM   SalInvoiceItem Line
JOIN   SalInvoice Inv  ON Inv.ID  = Line.InvoiceID
JOIN   InvItem    Item ON Item.ID = Line.ItemID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-20'
GROUP BY Item.ItemName
ORDER BY Sales_Value DESC;

-- Test case: TC-031 Calculate Gross Profit
-- Purpose  : Cost per invoice line today (COGS, first version).
-- Expected : Sum of cost for Gross Profit. Note: no quantity factor, use Q9b in Section C.
-- Status   : Executed
SELECT Inv.InvoiceNumber          AS Invoice_No,
       Cost.ItemCost              AS Line_Cost,
       Inv.InvoiceBeforeTaxAmount AS Invoice_Net_Excl_VAT
FROM   SalInvoiceItemCost Cost
JOIN   SalInvoice Inv ON Inv.ID = Cost.InvoiceID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-20';

-- Test case: TC-019 Calculate inventory item status counts
--            TC-020 Open inventory exception lists from the Overview
--            TC-064 Calculate Inventory tab counts
--            TC-072 Count items with stock movement or a Min/Max setup in the selected branch
-- Purpose  : Negative and positive stock counts in the branch stores.
-- Expected : Same counts as the Inventory tab.
-- Status   : Executed
-- Step 1: stock balance of each item in each branch store
WITH StockBalance AS (
    SELECT StoreID, ItemID, SUM(BaseItemQuantity) AS Balance_Qty
    FROM   InvStoreTransaction
    WHERE  StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    GROUP BY StoreID, ItemID),
-- Step 2: keep submitted items, and mark whether each item is applied to the branch
ItemsInScope AS (
    SELECT StockBalance.Balance_Qty,
           CASE WHEN Item.IsApplyToAllBranch = 1
                  OR EXISTS (SELECT 1 FROM InvItemBranch ItemBranch
                             WHERE ItemBranch.ItemID = Item.ID
                               AND ItemBranch.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
                THEN 'Applied to branch' ELSE 'Not applied' END AS Branch_Scope
    FROM   StockBalance
    JOIN   InvItem Item ON Item.ID = StockBalance.ItemID
    JOIN   GenLkpDocumentStatus Status ON Status.ID = Item.DocumentStatusID
    WHERE  Status.DocumentStatusName = 'Submitted')
-- Step 3: count negative and positive balances
SELECT Branch_Scope,
       SUM(CASE WHEN Balance_Qty < 0 THEN 1 ELSE 0 END) AS Negative_Count,
       SUM(CASE WHEN Balance_Qty > 0 THEN 1 ELSE 0 END) AS Positive_Count,
       COUNT(*)                                         AS Rows_With_Movement
FROM   ItemsInScope
GROUP BY Branch_Scope;

-- Test case: TC-063 Show Low Stock based on Min Quantity and positive stock
--            TC-065 Show inventory grid values and status
--            TC-066 Search Inventory by Item Name and Item Number
-- Purpose  : Tire - Item stock per store with min and max.
-- Expected : Same quantity, min and max as the Inventory grid.
-- Status   : Executed
SELECT Store.StoreName                AS Store_Name,
       SUM(Trx.BaseItemQuantity)      AS Stock_Qty,
       MAX(StoreItem.ItemMinQuantity) AS Min_Qty,
       MAX(StoreItem.ItemMaxQuantity) AS Max_Qty
FROM   InvStoreTransaction Trx
JOIN   InvItem  Item  ON Item.ID  = Trx.ItemID
JOIN   InvStore Store ON Store.ID = Trx.StoreID
LEFT JOIN InvStoreItem StoreItem ON StoreItem.StoreID = Trx.StoreID AND StoreItem.ItemID = Trx.ItemID
WHERE  Item.ItemNumber = 'TO_1000001'      -- Tire - Item
  AND  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Store.StoreName;

-- Test case: TC-029 Calculate current Inventory Value
--            TC-062 Calculate Inventory tab Stock Value
-- Purpose  : Inventory Value = quantity x transaction cost, items applied to the branch.
-- Expected : Same value as Inventory Value on the Executive Summary.
-- Status   : Executed
-- Step 1: quantity and value (qty x cost) of each item in each branch store
WITH StockBalance AS (
    SELECT Trx.StoreID, Trx.ItemID,
           SUM(Trx.BaseItemQuantity)                AS Balance_Qty,
           SUM(Trx.BaseItemQuantity * Trx.ItemCost) AS Balance_Value
    FROM   InvStoreTransaction Trx
    WHERE  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    GROUP BY Trx.StoreID, Trx.ItemID)
-- Step 2: total per store, only items applied to the branch
SELECT Store.StoreName                 AS Store_Name,
       SUM(StockBalance.Balance_Value) AS Value_Qty_x_Cost,
       SUM(CASE WHEN StockBalance.Balance_Qty > 0 THEN StockBalance.Balance_Qty END) AS Positive_Qty
FROM   StockBalance
JOIN   InvItem  Item  ON Item.ID  = StockBalance.ItemID
JOIN   InvStore Store ON Store.ID = StockBalance.StoreID
WHERE  Item.IsApplyToAllBranch = 1
   OR  EXISTS (SELECT 1 FROM InvItemBranch ItemBranch
               WHERE ItemBranch.ItemID = Item.ID
                 AND ItemBranch.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
GROUP BY Store.StoreName;

-- Test case: TC-029 Calculate current Inventory Value
--            TC-035 Calculate Input VAT net of purchase-return VAT
-- Purpose  : Today's latest stock movements (purchase and sales).
-- Expected : The purchase adds stock at its cost; sales remove it.
-- Status   : Executed
SELECT TOP 8
       Item.ItemNumber      AS Item_No,
       Trx.BaseItemQuantity AS Base_Qty,
       Trx.ItemCost         AS Unit_Cost,
       Trx.DocumentDate     AS Movement_Date,
       Store.StoreName      AS Store_Name
FROM   InvStoreTransaction Trx
JOIN   InvItem  Item  ON Item.ID  = Trx.ItemID
JOIN   InvStore Store ON Store.ID = Trx.StoreID
WHERE  Trx.DocumentDate >= '2026-11-20'
ORDER BY Trx.DocumentDate DESC;

-- Test case: TC-029 Calculate current Inventory Value
-- Purpose  : Air Filter 041 balance per store before and after PR-TO_11000003.
-- Expected : Stock rises by the purchased base quantity only.
-- Status   : Executed
SELECT Store.StoreName                          AS Store_Name,
       SUM(Trx.BaseItemQuantity)                AS Qty_Now,
       SUM(Trx.BaseItemQuantity * Trx.ItemCost) AS Value_Now,
       SUM(CASE WHEN Trx.DocumentDate < '2026-11-20 15:48'      -- before the purchase invoice
                THEN Trx.BaseItemQuantity ELSE 0 END) AS Qty_Before_Purchase
FROM   InvStoreTransaction Trx
JOIN   InvItem  Item  ON Item.ID  = Trx.ItemID
JOIN   InvStore Store ON Store.ID = Trx.StoreID
WHERE  Item.ItemNumber = 'NEW-ITEM-0041'      -- Air Filter 041
  AND  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Store.StoreName;

-- Test case: TC-029 Calculate current Inventory Value
-- Purpose  : Air Filter 041 units (packing size) and price.
-- Expected : Packing size explains base units per Each.
-- Status   : Executed
SELECT Unit.PackingSize AS Packing_Size,
       Unit.IsDefault   AS Is_Default_Unit,
       Price.ItemPrice  AS Price
FROM   InvItem Item
JOIN   InvItemUnit Unit ON Unit.ItemID = Item.ID
LEFT JOIN SalPriceListItem Price ON Price.ItemUnitID = Unit.ID
WHERE  Item.ItemNumber = 'NEW-ITEM-0041';

-- =====================================================================
-- Section B: Stock chain checks after each transaction   |   2026-11-20   |   Build 1.2.498
-- =====================================================================

-- Test case: none (supporting check)
-- Purpose  : Every Stock In and Stock Out of the day linked to its source document, item lines and store transactions (change the date for another day).
-- Expected : Every stock document has a source document and matching quantities.
-- Status   : Executed
-- Step 1: all Stock In and Stock Out documents of the day
WITH StockDocs AS (
    SELECT 'IN' AS Direction, ID, StockInNumber AS Stock_Doc_No, RefDocumentID AS Source_ID, StockInDate AS Doc_Date, StoreID
    FROM   InvStockIn
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockInDate  >= '2026-11-20'
    UNION ALL
    SELECT 'OUT', ID, StockOutNumber, RefDocumentID, StockOutDate, StoreID
    FROM   InvStockOut
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOutDate >= '2026-11-20')
-- Step 2: find the source document of each one, and compare the quantities
SELECT StockDocs.Direction,
       StockDocs.Stock_Doc_No,
       COALESCE(Inv.InvoiceNumber, Ret.ReturnNumber, WO.WorkOrderNumber, PurInv.InvoiceNumber, '?') AS Source_Doc_No,
       CASE WHEN Inv.ID    IS NOT NULL THEN 'Sales Invoice'
            WHEN Ret.ID    IS NOT NULL THEN 'Sales Return'
            WHEN WO.ID     IS NOT NULL THEN 'Work Order'
            WHEN PurInv.ID IS NOT NULL THEN 'Purchase Invoice'
            ELSE 'NOT LINKED' END AS Source_Type,
       WOStatus.DocumentStatusName AS WO_Status,
       Store.StoreName             AS Store_Name,
       (SELECT COUNT(*) FROM InvStockInItem  L WHERE L.StockInID  = StockDocs.ID)
     + (SELECT COUNT(*) FROM InvStockOutItem L WHERE L.StockOutID = StockDocs.ID) AS Item_Lines,
       (SELECT SUM(L.BaseItemQuantity) FROM InvStockInItem  L WHERE L.StockInID  = StockDocs.ID) AS In_Base_Qty,
       (SELECT SUM(L.BaseItemQuantity) FROM InvStockOutItem L WHERE L.StockOutID = StockDocs.ID) AS Out_Base_Qty,
       (SELECT SUM(T.BaseItemQuantity) FROM InvStoreTransaction T WHERE T.DocumentID = StockDocs.Source_ID) AS Store_Trx_Base_Qty
FROM   StockDocs
LEFT JOIN SalInvoice   Inv    ON Inv.ID    = StockDocs.Source_ID
LEFT JOIN SalReturn    Ret    ON Ret.ID    = StockDocs.Source_ID
LEFT JOIN SalWorkOrder WO     ON WO.ID     = StockDocs.Source_ID
LEFT JOIN GenLkpDocumentStatus WOStatus ON WOStatus.ID = WO.DocumentStatusID
LEFT JOIN ProInvoice   PurInv ON PurInv.ID = StockDocs.Source_ID
LEFT JOIN InvStore     Store  ON Store.ID  = StockDocs.StoreID
ORDER BY StockDocs.Doc_Date;

-- Test case: none (supporting check)
-- Purpose  : The day's store transactions with item type.
-- Expected : Service items do not move stock.
-- Status   : Executed
SELECT DocType.DocumentTypeName            AS Document_Type,
       Item.ItemNumber                     AS Item_No,
       Item.ItemName                       AS Item_Name,
       ItemType.ItemTypeName               AS Item_Type,
       Trx.ItemQuantity                    AS Qty,
       Trx.BaseItemQuantity                AS Base_Qty,
       Trx.ItemCost                        AS Unit_Cost,
       Trx.BaseItemQuantity * Trx.ItemCost AS Movement_Value,
       Store.StoreName                     AS Store_Name,
       Trx.DocumentDate                    AS Movement_Date,
       (SELECT InvoiceNumber FROM SalInvoice D WHERE D.ID = Trx.DocumentID) AS Linked_Invoice,
       (SELECT ReturnNumber  FROM SalReturn  D WHERE D.ID = Trx.DocumentID) AS Linked_Return,
       (SELECT InvoiceNumber FROM ProInvoice D WHERE D.ID = Trx.DocumentID) AS Linked_Purchase
FROM   InvStoreTransaction Trx
JOIN   GenLkpDocumentType DocType ON DocType.ID = Trx.DocumentTypeID
JOIN   InvItem Item ON Item.ID = Trx.ItemID
LEFT JOIN InvLkpItemType ItemType ON ItemType.ID = Item.ItemTypeID
JOIN   InvStore Store ON Store.ID = Trx.StoreID
WHERE  Trx.DocumentDate >= '2026-11-20'
  AND  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
ORDER BY Trx.DocumentDate;

-- Test case: none (supporting check)
-- Purpose  : Service items that hold stock in the branch stores.
-- Expected : No rows.
-- Status   : Executed
SELECT Item.ItemNumber           AS Item_No,
       Item.ItemName             AS Item_Name,
       Store.StoreName           AS Store_Name,
       SUM(Trx.BaseItemQuantity) AS Stock_Qty
FROM   InvStoreTransaction Trx
JOIN   InvItem        Item    ON Item.ID    = Trx.ItemID
JOIN   InvItemService Service ON Service.ID = Item.ID        -- only service items
JOIN   InvStore       Store   ON Store.ID   = Trx.StoreID
WHERE  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Item.ItemNumber, Item.ItemName, Store.StoreName
HAVING SUM(Trx.BaseItemQuantity) <> 0;

-- Test case: none (supporting check)
-- Purpose  : Batch cost written by today's purchases.
-- Expected : One batch cost per purchased item.
-- Status   : Executed
SELECT Item.ItemNumber             AS Item_No,
       Batch.BatchNumber           AS Batch_No,
       BatchCost.ItemBatchCost     AS Batch_Cost,
       BatchCost.ItemBatchCostDate AS Cost_Date
FROM   InvItemBatchCost BatchCost
JOIN   InvItemBatch Batch ON Batch.ID = BatchCost.ID
JOIN   InvItem      Item  ON Item.ID  = Batch.ItemID
WHERE  BatchCost.ItemBatchCostDate >= '2026-11-20';

-- =====================================================================
-- Section C: Run 9 (DevOps Test Run 74)   |   2026-11-20   |   Build 1.2.498
-- =====================================================================
-- Note: Section A "COGS today" sums ItemCost per line without quantity. Use Q9b below (base qty x cost), which matches the dashboard.

-- Test case: TC-008 Calculate Overview sales growth for non-zero yesterday sales
--            TC-039 Apply a valid custom Sales date range
--            TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Q2: net sales per day for the last days, for the growth percentage.
-- Expected : Today and yesterday sales as used by the growth KPI.
-- Status   : Verified (Run 74)
SELECT CAST(DocDate AS date)                            AS Sales_Day,
       SUM(Amount)                                      AS Net_Sales_Incl_VAT,
       SUM(CASE WHEN DocType = 'INV' THEN 1 ELSE 0 END) AS Invoices_Count,
       SUM(CASE WHEN DocType = 'RET' THEN 1 ELSE 0 END) AS Returns_Count
FROM (
    SELECT 'INV' AS DocType, InvoiceDate AS DocDate, InvoiceTotalAmount AS Amount
    FROM   SalInvoice
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-17'
    UNION ALL
    SELECT 'RET', ReturnDate, -ReturnTotalAmount          -- returns as negative
    FROM   SalReturn
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-17'
) AS AllDocs
GROUP BY CAST(DocDate AS date)
ORDER BY Sales_Day;

-- Test case: TC-017 Count total Work Orders for the current business day
--            TC-018 Calculate Work Order status counts and rates
--            TC-052 Apply WO Info period and custom date filters
--            TC-053 Calculate WO Info totals and customers served
--            TC-054 Calculate WO Info Pending, Completed, and Voided rates
-- Purpose  : Q7: Work Orders today by status, with customers and amount.
-- Expected : Same counts as the Overview and WO Info.
-- Status   : Verified (Run 74)
SELECT Status.DocumentStatusName     AS WO_Status,
       COUNT(*)                      AS WO_Count,
       COUNT(DISTINCT WO.CustomerID) AS Customers_Count,
       SUM(WO.WorkOrderTotalAmount)  AS WO_Amount
FROM   SalWorkOrder WO
JOIN   GenLkpDocumentStatus Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  WO.WorkOrderDate >= '2026-11-20'
GROUP BY Status.DocumentStatusName;

-- Test case: TC-031 Calculate Gross Profit
--            TC-032 Calculate Gross Margin percentage
-- Purpose  : Q9: COGS today = unit cost x quantity on sold lines, less returned lines.
-- Expected : Gross Profit cost. Note: understates (sales unit, not base unit).
-- Status   : Executed
-- Part 1: cost of each sold line
SELECT 'Sold'                            AS Part,
       Inv.InvoiceNumber                 AS Document_No,
       Item.ItemName                     AS Item_Name,
       Line.ItemQuantity                 AS Qty,
       Cost.ItemCost                     AS Unit_Cost,
       Cost.ItemCost * Line.ItemQuantity AS Line_Cost
FROM   SalInvoiceItemCost Cost
JOIN   SalInvoice     Inv  ON Inv.ID  = Cost.InvoiceID
JOIN   SalInvoiceItem Line ON Line.ID = Cost.InvoiceItemID
JOIN   InvItem        Item ON Item.ID = Cost.ItemID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-20'

UNION ALL

-- Part 2: cost of each returned line (negative)
SELECT 'Returned',
       Ret.ReturnNumber,
       Item.ItemName,
       Line.ItemQuantity,
       Cost.ItemCost,
       -Cost.ItemCost * Line.ItemQuantity
FROM   SalReturnItemCost Cost
JOIN   SalReturn     Ret  ON Ret.ID  = Cost.ReturnID
JOIN   SalReturnItem Line ON Line.ID = Cost.ReturnItemID
JOIN   InvItem       Item ON Item.ID = Line.ItemID
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Ret.ReturnDate >= '2026-11-20'

UNION ALL

-- Part 3: total COGS = sold cost minus returned cost
SELECT 'TOTAL COGS', NULL, NULL, NULL, NULL,
       (SELECT SUM(Cost.ItemCost * Line.ItemQuantity)
        FROM   SalInvoiceItemCost Cost
        JOIN   SalInvoice     Inv  ON Inv.ID  = Cost.InvoiceID
        JOIN   SalInvoiceItem Line ON Line.ID = Cost.InvoiceItemID
        WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceDate >= '2026-11-20')
     - ISNULL((SELECT SUM(Cost.ItemCost * Line.ItemQuantity)
               FROM   SalReturnItemCost Cost
               JOIN   SalReturn     Ret  ON Ret.ID  = Cost.ReturnID
               JOIN   SalReturnItem Line ON Line.ID = Cost.ReturnItemID
               WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.ReturnDate >= '2026-11-20'), 0);

-- Test case: TC-031 Calculate Gross Profit
--            TC-032 Calculate Gross Margin percentage
-- Purpose  : Q9b: cost of sales and returns today from store transactions (base qty x cost).
-- Expected : Cost behind Gross Profit and Gross Margin.
-- Status   : Verified (Run 74)
SELECT DocType.DocumentTypeName                  AS Document_Type,
       Item.ItemName                             AS Item_Name,
       SUM(Trx.BaseItemQuantity)                 AS Base_Qty,
       MAX(Trx.ItemCost)                         AS Unit_Cost,
       -SUM(Trx.BaseItemQuantity * Trx.ItemCost) AS Cost_Out
FROM   InvStoreTransaction Trx
JOIN   GenLkpDocumentType DocType ON DocType.ID = Trx.DocumentTypeID
JOIN   InvItem Item ON Item.ID = Trx.ItemID
WHERE  Trx.DocumentDate >= '2026-11-20'
  AND  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY ROLLUP (DocType.DocumentTypeName, Item.ItemName);     -- ROLLUP adds subtotal and total rows

-- Test case: TC-019 Calculate inventory item status counts
--            TC-020 Open inventory exception lists from the Overview
--            TC-064 Calculate Inventory tab counts
--            TC-072 Count items with stock movement or a Min/Max setup in the selected branch
-- Purpose  : Q10: stock classification per item and store, including store items without movement.
-- Expected : Same counts as the Inventory tab (did not match, see TC-019).
-- Status   : Executed
-- Step 1: stock balance of each item in each branch store
WITH StockBalance AS (
    SELECT StoreID, ItemID, SUM(BaseItemQuantity) AS Balance_Qty
    FROM   InvStoreTransaction
    WHERE  StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    GROUP BY StoreID, ItemID),
-- Step 2: every item and store pair: with movement, or set up in the store (InvStoreItem)
ItemStorePairs AS (
    SELECT StoreID, ItemID FROM StockBalance
    UNION
    SELECT StoreID, ItemID FROM InvStoreItem
    WHERE  StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')),
-- Step 3: balance and min quantity of submitted items applied to the branch
ItemsInScope AS (
    SELECT ISNULL(StockBalance.Balance_Qty, 0) AS Balance_Qty,
           StoreItem.ItemMinQuantity           AS Min_Qty
    FROM   ItemStorePairs Pair
    JOIN   InvItem Item ON Item.ID = Pair.ItemID
    JOIN   GenLkpDocumentStatus Status ON Status.ID = Item.DocumentStatusID
    LEFT JOIN StockBalance ON StockBalance.StoreID = Pair.StoreID AND StockBalance.ItemID = Pair.ItemID
    LEFT JOIN InvStoreItem StoreItem ON StoreItem.StoreID = Pair.StoreID AND StoreItem.ItemID = Pair.ItemID
    WHERE  Status.DocumentStatusName = 'Submitted'
      AND  (Item.IsApplyToAllBranch = 1
            OR EXISTS (SELECT 1 FROM InvItemBranch ItemBranch
                       WHERE ItemBranch.ItemID = Item.ID
                         AND ItemBranch.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')))
-- Step 4: count per stock status
SELECT COUNT(*)                                         AS Total_Pairs,
       SUM(CASE WHEN Balance_Qty < 0 THEN 1 ELSE 0 END) AS Negative_Stock,
       SUM(CASE WHEN Balance_Qty = 0 THEN 1 ELSE 0 END) AS Out_Of_Stock,
       SUM(CASE WHEN Balance_Qty > 0 AND Min_Qty IS NOT NULL AND Balance_Qty < Min_Qty THEN 1 ELSE 0 END) AS Low_Stock,
       SUM(CASE WHEN Balance_Qty > 0 AND (Min_Qty IS NULL OR Balance_Qty >= Min_Qty) THEN 1 ELSE 0 END)  AS In_Stock
FROM   ItemsInScope;

-- Test case: none (supporting check)
-- Purpose  : Helper: columns of the COGS and store item tables (schema check).
-- Expected : Column names for the queries above.
-- Status   : Executed
SELECT TABLE_NAME                    AS Table_Name,
       STRING_AGG(COLUMN_NAME, ', ') AS Columns
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME IN ('SalInvoiceItemCost', 'SalReturnItemCost', 'InvStoreItem')
GROUP BY TABLE_NAME;

-- Test case: TC-011 Open Daily Sales report filtered to the business date
--            TC-014 Open Fully Paid and Fully Refunded invoice lists
--            TC-015 Calculate Fully Paid and Fully Refunded counts
--            TC-016 Show refunds separately from sales on the Overview
--            TC-069 Count Fully Refunded invoices on Overview
-- Purpose  : Q11: today's invoices with amount, paid and returned amounts.
-- Expected : Same invoices and statuses as the Overview drill-downs.
-- Status   : Verified (Run 74)
SELECT Inv.InvoiceNumber      AS Invoice_No,
       Inv.InvoiceTotalAmount AS Invoice_Amount,
       -- total paid on this invoice
       ISNULL((SELECT SUM(Payment.PaymentAmount)
               FROM   SalInvoiceReceiptPayment Payment
               JOIN   SalInvoiceReceiptInvoice ReceiptInv ON ReceiptInv.InvoiceReceiptID = Payment.InvoiceReceiptID
               WHERE  ReceiptInv.InvoiceID = Inv.ID), 0) AS Paid_Amount,
       -- total returned from this invoice
       ISNULL((SELECT SUM(Ret.ReturnTotalAmount)
               FROM   SalReturn Ret
               WHERE  Ret.InvoiceID = Inv.ID), 0)        AS Returned_Amount
FROM   SalInvoice Inv
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-20'
ORDER BY Inv.InvoiceNumber;

-- Test case: TC-012 Open Sales Return List filtered to the business date
--            TC-016 Show refunds separately from sales on the Overview
--            TC-069 Count Fully Refunded invoices on Overview
-- Purpose  : Q12: today's sales returns with their original invoice.
-- Expected : Same refunds as the Refunds list.
-- Status   : Verified (Run 74)
SELECT Ret.ReturnNumber      AS Return_No,
       Ret.ReturnDate        AS Return_Date,
       Ret.ReturnTotalAmount AS Return_Amount,
       Inv.InvoiceNumber     AS Original_Invoice,
       Inv.InvoiceDate       AS Invoice_Date
FROM   SalReturn Ret
LEFT JOIN SalInvoice Inv ON Inv.ID = Ret.InvoiceID
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Ret.ReturnDate >= '2026-11-20';

-- Test case: TC-029 Calculate current Inventory Value
--            TC-062 Calculate Inventory tab Stock Value
-- Purpose  : Q13: Inventory Value = base qty x transaction cost per store.
-- Expected : Same as Inventory Value (did not match: 659,992.41 vs screen 78,689.00).
-- Status   : Verified (mismatch reported)
-- Step 1: quantity and value of each item in each branch store
WITH StockBalance AS (
    SELECT Trx.StoreID, Trx.ItemID,
           SUM(Trx.BaseItemQuantity)                AS Balance_Qty,
           SUM(Trx.BaseItemQuantity * Trx.ItemCost) AS Balance_Value
    FROM   InvStoreTransaction Trx
    WHERE  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    GROUP BY Trx.StoreID, Trx.ItemID)
-- Step 2: value per store and total, submitted items applied to the branch
SELECT ISNULL(Store.StoreName, 'TOTAL') AS Store_Name,
       SUM(StockBalance.Balance_Value)  AS Value_Qty_x_Cost,
       SUM(CASE WHEN StockBalance.Balance_Qty > 0 THEN StockBalance.Balance_Value ELSE 0 END) AS Value_Positive_Stock_Only
FROM   StockBalance
JOIN   InvItem  Item  ON Item.ID  = StockBalance.ItemID
JOIN   InvStore Store ON Store.ID = StockBalance.StoreID
JOIN   GenLkpDocumentStatus Status ON Status.ID = Item.DocumentStatusID
WHERE  Status.DocumentStatusName = 'Submitted'
  AND  (Item.IsApplyToAllBranch = 1
        OR EXISTS (SELECT 1 FROM InvItemBranch ItemBranch
                   WHERE ItemBranch.ItemID = Item.ID
                     AND ItemBranch.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'))
GROUP BY ROLLUP (Store.StoreName);     -- ROLLUP adds the TOTAL row

-- Test case: TC-053 Calculate WO Info totals and customers served
--            TC-054 Calculate WO Info Pending, Completed, and Voided rates
-- Purpose  : Q14: Work Orders today: total, distinct customers and count per status.
-- Expected : Same totals and rates as WO Info.
-- Status   : Verified (Run 74)
SELECT COUNT(*)                      AS Total_WOs,
       COUNT(DISTINCT WO.CustomerID) AS Distinct_Customers,
       SUM(CASE WHEN Status.DocumentStatusName = 'New'       THEN 1 ELSE 0 END) AS Pending,     -- New = Pending
       SUM(CASE WHEN Status.DocumentStatusName = 'Submitted' THEN 1 ELSE 0 END) AS Completed,   -- Submitted = Completed
       SUM(CASE WHEN Status.DocumentStatusName = 'Cancelled' THEN 1 ELSE 0 END) AS Voided       -- Cancelled = Voided
FROM   SalWorkOrder WO
JOIN   GenLkpDocumentStatus Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  WO.WorkOrderDate >= '2026-11-20';

-- Test case: TC-063 Show Low Stock based on Min Quantity and positive stock
--            TC-065 Show inventory grid values and status
--            TC-066 Search Inventory by Item Name and Item Number
-- Purpose  : Q15: inventory grid quantity, min and max per store for sample items.
-- Expected : Same values as the Inventory grid.
-- Status   : Verified (Run 74)
SELECT Item.ItemName                  AS Item_Name,
       Item.ItemNumber                AS Item_No,
       Store.StoreName                AS Store_Name,
       SUM(Trx.BaseItemQuantity)      AS Stock_Qty,
       MAX(StoreItem.ItemMinQuantity) AS Min_Qty,
       MAX(StoreItem.ItemMaxQuantity) AS Max_Qty
FROM   InvStoreTransaction Trx
JOIN   InvItem  Item  ON Item.ID  = Trx.ItemID
JOIN   InvStore Store ON Store.ID = Trx.StoreID
LEFT JOIN InvStoreItem StoreItem ON StoreItem.StoreID = Trx.StoreID AND StoreItem.ItemID = Trx.ItemID
WHERE  Item.ItemNumber IN ('TO_1000001', '45251-T2G-A00YMC', 'NEW-ITEM-0041', 'NEW-ITEM-0046')
  AND  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Item.ItemName, Item.ItemNumber, Store.StoreName
ORDER BY Item.ItemNumber, Store.StoreName;

-- =====================================================================
-- Section D: Relationship verification for the Knowledge Base   |   2026-11-20
-- =====================================================================
-- Note on Stock chain check 1 (Section B): Stock In rows for sales returns carry RefDocumentID = the SalInvoice ID
-- (see R2), so the SalReturn join there never matches and returns show as 'Sales Invoice'. Use RefDocumentTypeID to label.

-- Test case: none (supporting check)
-- Purpose  : KB1: foreign keys of every table used in this file (metadata).
-- Expected : List of real FK constraints.
-- Status   : Verified
SELECT OBJECT_NAME(FK.parent_object_id)     + '.' + ChildCol.name  AS Child_Column,
       OBJECT_NAME(FK.referenced_object_id) + '.' + ParentCol.name AS Parent_Column,
       FK.name                                                     AS FK_Name
FROM   sys.foreign_keys FK
JOIN   sys.foreign_key_columns FKCol ON FKCol.constraint_object_id = FK.object_id
JOIN   sys.columns ChildCol  ON ChildCol.object_id  = FKCol.parent_object_id     AND ChildCol.column_id  = FKCol.parent_column_id
JOIN   sys.columns ParentCol ON ParentCol.object_id = FKCol.referenced_object_id AND ParentCol.column_id = FKCol.referenced_column_id
WHERE  OBJECT_NAME(FK.parent_object_id) IN ('SalInvoice','SalReturn','SalInvoiceReceipt','SalInvoiceReceiptPayment','SalInvoiceReceiptInvoice','SalReturnReceipt','SalReturnReceiptPayment','SalWorkingDay','SalWorkOrder','SalInvoiceItem','SalInvoiceItemCost','SalReturnItem','SalReturnItemCost','InvStoreTransaction','InvItem','InvStoreItem','InvItemBranch','InvItemUnit','SalPriceListItem','InvStockIn','InvStockOut','InvStockInItem','InvStockOutItem','InvItemBatch','InvItemBatchCost','InvItemService')
ORDER BY 1;

-- Test case: none (supporting check)
-- Purpose  : KB2 to KB5: links without an FK constraint, checked on records (R1 SalReturn.InvoiceID, R2 Stock In/Out RefDocumentID, R3 InvStoreTransaction.DocumentID, R4 receipts linked to invoices).
-- Expected : Every reference resolves to its parent record.
-- Status   : Verified (R1, R4), Executed (R2, R3)
-- R1: does every return point to an existing invoice?
SELECT 'R1'                                                                          AS Check_Name,
       COUNT(*)                                                                      AS Total_Returns,
       SUM(CASE WHEN Ret.InvoiceID IS NULL THEN 1 ELSE 0 END)                        AS Without_Invoice,
       SUM(CASE WHEN Ret.InvoiceID IS NOT NULL AND Inv.ID IS NULL THEN 1 ELSE 0 END) AS Invoice_Not_Found
FROM   SalReturn Ret
LEFT JOIN SalInvoice Inv ON Inv.ID = Ret.InvoiceID;

-- R2: what does RefDocumentID of Stock In / Stock Out point to, per reference type?
SELECT 'R2' AS Check_Name, Direction, Ref_Type, COUNT(*) AS Rows_Count,
       SUM(Is_SalInvoice)   AS In_SalInvoice,
       SUM(Is_SalReturn)    AS In_SalReturn,
       SUM(Is_SalWorkOrder) AS In_SalWorkOrder,
       SUM(Is_ProInvoice)   AS In_ProInvoice
FROM (
    SELECT StockDocs.Direction,
           DocType.DocumentTypeName AS Ref_Type,
           CASE WHEN Inv.ID    IS NULL THEN 0 ELSE 1 END AS Is_SalInvoice,
           CASE WHEN Ret.ID    IS NULL THEN 0 ELSE 1 END AS Is_SalReturn,
           CASE WHEN WO.ID     IS NULL THEN 0 ELSE 1 END AS Is_SalWorkOrder,
           CASE WHEN PurInv.ID IS NULL THEN 0 ELSE 1 END AS Is_ProInvoice
    FROM (SELECT 'IN'  AS Direction, RefDocumentID AS Ref_ID, RefDocumentTypeID AS Ref_Type_ID FROM InvStockIn
          UNION ALL
          SELECT 'OUT', RefDocumentID, RefDocumentTypeID FROM InvStockOut) AS StockDocs
    LEFT JOIN GenLkpDocumentType DocType ON DocType.ID = StockDocs.Ref_Type_ID
    LEFT JOIN SalInvoice   Inv    ON Inv.ID    = StockDocs.Ref_ID
    LEFT JOIN SalReturn    Ret    ON Ret.ID    = StockDocs.Ref_ID
    LEFT JOIN SalWorkOrder WO     ON WO.ID     = StockDocs.Ref_ID
    LEFT JOIN ProInvoice   PurInv ON PurInv.ID = StockDocs.Ref_ID
) AS Checked
GROUP BY Direction, Ref_Type
ORDER BY 2, 3;

-- R3: what does DocumentID of a store transaction point to, per document type?
SELECT 'R3' AS Check_Name, DocumentTypeName AS Document_Type, COUNT(*) AS Rows_Count,
       SUM(Is_SalInvoice) AS In_SalInvoice,
       SUM(Is_SalReturn)  AS In_SalReturn,
       SUM(Is_ProInvoice) AS In_ProInvoice,
       SUM(Is_StockDoc)   AS Is_StockInOut_ID,
       SUM(Via_StockRef)  AS Via_Stock_Ref
FROM (
    SELECT DocType.DocumentTypeName,
           CASE WHEN Inv.ID    IS NULL THEN 0 ELSE 1 END AS Is_SalInvoice,
           CASE WHEN Ret.ID    IS NULL THEN 0 ELSE 1 END AS Is_SalReturn,
           CASE WHEN PurInv.ID IS NULL THEN 0 ELSE 1 END AS Is_ProInvoice,
           CASE WHEN StIn.ID IS NULL AND StOut.ID IS NULL THEN 0 ELSE 1 END AS Is_StockDoc,
           CASE WHEN EXISTS (SELECT 1 FROM InvStockIn  S WHERE S.RefDocumentID = Trx.DocumentID)
                  OR EXISTS (SELECT 1 FROM InvStockOut S WHERE S.RefDocumentID = Trx.DocumentID)
                THEN 1 ELSE 0 END AS Via_StockRef
    FROM   InvStoreTransaction Trx
    JOIN   GenLkpDocumentType DocType ON DocType.ID = Trx.DocumentTypeID
    LEFT JOIN SalInvoice  Inv    ON Inv.ID    = Trx.DocumentID
    LEFT JOIN SalReturn   Ret    ON Ret.ID    = Trx.DocumentID
    LEFT JOIN ProInvoice  PurInv ON PurInv.ID = Trx.DocumentID
    LEFT JOIN InvStockIn  StIn   ON StIn.ID   = Trx.DocumentID
    LEFT JOIN InvStockOut StOut  ON StOut.ID  = Trx.DocumentID
) AS Checked
GROUP BY DocumentTypeName
ORDER BY 2;

-- R4: how many invoice receipts are linked to at least one invoice?
SELECT 'R4' AS Check_Name, COUNT(*) AS Total_Receipts, SUM(Has_Invoice) AS Receipts_With_Invoice
FROM (
    SELECT CASE WHEN EXISTS (SELECT 1 FROM SalInvoiceReceiptInvoice ReceiptInv
                             WHERE ReceiptInv.InvoiceReceiptID = Receipt.ID)
                THEN 1 ELSE 0 END AS Has_Invoice
    FROM   SalInvoiceReceipt Receipt
) AS Checked;

-- =====================================================================
-- Section E: Close Day 20/11, Cash Deposit and Open Day 21/11   |   2026-11-21   |   Build 1.2.498
-- =====================================================================

-- Test case: TC-075 Exclude cash deposits from Expected Cash Balance
-- Purpose  : Q1: opening cash of 21/11, close of 20/11 and the linked cash deposit.
-- Expected : Deposit linked to the closed day; opening cash 100.
-- Status   : Executed
SELECT WorkDay.OpenDate               AS Opened_At,
       WorkDay.CloseDate              AS Closed_At,
       WorkDay.IsClosed               AS Is_Closed,
       WorkDay.OpenBalanceCashAmount  AS Opening_Cash,
       WorkDay.OpenActualCashAmount   AS Opening_Cash_Counted,
       WorkDay.CloseSystemCashAmount  AS Closing_Cash_System,
       WorkDay.CloseDepositCashAmount AS Closing_Deposit,
       WorkDay.CloseLeftCashAmount    AS Closing_Left_In_Drawer,
       Deposit.BankDepositNumber      AS Deposit_No,
       Deposit.DocumentStatusID       AS Deposit_Status,
       DayLink.DepositAmount          AS Linked_Deposit_Amount
FROM   SalWorkingDay WorkDay
LEFT JOIN SalBankDepositWorkingDay DayLink ON DayLink.WorkingDayID = WorkDay.ID
LEFT JOIN SalBankDeposit           Deposit ON Deposit.ID = DayLink.BankDepositID
WHERE  WorkDay.OpenDate >= '20261120 15:00'
ORDER BY WorkDay.OpenDate;

-- Test case: TC-071 Count a pending Work Order carried over from a previous business day
--            TC-067 Show negative sales growth and a full drop to zero
-- Purpose  : Q2: WO-182 carried to the next day and its invoice INV-137.
-- Expected : WO moved to the 21/11 working day.
-- Status   : Executed
SELECT WO.WorkOrderNumber      AS WO_No,
       WO.WorkOrderDate        AS WO_Date,
       WO.DocumentStatusID     AS WO_Status_ID,
       WO.IsShiftedEOD         AS Carried_At_Close_Day,
       WO.WorkOrderTotalAmount AS WO_Amount,
       WorkDay.OpenDate        AS Working_Day_Opened,
       FromDay.OpenDate        AS Carried_From_Day_Opened,
       Inv.InvoiceNumber       AS Invoice_No,
       Inv.InvoiceDate         AS Invoice_Date,
       Inv.InvoiceTotalAmount  AS Invoice_Amount
FROM   SalWorkOrder WO
JOIN   SalWorkingDay WorkDay ON WorkDay.ID = WO.WorkingDayID
LEFT JOIN SalWorkingDay FromDay ON FromDay.ID = WO.ShiftedFromWorkingDayID
LEFT JOIN SalInvoice Inv ON Inv.InvoiceNumber LIKE '%11000137'
WHERE  WO.WorkOrderNumber LIKE '%11000182';

-- Test case: TC-067 Show negative sales growth and a full drop to zero
-- Purpose  : Q3: net sales 20/11 versus 21/11 for the growth percentage.
-- Expected : (100 - 2,270) / 2,270 = -95.6%, as on the Overview.
-- Status   : Verified
SELECT CAST(Inv.InvoiceDate AS date) AS Sales_Day,
       COUNT(*)                      AS Invoices_Count,
       SUM(Inv.InvoiceTotalAmount)   AS Invoiced_Amount,
       -- confirmed returns made on the same day
       (SELECT ISNULL(SUM(Ret.ReturnTotalAmount), 0)
        FROM   SalReturn Ret
        WHERE  CAST(Ret.ReturnDate AS date) = CAST(Inv.InvoiceDate AS date)
          AND  Ret.DocumentStatusID = 2) AS Returned_Amount
FROM   SalInvoice Inv
WHERE  Inv.DocumentStatusID = 2               -- confirmed
  AND  Inv.InvoiceDate >= '2026-11-20'
  AND  Inv.InvoiceDate <  '2026-11-22'
GROUP BY CAST(Inv.InvoiceDate AS date);

-- =====================================================================
-- Section F: Sales custom date range   |   2026-11-21   |   Build 1.2.498 (Run 75)
-- =====================================================================

-- Test case: TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Q4: confirmed invoices and returns per day 16/11 to 21/11, with first and last document time (all branches).
-- Expected : Shows which documents sit near the day boundaries.
-- Status   : Executed
SELECT CAST(DocDate AS date)                  AS Doc_Day,
       DocType                                AS Document_Type,
       COUNT(*)                               AS Documents_Count,
       SUM(Amount)                            AS Amount,
       CONVERT(varchar(8), MIN(DocDate), 108) AS First_Time,
       CONVERT(varchar(8), MAX(DocDate), 108) AS Last_Time
FROM (
    SELECT InvoiceDate AS DocDate, 'Invoice' AS DocType, InvoiceTotalAmount AS Amount
    FROM   SalInvoice
    WHERE  DocumentStatusID = 2
    UNION ALL
    SELECT ReturnDate, 'Return', -ReturnTotalAmount
    FROM   SalReturn
    WHERE  DocumentStatusID = 2
) AS AllDocs
WHERE  DocDate >= '2026-11-16'
  AND  DocDate <  '2026-11-22'
GROUP BY CAST(DocDate AS date), DocType
ORDER BY Doc_Day, Document_Type;

-- Test case: TC-041 Refresh date range when changing period or manually editing dates
--            TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Q5: every document of branch Alshellah 17/11 to 20/11 with its exact time.
-- Expected : INV-121 17/11 22:48:48, INV-122 18/11 08:51:57, INV-129 20/11 15:38:22.
-- Status   : Verified (Run 75)
SELECT CAST(DocDate AS date)             AS Doc_Day,
       DocType                           AS Document_Type,
       DocNumber                         AS Document_No,
       CONVERT(varchar(8), DocDate, 108) AS Doc_Time,
       Amount
FROM (
    SELECT InvoiceDate AS DocDate, 'Invoice' AS DocType, InvoiceNumber AS DocNumber, InvoiceTotalAmount AS Amount
    FROM   SalInvoice
    WHERE  DocumentStatusID = 2
      AND  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'   -- branch Alshellah
    UNION ALL
    SELECT ReturnDate, 'Return', ReturnNumber, -ReturnTotalAmount
    FROM   SalReturn
    WHERE  DocumentStatusID = 2
      AND  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
) AS AllDocs
WHERE  DocDate >= '2026-11-17'
  AND  DocDate <  '2026-11-21'
ORDER BY DocDate;

-- Test case: TC-041 Refresh date range when changing period or manually editing dates
--            TC-078 Include documents on the boundary dates of a custom range
-- Purpose  : Q6: totals of the custom range 18/11 to 19/11 for branch Alshellah.
-- Expected : 7 invoices, 2 refunds, 1,507.59, as on the Sales tab.
-- Status   : Verified (Run 75)
-- Step 1: all invoices and returns of the branch in one list (returns as minus)
-- Step 2: count and add them up for 18/11 to 19/11
SELECT SUM(CASE WHEN DocType = 'Invoice' THEN 1 ELSE 0 END)      AS Invoices_Count,
       SUM(CASE WHEN DocType = 'Return'  THEN 1 ELSE 0 END)      AS Refunds_Count,
       SUM(Amount)                                               AS Total_Sales,
       SUM(CASE WHEN DocType = 'Return' THEN -Amount ELSE 0 END) AS Refunds_Amount
FROM (
    -- Confirmed invoices
    SELECT InvoiceDate AS DocDate, 'Invoice' AS DocType, InvoiceTotalAmount AS Amount
    FROM   SalInvoice
    WHERE  DocumentStatusID = 2
      AND  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'   -- branch Alshellah
    UNION ALL
    -- Confirmed returns, as negative amounts
    SELECT ReturnDate, 'Return', -ReturnTotalAmount
    FROM   SalReturn
    WHERE  DocumentStatusID = 2
      AND  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
) AS AllDocs
WHERE  DocDate >= '2026-11-18'    -- From 18/11
  AND  DocDate <  '2026-11-20';   -- To 19/11 (up to the end of the day)

-- =====================================================================
-- Section G: Zero-sales checks in Demo Company   |   2026-11-21   |   Build 1.2.498
-- =====================================================================

-- Test case: none (supporting check)
-- Purpose  : G1: find the table and column that hold the company name, to identify the Demo Company database.
-- Expected : One company table with a name column.
-- Status   : Executed (GenCompany.CompanyName)
SELECT TABLE_NAME  AS Table_Name,
       COLUMN_NAME AS Column_Name
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  COLUMN_NAME LIKE '%Company%Name%'
ORDER BY TABLE_NAME;

-- Test case: TC-010 Show zero growth when both days have zero sales
--            TC-033 Handle zero net sales in Gross Margin
-- Purpose  : G2: find the Demo Company database and count its invoices and returns for yesterday (20/11) and today (21/11).
-- Expected : Demo Company has 0 invoices and 0 returns on both days.
-- Status   : Executed. Result: no readable database has CompanyName = Demo Company (11 databases listed); MacOne_165d415d66034069b7b0171a6c242a6e is not readable by ReadUser. DB check for Demo Company is blocked.
-- Builds one SELECT per MacOne database that has GenCompany and SalInvoice, then runs them all together.
DECLARE @Sql nvarchar(max) = N'';
SELECT @Sql = @Sql + CASE WHEN @Sql = N'' THEN N'' ELSE N' UNION ALL ' END
     + N'SELECT ''' + name + N''' AS Database_Name,
              (SELECT TOP 1 CompanyName FROM ' + QUOTENAME(name) + N'.dbo.GenCompany) AS Company_Name,
              (SELECT COUNT(*) FROM ' + QUOTENAME(name) + N'.dbo.SalInvoice WHERE InvoiceDate >= ''2026-11-20'' AND InvoiceDate < ''2026-11-21'') AS Invoices_Yesterday,
              (SELECT COUNT(*) FROM ' + QUOTENAME(name) + N'.dbo.SalInvoice WHERE InvoiceDate >= ''2026-11-21'') AS Invoices_Today,
              (SELECT COUNT(*) FROM ' + QUOTENAME(name) + N'.dbo.SalReturn  WHERE ReturnDate  >= ''2026-11-20'') AS Returns_Yesterday_And_Today,
              (SELECT COUNT(*) FROM ' + QUOTENAME(name) + N'.dbo.SalInvoice) AS Invoices_All_Time'
FROM   sys.databases
WHERE  name LIKE 'MacOne[_]%'
  AND  HAS_DBACCESS(name) = 1                                                -- only databases this user can read
  AND  OBJECT_ID(QUOTENAME(name) + '.dbo.GenCompany') IS NOT NULL
  AND  OBJECT_ID(QUOTENAME(name) + '.dbo.SalInvoice') IS NOT NULL;
EXEC sp_executesql @Sql;

-- Test case: TC-010 Show zero growth when both days have zero sales
--            TC-033 Handle zero net sales in Gross Margin
-- Purpose  : G3: Demo Company database (given by the user): company name, invoices and returns yesterday (20/11) and today (21/11).
-- Expected : Company Demo Company; 0 invoices and 0 returns on both days, so growth 0% and Gross Margin 0%.
-- Status   : Executed 21/11 17:03: Msg 916, ReadUser cannot access this database. Executed 22/11 13:11: Msg 229, SELECT denied on SalReturn. Verified 22/11 13:35 (Run 77): Demo Company, all counts 0.
SELECT (SELECT TOP 1 CompanyName FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenCompany)                AS Company_Name,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice
        WHERE  InvoiceDate >= '2026-11-20' AND InvoiceDate < '2026-11-21')                                    AS Invoices_Yesterday,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice
        WHERE  InvoiceDate >= '2026-11-21')                                                                   AS Invoices_Today,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalReturn
        WHERE  ReturnDate >= '2026-11-20')                                                                    AS Returns_Yesterday_And_Today,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice)                          AS Invoices_All_Time;

-- Test case: TC-010, TC-033 (access check)
-- Purpose  : G4: show which Demo Company tables needed for the zero-sales checks ReadUser can read.
-- Expected : Can_Select = 1 for every table.
-- Status   : Executed 22/11 13:12: Can_Select = 0 on all 11 tables. Verified 22/11 13:34: Can_Select = 1 on all 11 after access was given.
SELECT Needed.Table_Name,
       HAS_PERMS_BY_NAME('MacOne_165d415d66034069b7b0171a6c242a6e.dbo.' + Needed.Table_Name,
                         'OBJECT',
                         'SELECT') AS Can_Select
FROM  (VALUES ('GenCompany'),
              ('SalInvoice'),
              ('SalInvoiceItem'),
              ('SalInvoiceItemCost'),
              ('SalInvoiceReceiptPayment'),
              ('SalReturn'),
              ('SalReturnItem'),
              ('SalReturnItemCost'),
              ('SalReturnReceiptPayment'),
              ('SalWorkOrder'),
              ('SalWorkingDay')) AS Needed (Table_Name);

-- Test case: TC-009, TC-082 (preparation)
-- Purpose  : G5: row counts of the Demo Company setup tables needed to make one sale.
-- Expected : Rows exist for branch, terminal, payment method, item, price list and customer.
-- Status   : Executed 22/11: branch, terminal, customer and price list exist; 0 items, price list items, stores, payment methods, document numbers and working days. A sale is not possible yet.
SELECT Tbl.name        AS Table_Name,
       SUM(Part.rows)  AS Row_Count
FROM   MacOne_165d415d66034069b7b0171a6c242a6e.sys.tables     AS Tbl
JOIN   MacOne_165d415d66034069b7b0171a6c242a6e.sys.partitions AS Part
       ON Part.object_id = Tbl.object_id
WHERE  Part.index_id IN (0, 1)                                                -- table rows only, not its indexes
  AND (   Tbl.name LIKE '%Branch%'
       OR Tbl.name LIKE '%Terminal%'
       OR Tbl.name LIKE '%PaymentMethod%'
       OR Tbl.name LIKE '%PriceList%'
       OR Tbl.name LIKE '%Bay%'
       OR Tbl.name IN ('InvItem', 'InvStore', 'SalCustomer', 'SalWorkingDay', 'SalWorkOrder', 'SalInvoice'))
GROUP BY Tbl.name
ORDER BY Row_Count DESC,
         Table_Name;

-- Test case: TC-082 Show a refunds-only period with zero gross sales
-- Purpose  : G6: days in QA - Company (all branches) that have returns and no invoices.
-- Expected : At least one day, to apply as From = To on the Sales tab.
-- Status   : Executed 22/11: 0 rows, no refunds-only day exists in any branch.
SELECT Ret.BranchID,
       CAST(Ret.ReturnDate AS date) AS Refunds_Only_Day,
       COUNT(*)                     AS Refunds_Count,
       SUM(Ret.ReturnTotalAmount)   AS Refunds_Amount
FROM   SalReturn AS Ret
WHERE  Ret.DocumentStatusID = 2                                               -- 2 = Submitted
  AND  NOT EXISTS (SELECT 1
                   FROM   SalInvoice AS Inv
                   WHERE  Inv.DocumentStatusID = 2
                     AND  Inv.BranchID = Ret.BranchID
                     AND  CAST(Inv.InvoiceDate AS date) = CAST(Ret.ReturnDate AS date))
GROUP BY Ret.BranchID,
         CAST(Ret.ReturnDate AS date)
ORDER BY Refunds_Only_Day DESC;

-- Test case: TC-009 Show New Sales when yesterday is zero and today is positive
-- Purpose  : G7: for each QA - Company branch, sales yesterday (21/11) and today (22/11), and what it has to make a sale.
-- Expected : A branch with 0 documents yesterday and payment methods and terminals set up.
-- Status   : Executed 22/11: branch 35B06942 has 0 documents yesterday and 2 invoices today.
SELECT Branch.ID AS Branch_ID,
       (SELECT COUNT(*) FROM SalInvoice
        WHERE  BranchID = Branch.ID AND DocumentStatusID = 2
          AND  InvoiceDate >= '2026-11-21' AND InvoiceDate < '2026-11-22') AS Invoices_Yesterday,
       (SELECT COUNT(*) FROM SalReturn
        WHERE  BranchID = Branch.ID AND DocumentStatusID = 2
          AND  ReturnDate >= '2026-11-21' AND ReturnDate < '2026-11-22')   AS Returns_Yesterday,
       (SELECT COUNT(*) FROM SalInvoice
        WHERE  BranchID = Branch.ID AND DocumentStatusID = 2
          AND  InvoiceDate >= '2026-11-22')                                AS Invoices_Today,
       (SELECT COUNT(*) FROM SalReturn
        WHERE  BranchID = Branch.ID AND DocumentStatusID = 2
          AND  ReturnDate >= '2026-11-22')                                 AS Returns_Today,
       (SELECT COUNT(*) FROM GenBranchPaymentMethod
        WHERE  BranchID = Branch.ID)                                       AS Payment_Methods,
       (SELECT COUNT(*) FROM GenTerminal
        WHERE  BranchID = Branch.ID)                                       AS Terminals
FROM   GenBranch AS Branch;

-- Test case: TC-009 Show New Sales when yesterday is zero and today is positive
-- Purpose  : G8: the candidate branch, its terminal, and today's invoices with the terminal and user that made them.
-- Expected : Positive sales today, all in branch 35B06942.
-- Status   : Executed 22/11: 2 invoices today, 25.00 + 25.00 = 50.00, made on terminal TO_12 (device R-ABUDELLEH).
SELECT *
FROM   GenBranch
WHERE  ID = '35B06942-427B-4226-8AC3-A255B9174385';

SELECT *
FROM   GenTerminal
WHERE  BranchID = '35B06942-427B-4226-8AC3-A255B9174385';

SELECT InvoiceNumber      AS Invoice_Number,
       InvoiceDate        AS Invoice_Date,
       InvoiceTotalAmount AS Total_Incl_VAT,
       TerminalID         AS Terminal_ID,
       SystemUserID       AS User_ID
FROM   SalInvoice
WHERE  BranchID = '35B06942-427B-4226-8AC3-A255B9174385'
  AND  DocumentStatusID = 2                                                   -- 2 = Submitted
  AND  InvoiceDate >= '2026-11-22';

-- Test case: TC-006 Include confirmed sales regardless of payment method or collection
-- Purpose  : G9: find the columns that hold a credit limit in QA - Company.
-- Expected : The table and column of the customer credit limit.
-- Status   : Executed 22/11: SalCustomer.IsCustomerCredit, SalCustomer.CustomerCreditLimitValue and SalCustomerContract limits.
SELECT TABLE_NAME  AS Table_Name,
       COLUMN_NAME AS Column_Name
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  COLUMN_NAME LIKE '%Credit%'
ORDER BY TABLE_NAME;

-- Test case: TC-006 Include confirmed sales regardless of payment method or collection
-- Purpose  : G10: customers and contracts in QA - Company that could buy on credit.
-- Expected : At least one customer with credit allowed and a limit above 0.
-- Status   : Executed 22/11: one credit customer (8AF26251) with limit 3.00, no contract with a limit. Too low for TC-006 (200 JOD credit invoice).
SELECT ID,
       DocumentStatusID,
       IsCustomerCredit         AS Is_Credit,
       CustomerCreditLimitValue AS Credit_Limit,
       *
FROM   SalCustomer
WHERE  IsCustomerCredit = 1
   OR  CustomerCreditLimitValue > 0;

SELECT *
FROM   SalCustomerContract
WHERE  CustomerContractCreditLimitValue > 0;


-- Test case: TC-045, 047, 073, 083, 085 (zero-data check); TC-009 (preparation)
-- Purpose  : G11: confirm that this database is the company open in MAC1 and that it has no transactions.
-- Expected : Company 91105c94, Branch efd545c0, Terminal b966ddaa, items as in MAC1, 0 transactions.
-- Status   : Verified 22/11 16:41: IDs match MAC1, 20 items, 0 invoices, returns, work orders, payments and working days. Verified against the screens (Run 78).
SELECT GETDATE()                                                  AS Server_Time,
       (SELECT TOP 1 ID          FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenCompany)  AS Company_ID,
       (SELECT TOP 1 CompanyName FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenCompany)  AS Company_Name,
       (SELECT TOP 1 ID          FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenBranch)   AS Branch_ID,
       (SELECT TOP 1 ID          FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenTerminal) AS Terminal_ID,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvItem)              AS Items,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice)           AS Invoices,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalReturn)            AS Returns,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalWorkOrder)         AS Work_Orders,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoiceReceiptPayment) AS Payments,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalReturnReceiptPayment)  AS Refund_Payments,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalWorkingDay)        AS Working_Days;

-- Test case: TC-009 New Sales; TC-032 Gross Margin; stock chain of the sale
-- Purpose  : G12: yesterday and today sales, payment, and Stock Out to store transaction chain in Demo Company.
-- Expected : Yesterday 0. Today one invoice 5.00 paid in Cash. One Stock Out with one line, linked, quantity -1.
-- Status   : Verified 22/11 20:29 (Run 79): yesterday 0, invoice 5.00, Cash 5.00, Stock Out 1 line, store qty -1, cost 10.00.
SELECT (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice WHERE InvoiceDate >= '2026-11-21' AND InvoiceDate < '2026-11-22') AS Inv_21,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalReturn) AS Returns_All,
       I.InvoiceNumber, I.InvoiceDate, I.InvoiceTotalAmount AS Total, I.InvoiceBeforeTaxAmount AS Net, I.InvoiceTaxAmount AS VAT,
       (SELECT SUM(P.PaymentAmount) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoiceReceiptPayment P JOIN MacOne_165d415d66034069b7b0171a6c242a6e.dbo.GenLkpPaymentMethod M ON M.ID = P.PaymentMethodID WHERE M.PaymentMethodName = 'Cash') AS Cash_Paid,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvStockOut O WHERE O.RefDocumentID = I.ID OR O.RefDocumentID IN (SELECT ID FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalWorkOrder)) AS StockOut,
       (SELECT COUNT(*) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvStockOutItem L JOIN MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvStockOut O ON O.ID = L.StockOutID WHERE O.RefDocumentID = I.ID OR O.RefDocumentID IN (SELECT ID FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalWorkOrder)) AS StockOut_Lines,
       (SELECT SUM(T.BaseItemQuantity) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvStoreTransaction T WHERE T.DocumentID = I.ID) AS Store_Qty,
       (SELECT SUM(T.BaseItemQuantity * T.ItemCost) FROM MacOne_165d415d66034069b7b0171a6c242a6e.dbo.InvStoreTransaction T WHERE T.DocumentID = I.ID) AS Store_Cost
FROM   MacOne_165d415d66034069b7b0171a6c242a6e.dbo.SalInvoice I;

-- =====================================================================
-- Section H: Run 80, full execution from scratch   |   2026-11-22   |   Build 1.2.498
-- QA - Company, branch Alshellah. Every query names its database.
-- =====================================================================

-- Test case: TC-005, 008, 013, 034, 037, 038, 039, 042, 043, 045, 077
-- Purpose  : H1: invoices and returns of each period shown on the screens, up to the capture time (22/11 21:04).
-- Expected : Sales = invoices minus returns. Same totals, net, VAT and counts as Overview and Sales.
-- Status   : Verified 22/11 (Run 80): all six periods match the screens.
SELECT Period.Period_Name,
       Inv.Inv_Count,
       Ret.Ret_Count,
       Inv.Total - Ret.Total     AS Sales_Incl_VAT,
       Inv.Net   - Ret.Net       AS Sales_Excl_VAT,
       Inv.VAT   - Ret.VAT       AS Output_VAT,
       Inv.Discount,
       Inv.Total                 AS Invoices_Total,
       Ret.Total                 AS Returns_Total
FROM  (VALUES (1, 'Daily 22/11',     '2026-11-22', '2026-11-22 21:04:30'),
              (2, 'Yesterday 21/11', '2026-11-21', '2026-11-22'),
              (3, 'Custom 18/11',    '2026-11-18', '2026-11-19'),
              (4, 'MTD from 01/11',  '2026-11-01', '2026-11-22 21:04:30'),
              (5, 'QTD from 01/10',  '2026-10-01', '2026-11-22 21:04:30'),
              (6, 'YTD from 01/01',  '2026-01-01', '2026-11-22 21:04:30')) AS Period (Sort_No, Period_Name, From_Date, Before_Date)
CROSS APPLY (SELECT COUNT(*)                                AS Inv_Count,
                    ISNULL(SUM(InvoiceTotalAmount), 0)      AS Total,
                    ISNULL(SUM(InvoiceBeforeTaxAmount), 0)  AS Net,
                    ISNULL(SUM(InvoiceTaxAmount), 0)        AS VAT,
                    ISNULL(SUM(InvoiceDiscountAmount), 0)   AS Discount
             FROM   SalInvoice
             WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
               AND  InvoiceDate >= Period.From_Date
               AND  InvoiceDate <  Period.Before_Date) AS Inv
CROSS APPLY (SELECT COUNT(*)                                AS Ret_Count,
                    ISNULL(SUM(ReturnTotalAmount), 0)       AS Total,
                    ISNULL(SUM(ReturnBeforeTaxAmount), 0)   AS Net,
                    ISNULL(SUM(ReturnTaxAmount), 0)         AS VAT
             FROM   SalReturn
             WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
               AND  ReturnDate >= Period.From_Date
               AND  ReturnDate <  Period.Before_Date) AS Ret
ORDER BY Period.Sort_No;

-- Test case: TC-017, 021, 023, 053, 054, 058, 061, 071
-- Purpose  : H2: today's Work Orders, payments per method, refunds and the open working day (screens of 22/11 21:14).
-- Expected : Same WO counts and customers, same amount per method, same opening date and cash as the screens.
-- Status   : Verified 22/11 21:17 (Run 80): all nine rows match the screens.
SELECT '1 Work Orders' AS Check_Name, Status.DocumentStatusName AS Detail,
       COUNT(*) AS Row_Count, NULL AS Amount, NULL AS Date_Time
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderDate >= '2026-11-22' AND WO.WorkOrderDate < '2026-11-22 21:15:00'
GROUP BY Status.DocumentStatusName
UNION ALL
SELECT '2 Customers served', 'Distinct customers', COUNT(DISTINCT CustomerID), NULL, NULL
FROM   SalWorkOrder
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderDate >= '2026-11-22' AND WorkOrderDate < '2026-11-22 21:15:00'
UNION ALL
SELECT '3 Received', Method.PaymentMethodName, COUNT(*), SUM(Payment.PaymentAmount), NULL
FROM   SalInvoiceReceiptPayment AS Payment
JOIN   SalInvoiceReceipt AS Receipt ON Receipt.ID = Payment.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Payment.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.InvoiceReceiptDate >= '2026-11-22' AND Receipt.InvoiceReceiptDate < '2026-11-22 21:15:00'
GROUP BY Method.PaymentMethodName
UNION ALL
SELECT '4 Refunded', 'All methods', COUNT(*), ISNULL(SUM(Payment.PaymentAmount), 0), NULL
FROM   SalReturnReceiptPayment AS Payment
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Payment.ReturnReceiptID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-22' AND Receipt.ReturnReceiptDate < '2026-11-22 21:15:00'
UNION ALL
SELECT '5 Open working day', 'Opening cash', 1, OpenBalanceCashAmount, OpenDate
FROM   SalWorkingDay
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND OpenDate >= '2026-11-22'
ORDER BY Check_Name, Detail;

-- Test case: TC-059, 086 (Cash tab QTD against Sales QTD)
-- Purpose  : H3: per month, invoices total against the money received and refunded.
-- Expected : Cash QTD 96,439.12 received equals the receipts. Shows where Sales QTD (103,964.34) differs from receipts.
-- Status   : Verified 22/11 21:20 (Run 80): Cash tab equals receipts. October invoices exceed receipts by 7,525.22 (question logged).
SELECT Period.Month_Name,
       (SELECT SUM(InvoiceTotalAmount)
        FROM   SalInvoice
        WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
          AND  InvoiceDate >= Period.From_Date AND InvoiceDate < Period.Before_Date) AS Invoices_Total,
       (SELECT SUM(Payment.PaymentAmount)
        FROM   SalInvoiceReceiptPayment AS Payment
        JOIN   SalInvoiceReceipt AS Receipt ON Receipt.ID = Payment.InvoiceReceiptID
        WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
          AND  Receipt.InvoiceReceiptDate >= Period.From_Date AND Receipt.InvoiceReceiptDate < Period.Before_Date) AS Received,
       (SELECT SUM(Payment.PaymentAmount)
        FROM   SalReturnReceiptPayment AS Payment
        JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Payment.ReturnReceiptID
        WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
          AND  Receipt.ReturnReceiptDate >= Period.From_Date AND Receipt.ReturnReceiptDate < Period.Before_Date) AS Refunded
FROM  (VALUES ('October',        '2026-10-01', '2026-11-01'),
              ('November to 22', '2026-11-01', '2026-11-22 21:19:00'),
              ('QTD',            '2026-10-01', '2026-11-22 21:19:00')) AS Period (Month_Name, From_Date, Before_Date);

-- Test case: TC-026, 031, 032, 045, 047, 055, 083
-- Purpose  : H4: Work Orders of 18/11, documents of the empty day 25/11, items sold today and cost of goods sold today.
-- Expected : Same WO counts as the screen, 0 documents on 25/11, same items as Top Selling, Gross Profit = 1,010.87 - COGS.
-- Status   : Verified 22/11 (18/11: 2 and 4, 25/11: 0, same 4 items, COGS 143.00).
SELECT '1 WO 18/11' AS Check_Name, Status.DocumentStatusName AS Detail, CAST(COUNT(*) AS decimal(18, 2)) AS Quantity, NULL AS Amount
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderDate >= '2026-11-18' AND WO.WorkOrderDate < '2026-11-19'
GROUP BY Status.DocumentStatusName
UNION ALL
SELECT '2 Empty 25/11', 'Invoices', COUNT(*), SUM(InvoiceTotalAmount)
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-25' AND InvoiceDate < '2026-11-26'
UNION ALL
SELECT '2 Empty 25/11', 'Returns', COUNT(*), SUM(ReturnTotalAmount)
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-25' AND ReturnDate < '2026-11-26'
UNION ALL
SELECT '2 Empty 25/11', 'Work Orders', COUNT(*), NULL
FROM   SalWorkOrder
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderDate >= '2026-11-25' AND WorkOrderDate < '2026-11-26'
UNION ALL
SELECT '3 Sold today', Item.ItemName, SUM(Line.ItemQuantity), SUM(Line.ItemTotalAmount)
FROM   SalInvoiceItem AS Line
JOIN   SalInvoice AS Inv ON Inv.ID = Line.InvoiceID
JOIN   InvItem AS Item ON Item.ID = Line.ItemID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceDate >= '2026-11-22' AND Inv.InvoiceDate < '2026-11-22 21:30:00'
GROUP BY Item.ItemName
UNION ALL
SELECT '4 COGS today', 'Store quantity x cost', SUM(Trx.BaseItemQuantity), SUM(Trx.BaseItemQuantity * Trx.ItemCost)
FROM   InvStoreTransaction AS Trx
JOIN   SalInvoice AS Inv ON Inv.ID = Trx.DocumentID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceDate >= '2026-11-22' AND Inv.InvoiceDate < '2026-11-22 21:30:00'
ORDER BY Check_Name, Amount DESC;

-- Test case: TC-021, 029, 038, 087 (schema check before the Run 80 queries)
-- Purpose  : H5: metadata of the working day, financial year, stock adjustment and item tables, with the foreign keys of SalWorkingDay.
-- Expected : Column names and linked tables for the next queries (no assumed names).
-- Status   : Executed 22/11 (24 rows, long column lists cut in the grid, see H6).
SELECT TABLE_NAME AS Table_Name, STRING_AGG(CAST(COLUMN_NAME AS nvarchar(max)), ', ') AS Columns
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME IN ('SalWorkingDay', 'InvItem')
   OR  TABLE_NAME LIKE '%Fiscal%' OR TABLE_NAME LIKE '%Financial%' OR TABLE_NAME LIKE 'Inv%Adjust%'
GROUP BY TABLE_NAME
UNION ALL
SELECT 'FK SalWorkingDay: ' + FromCol.name, ToSchema.name + '.' + ToTable.name
FROM   sys.foreign_key_columns AS Link
JOIN   sys.tables  AS FromTable ON FromTable.object_id = Link.parent_object_id AND FromTable.name = 'SalWorkingDay'
JOIN   sys.columns AS FromCol   ON FromCol.object_id = Link.parent_object_id AND FromCol.column_id = Link.parent_column_id
JOIN   sys.tables  AS ToTable   ON ToTable.object_id = Link.referenced_object_id
JOIN   sys.schemas AS ToSchema  ON ToSchema.schema_id = ToTable.schema_id;

-- Test case: TC-021, 038, 087 (schema check before the Run 80 queries)
-- Purpose  : H6: only the columns for day number and opener, financial year start and inactive items.
-- Expected : One row per column, with the table it references when it has a foreign key.
-- Status   : Executed 22/11 (WorkingDayNumber, OpenSystemUserID to SecSystemUser, GenCompany.CompanyFiscalMonthID, no inactive column in InvItem).
SELECT Tbl.name AS Table_Name, Col.name AS Column_Name, RefTable.name AS References_Table
FROM   sys.tables AS Tbl
JOIN   sys.columns AS Col ON Col.object_id = Tbl.object_id
LEFT JOIN sys.foreign_key_columns AS Link ON Link.parent_object_id = Col.object_id AND Link.parent_column_id = Col.column_id
LEFT JOIN sys.tables AS RefTable ON RefTable.object_id = Link.referenced_object_id
WHERE (Tbl.name = 'SalWorkingDay' AND (Col.name LIKE '%Number%' OR Col.name LIKE '%User%' OR Col.name LIKE '%By%' OR RefTable.name LIKE '%User%'))
   OR (Tbl.name = 'InvItem' AND (Col.name LIKE '%Active%' OR Col.name LIKE '%Disable%'))
   OR (Col.name LIKE '%FiscalMonth%ID' AND Tbl.name NOT LIKE '%Language')
ORDER BY Table_Name, Column_Name;

-- Test case: TC-021, 038 (schema check before the Run 80 queries)
-- Purpose  : H7: name columns of the system user and fiscal month tables.
-- Expected : The column that holds the opener name and the fiscal month name.
-- Status   : Executed 22/11 (UserName, CompanyFiscalMonthName).
SELECT TABLE_NAME AS Table_Name, COLUMN_NAME AS Column_Name, DATA_TYPE AS Data_Type
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  (TABLE_NAME = 'SecSystemUser' AND COLUMN_NAME LIKE '%Name%')
   OR   TABLE_NAME = 'GenLkpCompanyFiscalMonth'
   OR  (TABLE_NAME = 'GenCompany' AND COLUMN_NAME = 'CompanyFiscalMonthID')
ORDER BY Table_Name, Column_Name;

-- Test case: TC-021, 038, 085
-- Purpose  : H8: open day number and opener, first month of the financial year, money received and refunded on the empty day 25/11.
-- Expected : TO_11000033 opened by m.alshellah, YTD starts in that month, 0 payments and 0 refunds on 25/11.
-- Status   : Verified 22/11 for day number and 0 payments. Opener UserName is M98 (see H9), fiscal month is NULL.
SELECT '1 Open day' AS Check_Name, CAST(WorkDay.WorkingDayNumber AS nvarchar(100)) AS Detail, CAST(Opener.UserName AS nvarchar(100)) AS Value
FROM   SalWorkingDay AS WorkDay
JOIN   SecSystemUser AS Opener ON Opener.ID = WorkDay.OpenSystemUserID
WHERE  WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkDay.OpenDate >= '2026-11-22'
UNION ALL
SELECT '2 Financial year starts', CAST(Company.CompanyName AS nvarchar(100)), CAST(FirstMonth.CompanyFiscalMonthName AS nvarchar(100))
FROM   GenCompany AS Company
LEFT JOIN GenLkpCompanyFiscalMonth AS FirstMonth ON FirstMonth.ID = Company.CompanyFiscalMonthID
UNION ALL
SELECT '3 Empty 25/11', 'Receipts', CAST(COUNT(*) AS nvarchar(100))
FROM   SalInvoiceReceipt
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceReceiptDate >= '2026-11-25' AND InvoiceReceiptDate < '2026-11-26'
UNION ALL
SELECT '3 Empty 25/11', 'Refund receipts', CAST(COUNT(*) AS nvarchar(100))
FROM   SalReturnReceipt
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnReceiptDate >= '2026-11-25' AND ReturnReceiptDate < '2026-11-26'
ORDER BY Check_Name, Detail;

-- Test case: TC-021, 038
-- Purpose  : H9: the opener's user name and full name, and the raw fiscal month value of the company.
-- Expected : One of the opener names is the one on the Cash Register card; the fiscal month shows whether a start is configured.
-- Status   : Verified 22/11 (FullName m.alshellah matches the card). Fiscal month is NULL, business question logged.
SELECT WorkDay.WorkingDayNumber AS Day_No, Opener.UserName AS User_Name, Opener.FullName AS Full_Name,
       (SELECT TOP 1 CompanyFiscalMonthID FROM GenCompany) AS Fiscal_Month_ID
FROM   SalWorkingDay AS WorkDay
JOIN   SecSystemUser AS Opener ON Opener.ID = WorkDay.OpenSystemUserID
WHERE  WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkDay.OpenDate >= '2026-11-22';

-- Test case: TC-019, 020, 029, 062, 063, 064, 072
-- Purpose  : H10: inventory snapshot before the test transactions of 22/11 evening: distinct items and item-store rows per stock state, and value.
-- Expected : Screen of 21:43: All 363, In Stock 353, Low 1, Out of Stock 12, Negative 22, Stock Value 83,474.00.
-- Status   : Executed 22/11 21:4x. Matches only Low 1 and Negative 22. All 492, in stock 357, out 137, value 659,849.41: counting basis not confirmed.
WITH Balance AS (
    SELECT StoreID, ItemID, SUM(BaseItemQuantity) AS Qty, SUM(BaseItemQuantity * ItemCost) AS Stock_Value
    FROM   InvStoreTransaction
    WHERE  StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    GROUP BY StoreID, ItemID),
Pairs AS (
    SELECT StoreID, ItemID FROM Balance
    UNION
    SELECT StoreID, ItemID FROM InvStoreItem
    WHERE  StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')),
StockRows AS (
    SELECT Item.ID AS ItemID, ISNULL(Balance.Qty, 0) AS Qty, Balance.Stock_Value, Setup.ItemMinQuantity AS Min_Qty
    FROM   InvItem AS Item
    JOIN   GenLkpDocumentStatus AS Status ON Status.ID = Item.DocumentStatusID AND Status.DocumentStatusName = 'Submitted'
    LEFT JOIN Pairs   ON Pairs.ItemID = Item.ID
    LEFT JOIN Balance ON Balance.ItemID = Item.ID AND Balance.StoreID = Pairs.StoreID
    LEFT JOIN InvStoreItem AS Setup ON Setup.ItemID = Item.ID AND Setup.StoreID = Pairs.StoreID
    WHERE  Item.IsApplyToAllBranch = 1
       OR  EXISTS (SELECT 1 FROM InvItemBranch AS Link
                   WHERE Link.ItemID = Item.ID AND Link.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'))
SELECT '1 All' AS Stock_State, COUNT(DISTINCT ItemID) AS Distinct_Items, COUNT(*) AS Item_Store_Rows, SUM(Stock_Value) AS Qty_x_Cost FROM StockRows
UNION ALL
SELECT '2 In stock (qty > 0)', COUNT(DISTINCT ItemID), COUNT(*), SUM(Stock_Value) FROM StockRows WHERE Qty > 0
UNION ALL
SELECT '3 Low (0 < qty <= min)', COUNT(DISTINCT ItemID), COUNT(*), SUM(Stock_Value) FROM StockRows WHERE Qty > 0 AND Qty <= Min_Qty
UNION ALL
SELECT '4 Out of stock (qty = 0)', COUNT(DISTINCT ItemID), COUNT(*), SUM(Stock_Value) FROM StockRows WHERE Qty = 0
UNION ALL
SELECT '5 Negative (qty < 0)', COUNT(DISTINCT ItemID), COUNT(*), SUM(Stock_Value) FROM StockRows WHERE Qty < 0
ORDER BY Stock_State;

-- Test case: TC-005, 025, 027, 031, 068, 074, 079 (data T1) and stock chain
-- Purpose  : H11: invoice INV-TO_11000140 of WO-TO_11000190: totals, lines, payments, stock documents and store transactions.
-- Expected : 473.51 incl. VAT, discount, six lines, Cash 300.00 and Mada 173.51, stock out only for Sticker Item, linked to its document.
-- Status   : Verified 22/11 (473.51, six lines, 300.00 and 173.51, Stock Out TO_11000201 qty 1, cost 88.00).
WITH Src AS (
    SELECT ID, InvoiceTotalAmount FROM SalInvoice
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceNumber LIKE '%11000140'),
Docs AS (
    SELECT ID FROM Src
    UNION ALL
    SELECT ID FROM SalWorkOrder WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderNumber LIKE '%11000190')
SELECT '1 Invoice' AS Check_Name, 'Total incl. VAT' AS Detail, CAST(NULL AS decimal(18, 3)) AS Quantity, InvoiceTotalAmount AS Amount FROM Src
UNION ALL
SELECT '2 Line', Item.ItemName, Line.ItemQuantity, Line.ItemTotalAmount
FROM   SalInvoiceItem AS Line
JOIN   Src ON Src.ID = Line.InvoiceID
JOIN   InvItem AS Item ON Item.ID = Line.ItemID
UNION ALL
SELECT '3 Payment', Method.PaymentMethodName, NULL, Pay.PaymentAmount
FROM   SalInvoiceReceiptInvoice AS Link
JOIN   Src ON Src.ID = Link.InvoiceID
JOIN   SalInvoiceReceiptPayment AS Pay ON Pay.InvoiceReceiptID = Link.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
UNION ALL
SELECT '4 Stock Out ' + CAST(StockOut.StockOutNumber AS nvarchar(50)),
       'Item lines: ' + CAST((SELECT COUNT(*) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID) AS nvarchar(10)),
       (SELECT SUM(OutLine.BaseItemQuantity) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID), NULL
FROM   InvStockOut AS StockOut
JOIN   Docs ON Docs.ID = StockOut.RefDocumentID
UNION ALL
SELECT '5 Store transaction (cost)', Item.ItemName, Trx.BaseItemQuantity, Trx.BaseItemQuantity * Trx.ItemCost
FROM   InvStoreTransaction AS Trx
JOIN   Docs ON Docs.ID = Trx.DocumentID
JOIN   InvItem AS Item ON Item.ID = Trx.ItemID
ORDER BY Check_Name, Detail;

-- Test case: TC-022, 023, 046, 074, 076 (data T2) and stock chain
-- Purpose  : H12: invoice INV-TO_11000141 of WO-TO_11000191: totals, line, payment, stock document and store transaction.
-- Expected : 210.00 incl. VAT, one Sticker Item line, Mada 210.00, one Stock Out of 1 linked to its document.
-- Status   : Verified 22/11 (210.00, Mada, Stock Out TO_11000202 qty 1, cost 88.00).
WITH Src AS (
    SELECT ID, InvoiceTotalAmount FROM SalInvoice
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceNumber LIKE '%11000141'),
Docs AS (
    SELECT ID FROM Src
    UNION ALL
    SELECT ID FROM SalWorkOrder WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderNumber LIKE '%11000191')
SELECT '1 Invoice' AS Check_Name, 'Total incl. VAT' AS Detail, CAST(NULL AS decimal(18, 3)) AS Quantity, InvoiceTotalAmount AS Amount FROM Src
UNION ALL
SELECT '2 Line', Item.ItemName, Line.ItemQuantity, Line.ItemTotalAmount
FROM   SalInvoiceItem AS Line
JOIN   Src ON Src.ID = Line.InvoiceID
JOIN   InvItem AS Item ON Item.ID = Line.ItemID
UNION ALL
SELECT '3 Payment', Method.PaymentMethodName, NULL, Pay.PaymentAmount
FROM   SalInvoiceReceiptInvoice AS Link
JOIN   Src ON Src.ID = Link.InvoiceID
JOIN   SalInvoiceReceiptPayment AS Pay ON Pay.InvoiceReceiptID = Link.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
UNION ALL
SELECT '4 Stock Out ' + CAST(StockOut.StockOutNumber AS nvarchar(50)),
       'Item lines: ' + CAST((SELECT COUNT(*) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID) AS nvarchar(10)),
       (SELECT SUM(OutLine.BaseItemQuantity) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID), NULL
FROM   InvStockOut AS StockOut
JOIN   Docs ON Docs.ID = StockOut.RefDocumentID
UNION ALL
SELECT '5 Store transaction (cost)', Item.ItemName, Trx.BaseItemQuantity, Trx.BaseItemQuantity * Trx.ItemCost
FROM   InvStoreTransaction AS Trx
JOIN   Docs ON Docs.ID = Trx.DocumentID
JOIN   InvItem AS Item ON Item.ID = Trx.ItemID
ORDER BY Check_Name, Detail;

-- Test case: TC-005, 012, 016, 022, 027, 031, 034, 046, 068, 069, 074, 076, 077 (data T1 to T3) and stock chain of RTN-TO_11000020
-- Purpose  : H13: totals of 22/11 up to 21:59 after the return, money per method, the return's original invoice, stock in and COGS.
-- Expected : Sales 1,606.01, net 1,435.66, VAT 170.35, refunds 210.00 in Cash, stock +1 for INV-141, Gross Profit 1,204.66 = net - COGS.
-- Status   : Verified 22/11 (all values match, Stock In TO_11000040 qty 1, COGS 231.00).
WITH Inv AS (
    SELECT * FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-22 21:59:30'),
Ret AS (
    SELECT * FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-22 21:59:30')
SELECT '1 Invoices' AS Check_Name, 'Count, total' AS Detail, CAST(COUNT(*) AS decimal(18, 2)) AS Quantity, SUM(InvoiceTotalAmount) AS Amount FROM Inv
UNION ALL SELECT '1 Invoices', 'Discount', NULL, SUM(InvoiceDiscountAmount) FROM Inv
UNION ALL SELECT '2 Return', CAST(Ret.ReturnNumber AS nvarchar(40)) + ' of ' + CAST(Orig.InvoiceNumber AS nvarchar(40)), NULL, Ret.ReturnTotalAmount
          FROM Ret JOIN SalInvoice AS Orig ON Orig.ID = Ret.InvoiceID
UNION ALL SELECT '3 Net day', 'Sales incl. VAT', NULL, (SELECT SUM(InvoiceTotalAmount) FROM Inv) - (SELECT SUM(ReturnTotalAmount) FROM Ret)
UNION ALL SELECT '3 Net day', 'Sales excl. VAT', NULL, (SELECT SUM(InvoiceBeforeTaxAmount) FROM Inv) - (SELECT SUM(ReturnBeforeTaxAmount) FROM Ret)
UNION ALL SELECT '3 Net day', 'Output VAT', NULL, (SELECT SUM(InvoiceTaxAmount) FROM Inv) - (SELECT SUM(ReturnTaxAmount) FROM Ret)
UNION ALL SELECT '4 Received', Method.PaymentMethodName, COUNT(*), SUM(Pay.PaymentAmount)
          FROM SalInvoiceReceiptPayment AS Pay
          JOIN SalInvoiceReceipt AS Receipt ON Receipt.ID = Pay.InvoiceReceiptID
          JOIN GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
          WHERE Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.InvoiceReceiptDate >= '2026-11-22' AND Receipt.InvoiceReceiptDate < '2026-11-22 21:59:30'
          GROUP BY Method.PaymentMethodName
UNION ALL SELECT '5 Refunded', Method.PaymentMethodName, COUNT(*), SUM(Pay.PaymentAmount)
          FROM SalReturnReceiptPayment AS Pay
          JOIN SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
          JOIN GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
          WHERE Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-22' AND Receipt.ReturnReceiptDate < '2026-11-22 21:59:30'
          GROUP BY Method.PaymentMethodName
UNION ALL SELECT '6 Stock In', CAST(StockIn.StockInNumber AS nvarchar(40)),
          (SELECT SUM(InLine.BaseItemQuantity) FROM InvStockInItem AS InLine WHERE InLine.StockInID = StockIn.ID), NULL
          FROM InvStockIn AS StockIn
          WHERE StockIn.RefDocumentID IN (SELECT ID FROM Ret UNION ALL SELECT InvoiceID FROM Ret)
UNION ALL SELECT '7 INV-141 and return', 'Net store movement', SUM(Trx.BaseItemQuantity), SUM(Trx.BaseItemQuantity * Trx.ItemCost)
          FROM InvStoreTransaction AS Trx
          WHERE Trx.DocumentID IN (SELECT ID FROM Ret UNION ALL SELECT InvoiceID FROM Ret)
UNION ALL SELECT '8 COGS day', 'Store quantity x cost', SUM(Trx.BaseItemQuantity), SUM(Trx.BaseItemQuantity * Trx.ItemCost)
          FROM InvStoreTransaction AS Trx
          WHERE Trx.DocumentID IN (SELECT ID FROM Inv UNION SELECT ID FROM Ret)
ORDER BY Check_Name, Detail;

-- Test case: TC-068, 079 (data T4) and stock chain
-- Purpose  : H14: every document of 22/11 up to 22:05 with lines, quantity and methods, the day net, and stock movement of INV-TO_11000142.
-- Expected : INV-142 one line of qty 2 paid Master 200.00 with no stock movement, day net 1,806.01.
-- Status   : Verified 22/11 (INV-142: 1 line, qty 2, Master, no movement. Day net 1,806.01).
WITH Inv AS (
    SELECT ID, InvoiceNumber, InvoiceTotalAmount FROM SalInvoice
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-22 22:05:30'),
Ret AS (
    SELECT ID, ReturnNumber, ReturnTotalAmount FROM SalReturn
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-22 22:05:30')
SELECT CAST(Inv.InvoiceNumber AS nvarchar(40)) AS Document_No,
       (SELECT COUNT(*) FROM SalInvoiceItem AS Line WHERE Line.InvoiceID = Inv.ID) AS Line_Count,
       (SELECT SUM(Line.ItemQuantity) FROM SalInvoiceItem AS Line WHERE Line.InvoiceID = Inv.ID) AS Total_Qty,
       (SELECT STRING_AGG(CAST(Method.PaymentMethodName AS nvarchar(50)), ' + ')
        FROM SalInvoiceReceiptInvoice AS Link
        JOIN SalInvoiceReceiptPayment AS Pay ON Pay.InvoiceReceiptID = Link.InvoiceReceiptID
        JOIN GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
        WHERE Link.InvoiceID = Inv.ID) AS Methods,
       Inv.InvoiceTotalAmount AS Amount,
       (SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx WHERE Trx.DocumentID = Inv.ID) AS Stock_Qty
FROM   Inv
UNION ALL
SELECT CAST(Ret.ReturnNumber AS nvarchar(40)), NULL, NULL, 'Return', -Ret.ReturnTotalAmount, NULL FROM Ret
UNION ALL
SELECT 'ZZ Day net', NULL, NULL, NULL, (SELECT SUM(InvoiceTotalAmount) FROM Inv) - (SELECT SUM(ReturnTotalAmount) FROM Ret), NULL
ORDER BY Document_No;

-- Test case: TC-051, 057, 081
-- Purpose  : H15: every Work Order of 22/11 up to 22:12 with status and amount, to compare with the WO info exports.
-- Expected : Nine rows: 1 New, 5 Submitted, 3 Cancelled, same numbers and amounts as the exported files.
-- Status   : Verified 22/11 (nine rows, same as the five exported files).
SELECT WO.WorkOrderNumber AS WO_No, WO.WorkOrderDate AS WO_Date, Status.DocumentStatusName AS WO_Status, WO.WorkOrderTotalAmount AS Amount
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderDate >= '2026-11-22' AND WO.WorkOrderDate < '2026-11-22 22:12:30'
ORDER BY WO.WorkOrderNumber DESC;

-- Test case: TC-066 (and stock effect of T1 to T3)
-- Purpose  : H16: items with 'Sticker' in the name that have stock rows in the branch stores, with quantity per store.
-- Expected : The rows of the 22:13 search: Oil Change Sticker Roll 50, Sticker Item 55 and -3.
-- Status   : Verified 22/11 (same three rows and quantities).
SELECT Item.ItemName AS Item_Name, Item.ItemNumber AS Item_No, Store.StoreName AS Store_Name, SUM(Trx.BaseItemQuantity) AS Stock_Qty
FROM   InvStoreTransaction AS Trx
JOIN   InvItem AS Item ON Item.ID = Trx.ItemID
JOIN   InvStore AS Store ON Store.ID = Trx.StoreID
WHERE  Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
  AND (Item.ItemName LIKE '%Sticker%' OR Item.ItemNumber LIKE '%Sticker%')
GROUP BY Item.ItemName, Item.ItemNumber, Store.StoreName
ORDER BY Item_Name, Store_Name;

-- Test case: TC-056 (schema check)
-- Purpose  : H17: foreign keys of SalWorkOrder for customer, vehicle, bay and technician, with the name columns of those tables.
-- Expected : The tables and columns behind Customer, Plate Number, Bay Name and Tech on WO info.
-- Status   : Executed 22/11 (SalCustomer, AutVehicle, AutBay, SecSystemUser by foreign key).
SELECT FromCol.name AS WO_Column, ToTable.name AS References_Table,
       (SELECT STRING_AGG(CAST(NameCol.name AS nvarchar(max)), ', ')
        FROM sys.columns AS NameCol
        WHERE NameCol.object_id = ToTable.object_id AND (NameCol.name LIKE '%Name' OR NameCol.name LIKE '%Plate%' OR NameCol.name LIKE '%VIN%')) AS Name_Columns
FROM   sys.foreign_key_columns AS Link
JOIN   sys.tables  AS FromTable ON FromTable.object_id = Link.parent_object_id AND FromTable.name = 'SalWorkOrder'
JOIN   sys.columns AS FromCol   ON FromCol.object_id = Link.parent_object_id AND FromCol.column_id = Link.parent_column_id
JOIN   sys.tables  AS ToTable   ON ToTable.object_id = Link.referenced_object_id
WHERE  FromCol.name LIKE '%Customer%' OR FromCol.name LIKE '%Vehicle%' OR FromCol.name LIKE '%Bay%' OR FromCol.name LIKE '%User%' OR FromCol.name LIKE '%Tech%' OR FromCol.name LIKE '%Employee%'
ORDER BY WO_Column;

-- Test case: TC-056
-- Purpose  : H18: customer, plate, bay, technician, VIN, amount and status behind each WO info row of 22/11 up to 22:12.
-- Expected : Same values as the nine rows of WO info; VIN 1GNSKRKD5NR245817 only on WO-TO_11000189.
-- Status   : Verified 22/11 (nine rows, every column matches).
SELECT WO.WorkOrderNumber AS WO_No, Cust.CustomerName AS Customer, Car.VehiclePlate AS Plate, Bay.BayName AS Bay,
       Tech.FullName AS Technician, Car.VehicleVin AS VIN, WO.WorkOrderTotalAmount AS Amount, Status.DocumentStatusName AS WO_Status
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
LEFT JOIN SalCustomer   AS Cust ON Cust.ID = WO.CustomerID
LEFT JOIN AutVehicle    AS Car  ON Car.ID  = WO.VehicleID
LEFT JOIN AutBay        AS Bay  ON Bay.ID  = WO.BayID
LEFT JOIN SecSystemUser AS Tech ON Tech.ID = WO.SystemUserID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderDate >= '2026-11-22' AND WO.WorkOrderDate < '2026-11-22 22:12:30'
ORDER BY WO.WorkOrderNumber DESC;

-- Test case: TC-065
-- Purpose  : H19: name, number, store, quantity, min and max behind the Inventory rows captured at 21:43 (first rows and Low Stock row).
-- Expected : Front Brake Rotors 300 and 0 (10, 100), 97 and 200 (5, 100), Air Filter 041 96 and 4, Tire - Item Branch 2: 4 (10, 100).
-- Status   : Verified 22/11 (every compared value matches).
SELECT Item.ItemName AS Item_Name, Item.ItemNumber AS Item_No, Store.StoreName AS Store_Name,
       (SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx WHERE Trx.ItemID = Item.ID AND Trx.StoreID = Store.ID) AS Stock_Qty,
       Setup.ItemMinQuantity AS Min_Qty, Setup.ItemMaxQuantity AS Max_Qty
FROM   InvItem AS Item
CROSS JOIN InvStore AS Store
LEFT JOIN InvStoreItem AS Setup ON Setup.ItemID = Item.ID AND Setup.StoreID = Store.ID
WHERE  Item.ItemNumber IN ('45251-T2G-A00YMC', '45288851-T2G-A00YMC', 'NEW-ITEM-0041', 'TO_1000001')
  AND  Store.ID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
ORDER BY Item_Name, Store_Name;

-- Test case: TC-084 (data T5) and stock chain
-- Purpose  : H20: WO-TO_11000193 after Complete, its invoice and payment, WO counts of the day and any stock movement.
-- Expected : WO Submitted 30.00, INV-TO_11000143 30.00 Mada, counts 1 New, 6 Submitted, 3 Cancelled, no stock movement (service).
-- Status   : Verified 22/11 (all values match).
SELECT '1 Work Order' AS Check_Name, CAST(WO.WorkOrderNumber AS nvarchar(40)) + ' ' + Status.DocumentStatusName AS Detail, WO.WorkOrderTotalAmount AS Amount
FROM   SalWorkOrder AS WO JOIN GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderNumber LIKE '%11000193'
UNION ALL
SELECT '2 Invoice', CAST(Inv.InvoiceNumber AS nvarchar(40)) + ' ' + Method.PaymentMethodName, Pay.PaymentAmount
FROM   SalInvoice AS Inv
JOIN   SalInvoiceReceiptInvoice AS Link ON Link.InvoiceID = Inv.ID
JOIN   SalInvoiceReceiptPayment AS Pay ON Pay.InvoiceReceiptID = Link.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceNumber LIKE '%11000143'
UNION ALL
SELECT '3 WO count today', Status.DocumentStatusName, COUNT(*)
FROM   SalWorkOrder AS WO JOIN GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WO.WorkOrderDate >= '2026-11-22' AND WO.WorkOrderDate < '2026-11-22 22:23:30'
GROUP BY Status.DocumentStatusName
UNION ALL
SELECT '4 Store transactions', 'Rows for INV-143', COUNT(*)
FROM   InvStoreTransaction AS Trx
WHERE  Trx.DocumentID IN (SELECT Inv.ID FROM SalInvoice AS Inv WHERE Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceNumber LIKE '%11000143')
ORDER BY Check_Name, Detail;

-- Test case: TC-035, 036 (schema check)
-- Purpose  : H21: amount, date, branch and number columns of the purchase invoice and purchase return tables.
-- Expected : The columns needed to prove Input VAT.
-- Status   : Executed 22/11 (17 columns).
SELECT TABLE_NAME AS Table_Name, COLUMN_NAME AS Column_Name
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME IN ('ProInvoice', 'ProReturn')
  AND (COLUMN_NAME LIKE '%Amount%' OR COLUMN_NAME LIKE '%Date' OR COLUMN_NAME LIKE '%Number' OR COLUMN_NAME = 'BranchID')
ORDER BY Table_Name, Column_Name;

-- Test case: TC-035, 036 (data T6) and stock chain
-- Purpose  : H22: purchase PR-TO_11000004, Input and Output VAT of 22/11 up to 22:27, purchase returns, stock in of the purchase.
-- Expected : Purchase tax 30.00, 0 purchase returns, Output 200.35, so Net VAT Payable 170.35. Stock in 2 linked to the purchase.
-- Status   : Verified 22/11 (30.00, 200.35, Stock In TO_11000041: 4 base units = 2 Each x packing 2, see H23).
WITH Pur AS (
    SELECT ID, InvoiceNumber, InvoiceTotalAmount, InvoiceTaxAmount FROM ProInvoice
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-22 22:27:30')
SELECT '1 Purchase' AS Check_Name, CAST(InvoiceNumber AS nvarchar(40)) AS Detail, CAST(NULL AS decimal(18, 3)) AS Quantity, InvoiceTotalAmount AS Amount FROM Pur
UNION ALL SELECT '2 Input VAT', 'Purchase tax', NULL, SUM(InvoiceTaxAmount) FROM Pur
UNION ALL SELECT '2 Input VAT', 'Purchase returns (count)', COUNT(*), NULL FROM ProReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-22 22:27:30'
UNION ALL SELECT '3 Output VAT', 'Invoices minus returns', NULL,
          (SELECT SUM(InvoiceTaxAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-22 22:27:30')
        - (SELECT SUM(ReturnTaxAmount) FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-22 22:27:30')
UNION ALL SELECT '4 Stock In', CAST(StockIn.StockInNumber AS nvarchar(40)),
          (SELECT SUM(InLine.BaseItemQuantity) FROM InvStockInItem AS InLine WHERE InLine.StockInID = StockIn.ID), NULL
          FROM InvStockIn AS StockIn WHERE StockIn.RefDocumentID IN (SELECT ID FROM Pur)
UNION ALL SELECT '5 Store transaction (cost)', 'Purchase', SUM(Trx.BaseItemQuantity), SUM(Trx.BaseItemQuantity * Trx.ItemCost)
          FROM InvStoreTransaction AS Trx WHERE Trx.DocumentID IN (SELECT ID FROM Pur)
ORDER BY Check_Name, Detail;

-- Test case: TC-035 (stock chain of data T6)
-- Purpose  : H23: units and packing size of Air Filter 041, to explain Stock In 4 for a purchase of 2 Each.
-- Expected : Packing size 2 for the purchased unit, so 2 Each = 4 base units.
-- Status   : Verified 22/11 (default unit packing size 2).
SELECT Unit.PackingSize AS Packing_Size, Unit.IsDefault AS Is_Default_Unit
FROM   InvItem AS Item
JOIN   InvItemUnit AS Unit ON Unit.ItemID = Item.ID
WHERE  Item.ItemNumber = 'NEW-ITEM-0041';

-- Test case: TC-035 (data T7) and stock chain
-- Purpose  : H24: purchase returns saved on 22/11, their tax, stock out, and Input VAT after them.
-- Expected : One return 115.00 with tax 15.00, stock out of 2 base units, Input VAT 30.00 - 15.00 = 15.00.
-- Status   : Verified 22/11 (115.00, tax 15.00, Input VAT 15.00, stock -2 base).
WITH Ret AS (
    SELECT ID, ReturnNumber, ReturnTotalAmount, ReturnTaxAmount FROM ProReturn
    WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-23')
SELECT '1 Purchase return' AS Check_Name, CAST(ReturnNumber AS nvarchar(40)) AS Detail, CAST(NULL AS decimal(18, 3)) AS Quantity, ReturnTotalAmount AS Amount FROM Ret
UNION ALL SELECT '2 Return count and tax', 'All of 22/11', COUNT(*), SUM(ReturnTaxAmount) FROM Ret
UNION ALL SELECT '3 Input VAT', 'Purchase tax - return tax', NULL,
          (SELECT SUM(InvoiceTaxAmount) FROM ProInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-23')
        - ISNULL((SELECT SUM(ReturnTaxAmount) FROM Ret), 0)
UNION ALL SELECT '4 Stock Out', CAST(StockOut.StockOutNumber AS nvarchar(40)),
          (SELECT SUM(OutLine.BaseItemQuantity) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID), NULL
          FROM InvStockOut AS StockOut WHERE StockOut.RefDocumentID IN (SELECT ID FROM Ret)
UNION ALL SELECT '5 Store transaction (cost)', 'Purchase return', SUM(Trx.BaseItemQuantity), SUM(Trx.BaseItemQuantity * Trx.ItemCost)
          FROM InvStoreTransaction AS Trx WHERE Trx.DocumentID IN (SELECT ID FROM Ret)
ORDER BY Check_Name, Detail;

-- Test case: TC-035 (stock chain of data T7)
-- Purpose  : H25: every Stock Out header numbered TO_11000205, with its date, source and line count.
-- Expected : One Stock Out header for the purchase return.
-- Status   : Verified 22/11: MISMATCH, two headers with the same number and source, one without lines (bug draft).
SELECT StockOut.ID AS Stock_Out_ID, StockOut.StockOutNumber AS Stock_Out_No, StockOut.StockOutDate AS Stock_Out_Date, StockOut.RefDocumentID AS Source_ID,
       (SELECT COUNT(*) FROM InvStockOutItem AS OutLine WHERE OutLine.StockOutID = StockOut.ID) AS Item_Lines
FROM   InvStockOut AS StockOut
WHERE  StockOut.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOut.StockOutNumber LIKE '%11000205';

-- Test case: TC-003, 004, 028, 087
-- Purpose  : H26: payment methods of the branch and not of the branch, inactive item Air Filter 039, documents of the other branches today, user count.
-- Expected : Chart shows only the branch methods. Air Filter 039 is Cancelled with stock. Other branches' documents are not in Alshellah figures.
-- Status   : Verified 22/11 (five methods, 0 others, Cancelled with 50, other branches 675.00 outside 1,836.01).
SELECT '1 Methods of Alshellah' AS Check_Name, STRING_AGG(CAST(Method.PaymentMethodName AS nvarchar(max)), ', ') AS Detail, CAST(COUNT(*) AS decimal(18, 2)) AS Value
FROM   GenBranchPaymentMethod AS Link
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Link.PaymentMethodID
WHERE  Link.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
UNION ALL
SELECT '2 Methods not of Alshellah', STRING_AGG(CAST(Method.PaymentMethodName AS nvarchar(max)), ', '), COUNT(*)
FROM   GenLkpPaymentMethod AS Method
WHERE  NOT EXISTS (SELECT 1 FROM GenBranchPaymentMethod AS Link WHERE Link.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Link.PaymentMethodID = Method.ID)
UNION ALL
SELECT '3 Air Filter 039 (qty in branch stores)', CAST(Status.DocumentStatusName AS nvarchar(max)),
       (SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx
        WHERE Trx.ItemID = Item.ID AND Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596'))
FROM   InvItem AS Item
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = Item.DocumentStatusID
WHERE  Item.ItemNumber = 'NEW-ITEM-0039'
UNION ALL
SELECT '4 Other branches today', 'Invoices (count)', COUNT(*) FROM SalInvoice WHERE BranchID <> 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-23'
UNION ALL
SELECT '4 Other branches today', 'Invoices (total)', SUM(InvoiceTotalAmount) FROM SalInvoice WHERE BranchID <> 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-23'
UNION ALL
SELECT '4 Other branches today', 'Work Orders (count)', COUNT(*) FROM SalWorkOrder WHERE BranchID <> 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderDate >= '2026-11-22' AND WorkOrderDate < '2026-11-23'
UNION ALL
SELECT '5 Alshellah today', 'Invoices minus returns', (SELECT SUM(InvoiceTotalAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-22 22:39:00')
       - (SELECT SUM(ReturnTotalAmount) FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-22 22:39:00')
UNION ALL
SELECT '6 System users', 'All users of the company', COUNT(*) FROM SecSystemUser
ORDER BY Check_Name, Detail;

-- Test case: TC-028 (data T8) and stock chain
-- Purpose  : H27: payment rows of INV-TO_11000144, received and refunded per method today, stock rows of the invoice.
-- Expected : Only Visa 30.00 on INV-144 (no cancelled Cash 10.00). Cash 740.00 - 210.00 = 530.00 and Visa 210.00 as on the chart. No stock row (service).
-- Status   : Verified 22/11 (Visa 30.00 only, all methods match the chart, 0 stock rows).
SELECT '1 INV-144 payment' AS Check_Name, CAST(Method.PaymentMethodName AS nvarchar(60)) AS Detail, Pay.PaymentAmount AS Amount
FROM   SalInvoice AS Inv
JOIN   SalInvoiceReceiptInvoice AS Link ON Link.InvoiceID = Inv.ID
JOIN   SalInvoiceReceiptPayment AS Pay ON Pay.InvoiceReceiptID = Link.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceNumber LIKE '%11000144'
UNION ALL
SELECT '2 Received today', CAST(Method.PaymentMethodName AS nvarchar(60)), SUM(Pay.PaymentAmount)
FROM   SalInvoiceReceiptPayment AS Pay
JOIN   SalInvoiceReceipt AS Receipt ON Receipt.ID = Pay.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.InvoiceReceiptDate >= '2026-11-22' AND Receipt.InvoiceReceiptDate < '2026-11-22 22:48:00'
GROUP BY Method.PaymentMethodName
UNION ALL
SELECT '3 Refunded today', 'All methods', SUM(Pay.PaymentAmount)
FROM   SalReturnReceiptPayment AS Pay
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-22' AND Receipt.ReturnReceiptDate < '2026-11-22 22:48:00'
UNION ALL
SELECT '4 Store transactions', 'Rows of INV-144', COUNT(*)
FROM   InvStoreTransaction AS Trx
WHERE  Trx.DocumentID IN (SELECT Inv.ID FROM SalInvoice AS Inv WHERE Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceNumber LIKE '%11000144')
ORDER BY Check_Name, Detail;

-- Test case: TC-063 (data T9, before Submit)
-- Purpose  : H28: the existing stock adjustments numbered 11000005 and 11000006 before the new adjustment is submitted.
-- Expected : One existing TO_11000005 of 13/11. Its ID and date must stay the same after Submit.
-- Status   : Executed 22/11 (one TO_11000005 of 13/11 before Submit).
SELECT ID AS Adjustment_ID, AdjustmentNumber AS Adjustment_No, AdjustmentDate AS Adjustment_Date
FROM   InvStockAdjustment
WHERE  AdjustmentNumber LIKE '%11000005' OR AdjustmentNumber LIKE '%11000006' OR AdjustmentDate >= '2026-11-22'
ORDER BY AdjustmentDate;

-- Test case: TC-063 (data T9, safety check)
-- Purpose  : H29: stock footprint of the existing TO_11000005 of 13/11 and Tire - Item balance per branch store, before Submit.
-- Expected : Tire Branch-2 = 4. The 13/11 footprint must be identical after Submit.
-- Status   : Executed 22/11 (old footprint 2 rows, 14 units, one Stock In; Tire Branch-2 = 4).
SELECT 'Old adjustment transactions' AS Check_Name, CAST(COUNT(*) AS varchar(50)) AS Detail, SUM(Trx.BaseItemQuantity) AS Quantity
FROM   InvStoreTransaction AS Trx
WHERE  Trx.DocumentID = '68F90B7B-A0EC-4A4A-9011-22A8F2282CAD'
   OR  Trx.DocumentID IN (SELECT ID FROM InvStockIn WHERE RefDocumentID = '68F90B7B-A0EC-4A4A-9011-22A8F2282CAD')
   OR  Trx.DocumentID IN (SELECT ID FROM InvStockOut WHERE RefDocumentID = '68F90B7B-A0EC-4A4A-9011-22A8F2282CAD')
UNION ALL
SELECT 'Old adjustment Stock In headers', CAST(COUNT(*) AS varchar(50)), NULL FROM InvStockIn WHERE RefDocumentID = '68F90B7B-A0EC-4A4A-9011-22A8F2282CAD'
UNION ALL
SELECT 'Old adjustment Stock Out headers', CAST(COUNT(*) AS varchar(50)), NULL FROM InvStockOut WHERE RefDocumentID = '68F90B7B-A0EC-4A4A-9011-22A8F2282CAD'
UNION ALL
SELECT 'Tire - Item balance', CAST(Trx.StoreID AS varchar(50)), SUM(Trx.BaseItemQuantity)
FROM   InvStoreTransaction AS Trx
JOIN   InvItem AS Item ON Item.ID = Trx.ItemID
WHERE  Item.ItemNumber = 'TO_1000001' AND Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Trx.StoreID;

-- Test case: TC-063, TC-030 (data T9, after Submit)
-- Purpose  : H30: every adjustment numbered TO_11000005, its Stock In, its store movement, and the Tire - Item balance after T9.
-- Expected : T9 +6 at cost 55 (330.00), Tire Branch-2 = 10, 13/11 footprint still 14. One number should mean one document.
-- Status   : Verified 22/11 (+6, 330.00, balance 10, old document unchanged). FINDING: two documents share one number (bug draft e-20261122-022).
SELECT '1 Adjustment' AS Check_Name, CAST(Adj.ID AS varchar(50)) AS Document_ID, CONVERT(varchar(19), Adj.AdjustmentDate, 120) AS Detail,
       (SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx
        WHERE Trx.DocumentID = Adj.ID OR Trx.DocumentID IN (SELECT ID FROM InvStockIn WHERE RefDocumentID = Adj.ID)) AS Quantity,
       (SELECT SUM(Trx.BaseItemQuantity * Trx.ItemCost) FROM InvStoreTransaction AS Trx
        WHERE Trx.DocumentID = Adj.ID OR Trx.DocumentID IN (SELECT ID FROM InvStockIn WHERE RefDocumentID = Adj.ID)) AS Cost_Value
FROM   InvStockAdjustment AS Adj
WHERE  Adj.AdjustmentNumber LIKE '%TO_11000005'
UNION ALL
SELECT '2 Stock In', CAST(StockIn.RefDocumentID AS varchar(50)), CAST(StockIn.StockInNumber AS varchar(50)),
       (SELECT SUM(InLine.BaseItemQuantity) FROM InvStockInItem AS InLine WHERE InLine.StockInID = StockIn.ID), NULL
FROM   InvStockIn AS StockIn
WHERE  StockIn.RefDocumentID IN (SELECT ID FROM InvStockAdjustment WHERE AdjustmentNumber LIKE '%TO_11000005')
UNION ALL
SELECT '3 Tire - Item balance', CAST(Trx.StoreID AS varchar(50)), 'Branch store', SUM(Trx.BaseItemQuantity), NULL
FROM   InvStoreTransaction AS Trx
JOIN   InvItem AS Item ON Item.ID = Trx.ItemID
WHERE  Item.ItemNumber = 'TO_1000001' AND Trx.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY Trx.StoreID
ORDER BY Check_Name, Detail;

-- Test case: TC-067 (Case B), TC-033, TC-073 (Case B), TC-071 (start state)
-- Purpose  : H31: branch Alshellah on 23/11 before any sale: documents of today, sales of yesterday, working days, and WO-TO_11000189.
-- Expected : Today 0 invoices, 0 returns, 0 Work Orders. Yesterday invoices minus returns 1,866.01. WO-189 created 22/11 and still New.
-- Status   : Verified 23/11 08:33 (0, 0, 0; yesterday 2,076.01 - 210.00 = 1,866.01; days of 21/11 and 22/11 both still open; WO-189 New, 22/11 21:13).
SELECT '1 Today' AS Check_Name, 'Invoices' AS Detail, CAST(COUNT(*) AS decimal(18,2)) AS Value, NULL AS Extra
FROM   SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-23'
UNION ALL
SELECT '1 Today', 'Returns', COUNT(*), NULL FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-23'
UNION ALL
SELECT '1 Today', 'Work Orders', COUNT(*), NULL FROM SalWorkOrder WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderDate >= '2026-11-23'
UNION ALL
SELECT '2 Yesterday', 'Invoices total', (SELECT SUM(InvoiceTotalAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-22' AND InvoiceDate < '2026-11-23'), NULL
UNION ALL
SELECT '2 Yesterday', 'Returns total', (SELECT SUM(ReturnTotalAmount) FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-22' AND ReturnDate < '2026-11-23'), NULL
UNION ALL
SELECT '3 Working day', CONVERT(varchar(19), WorkDay.OpenDate, 120), WorkDay.OpenBalanceCashAmount, CASE WHEN WorkDay.IsClosed = 1 THEN 'Closed' ELSE 'Open' END
FROM   SalWorkingDay AS WorkDay WHERE WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkDay.OpenDate >= '2026-11-21'
UNION ALL
SELECT '4 WO-189', CONVERT(varchar(19), WO.WorkOrderDate, 120), WO.WorkOrderTotalAmount, Status.DocumentStatusName
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.WorkOrderNumber LIKE '%11000189'
ORDER BY Check_Name, Detail;

-- Test case: TC-082, TC-075 (start), TC-069 (earlier-day return)
-- Purpose  : H32: RTN-TO_11000021 of INV-TO_11000143, refund payment, stock documents and movement, today's sales and returns, opening cash of today.
-- Expected : One return today of 30.00 refunded in Cash, 0 invoices today, opening cash 200.00, expected cash 200 - 30 = 170.00, no stock movement for a service.
-- Status   : Verified 23/11 08:40 (30.00 Cash, 0 invoices, 1 return, day 200.00 open). FINDING: Stock In TO_11000043 +1 for a service item (draft e-20261120-007).
WITH Ret AS (SELECT ID, InvoiceID FROM SalReturn WHERE ReturnNumber LIKE '%11000021' AND BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
SELECT '1 Return' AS Check_Name, Doc.ReturnNumber AS Detail, Doc.ReturnTotalAmount AS Amount, CONVERT(varchar(19), Doc.ReturnDate, 120) AS Extra
FROM   SalReturn AS Doc JOIN Ret ON Ret.ID = Doc.ID
UNION ALL
SELECT '2 Refund payment', Method.PaymentMethodName, Pay.PaymentAmount, NULL
FROM   SalReturnReceiptPayment AS Pay
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-23'
UNION ALL
SELECT '3 Today', 'Invoices', COUNT(*), NULL FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-23'
UNION ALL
SELECT '3 Today', 'Returns', COUNT(*), CAST(SUM(ReturnTotalAmount) AS varchar(30)) FROM SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-23'
UNION ALL
SELECT '4 Working day', CONVERT(varchar(19), WorkDay.OpenDate, 120), WorkDay.OpenBalanceCashAmount, CASE WHEN WorkDay.IsClosed = 1 THEN 'Closed' ELSE 'Open' END
FROM   SalWorkingDay AS WorkDay WHERE WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkDay.OpenDate >= '2026-11-23'
UNION ALL
SELECT '5 Stock In', CAST(StockIn.StockInNumber AS varchar(50)),
       (SELECT SUM(InLine.BaseItemQuantity) FROM InvStockInItem AS InLine WHERE InLine.StockInID = StockIn.ID), NULL
FROM   InvStockIn AS StockIn WHERE StockIn.RefDocumentID IN (SELECT ID FROM Ret UNION ALL SELECT InvoiceID FROM Ret)
UNION ALL
SELECT '6 Store movement', 'Return and invoice', SUM(Trx.BaseItemQuantity), CAST(COUNT(*) AS varchar(10)) + ' rows'
FROM   InvStoreTransaction AS Trx WHERE Trx.DocumentID IN (SELECT ID FROM Ret UNION ALL SELECT InvoiceID FROM Ret)
ORDER BY Check_Name, Detail;

-- Test case: TC-046, TC-069, TC-079
-- Purpose  : H33: invoices and returns of 22/11 and 23/11 by document date, with discount, status, original invoice date and refund methods; returns not submitted.
-- Expected : 22/11 returns 210.00 only; 23/11 returns 30.00 (invoice of 22/11) and 100.00 (invoice of 23/11), both Cash; return rate base = invoices + discounts.
-- Status   : Executed 23/11 08:50, FAILED (Msg 402: varchar + uniqueidentifier in part 6), no rows. Replaced by H34.
SELECT '1 Invoices' AS Check_Name, CONVERT(varchar(10), Inv.InvoiceDate, 120) AS Day, COUNT(*) AS Docs,
       SUM(Inv.InvoiceTotalAmount) AS Total_Amount, SUM(Inv.InvoiceDiscountAmount) AS Discount, NULL AS Extra
FROM   SalInvoice AS Inv
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceDate >= '2026-11-22' AND Inv.DocumentStatusID = 2
GROUP BY CONVERT(varchar(10), Inv.InvoiceDate, 120)
UNION ALL
SELECT '2 Returns', CONVERT(varchar(10), Ret.ReturnDate, 120), COUNT(*), SUM(Ret.ReturnTotalAmount), SUM(Ret.ReturnDiscountAmount), NULL
FROM   SalReturn AS Ret
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.ReturnDate >= '2026-11-22' AND Ret.DocumentStatusID = 2
GROUP BY CONVERT(varchar(10), Ret.ReturnDate, 120)
UNION ALL
SELECT '3 Return of ' + Inv.InvoiceNumber, CONVERT(varchar(10), Ret.ReturnDate, 120), 1, Ret.ReturnTotalAmount, NULL, 'Invoice date ' + CONVERT(varchar(10), Inv.InvoiceDate, 120)
FROM   SalReturn AS Ret JOIN SalInvoice AS Inv ON Inv.ID = Ret.InvoiceID
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.ReturnDate >= '2026-11-22'
UNION ALL
SELECT '4 Returns not submitted', 'All dates', COUNT(*), NULL, NULL, NULL
FROM   SalReturn AS Ret WHERE Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.DocumentStatusID <> 2
UNION ALL
SELECT '5 Payments of ' + Inv.InvoiceNumber, Method.PaymentMethodName, 1, Pay.PaymentAmount, NULL, NULL
FROM   SalInvoiceReceiptPayment AS Pay
JOIN   SalInvoiceReceiptInvoice AS Link ON Link.InvoiceReceiptID = Pay.InvoiceReceiptID
JOIN   SalInvoice AS Inv ON Inv.ID = Link.InvoiceID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Inv.InvoiceNumber LIKE '%1100014[56]'
UNION ALL
SELECT '6 Refund ' + Receipt.ID, Method.PaymentMethodName, 1, Pay.PaymentAmount, NULL, CONVERT(varchar(19), Receipt.ReturnReceiptDate, 120)
FROM   SalReturnReceiptPayment AS Pay
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-23'
ORDER BY Check_Name, Day;

-- Test case: TC-046, TC-069, TC-079
-- Purpose  : H34 (H33 corrected): invoices and returns of 22/11 and 23/11 by document date, with discount, status, original invoice date and refund methods; returns not submitted.
-- Expected : 22/11 returns 210.00 only; 23/11 returns 30.00 (invoice of 22/11) and 100.00 (invoice of 23/11), both Cash; return rate base = invoices + discounts.
-- Status   : Verified 23/11 08:52 (22/11: 2,076.01, discount 103.48, return 210.00; 23/11: 325.01, returns 30.00 and 100.00 in Cash; 0 returns not submitted).
SELECT '1 Invoices' AS Check_Name, CONVERT(varchar(10), Inv.InvoiceDate, 120) AS Day, COUNT(*) AS Docs,
       SUM(Inv.InvoiceTotalAmount) AS Total_Amount, SUM(Inv.InvoiceDiscountAmount) AS Discount, NULL AS Extra
FROM   SalInvoice AS Inv
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Inv.InvoiceDate >= '2026-11-22' AND Inv.DocumentStatusID = 2
GROUP BY CONVERT(varchar(10), Inv.InvoiceDate, 120)
UNION ALL
SELECT '2 Returns', CONVERT(varchar(10), Ret.ReturnDate, 120), COUNT(*), SUM(Ret.ReturnTotalAmount), SUM(Ret.ReturnDiscountAmount), NULL
FROM   SalReturn AS Ret
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.ReturnDate >= '2026-11-22' AND Ret.DocumentStatusID = 2
GROUP BY CONVERT(varchar(10), Ret.ReturnDate, 120)
UNION ALL
SELECT '3 Return of ' + Inv.InvoiceNumber, CONVERT(varchar(10), Ret.ReturnDate, 120), 1, Ret.ReturnTotalAmount, NULL, 'Invoice date ' + CONVERT(varchar(10), Inv.InvoiceDate, 120)
FROM   SalReturn AS Ret JOIN SalInvoice AS Inv ON Inv.ID = Ret.InvoiceID
WHERE  Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.ReturnDate >= '2026-11-22'
UNION ALL
SELECT '4 Returns not submitted', 'All dates', COUNT(*), NULL, NULL, NULL
FROM   SalReturn AS Ret WHERE Ret.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Ret.DocumentStatusID <> 2
UNION ALL
SELECT '5 Payments of ' + Inv.InvoiceNumber, Method.PaymentMethodName, 1, Pay.PaymentAmount, NULL, NULL
FROM   SalInvoiceReceiptPayment AS Pay
JOIN   SalInvoiceReceiptInvoice AS Link ON Link.InvoiceReceiptID = Pay.InvoiceReceiptID
JOIN   SalInvoice AS Inv ON Inv.ID = Link.InvoiceID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Inv.InvoiceNumber LIKE '%1100014[56]'
UNION ALL
SELECT '6 Refund ' + CAST(Receipt.ID AS varchar(36)), Method.PaymentMethodName, 1, Pay.PaymentAmount, NULL, CONVERT(varchar(19), Receipt.ReturnReceiptDate, 120)
FROM   SalReturnReceiptPayment AS Pay
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Receipt.ReturnReceiptDate >= '2026-11-23'
ORDER BY Check_Name, Day;

-- Test case: TC-071
-- Purpose  : H35: Work Orders of branch Alshellah dated 23/11 and WO-TO_11000189, with status, WO date, working day, carry-over flags and invoice date.
-- Expected : 195, 196 Completed; 197 New; 198 Cancelled. WO-189 was created 22/11 21:13 (H31) and completed today: is its WO date still 22/11?
-- Status   : Executed 23/11 09:02, FAILED (Msg 207: SalInvoice has no WorkOrderID), no rows. Replaced by H36.
SELECT WO.WorkOrderNumber AS WO_No, Status.DocumentStatusName AS WO_Status, CONVERT(varchar(19), WO.WorkOrderDate, 120) AS WO_Date,
       CONVERT(varchar(19), WorkDay.OpenDate, 120) AS Working_Day_Opened, WO.IsShiftedEOD AS Carried_At_Close_Day,
       CONVERT(varchar(19), FromDay.OpenDate, 120) AS Carried_From_Day, WO.WorkOrderTotalAmount AS Amount,
       (SELECT TOP 1 Inv.InvoiceNumber + ' ' + CONVERT(varchar(19), Inv.InvoiceDate, 120) FROM SalInvoice AS Inv WHERE Inv.WorkOrderID = WO.ID) AS Invoice
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
LEFT JOIN SalWorkingDay AS WorkDay ON WorkDay.ID = WO.WorkingDayID
LEFT JOIN SalWorkingDay AS FromDay ON FromDay.ID = WO.ShiftedFromWorkingDayID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND (WO.WorkOrderDate >= '2026-11-23' OR WO.WorkOrderNumber LIKE '%11000189')
ORDER BY WO.WorkOrderNumber;

-- Test case: TC-071
-- Purpose  : H36 (H35 without the invoice column): Work Orders of branch Alshellah dated 23/11 and WO-TO_11000189, with status, WO date, working day, carry-over flags.
-- Expected : 195, 196 Completed; 197 New; 198 Cancelled. WO-189 was created 22/11 21:13 (H31) and completed today: is its WO date still 22/11?
-- Status   : Verified 23/11 09:03. FINDING: WO-189 WorkOrderDate changed from 22/11 21:13 (H31) to 23/11 08:58:58 and moved to the working day of 23/11 on completion, not carried over (bug draft).
SELECT WO.WorkOrderNumber AS WO_No, Status.DocumentStatusName AS WO_Status, CONVERT(varchar(19), WO.WorkOrderDate, 120) AS WO_Date,
       CONVERT(varchar(19), WorkDay.OpenDate, 120) AS Working_Day_Opened, WO.IsShiftedEOD AS Carried_At_Close_Day,
       CONVERT(varchar(19), FromDay.OpenDate, 120) AS Carried_From_Day, WO.WorkOrderTotalAmount AS Amount
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
LEFT JOIN SalWorkingDay AS WorkDay ON WorkDay.ID = WO.WorkingDayID
LEFT JOIN SalWorkingDay AS FromDay ON FromDay.ID = WO.ShiftedFromWorkingDayID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND (WO.WorkOrderDate >= '2026-11-23' OR WO.WorkOrderNumber LIKE '%11000189')
ORDER BY WO.WorkOrderNumber;

-- Test case: TC-078
-- Purpose  : H37: invoices and returns of branch Alshellah dated in the first or last hour of a day (November), to pick boundary ranges.
-- Expected : Documents near 00:00 and 23:59 that can serve as From and To boundary documents.
-- Status   : Executed 23/11 09:08 (8 invoices, 0 returns; 14/11 00:44 and 23:36, 21/11 00:10).
SELECT 'Invoice' AS Doc_Type, InvoiceNumber AS Doc_No, CONVERT(varchar(19), InvoiceDate, 120) AS Doc_Date, InvoiceTotalAmount AS Amount
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-01' AND DocumentStatusID = 2
  AND (DATEPART(hour, InvoiceDate) = 0 OR DATEPART(hour, InvoiceDate) = 23)
UNION ALL
SELECT 'Return', ReturnNumber, CONVERT(varchar(19), ReturnDate, 120), ReturnTotalAmount
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate >= '2026-11-01' AND DocumentStatusID = 2
  AND (DATEPART(hour, ReturnDate) = 0 OR DATEPART(hour, ReturnDate) = 23)
ORDER BY Doc_Date;

-- Test case: TC-078
-- Purpose  : H38: invoices and returns of branch Alshellah per range by document date: 14/11 only, 14/11 to 20/11, and the boundary documents INV-82, INV-97, INV-137.
-- Expected : 14/11 includes INV-82 (00:44) and INV-97 (23:36); 14/11 to 20/11 excludes INV-137 (21/11 00:10). Counts and totals to compare with the Sales tab.
-- Status   : Verified 23/11 09:10 (14/11: 16 invoices 18,125.11, 0 returns; 14-20/11: 55 invoices 27,386.48, 3 returns 149.90; INV-82 00:44, INV-97 23:36, INV-137 21/11 00:10).
SELECT '1 Range 14/11' AS Check_Name, 'Invoices' AS Detail, COUNT(*) AS Docs, SUM(InvoiceTotalAmount) AS Amount
FROM   SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND DocumentStatusID = 2 AND InvoiceDate >= '2026-11-14' AND InvoiceDate < '2026-11-15'
UNION ALL
SELECT '1 Range 14/11', 'Returns', COUNT(*), SUM(ReturnTotalAmount)
FROM   SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND DocumentStatusID = 2 AND ReturnDate >= '2026-11-14' AND ReturnDate < '2026-11-15'
UNION ALL
SELECT '2 Range 14/11-20/11', 'Invoices', COUNT(*), SUM(InvoiceTotalAmount)
FROM   SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND DocumentStatusID = 2 AND InvoiceDate >= '2026-11-14' AND InvoiceDate < '2026-11-21'
UNION ALL
SELECT '2 Range 14/11-20/11', 'Returns', COUNT(*), SUM(ReturnTotalAmount)
FROM   SalReturn WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND DocumentStatusID = 2 AND ReturnDate >= '2026-11-14' AND ReturnDate < '2026-11-21'
UNION ALL
SELECT '3 Boundary ' + InvoiceNumber, CONVERT(varchar(19), InvoiceDate, 120), 1, InvoiceTotalAmount
FROM   SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND (InvoiceNumber LIKE '%11000082' OR InvoiceNumber LIKE '%11000097' OR InvoiceNumber LIKE '%11000137')
ORDER BY Check_Name, Detail;

-- Test case: TC-075
-- Purpose  : H39: working day of 23/11 after Close Day (counted cash, deposit, left in drawer) and the linked cash deposit TO_11000005 with its status.
-- Expected : Day closed, system cash 455.01, deposit 100.00, left 355.01; deposit 100.00 Submitted and linked to the day. Expected Cash after the deposit = 355.01.
-- Status   : Verified 23/11 09:24 (closed 09:20:10, system 455.01, deposit 100.00, left 355.01, TO_11000005 Submitted linked 100.00). Dashboard still shows 455.01 (draft e-20261120-076).
SELECT CONVERT(varchar(19), WorkDay.OpenDate, 120)  AS Opened_At,
       CONVERT(varchar(19), WorkDay.CloseDate, 120) AS Closed_At,
       WorkDay.IsClosed               AS Is_Closed,
       WorkDay.OpenBalanceCashAmount  AS Opening_Cash,
       WorkDay.CloseSystemCashAmount  AS Closing_Cash_System,
       WorkDay.CloseDepositCashAmount AS Closing_Deposit,
       WorkDay.CloseLeftCashAmount    AS Closing_Left_In_Drawer,
       Deposit.BankDepositNumber      AS Deposit_No,
       Status.DocumentStatusName      AS Deposit_Status,
       DayLink.DepositAmount          AS Linked_Deposit_Amount
FROM   SalWorkingDay AS WorkDay
LEFT JOIN SalBankDepositWorkingDay AS DayLink ON DayLink.WorkingDayID = WorkDay.ID
LEFT JOIN SalBankDeposit AS Deposit ON Deposit.ID = DayLink.BankDepositID
LEFT JOIN GenLkpDocumentStatus AS Status ON Status.ID = Deposit.DocumentStatusID
WHERE  WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkDay.OpenDate >= '2026-11-23'
ORDER BY WorkDay.OpenDate;

-- Test case: file rebuild (foreign keys)
-- Purpose  : Foreign keys between the sales, work order, stock and working day tables: child column -> parent table, one row per child table.
-- Expected : The verified ID links used by the rebuilt query files.
-- Status   : Written 23/11
SELECT ChildTable.name AS Child_Table,
       STRING_AGG(CAST(ChildCol.name + ' -> ' + ParentTable.name AS nvarchar(max)), ' | ') WITHIN GROUP (ORDER BY ChildCol.name) AS Links
FROM   sys.foreign_key_columns AS Link
JOIN   sys.tables  AS ChildTable  ON ChildTable.object_id  = Link.parent_object_id
JOIN   sys.columns AS ChildCol    ON ChildCol.object_id    = Link.parent_object_id AND ChildCol.column_id = Link.parent_column_id
JOIN   sys.tables  AS ParentTable ON ParentTable.object_id = Link.referenced_object_id
WHERE  ChildTable.name IN ('SalWorkOrder','SalWorkOrderItem','SalInvoice','SalInvoiceItem','SalInvoiceReceipt','SalInvoiceReceiptInvoice','SalInvoiceReceiptPayment','SalReturn','SalReturnItem','SalReturnReceipt','SalReturnReceiptPayment','SalWorkingDay','SalBankDeposit','SalBankDepositWorkingDay','InvStockIn','InvStockInItem','InvStockOut','InvStockOutItem','InvStoreTransaction','InvItemUnit','InvStoreItem','InvItemBranch','InvStoreBranch','InvStockAdjustment','InvStockAdjustmentItem')
  AND  ParentTable.name NOT IN ('SecSystemUser','GenLkpDocumentStatus','GenLkpDocumentType','GenTerminal')
GROUP BY ChildTable.name
ORDER BY ChildTable.name;

-- Test case: file rebuild (foreign keys between the core tables)
-- Purpose  : One row per foreign key between the core sales, work order, stock and working day tables (lookup tables left out).
-- Expected : The verified ID links used by the rebuilt query files.
-- Status   : Written 23/11
SELECT ChildTable.name AS Child_Table, ChildCol.name AS Child_Column, ParentTable.name AS Parent_Table
FROM   sys.foreign_key_columns AS Link
JOIN   sys.tables  AS ChildTable  ON ChildTable.object_id  = Link.parent_object_id
JOIN   sys.columns AS ChildCol    ON ChildCol.object_id    = Link.parent_object_id AND ChildCol.column_id = Link.parent_column_id
JOIN   sys.tables  AS ParentTable ON ParentTable.object_id = Link.referenced_object_id
WHERE  ChildTable.name IN ('SalWorkOrder','SalWorkOrderItem','SalInvoice','SalInvoiceItem','SalInvoiceReceipt','SalInvoiceReceiptInvoice','SalInvoiceReceiptPayment','SalReturn','SalReturnItem','SalReturnReceipt','SalReturnReceiptPayment','SalWorkingDay','SalBankDeposit','SalBankDepositWorkingDay','InvStockIn','InvStockInItem','InvStockOut','InvStockOutItem','InvStoreTransaction','InvItemUnit','InvStoreItem','InvItemBranch','InvStoreBranch','InvStockAdjustment','InvStockAdjustmentItem','InvItem','InvStore','InvItemBatch') AND ParentTable.name IN ('SalWorkOrder','SalWorkOrderItem','SalInvoice','SalInvoiceItem','SalInvoiceReceipt','SalInvoiceReceiptInvoice','SalInvoiceReceiptPayment','SalReturn','SalReturnItem','SalReturnReceipt','SalReturnReceiptPayment','SalWorkingDay','SalBankDeposit','SalBankDepositWorkingDay','InvStockIn','InvStockInItem','InvStockOut','InvStockOutItem','InvStoreTransaction','InvItemUnit','InvStoreItem','InvItemBranch','InvStoreBranch','InvStockAdjustment','InvStockAdjustmentItem','InvItem','InvStore','InvItemBatch')
ORDER BY ChildTable.name, ChildCol.name;

-- Test case: file rebuild (ID columns without a foreign key)
-- Purpose  : Every column ending in ID in the sales documents and receipts, to find the Work Order - invoice and return - receipt links that have no foreign key.
-- Expected : Columns such as RefDocumentID or WorkOrderID that hold another document's ID.
-- Status   : Written 23/11
SELECT TABLE_NAME AS Table_Name, STRING_AGG(CAST(COLUMN_NAME AS nvarchar(max)), ', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION) AS ID_Columns
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME IN ('SalInvoice','SalWorkOrder','SalReturn','SalReturnReceipt','SalReturnReceiptPayment','SalInvoiceReceipt')
  AND  COLUMN_NAME LIKE '%ID' AND COLUMN_NAME NOT IN ('ID','BranchID','TerminalID','SystemUserID','CustomerID','CurrencyID','DocumentStatusID','DocumentTypeID','PriceListID','CreatedBy','ModifiedBy')
GROUP BY TABLE_NAME;

-- Test case: file rebuild (Work Order to invoice link)
-- Purpose  : Whether a paid Work Order and its invoice share the same ID (WO-TO_11000195 and INV-TO_11000145, WO-TO_11000196 and INV-TO_11000146), and the Work Order columns that mention Invoice.
-- Expected : Same ID on both rows if the invoice reuses the Work Order ID.
-- Status   : Written 23/11
SELECT 'Work Order' AS Doc, WorkOrderNumber AS Doc_No, CAST(ID AS varchar(36)) AS Doc_ID FROM SalWorkOrder WHERE WorkOrderNumber LIKE '%1100019[56]'
UNION ALL
SELECT 'Invoice', InvoiceNumber, CAST(ID AS varchar(36)) FROM SalInvoice WHERE InvoiceNumber LIKE '%1100014[56]'
UNION ALL
SELECT 'WO column', COLUMN_NAME, NULL FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'SalWorkOrder' AND (COLUMN_NAME LIKE '%Invoice%' OR COLUMN_NAME LIKE '%Ref%')
ORDER BY Doc, Doc_No;

-- Test case: file rebuild (link tables)
-- Purpose  : Tables and columns that could link a Work Order to its invoice, or a return to its refund receipt: any table with a WorkOrder column, and any column of the return receipt tables.
-- Expected : A link table or column, if one exists.
-- Status   : Written 23/11
SELECT TABLE_NAME AS Table_Name, COLUMN_NAME AS Column_Name
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  (COLUMN_NAME LIKE '%WorkOrder%' AND TABLE_NAME NOT LIKE 'SalWorkOrder%')
   OR  (TABLE_NAME LIKE 'SalReturnReceipt%' AND COLUMN_NAME LIKE '%ID')
ORDER BY Table_Name, Column_Name;

-- =====================================================================
-- Section H: Run 80, Demo Company   |   2026-11-24   |   Build 1.2.498
-- Demo Company has its own database: choose it in the SSMS list (USE line below).
-- =====================================================================

-- Test case: TC-010 Show zero growth when both days have zero sales
-- Purpose  : H40: Demo Company invoices, returns and Work Orders of yesterday (23/11) and today (24/11), each table on its own, then the day totals.
-- Expected : No invoice, return or Work Order on 23/11 and 24/11, so both days are 0 and growth shows 0%.
-- Status   : Written, Executed, Verified 24/11 (0 and 0, matched UI)
USE MacOne_165d415d66034069b7b0171a6c242a6e;
SELECT * FROM SalInvoice   WHERE InvoiceDate   >= '2026-11-23' AND InvoiceDate   < '2026-11-25';
SELECT * FROM SalReturn    WHERE ReturnDate    >= '2026-11-23' AND ReturnDate    < '2026-11-25';
SELECT * FROM SalWorkOrder WHERE WorkOrderDate >= '2026-11-23' AND WorkOrderDate < '2026-11-25';
SELECT Days.Day,
       (SELECT COUNT(*) FROM SalInvoice WHERE CAST(InvoiceDate AS date) = Days.Day) AS Invoices,
       ISNULL((SELECT SUM(InvoiceTotalAmount) FROM SalInvoice WHERE CAST(InvoiceDate AS date) = Days.Day), 0)
     - ISNULL((SELECT SUM(ReturnTotalAmount)  FROM SalReturn  WHERE CAST(ReturnDate  AS date) = Days.Day), 0) AS Net_Sales
FROM  (SELECT CAST('2026-11-23' AS date) AS Day UNION ALL SELECT CAST('2026-11-24' AS date)) AS Days;

-- Test case: TC-009 Show New Sales when yesterday is zero and today is positive
-- Purpose  : H41: Demo Company after the 24/11 sale (WO TO_1000005 carried from 22/11, paid 39.50 Cash): sales of 23/11 and 24/11, then the invoice and its chain, each table on its own and linked by ID.
-- Expected : 23/11 net 0, 24/11 one invoice 39.50 paid Cash. Invoice linked to the WO by SalWorkOrderInvoice, a Stock Out with lines and store movements at the item cost.
-- Status   : Written, Executed, Verified 24/11 (MATCH with UI)
USE MacOne_165d415d66034069b7b0171a6c242a6e;
SELECT Days.Day,
       (SELECT COUNT(*) FROM SalInvoice WHERE CAST(InvoiceDate AS date) = Days.Day) AS Invoices,
       ISNULL((SELECT SUM(InvoiceTotalAmount) FROM SalInvoice WHERE CAST(InvoiceDate AS date) = Days.Day), 0)
     - ISNULL((SELECT SUM(ReturnTotalAmount)  FROM SalReturn  WHERE CAST(ReturnDate  AS date) = Days.Day), 0) AS Net_Sales
FROM  (SELECT CAST('2026-11-23' AS date) AS Day UNION ALL SELECT CAST('2026-11-24' AS date)) AS Days;
SELECT * FROM SalInvoice WHERE InvoiceDate >= '2026-11-24';
SELECT * FROM SalWorkOrderInvoice WHERE InvoiceID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24');
SELECT * FROM SalWorkOrder WHERE ID IN (SELECT WorkOrderID FROM SalWorkOrderInvoice WHERE InvoiceID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24'));
SELECT * FROM SalInvoiceReceiptPayment WHERE InvoiceReceiptID IN (SELECT InvoiceReceiptID FROM SalInvoiceReceiptInvoice WHERE InvoiceID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24'));
SELECT * FROM InvStockOut WHERE RefDocumentID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24') OR RefDocumentID IN (SELECT WorkOrderID FROM SalWorkOrderInvoice WHERE InvoiceID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24'));
SELECT * FROM InvStoreTransaction WHERE DocumentID IN (SELECT ID FROM SalInvoice WHERE InvoiceDate >= '2026-11-24');

-- ============================================================================
-- Section I: Bug retests on build 1.2.504, QA - Company | 2026-11-24
-- ============================================================================

-- Test case: TC-019 Bug 2286 retest, Inventory counts after the Store filter fix
-- Purpose  : H42: Same rules as G-T12 (General-Queries): submitted Product and ProductPackage items of branch Alshellah, every item x branch store pair (InvStoreBranch), items with no pair count as Out of Stock. First result: each category as distinct items and as item x store rows. Second result: the same per store, to compare with the search for one store.
-- Expected : UI on 24/11 12:54: All 363, In Stock 353, Low Stock 1, Out of Stock 12, Negative 21; search "Mohammad Store Branch - 2" shows 27/390 results.
-- Status   : Written, Executed, Verified 24/11. All stores matches UI (363, 353, 1, 12, 21; 390 rows). Branch - 2: 27 rows = 3 In, 1 Low, 2 Out, 21 Negative; UI cards unchanged by the search
WITH BranchStores AS (
    SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
),
Items AS (
    SELECT Item.ID AS ItemID
    FROM   InvItem AS Item
    WHERE  Item.DocumentStatusID = 2
      AND  Item.ItemTypeID IN (1, 3)
      AND (Item.IsApplyToAllBranch = 1
           OR EXISTS (SELECT 1 FROM InvItemBranch AS IB WHERE IB.ItemID = Item.ID AND IB.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'))
),
Pairs AS (
    SELECT Trx.ItemID, Trx.StoreID
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM BranchStores) AND Trx.ItemID IN (SELECT ItemID FROM Items)
    UNION
    SELECT Setup.ItemID, Setup.StoreID
    FROM   InvStoreItem AS Setup
    WHERE  Setup.StoreID IN (SELECT StoreID FROM BranchStores) AND Setup.ItemID IN (SELECT ItemID FROM Items)
),
Rows AS (
    SELECT Items.ItemID, Pairs.StoreID,
           ISNULL((SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx
                   WHERE Trx.ItemID = Items.ItemID AND Trx.StoreID = Pairs.StoreID), 0) AS Quantity,
           ISNULL((SELECT MAX(Setup.ItemMinQuantity) FROM InvStoreItem AS Setup
                   WHERE Setup.ItemID = Items.ItemID AND Setup.StoreID = Pairs.StoreID), 0) AS Min_Quantity
    FROM   Items
    LEFT JOIN Pairs ON Pairs.ItemID = Items.ItemID
),
Classified AS (
    SELECT Rows.ItemID, ISNULL(Store.StoreName, '(no store)') AS Store_Name,
           CASE WHEN Quantity < 0 THEN '4 Negative'
                WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity > 0 AND Quantity <= Min_Quantity THEN '2 Low Stock'
                ELSE '1 In Stock' END AS Category
    FROM   Rows
    LEFT JOIN InvStore AS Store ON Store.ID = Rows.StoreID
)
SELECT 'All stores' AS Scope, Category, COUNT(DISTINCT ItemID) AS Items, COUNT(*) AS Item_Store_Rows
FROM   Classified GROUP BY Category
UNION ALL
SELECT 'All stores', '0 All', COUNT(DISTINCT ItemID), COUNT(*) FROM Classified
UNION ALL
SELECT Store_Name, Category, COUNT(DISTINCT ItemID), COUNT(*)
FROM   Classified GROUP BY Store_Name, Category
UNION ALL
SELECT Store_Name, '0 All', COUNT(DISTINCT ItemID), COUNT(*)
FROM   Classified GROUP BY Store_Name
ORDER BY Scope, Category;

-- ============================================================================
-- Section J: Executive Summary, the tables behind each line | 2026-11-24
-- Company : QA - Company (pick its database in SSMS, no prefix in the queries)
-- Branch  : Alshellah  = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
-- Day     : 24/11/2026 (change the two dates to check another day)
-- Each table is queried on its own. Run one query at a time (select it, F5).
-- Status  : Written 24/11
-- ============================================================================


-- ----------------------------------------------------------------------------
-- J1. GenBranch: the branch itself
-- Used by : every line (all figures are for this branch only)
-- Returns : one row, the branch name and ID that SalInvoice.BranchID and SalReturn.BranchID point to.
-- ----------------------------------------------------------------------------
SELECT *
FROM   GenBranch
WHERE  ID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817';


-- ----------------------------------------------------------------------------
-- J2. SalWorkingDay: the working days of the branch
-- Used by : every daily figure (an invoice belongs to one working day through SalInvoice.WorkingDayID)
-- Returns : the days opened on or after 23/11, with open and close time and opening cash.
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalWorkingDay
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  OpenDate >= '2026-11-23'
ORDER BY OpenDate;


-- ----------------------------------------------------------------------------
-- J3. SalInvoice: sales invoices of the day
-- Used by : Daily Sales (InvoiceTotalAmount), Daily Net Sales (InvoiceBeforeTaxAmount),
--           Output VAT (InvoiceTaxAmount), and the Net Sales part of Gross Profit and Gross Margin
-- Returns : one row per invoice of the branch on that day.
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'
ORDER BY InvoiceDate;


-- ----------------------------------------------------------------------------
-- J4. SalReturn: sales returns of the day
-- Used by : subtracted from Daily Sales (ReturnTotalAmount), Daily Net Sales (ReturnBeforeTaxAmount)
--           and Output VAT (ReturnTaxAmount)
-- Returns : one row per return of the branch on that day. InvoiceID is the original invoice
--           (logical link, no FK).
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-24' AND ReturnDate < '2026-11-25'
ORDER BY ReturnDate;


-- ----------------------------------------------------------------------------
-- J5. GenLkpDocumentType: the document types
-- Used by : Gross Profit (to know which store movements are sales and which are returns)
-- Returns : every document type with its ID, to read InvStoreTransaction.DocumentTypeID.
-- ----------------------------------------------------------------------------
SELECT *
FROM   GenLkpDocumentType;


-- ----------------------------------------------------------------------------
-- J6. InvStoreTransaction: stock movements of the day
-- Used by : Gross Profit, the COGS part = BaseItemQuantity x ItemCost of sale and return movements
-- Returns : one row per item per document that moved stock on that day (sales, returns, purchases,
--           adjustments). DocumentID points to the document, DocumentTypeID to J5.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreTransaction
WHERE  DocumentDate >= '2026-11-24' AND DocumentDate < '2026-11-25'
ORDER BY DocumentDate;


-- ----------------------------------------------------------------------------
-- J7. InvStoreBranch: which stores belong to the branch
-- Used by : Inventory Value (only these stores are counted, KB item 14)
-- Returns : one row per store linked to the branch.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreBranch
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817';


-- ----------------------------------------------------------------------------
-- J8. InvStore: the stores
-- Used by : Inventory Value (store names behind J7)
-- Returns : the stores of the branch, with name and settings such as IsApplyToAllBranch.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStore
WHERE  ID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817');


-- ----------------------------------------------------------------------------
-- J9. InvItem: the items
-- Used by : Inventory Value (which items are stock items: ItemTypeID 1 Product, 3 Product Package;
--           services have no stock)
-- Returns : every submitted item (DocumentStatusID = 2) with its type.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvItem
WHERE  DocumentStatusID = 2
ORDER BY ItemName;


-- ----------------------------------------------------------------------------
-- J10. InvStoreTransaction: all stock movements of the branch stores
-- Used by : Inventory Value. Current quantity = SUM(BaseItemQuantity) per item and store,
--           cost = ItemCost. The exact formula is still unknown (KB item 6), so compare with care.
-- Returns : every movement ever made in the branch stores (large result).
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreTransaction
WHERE  StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
ORDER BY ItemID, StoreID, DocumentDate;


-- ----------------------------------------------------------------------------
-- J11. ProInvoice: purchase invoices
-- Used by : Input VAT (tax of purchase invoices)
-- Returns : the purchase invoices. The date and tax column names are not verified yet, so the
--           query lists all rows; read the columns and filter by the day afterwards.
-- ----------------------------------------------------------------------------
SELECT *
FROM   ProInvoice;


-- ----------------------------------------------------------------------------
-- J12. Purchase return table: name not verified yet
-- Used by : Input VAT (tax of purchase returns, subtracted)
-- Returns : the tables whose name looks like a purchase return, to find the right one.
--           This is a lookup only; the table is not confirmed.
-- ----------------------------------------------------------------------------
SELECT name AS Table_Name
FROM   sys.tables
WHERE  name LIKE 'Pro%Return%'
ORDER BY name;

-- ============================================================================
-- Section K: Executive Summary, one query per calculation | 2026-11-24
-- Company : QA - Company   Branch: Alshellah   Day: 24/11/2026
-- To check another day, change the dates '2026-11-24' and '2026-11-25' in each query.
-- Run one query at a time (select it, F5).
-- Status  : Written 24/11
-- ============================================================================


-- ----------------------------------------------------------------------------
-- K1. Daily Sales, Daily Net Sales, Output VAT: invoice by invoice
-- Shows   : every invoice and every return of the day with its three amounts.
--           Returns are shown negative so the column totals in K2 are simple sums.
-- ----------------------------------------------------------------------------
SELECT 'Invoice'                  AS Document_Kind,
       InvoiceNumber              AS Document_No,
       InvoiceDate                AS Document_Date,
       InvoiceTotalAmount         AS Incl_VAT,
       InvoiceBeforeTaxAmount     AS Excl_VAT,
       InvoiceTaxAmount           AS VAT
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'
UNION ALL
SELECT 'Return',
       ReturnNumber,
       ReturnDate,
       -ReturnTotalAmount,
       -ReturnBeforeTaxAmount,
       -ReturnTaxAmount
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-24' AND ReturnDate < '2026-11-25'
ORDER BY Document_Date;


-- ----------------------------------------------------------------------------
-- K2. Daily Sales, Daily Net Sales, Output VAT: totals
-- Formula : Daily Sales     = invoices Incl. VAT  - returns Incl. VAT
--           Daily Net Sales = invoices Excl. VAT  - returns Excl. VAT
--           Output VAT      = invoices VAT        - returns VAT
-- Compare : Daily Sales (Incl. VAT), Daily Net Sales (Excl. VAT), Output VAT on the screen.
-- ----------------------------------------------------------------------------
SELECT ISNULL((SELECT SUM(InvoiceTotalAmount)     FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnTotalAmount)      FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Daily_Sales_Incl_VAT,
       ISNULL((SELECT SUM(InvoiceBeforeTaxAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnBeforeTaxAmount)  FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Daily_Net_Sales_Excl_VAT,
       ISNULL((SELECT SUM(InvoiceTaxAmount)       FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnTaxAmount)        FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Output_VAT;


-- ----------------------------------------------------------------------------
-- K3. COGS: line by line
-- Shows   : every stock movement of today's invoices, with its document type, item, store,
--           base quantity, unit cost and line cost (base quantity x cost).
--           Return movements also carry the original invoice ID (KB section 5 item 3),
--           so they appear here with their own document type.
--           Service items have no stock movement, so they add no cost.
-- ----------------------------------------------------------------------------
SELECT Inv.InvoiceNumber                     AS Invoice_No,
       DocType.DocumentTypeName              AS Movement_Type,
       Item.ItemName                         AS Item_Name,
       Store.StoreName                       AS Store_Name,
       Trx.BaseItemQuantity                  AS Base_Qty,
       Trx.ItemCost                          AS Unit_Cost,
       Trx.BaseItemQuantity * Trx.ItemCost   AS Line_Cost
FROM   InvStoreTransaction AS Trx
JOIN   SalInvoice          AS Inv     ON Inv.ID     = Trx.DocumentID
JOIN   InvItem             AS Item    ON Item.ID    = Trx.ItemID
JOIN   InvStore            AS Store   ON Store.ID   = Trx.StoreID
JOIN   GenLkpDocumentType  AS DocType ON DocType.ID = Trx.DocumentTypeID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-24' AND Inv.InvoiceDate < '2026-11-25'
ORDER BY Inv.InvoiceNumber, Item.ItemName;


-- ----------------------------------------------------------------------------
-- K4. Gross Profit and Gross Margin
-- Formula : COGS          = SUM(base quantity x unit cost) of K3   (same rule as H4, verified 22/11)
--           Gross Profit  = Daily Net Sales (K2) - COGS
--           Gross Margin  = Gross Profit / Daily Net Sales x 100   (0 when Net Sales is 0)
-- Compare : screen on 24/11: Net Sales 434.78, Gross Profit 379.78, Gross Margin 87.35% (so COGS 55.00).
-- ----------------------------------------------------------------------------
WITH NetSales AS (
    SELECT ISNULL((SELECT SUM(InvoiceBeforeTaxAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
         - ISNULL((SELECT SUM(ReturnBeforeTaxAmount)  FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Amount
),
Cogs AS (
    SELECT ISNULL(SUM(Trx.BaseItemQuantity * Trx.ItemCost), 0) AS Amount
    FROM   InvStoreTransaction AS Trx
    JOIN   SalInvoice          AS Inv ON Inv.ID = Trx.DocumentID
    WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
      AND  Inv.InvoiceDate >= '2026-11-24' AND Inv.InvoiceDate < '2026-11-25'
)
SELECT NetSales.Amount                                   AS Daily_Net_Sales,
       Cogs.Amount                                       AS COGS,
       NetSales.Amount - Cogs.Amount                     AS Gross_Profit,
       CASE WHEN NetSales.Amount = 0 THEN 0
            ELSE ROUND((NetSales.Amount - Cogs.Amount) * 100.0 / NetSales.Amount, 2) END AS Gross_Margin_Pct
FROM   NetSales, Cogs;


-- ----------------------------------------------------------------------------
-- K5. Input VAT: columns of the purchase tables first
-- Formula : Input VAT = VAT of purchase invoices - VAT of purchase returns (story rule).
-- Shows   : the column names of every Pro... table, so the date and tax columns can be chosen.
--           The final Input VAT query is written after these names are read (no guessed names).
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME  AS Table_Name,
       COLUMN_NAME AS Column_Name,
       DATA_TYPE   AS Data_Type
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME LIKE 'Pro%'
  AND (COLUMN_NAME LIKE '%Date%' OR COLUMN_NAME LIKE '%Tax%' OR COLUMN_NAME LIKE '%Branch%' OR COLUMN_NAME LIKE '%Number%')
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ----------------------------------------------------------------------------
-- K6. Net VAT Payable
-- Formula : Output VAT (K2) - Input VAT (K5).
--           Today Input VAT is 0.00 on the screen, so Net VAT Payable = Output VAT.
--           Not repeated as its own query until the Input VAT query exists.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- K7. Inventory Value: candidate formula, NOT confirmed
-- Formula : SUM over branch stores of (current base quantity x item cost of its latest movement).
--           The real formula is unknown (KB section 5 item 6). Use this to compare only; a
--           mismatch is expected until development gives the rule.
-- Compare : screen on 24/11: 95,410.00.
-- ----------------------------------------------------------------------------
WITH Balance AS (
    SELECT Trx.ItemID, Trx.StoreID, SUM(Trx.BaseItemQuantity) AS Qty
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
    GROUP BY Trx.ItemID, Trx.StoreID
),
LastCost AS (
    SELECT Balance.ItemID, Balance.StoreID, Balance.Qty,
           (SELECT TOP 1 Trx.ItemCost FROM InvStoreTransaction AS Trx
            WHERE  Trx.ItemID = Balance.ItemID AND Trx.StoreID = Balance.StoreID
            ORDER BY Trx.DocumentDate DESC) AS Unit_Cost
    FROM   Balance
)
SELECT SUM(Qty * Unit_Cost)                              AS Value_All_Rows,
       SUM(CASE WHEN Qty > 0 THEN Qty * Unit_Cost END)   AS Value_Positive_Qty_Only
FROM   LastCost;


-- ============================================================================
-- Section L: Post-QA Quick Validation, QA - Company | 2026-11-25 | Build 1.2.508
-- ============================================================================

-- Test case: Post-QA happy path, Overview, Sales, WO Info and Cash of 25/11
-- Purpose  : L1: Today's invoices and returns (count, incl. VAT, excl. VAT, VAT) and every Work Order the WO Info tab lists today, with status and date.
-- Expected : UI 25/11 10:40: Invoices 1 (500.00), Refunds 500.00, Daily Sales 0.00, Net Sales 0.00; WO 202 Completed 25/11, WO 199 Pending 24/11, WO 197 Pending 23/11.
-- Status   : Written, Executed, Verified 25/11. Matches UI: invoice INV-TO_11000150 500.00 and return RTN-TO_11000025 500.00 (net 0.00, VAT 65.22 both ways); WO 202 Submitted 25/11, WO 199 New 24/11, WO 197 New 23/11
SELECT 'Invoice' AS Kind, InvoiceNumber AS Doc_No, InvoiceDate AS Doc_Date,
       InvoiceTotalAmount AS Incl_VAT, InvoiceBeforeTaxAmount AS Excl_VAT, InvoiceTaxAmount AS VAT, NULL AS WO_Status
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-25' AND InvoiceDate < '2026-11-26'
UNION ALL
SELECT 'Return', ReturnNumber, ReturnDate,
       -ReturnTotalAmount, -ReturnBeforeTaxAmount, -ReturnTaxAmount, NULL
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-25' AND ReturnDate < '2026-11-26'
UNION ALL
SELECT 'Work Order', WO.WorkOrderNumber, WO.WorkOrderDate,
       WO.WorkOrderTotalAmount, NULL, NULL, Status.DocumentStatusName
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
WHERE  WO.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  WO.WorkOrderDate >= '2026-11-23'
ORDER BY Kind, Doc_Date;

-- Test case: Post-QA happy path, Inventory tab and Overview inventory card of 25/11
-- Purpose  : L2: Same rules as H42 (Section I), run again on 25/11 after Bug 2286 was closed. Each stock category as distinct items and item x store rows, all branch stores and per store.
-- Expected : UI 25/11 10:41: All 367, In Stock 355, Low Stock 1, Out of Stock 11, Negative 0, Stock Value 86,674.00.
-- Status   : Written, Executed, Verified 25/11. MISMATCH: DB 363 items / 390 rows (In 357, Low 1, Out 11, Negative 21, all 21 in Branch - 2); UI 367 (355, 1, 11, Negative 0). UI store filter lists Branch - 2 with 4 items, DB has 27 pairs
WITH BranchStores AS (
    SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
),
Items AS (
    SELECT Item.ID AS ItemID
    FROM   InvItem AS Item
    WHERE  Item.DocumentStatusID = 2
      AND  Item.ItemTypeID IN (1, 3)
      AND (Item.IsApplyToAllBranch = 1
           OR EXISTS (SELECT 1 FROM InvItemBranch AS IB WHERE IB.ItemID = Item.ID AND IB.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'))
),
Pairs AS (
    SELECT Trx.ItemID, Trx.StoreID
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM BranchStores) AND Trx.ItemID IN (SELECT ItemID FROM Items)
    UNION
    SELECT Setup.ItemID, Setup.StoreID
    FROM   InvStoreItem AS Setup
    WHERE  Setup.StoreID IN (SELECT StoreID FROM BranchStores) AND Setup.ItemID IN (SELECT ItemID FROM Items)
),
Rows AS (
    SELECT Items.ItemID, Pairs.StoreID,
           ISNULL((SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx
                   WHERE Trx.ItemID = Items.ItemID AND Trx.StoreID = Pairs.StoreID), 0) AS Quantity,
           ISNULL((SELECT MAX(Setup.ItemMinQuantity) FROM InvStoreItem AS Setup
                   WHERE Setup.ItemID = Items.ItemID AND Setup.StoreID = Pairs.StoreID), 0) AS Min_Quantity
    FROM   Items
    LEFT JOIN Pairs ON Pairs.ItemID = Items.ItemID
),
Classified AS (
    SELECT Rows.ItemID, ISNULL(Store.StoreName, '(no store)') AS Store_Name,
           CASE WHEN Quantity < 0 THEN '4 Negative'
                WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity > 0 AND Quantity <= Min_Quantity THEN '2 Low Stock'
                ELSE '1 In Stock' END AS Category
    FROM   Rows
    LEFT JOIN InvStore AS Store ON Store.ID = Rows.StoreID
)
SELECT 'All stores' AS Scope, Category, COUNT(DISTINCT ItemID) AS Items, COUNT(*) AS Item_Store_Rows
FROM   Classified GROUP BY Category
UNION ALL
SELECT 'All stores', '0 All', COUNT(DISTINCT ItemID), COUNT(*) FROM Classified
UNION ALL
SELECT Store_Name, Category, COUNT(DISTINCT ItemID), COUNT(*)
FROM   Classified GROUP BY Store_Name, Category
UNION ALL
SELECT Store_Name, '0 All', COUNT(DISTINCT ItemID), COUNT(*)
FROM   Classified GROUP BY Store_Name
ORDER BY Scope, Category;

-- Test case: Bug 2294 retest, completing a Work Order from an earlier day keeps its creation date
-- Purpose  : L3: WO-TO_11000197 (created 23/11, completed 25/11 10:45 with Cash 25.00): its WorkOrderDate and status, and the invoice its completion created (through SalWorkOrderInvoice) with the invoice date.
-- Expected : WorkOrderDate stays 2026-11-23 08:56:23 (value in L1 before completion); status Submitted; one invoice of 25.00 dated 25/11.
-- Status   : Written, Executed, Verified 25/11. Passed: WO_Date 2026-11-23 08:56:23 unchanged, Submitted, invoice INV - TO_11000151 25.00 dated 2026-11-25 10:44:50
SELECT WO.WorkOrderNumber      AS WO_No,
       WO.WorkOrderDate        AS WO_Date,
       Status.DocumentStatusName AS WO_Status,
       WO.WorkOrderTotalAmount AS WO_Total,
       Inv.InvoiceNumber       AS Invoice_No,
       Inv.InvoiceDate         AS Invoice_Date,
       Inv.InvoiceTotalAmount  AS Invoice_Total
FROM   SalWorkOrder AS WO
JOIN   GenLkpDocumentStatus AS Status ON Status.ID = WO.DocumentStatusID
LEFT JOIN SalWorkOrderInvoice AS Link ON Link.WorkOrderID = WO.ID
LEFT JOIN SalInvoice AS Inv ON Inv.ID = Link.InvoiceID
WHERE  WO.WorkOrderNumber = 'WO - TO_11000197';

-- Test case: Post-QA Inventory, rows missing from the UI per branch store
-- Purpose  : L4: For each branch store, item rows that have stock movements (InvStoreTransaction) split by whether the item is still set up in the store (InvStoreItem), with their stock category. Checks if the UI shows only items set up in the store.
-- Expected : UI 25/11: Branch Store 363 items, Branch - 2 4 items.
-- Status   : Written, Executed 25/11: error Msg 144 (subquery in GROUP BY). Replaced by L4b
WITH Moved AS (
    SELECT Trx.StoreID, Trx.ItemID, SUM(Trx.BaseItemQuantity) AS Quantity
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
    GROUP BY Trx.StoreID, Trx.ItemID
)
SELECT Store.StoreName AS Store_Name,
       CASE WHEN EXISTS (SELECT 1 FROM InvStoreItem AS Setup WHERE Setup.StoreID = Moved.StoreID AND Setup.ItemID = Moved.ItemID)
            THEN 'Set up in store' ELSE 'NOT set up in store' END AS Store_Setup,
       CASE WHEN Quantity < 0 THEN 'Negative' WHEN Quantity = 0 THEN 'Zero' ELSE 'Positive' END AS Quantity_Sign,
       COUNT(*) AS Item_Rows
FROM   Moved
JOIN   InvStore AS Store ON Store.ID = Moved.StoreID
GROUP BY Store.StoreName,
         CASE WHEN EXISTS (SELECT 1 FROM InvStoreItem AS Setup WHERE Setup.StoreID = Moved.StoreID AND Setup.ItemID = Moved.ItemID)
              THEN 'Set up in store' ELSE 'NOT set up in store' END,
         CASE WHEN Quantity < 0 THEN 'Negative' WHEN Quantity = 0 THEN 'Zero' ELSE 'Positive' END
ORDER BY Store_Name, Store_Setup, Quantity_Sign;

-- Test case: Post-QA Inventory, rows missing from the UI per branch store (corrected)
-- Purpose  : L4b: Same as L4 with the setup flag computed in a CTE first. Per branch store: item rows with stock movements, split by store setup (InvStoreItem) and quantity sign.
-- Expected : UI 25/11: Branch Store 363 items, Branch - 2 4 items.
-- Status   : Written, Executed, Verified 25/11. Branch Store: 360 moved rows, none set up in InvStoreItem, yet shown in UI. Branch - 2: 33 moved rows = 22 Negative and 8 Positive NOT set up (hidden in UI) and 3 Positive set up (shown). UI shows Branch - 2 rows only when set up in the store
WITH Moved AS (
    SELECT Trx.StoreID, Trx.ItemID, SUM(Trx.BaseItemQuantity) AS Quantity
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
    GROUP BY Trx.StoreID, Trx.ItemID
),
Flagged AS (
    SELECT Moved.StoreID,
           CASE WHEN EXISTS (SELECT 1 FROM InvStoreItem AS Setup WHERE Setup.StoreID = Moved.StoreID AND Setup.ItemID = Moved.ItemID)
                THEN 'Set up in store' ELSE 'NOT set up in store' END AS Store_Setup,
           CASE WHEN Quantity < 0 THEN 'Negative' WHEN Quantity = 0 THEN 'Zero' ELSE 'Positive' END AS Quantity_Sign
    FROM   Moved
)
SELECT Store.StoreName AS Store_Name, Flagged.Store_Setup, Flagged.Quantity_Sign, COUNT(*) AS Item_Rows
FROM   Flagged
JOIN   InvStore AS Store ON Store.ID = Flagged.StoreID
GROUP BY Store.StoreName, Flagged.Store_Setup, Flagged.Quantity_Sign
ORDER BY Store_Name, Store_Setup, Quantity_Sign;



----------------------------------------------------------------------------------



-- ============================================================================
-- Section J: Executive Summary, the tables behind each line | 2026-11-24
-- Company : QA - Company (pick its database in SSMS, no prefix in the queries)
-- Branch  : Alshellah  = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
-- Day     : 24/11/2026 (change the two dates to check another day)
-- Each table is queried on its own. Run one query at a time (select it, F5).
-- Status  : Written 24/11
-- ============================================================================


-- ----------------------------------------------------------------------------
-- J1. GenBranch: the branch itself
-- Used by : every line (all figures are for this branch only)
-- Returns : one row, the branch name and ID that SalInvoice.BranchID and SalReturn.BranchID point to.
-- ----------------------------------------------------------------------------
SELECT *
FROM   GenBranch
WHERE  ID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817';


-- ----------------------------------------------------------------------------
-- J2. SalWorkingDay: the working days of the branch
-- Used by : every daily figure (an invoice belongs to one working day through SalInvoice.WorkingDayID)
-- Returns : the days opened on or after 23/11, with open and close time and opening cash.
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalWorkingDay
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  OpenDate >= '2026-11-23'
ORDER BY OpenDate;


-- ----------------------------------------------------------------------------
-- J3. SalInvoice: sales invoices of the day
-- Used by : Daily Sales (InvoiceTotalAmount), Daily Net Sales (InvoiceBeforeTaxAmount),
--           Output VAT (InvoiceTaxAmount), and the Net Sales part of Gross Profit and Gross Margin
-- Returns : one row per invoice of the branch on that day.
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'
ORDER BY InvoiceDate;


-- ----------------------------------------------------------------------------
-- J4. SalReturn: sales returns of the day
-- Used by : subtracted from Daily Sales (ReturnTotalAmount), Daily Net Sales (ReturnBeforeTaxAmount)
--           and Output VAT (ReturnTaxAmount)
-- Returns : one row per return of the branch on that day. InvoiceID is the original invoice
--           (logical link, no FK).
-- ----------------------------------------------------------------------------
SELECT *
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-24' AND ReturnDate < '2026-11-25'
ORDER BY ReturnDate;


-- ----------------------------------------------------------------------------
-- J5. GenLkpDocumentType: the document types
-- Used by : Gross Profit (to know which store movements are sales and which are returns)
-- Returns : every document type with its ID, to read InvStoreTransaction.DocumentTypeID.
-- ----------------------------------------------------------------------------
SELECT *
FROM   GenLkpDocumentType;


-- ----------------------------------------------------------------------------
-- J6. InvStoreTransaction: stock movements of the day
-- Used by : Gross Profit, the COGS part = BaseItemQuantity x ItemCost of sale and return movements
-- Returns : one row per item per document that moved stock on that day (sales, returns, purchases,
--           adjustments). DocumentID points to the document, DocumentTypeID to J5.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreTransaction
WHERE  DocumentDate >= '2026-11-24' AND DocumentDate < '2026-11-25'
and StoreID in ('621D731D-A397-43A7-AA4D-6DC8BE591DB7','F833CAAB-DC19-43E6-8C0E-F36B80763596')
ORDER BY DocumentDate;

select * from InvStore

-- ----------------------------------------------------------------------------
-- J7. InvStoreBranch: which stores belong to the branch
-- Used by : Inventory Value (only these stores are counted, KB item 14)
-- Returns : one row per store linked to the branch.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreBranch
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817';


-- ----------------------------------------------------------------------------
-- J8. InvStore: the stores
-- Used by : Inventory Value (store names behind J7)
-- Returns : the stores of the branch, with name and settings such as IsApplyToAllBranch.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStore
WHERE  ID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817');


-- ----------------------------------------------------------------------------
-- J9. InvItem: the items
-- Used by : Inventory Value (which items are stock items: ItemTypeID 1 Product, 3 Product Package;
--           services have no stock)
-- Returns : every submitted item (DocumentStatusID = 2) with its type.
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvItem
WHERE  DocumentStatusID = 2
ORDER BY ItemName;


-- ----------------------------------------------------------------------------
-- J10. InvStoreTransaction: all stock movements of the branch stores
-- Used by : Inventory Value. Current quantity = SUM(BaseItemQuantity) per item and store,
--           cost = ItemCost. The exact formula is still unknown (KB item 6), so compare with care.
-- Returns : every movement ever made in the branch stores (large result).
-- ----------------------------------------------------------------------------
SELECT *
FROM   InvStoreTransaction
WHERE  StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
ORDER BY ItemID, StoreID, DocumentDate;


-- ----------------------------------------------------------------------------
-- J11. ProInvoice: purchase invoices
-- Used by : Input VAT (tax of purchase invoices)
-- Returns : the purchase invoices. The date and tax column names are not verified yet, so the
--           query lists all rows; read the columns and filter by the day afterwards.
-- ----------------------------------------------------------------------------
SELECT *
FROM   ProInvoice;


-- ----------------------------------------------------------------------------
-- J12. Purchase return table: name not verified yet
-- Used by : Input VAT (tax of purchase returns, subtracted)
-- Returns : the tables whose name looks like a purchase return, to find the right one.
--           This is a lookup only; the table is not confirmed.
-- ----------------------------------------------------------------------------
SELECT name AS Table_Name
FROM   sys.tables
WHERE  name LIKE 'Pro%Return%'
ORDER BY name;


-- ============================================================================
-- Section K: Executive Summary, one query per calculation | 2026-11-24
-- Company : QA - Company   Branch: Alshellah   Day: 24/11/2026
-- To check another day, change the dates '2026-11-24' and '2026-11-25' in each query.
-- Run one query at a time (select it, F5).
-- Status  : Written 24/11
-- ============================================================================


-- ----------------------------------------------------------------------------
-- K1. Daily Sales, Daily Net Sales, Output VAT: invoice by invoice
-- Shows   : every invoice and every return of the day with its three amounts.
--           Returns are shown negative so the column totals in K2 are simple sums.
-- ----------------------------------------------------------------------------
SELECT 'Invoice'                  AS Document_Kind,
       InvoiceNumber              AS Document_No,
       InvoiceDate                AS Document_Date,
       InvoiceTotalAmount         AS Incl_VAT,
       InvoiceBeforeTaxAmount     AS Excl_VAT,
       InvoiceTaxAmount           AS VAT
FROM   SalInvoice
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'
UNION ALL
SELECT 'Return',
       ReturnNumber,
       ReturnDate,
       -ReturnTotalAmount,
       -ReturnBeforeTaxAmount,
       -ReturnTaxAmount
FROM   SalReturn
WHERE  BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  ReturnDate >= '2026-11-24' AND ReturnDate < '2026-11-25'
ORDER BY Document_Date;


-- ----------------------------------------------------------------------------
-- K2. Daily Sales, Daily Net Sales, Output VAT: totals
-- Formula : Daily Sales     = invoices Incl. VAT  - returns Incl. VAT
--           Daily Net Sales = invoices Excl. VAT  - returns Excl. VAT
--           Output VAT      = invoices VAT        - returns VAT
-- Compare : Daily Sales (Incl. VAT), Daily Net Sales (Excl. VAT), Output VAT on the screen.
-- ----------------------------------------------------------------------------
SELECT ISNULL((SELECT SUM(InvoiceTotalAmount)     FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnTotalAmount)      FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Daily_Sales_Incl_VAT,
       ISNULL((SELECT SUM(InvoiceBeforeTaxAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnBeforeTaxAmount)  FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Daily_Net_Sales_Excl_VAT,
       ISNULL((SELECT SUM(InvoiceTaxAmount)       FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
     - ISNULL((SELECT SUM(ReturnTaxAmount)        FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Output_VAT;


-- ----------------------------------------------------------------------------
-- K3. COGS: line by line
-- Shows   : every stock movement of today's invoices, with its document type, item, store,
--           base quantity, unit cost and line cost (base quantity x cost).
--           Return movements also carry the original invoice ID (KB section 5 item 3),
--           so they appear here with their own document type.
--           Service items have no stock movement, so they add no cost.
-- ----------------------------------------------------------------------------
SELECT Inv.InvoiceNumber                     AS Invoice_No,
       DocType.DocumentTypeName              AS Movement_Type,
       Item.ItemName                         AS Item_Name,
       Store.StoreName                       AS Store_Name,
       Trx.BaseItemQuantity                  AS Base_Qty,
       Trx.ItemCost                          AS Unit_Cost,
       Trx.BaseItemQuantity * Trx.ItemCost   AS Line_Cost
FROM   InvStoreTransaction AS Trx
JOIN   SalInvoice          AS Inv     ON Inv.ID     = Trx.DocumentID
JOIN   InvItem             AS Item    ON Item.ID    = Trx.ItemID
JOIN   InvStore            AS Store   ON Store.ID   = Trx.StoreID
JOIN   GenLkpDocumentType  AS DocType ON DocType.ID = Trx.DocumentTypeID
WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  Inv.InvoiceDate >= '2026-11-24' AND Inv.InvoiceDate < '2026-11-25'
ORDER BY Inv.InvoiceNumber, Item.ItemName;


-- ----------------------------------------------------------------------------
-- K4. Gross Profit and Gross Margin
-- Formula : COGS          = SUM(base quantity x unit cost) of K3   (same rule as H4, verified 22/11)
--           Gross Profit  = Daily Net Sales (K2) - COGS
--           Gross Margin  = Gross Profit / Daily Net Sales x 100   (0 when Net Sales is 0)
-- Compare : screen on 24/11: Net Sales 434.78, Gross Profit 379.78, Gross Margin 87.35% (so COGS 55.00).
-- ----------------------------------------------------------------------------
WITH NetSales AS (
    SELECT ISNULL((SELECT SUM(InvoiceBeforeTaxAmount) FROM SalInvoice WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND InvoiceDate >= '2026-11-24' AND InvoiceDate < '2026-11-25'), 0)
         - ISNULL((SELECT SUM(ReturnBeforeTaxAmount)  FROM SalReturn  WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND ReturnDate  >= '2026-11-24' AND ReturnDate  < '2026-11-25'), 0) AS Amount
),
Cogs AS (
    SELECT ISNULL(SUM(Trx.BaseItemQuantity * Trx.ItemCost), 0) AS Amount
    FROM   InvStoreTransaction AS Trx
    JOIN   SalInvoice          AS Inv ON Inv.ID = Trx.DocumentID
    WHERE  Inv.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
      AND  Inv.InvoiceDate >= '2026-11-24' AND Inv.InvoiceDate < '2026-11-25'
)
SELECT NetSales.Amount                                   AS Daily_Net_Sales,
       Cogs.Amount                                       AS COGS,
       NetSales.Amount - Cogs.Amount                     AS Gross_Profit,
       CASE WHEN NetSales.Amount = 0 THEN 0
            ELSE ROUND((NetSales.Amount - Cogs.Amount) * 100.0 / NetSales.Amount, 2) END AS Gross_Margin_Pct
FROM   NetSales, Cogs;


-- ----------------------------------------------------------------------------
-- K5. Input VAT: columns of the purchase tables first
-- Formula : Input VAT = VAT of purchase invoices - VAT of purchase returns (story rule).
-- Shows   : the column names of every Pro... table, so the date and tax columns can be chosen.
--           The final Input VAT query is written after these names are read (no guessed names).
-- ----------------------------------------------------------------------------
SELECT TABLE_NAME  AS Table_Name,
       COLUMN_NAME AS Column_Name,
       DATA_TYPE   AS Data_Type
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME LIKE 'Pro%'
  AND (COLUMN_NAME LIKE '%Date%' OR COLUMN_NAME LIKE '%Tax%' OR COLUMN_NAME LIKE '%Branch%' OR COLUMN_NAME LIKE '%Number%')
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ----------------------------------------------------------------------------
-- K6. Net VAT Payable
-- Formula : Output VAT (K2) - Input VAT (K5).
--           Today Input VAT is 0.00 on the screen, so Net VAT Payable = Output VAT.
--           Not repeated as its own query until the Input VAT query exists.
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
-- K7. Inventory Value: candidate formula, NOT confirmed
-- Formula : SUM over branch stores of (current base quantity x item cost of its latest movement).
--           The real formula is unknown (KB section 5 item 6). Use this to compare only; a
--           mismatch is expected until development gives the rule.
-- Compare : screen on 24/11: 95,410.00.
-- ----------------------------------------------------------------------------
WITH Balance AS (
    SELECT Trx.ItemID, Trx.StoreID, SUM(Trx.BaseItemQuantity) AS Qty
    FROM   InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817')
    GROUP BY Trx.ItemID, Trx.StoreID
),
LastCost AS (
    SELECT Balance.ItemID, Balance.StoreID, Balance.Qty,
           (SELECT TOP 1 Trx.ItemCost FROM InvStoreTransaction AS Trx
            WHERE  Trx.ItemID = Balance.ItemID AND Trx.StoreID = Balance.StoreID
            ORDER BY Trx.DocumentDate DESC) AS Unit_Cost
    FROM   Balance
)
SELECT SUM(Qty * Unit_Cost)                              AS Value_All_Rows,
       SUM(CASE WHEN Qty > 0 THEN Qty * Unit_Cost END)   AS Value_Positive_Qty_Only
FROM   LastCost;

-- Test case: Expected Cash Balance check 26/11 (user question)
-- Purpose  : L5: where 16,737.80 comes from. Day TO_11000037 opened 26/11 09:02 with 500.00 and no sales; compare with branch totals of all days.
-- Expected : Expected Cash = Opening 500.00 + today's cash sales - today's cash refunds = 500.00.
-- Status   : Executed 26/11 09:15 (42 rows: all-days cash received 39,491.93, cash refunded 16,255.90, openings 6,121.00, deposits 2,707.80; no simple sum gives 16,737.80, see L5b).
SELECT '1 Day ' + CONVERT(varchar(16), WorkDay.OpenDate, 120) AS Check_Name, WorkDay.OpenBalanceCashAmount AS Amount,
       WorkDay.CloseSystemCashAmount AS Close_System, WorkDay.CloseLeftCashAmount AS Close_Left
FROM   SalWorkingDay AS WorkDay WHERE WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
UNION ALL
SELECT '2 All days: cash received', SUM(Pay.PaymentAmount), NULL, NULL
FROM   SalInvoiceReceiptPayment AS Pay
JOIN   SalInvoiceReceipt AS Receipt ON Receipt.ID = Pay.InvoiceReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Method.PaymentMethodName = 'Cash'
UNION ALL
SELECT '3 All days: cash refunded', SUM(Pay.PaymentAmount), NULL, NULL
FROM   SalReturnReceiptPayment AS Pay
JOIN   SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
JOIN   GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
WHERE  Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Method.PaymentMethodName = 'Cash'
UNION ALL
SELECT '4 All days: opening balances', SUM(OpenBalanceCashAmount), SUM(CloseSystemCashAmount), SUM(CloseLeftCashAmount)
FROM   SalWorkingDay WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
UNION ALL
SELECT '5 All days: cash deposits', SUM(DayLink.DepositAmount), NULL, NULL
FROM   SalBankDepositWorkingDay AS DayLink
JOIN   SalWorkingDay AS WorkDay ON WorkDay.ID = DayLink.WorkingDayID
WHERE  WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
ORDER BY Check_Name;

-- Test case: Expected Cash Balance check 26/11 (user question)
-- Purpose  : L5b: cash in and out per working day of the branch (by document date between day openings), with a running total from the newest day back, to find which days make 16,737.80.
-- Expected : Only today's day (500.00 opening, no cash movement) should count.
-- Status   : Executed 26/11 09:20 (38 days; no window of days gives 16,737.80; day 25/11 TO_11000036 still IsClosed = 0 while 26/11 is open; 14 earlier days never closed). Local app DB has the same totals.
WITH Days AS (
    SELECT WorkDay.OpenDate, WorkDay.OpenBalanceCashAmount AS Opening, WorkDay.IsClosed,
           LEAD(WorkDay.OpenDate, 1, '2100-01-01') OVER (ORDER BY WorkDay.OpenDate) AS Next_Open
    FROM   SalWorkingDay AS WorkDay WHERE WorkDay.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
),
Flow AS (
    SELECT Days.OpenDate, Days.Opening, Days.IsClosed,
           ISNULL((SELECT SUM(Pay.PaymentAmount) FROM SalInvoiceReceiptPayment AS Pay
                   JOIN SalInvoiceReceipt AS Receipt ON Receipt.ID = Pay.InvoiceReceiptID
                   JOIN GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
                   WHERE Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Method.PaymentMethodName = 'Cash'
                     AND Receipt.InvoiceReceiptDate >= Days.OpenDate AND Receipt.InvoiceReceiptDate < Days.Next_Open), 0) AS Cash_In,
           ISNULL((SELECT SUM(Pay.PaymentAmount) FROM SalReturnReceiptPayment AS Pay
                   JOIN SalReturnReceipt AS Receipt ON Receipt.ID = Pay.ReturnReceiptID
                   JOIN GenLkpPaymentMethod AS Method ON Method.ID = Pay.PaymentMethodID
                   WHERE Receipt.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND Method.PaymentMethodName = 'Cash'
                     AND Receipt.ReturnReceiptDate >= Days.OpenDate AND Receipt.ReturnReceiptDate < Days.Next_Open), 0) AS Cash_Out
    FROM   Days
)
SELECT CONVERT(varchar(16), OpenDate, 120) AS Day_Opened, IsClosed AS Is_Closed, Opening, Cash_In, Cash_Out,
       Cash_In - Cash_Out AS Net_Cash,
       SUM(Cash_In - Cash_Out) OVER (ORDER BY OpenDate DESC ROWS UNBOUNDED PRECEDING) AS Net_From_Newest
FROM   Flow
ORDER BY OpenDate DESC;
