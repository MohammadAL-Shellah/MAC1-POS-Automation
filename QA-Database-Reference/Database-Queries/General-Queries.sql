-- =====================================================================
-- General queries (not tied to one story)
-- Environment: QA - Company database on qadb.minerets.com,55009, ReadUser (SELECT only)
-- Use: any lookup that is not part of a story test (schema checks, finding a document, IDs, setup data).
-- Every query is added at the end with a comment: date, purpose, and the story or question it served.
-- Branch Alshellah = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
-- =====================================================================

-- Format of each query: see README.md, 'Query block format'. Use '-- For :' instead of '-- Test case:'.

-- =====================================================================
-- Section: MAC1 local Sync storage (SQLite)   |   2026-11-22   |   Build 1.2.498 (About)
-- Database: copy of %LOCALAPPDATA%\Minerets\MineretsMacOne\Data\<id>.db (SQLite, not SSMS)
-- =====================================================================

-- For : G-L1 Work Order is saved as one JSON in the sync file
-- Purpose  : Structure of the local Sync and Work Order tables.
-- Expected : Schema lookup, no expected value.
-- Status   : Executed (schema read, latest DB)
SELECT name, sql FROM sqlite_master
WHERE type = 'table' AND (name LIKE 'Sync%' OR name LIKE 'SalWorkOrder%');

-- For : G-L2 Work Order is saved as one JSON in the sync file
-- Purpose  : Upload rows by status, with the first bytes of the payload to identify its format.
-- Expected : Lookup, no expected value.
-- Status   : Executed (SyncUpload empty in all 3 copies, no rows returned)
SELECT u.UploadStatusID, s.SyncUploadStatusName, COUNT(*) AS UploadRows,
       CAST(MIN(u.ModifiedOn) AS TEXT) AS FirstTicks, CAST(MAX(u.ModifiedOn) AS TEXT) AS LastTicks,
       MAX(length(u.UploadData)) AS MaxBytes, hex(substr(u.UploadData, 1, 48)) AS FirstBytes
FROM SyncUpload u
LEFT JOIN SyncLkpUploadStatus s ON s.ID = u.UploadStatusID
GROUP BY u.UploadStatusID;

-- For : G-L3 Work Order is saved as one JSON in the sync file
-- Purpose  : Number and date range of local Work Orders.
-- Expected : Lookup, no expected value.
-- Status   : Executed (184, 0 and 13 Work Orders)
SELECT COUNT(*) AS WorkOrders, datetime((MIN(WorkOrderDate) - 621355968000000000) / 10000000, 'unixepoch') AS FirstDate,
       datetime((MAX(ModifiedOn) - 621355968000000000) / 10000000, 'unixepoch') AS LastModified
FROM SalWorkOrder;

-- For : G-L4 Work Order is saved as one JSON in the sync file
-- Purpose  : Confirm whether any upload or delete rows are waiting.
-- Expected : Lookup, no expected value.
-- Status   : Executed (UploadRows 0 in all 3 copies)
SELECT (SELECT COUNT(*) FROM SyncUpload) AS UploadRows,
       (SELECT COUNT(*) FROM SyncDelete) AS DeleteRows,
       (SELECT freelist_count FROM pragma_freelist_count) AS FreePages,
       (SELECT journal_mode FROM pragma_journal_mode) AS JournalMode;

-- For : G-L5 Work Order is saved as one JSON in the sync file
-- Purpose  : All local rows of WO-TO_11000184 with save time, to compare with its recovered JSON payload.
-- Expected : Rows changed at 09:46:21 are in the JSON, deleted discount rows are gone.
-- Status   : Executed (header and service at 09:46:21 match the JSON, item at 09:46:10 is not in it)
WITH w AS (SELECT '113b1d33-6895-4cb2-9c60-c3a9fa1f42dd' AS ID),
r AS (
  SELECT 'Header' AS Part, ID, ModifiedOn, WorkOrderTotalAmount AS Amount, WorkOrderNumber AS Info FROM SalWorkOrder WHERE ID = (SELECT ID FROM w)
  UNION ALL SELECT 'Item', ID, ModifiedOn, ItemTotalAmount, ItemID FROM SalWorkOrderItem WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'ItemTax', ID, ModifiedOn, TaxAmount, TaxID FROM SalWorkOrderItemTax WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'ItemDiscount', ID, ModifiedOn, DiscountAmount, DiscountID FROM SalWorkOrderItemDiscount WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'ItemBatch', ID, ModifiedOn, ItemQuantity, ItemBatchID FROM SalWorkOrderItemBatch WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'Discount', ID, ModifiedOn, DiscountAmount, DiscountID FROM SalWorkOrderDiscount WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'Service', ID, ModifiedOn, NextServiceMiles, ItemID FROM SalWorkOrderService WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'PackageItem', ID, ModifiedOn, ItemTotalAmount, ItemID FROM SalWorkOrderServicePackageItem WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'PackageService', ID, ModifiedOn, ItemTotalAmount, ItemID FROM SalWorkOrderServicePackageService WHERE WorkOrderID = (SELECT ID FROM w)
  UNION ALL SELECT 'PackageServiceItem', ID, ModifiedOn, ItemTotalAmount, ItemID FROM SalWorkOrderServicePackageServiceItem WHERE WorkOrderID = (SELECT ID FROM w)
)
SELECT Part, ID, Amount, Info, datetime((ModifiedOn - 621355968000000000) / 10000000, 'unixepoch') AS ModifiedAt FROM r;

-- For : G-L6 Work Order is saved as one JSON in the sync file
-- Purpose  : Live read only capture of upload rows, polled during each save, before the app deletes them.
-- Expected : One row per save, whose JSON holds the full Work Order (rule given by Mohammad 2026-11-22).
-- Status   : Executed (8 saves, one row each, 7 full, note save partial: Failed)
SELECT ID, UploadIndex, UploadStatusID, UploadError, UploadData, CAST(ModifiedOn AS TEXT) AS Ticks
FROM SyncUpload;

-- For : G-S1 Work Order is saved as one JSON in the sync file (SQL Server, run in SSMS)
-- Purpose  : WO-TO_11000185 on the server after upload, to compare with the screen and the last JSON.
-- Expected : One header with 180.00, discount 17.39, tax 23.48 and the note, one item qty 2, no service, one discount.
-- Status   : Verified (server matches screen and last JSON)
SELECT w.WorkOrderNumber, w.WorkOrderTotalAmount AS Total, w.WorkOrderDiscountAmount AS Disc,
       w.WorkOrderTaxAmount AS Tax, w.WorkOrderNote AS Note,
       (SELECT COUNT(*) FROM SalWorkOrder x WHERE x.WorkOrderNumber = w.WorkOrderNumber AND x.BranchID = w.BranchID) AS Headers,
       (SELECT COUNT(*) FROM SalWorkOrderItem i WHERE i.WorkOrderID = w.ID) AS Items,
       (SELECT SUM(i.ItemQuantity) FROM SalWorkOrderItem i WHERE i.WorkOrderID = w.ID) AS Qty,
       (SELECT COUNT(*) FROM SalWorkOrderItemTax t WHERE t.WorkOrderID = w.ID) AS Taxes,
       (SELECT COUNT(*) FROM SalWorkOrderService s WHERE s.WorkOrderID = w.ID) AS Svc,
       (SELECT COUNT(*) FROM SalWorkOrderDiscount d WHERE d.WorkOrderID = w.ID) AS Discs,
       (SELECT COUNT(*) FROM InvStockOut o WHERE o.RefDocumentID = w.ID) AS StockOut,
       (SELECT COUNT(*) FROM InvStockOutItem oi JOIN InvStockOut o ON o.ID = oi.StockOutID WHERE o.RefDocumentID = w.ID) AS StockLines,
       (SELECT COUNT(*) FROM InvStoreTransaction st WHERE st.DocumentID = w.ID) AS StoreTx
FROM SalWorkOrder w
WHERE w.ID = '573db207-deef-4b60-84bd-f7106773f4f7';

-- For : G-L7 Work Order is saved as one JSON in the sync file
-- Purpose  : Whether Car Wash is a service, to judge the stock out without lines.
-- Expected : A service has an InvItemService row and moves no stock.
-- Status   : Executed (Car Wash is a service)
SELECT i.ID, i.ItemTypeID, (SELECT COUNT(*) FROM InvItemService s WHERE s.ID = i.ID) AS IsService
FROM InvItem i
WHERE i.ID = '03005c7f-591b-43cc-992f-061eb3481fee';

select * from syncupload where TerminalID = 'B966DDAA-3A3F-485E-A7CF-45F6662E2783' order by ModifiedOn desc
select * from GenTerminal where BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
select * from SalWorkOrderItem where WorkOrderID = '43A6FDE2-38B6-4446-93B6-799A2A39ECDD' order by ModifiedOn desc

-- For      : G-Q1 Empty Stock Out headers (question e-20261120-009), QA - Company, branch Alshellah
-- Purpose  : Stock Out documents of November with no lines, with the document they belong to (Work Order or invoice) and its status.
-- Expected : Shows which service-only or voided Work Orders created a Stock Out header without lines. Second part: how many Stock Outs have lines and how many are empty.
-- Status   : Executed 23/11, second part FAILED (Msg 144: subquery in GROUP BY). Replaced by G-Q1b.
SELECT StockOut.StockOutNumber                      AS Stock_Out_No,
       CONVERT(varchar(19), StockOut.StockOutDate, 120) AS Stock_Out_Date,
       COALESCE(WO.WorkOrderNumber, Inv.InvoiceNumber, '?') AS Source_Document,
       CASE WHEN WO.ID IS NOT NULL THEN 'Work Order' WHEN Inv.ID IS NOT NULL THEN 'Invoice' ELSE 'Other' END AS Source_Type,
       Status.DocumentStatusName                    AS Source_Status
FROM   InvStockOut AS StockOut
LEFT JOIN SalWorkOrder AS WO  ON WO.ID  = StockOut.RefDocumentID
LEFT JOIN SalInvoice   AS Inv ON Inv.ID = StockOut.RefDocumentID
LEFT JOIN GenLkpDocumentStatus AS Status ON Status.ID = COALESCE(WO.DocumentStatusID, Inv.DocumentStatusID)
WHERE  StockOut.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
  AND  StockOut.StockOutDate >= '2026-11-01'
  AND  NOT EXISTS (SELECT 1 FROM InvStockOutItem AS Line WHERE Line.StockOutID = StockOut.ID)
ORDER BY StockOut.StockOutDate;

SELECT CASE WHEN EXISTS (SELECT 1 FROM InvStockOutItem AS Line WHERE Line.StockOutID = StockOut.ID)
            THEN 'With lines' ELSE 'Empty (0 lines)' END AS Stock_Out_Kind,
       COUNT(*) AS Documents
FROM   InvStockOut AS StockOut
WHERE  StockOut.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOut.StockOutDate >= '2026-11-01'
GROUP BY CASE WHEN EXISTS (SELECT 1 FROM InvStockOutItem AS Line WHERE Line.StockOutID = StockOut.ID)
              THEN 'With lines' ELSE 'Empty (0 lines)' END;

-- For      : G-Q2 Inventory counts per item x store (answer to e-20261115-154 and e-20261120-075), QA - Company, branch Alshellah
-- Purpose  : Every item and store pair of the two branch stores (a stock movement or a store setup row), its quantity, minimum and category, counted per category.
-- Expected : Compare with the Inventory tab: All 363, In Stock 353, Low Stock 1, Out of Stock 12, Negative 22 (23/11). Rule used: below 0 Negative, 0 Out of Stock, above 0 and up to the minimum Low Stock, otherwise In Stock. Only submitted items (DocumentStatusID 2).
-- Status   : Written 23/11
WITH Pairs AS (
    SELECT ItemID, StoreID FROM InvStoreTransaction WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    UNION
    SELECT ItemID, StoreID FROM InvStoreItem        WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
),
Stock AS (
    SELECT Pairs.ItemID, Pairs.StoreID,
           ISNULL((SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx
                   WHERE Trx.ItemID = Pairs.ItemID AND Trx.StoreID = Pairs.StoreID), 0) AS Quantity,
           Setup.ItemMinQuantity AS Min_Quantity
    FROM   Pairs
    JOIN   InvItem AS Item ON Item.ID = Pairs.ItemID AND Item.DocumentStatusID = 2
    LEFT JOIN InvStoreItem AS Setup ON Setup.ItemID = Pairs.ItemID AND Setup.StoreID = Pairs.StoreID
)
SELECT CASE WHEN Quantity < 0 THEN '4 Negative'
            WHEN Quantity = 0 THEN '3 Out of Stock'
            WHEN Min_Quantity IS NOT NULL AND Quantity <= Min_Quantity THEN '2 Low Stock'
            ELSE '1 In Stock' END AS Category,
       COUNT(*) AS Item_Store_Pairs
FROM   Stock
GROUP BY CASE WHEN Quantity < 0 THEN '4 Negative'
              WHEN Quantity = 0 THEN '3 Out of Stock'
              WHEN Min_Quantity IS NOT NULL AND Quantity <= Min_Quantity THEN '2 Low Stock'
              ELSE '1 In Stock' END
UNION ALL
SELECT '0 All pairs', COUNT(*) FROM Stock
ORDER BY Category;

-- For      : G-Q1b Count of Stock Outs with and without lines (G-Q1 second part, corrected)
-- Purpose  : How many Stock Out documents of November in branch Alshellah have lines and how many are empty.
-- Expected : Two rows: With lines and Empty (0 lines).
-- Status   : Written 23/11
SELECT Docs.Stock_Out_Kind, COUNT(*) AS Documents
FROM  (SELECT CASE WHEN (SELECT COUNT(*) FROM InvStockOutItem AS Line WHERE Line.StockOutID = StockOut.ID) > 0
                   THEN 'With lines' ELSE 'Empty (0 lines)' END AS Stock_Out_Kind
       FROM   InvStockOut AS StockOut
       WHERE  StockOut.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOut.StockOutDate >= '2026-11-01') AS Docs
GROUP BY Docs.Stock_Out_Kind;

-- For      : G-T1 Stock Out headers (simple, one table)
-- Purpose  : All Stock Out documents of branch Alshellah from 22/11, every column.
-- Expected : RefDocumentID shows the Work Order or invoice each one belongs to.
-- Status   : Written 23/11
SELECT * FROM InvStockOut WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOutDate >= '2026-11-22' ORDER BY StockOutDate;

-- For      : G-T2 Stock Out lines (simple, one table)
-- Purpose  : All lines of the Stock Outs in G-T1, every column. A Stock Out with no row here is empty.
-- Expected : Compare StockOutID with the ID column of G-T1.
-- Status   : Written 23/11
SELECT * FROM InvStockOutItem WHERE StockOutID IN (SELECT ID FROM InvStockOut WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND StockOutDate >= '2026-11-22');

-- For      : G-T3 Work Orders (simple, one table)
-- Purpose  : All Work Orders of branch Alshellah from 22/11, every column.
-- Expected : Their ID matches RefDocumentID in G-T1.
-- Status   : Written 23/11
SELECT * FROM SalWorkOrder WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND WorkOrderDate >= '2026-11-22' ORDER BY WorkOrderDate;

-- For      : G-T4 Store setup per item (simple, one table)
-- Purpose  : All item rows of the two branch stores with min and max, every column.
-- Expected : One row per item x store that has a setup.
-- Status   : Written 23/11
SELECT * FROM InvStoreItem WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596');

-- For      : G-T5 Stock per item x store (one table, summed)
-- Purpose  : Quantity of every item in each of the two branch stores, from the store transactions.
-- Expected : One row per item x store; Quantity below 0 Negative, 0 Out of Stock.
-- Status   : Written 23/11
SELECT ItemID, StoreID, SUM(BaseItemQuantity) AS Quantity, COUNT(*) AS Movements FROM InvStoreTransaction WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596') GROUP BY ItemID, StoreID ORDER BY Quantity;

-- For      : G-T6 Inventory counts per item x store, split by item status and item kind
-- Purpose  : Every item x store pair of the two branch stores (movement or setup), grouped by item status (Submitted or other), item kind (service or stock item) and stock category.
-- Expected : Find which group makes the difference between the database pairs and the Inventory tab: All 363, In Stock 353, Low 1, Out of Stock 12, Negative 22.
-- Status   : Written 23/11
WITH Pairs AS (
    SELECT ItemID, StoreID FROM InvStoreTransaction WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
    UNION
    SELECT ItemID, StoreID FROM InvStoreItem WHERE StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
),
Stock AS (
    SELECT Pairs.ItemID,
           CASE WHEN Item.DocumentStatusID = 2 THEN 'Submitted' ELSE 'Not submitted' END AS Item_Status,
           CASE WHEN EXISTS (SELECT 1 FROM InvItemService AS Svc WHERE Svc.ID = Pairs.ItemID) THEN 'Service' ELSE 'Stock item' END AS Item_Kind,
           ISNULL((SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx WHERE Trx.ItemID = Pairs.ItemID AND Trx.StoreID = Pairs.StoreID), 0) AS Quantity,
           Setup.ItemMinQuantity AS Min_Quantity
    FROM   Pairs
    JOIN   InvItem AS Item ON Item.ID = Pairs.ItemID
    LEFT JOIN InvStoreItem AS Setup ON Setup.ItemID = Pairs.ItemID AND Setup.StoreID = Pairs.StoreID
),
Classified AS (
    SELECT Item_Status, Item_Kind,
           CASE WHEN Quantity < 0 THEN '4 Negative' WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity IS NOT NULL AND Quantity <= Min_Quantity THEN '2 Low Stock' ELSE '1 In Stock' END AS Category
    FROM Stock
)
SELECT Item_Status, Item_Kind, Category, COUNT(*) AS Pairs
FROM   Classified
GROUP BY Item_Status, Item_Kind, Category
ORDER BY Item_Status DESC, Item_Kind, Category



-- For      : G-T7 Columns of the stock in and stock out tables
-- Purpose  : Column names of InvStockIn, InvStockInItem, InvStockOut, InvStockOutItem and InvItemUnit, to write G-T6 from these tables.
-- Expected : Store, item or item unit, and quantity columns.
-- Status   : Written 23/11
SELECT TABLE_NAME, STRING_AGG(COLUMN_NAME, ', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION) AS Columns
FROM   INFORMATION_SCHEMA.COLUMNS
WHERE  TABLE_NAME IN ('InvStockIn', 'InvStockInItem', 'InvStockOut', 'InvStockOutItem', 'InvItemUnit')
GROUP BY TABLE_NAME;

-- For      : G-T8 Inventory counts per item x store from Stock In and Stock Out documents
-- Purpose  : Same as G-T6, but the quantity of each item x store = submitted Stock In lines - submitted Stock Out lines (base quantity), instead of InvStoreTransaction.
-- Expected : Compare with G-T6 and with the Inventory tab: All 363, In Stock 353, Low 1, Out of Stock 12, Negative 22.
-- Status   : Written 23/11
WITH Moves AS (
    SELECT Unit.ItemID, Doc.StoreID, Line.BaseItemQuantity AS Quantity
    FROM   InvStockInItem AS Line
    JOIN   InvStockIn     AS Doc  ON Doc.ID  = Line.StockInID
    JOIN   InvItemUnit    AS Unit ON Unit.ID = Line.ItemUnitID
    WHERE  Doc.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596') AND Doc.DocumentStatusID = 2
    UNION ALL
    SELECT Unit.ItemID, Doc.StoreID, -Line.BaseItemQuantity
    FROM   InvStockOutItem AS Line
    JOIN   InvStockOut     AS Doc  ON Doc.ID  = Line.StockOutID
    JOIN   InvItemUnit     AS Unit ON Unit.ID = Line.ItemUnitID
    WHERE  Doc.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596') AND Doc.DocumentStatusID = 2
),
Stock AS (
    SELECT Moves.ItemID, Moves.StoreID, SUM(Moves.Quantity) AS Quantity,
           CASE WHEN Item.DocumentStatusID = 2 THEN 'Submitted' ELSE 'Not submitted' END AS Item_Status,
           CASE WHEN EXISTS (SELECT 1 FROM InvItemService AS Svc WHERE Svc.ID = Moves.ItemID) THEN 'Service' ELSE 'Stock item' END AS Item_Kind,
           MAX(Setup.ItemMinQuantity) AS Min_Quantity
    FROM   Moves
    JOIN   InvItem AS Item ON Item.ID = Moves.ItemID
    LEFT JOIN InvStoreItem AS Setup ON Setup.ItemID = Moves.ItemID AND Setup.StoreID = Moves.StoreID
    GROUP BY Moves.ItemID, Moves.StoreID, Item.DocumentStatusID
),
Classified AS (
    SELECT Item_Status, Item_Kind,
           CASE WHEN Quantity < 0 THEN '4 Negative' WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity IS NOT NULL AND Quantity <= Min_Quantity THEN '2 Low Stock' ELSE '1 In Stock' END AS Category
    FROM Stock
)
SELECT Item_Status, Item_Kind, Category, COUNT(*) AS Pairs
FROM   Classified
GROUP BY Item_Status, Item_Kind, Category
ORDER BY Item_Status DESC, Item_Kind, Category;


-- For      : G-T9 Items with no stock in (no opening balance, no adjustment, no purchase)
-- Purpose  : First result: source types of submitted Stock In documents in the two branch stores, with a sample number. Second result: submitted stock items x store that have Stock Out lines but no Stock In line at all.
-- Expected : The user expects 3 items with no opening balance or adjustment.
-- Status   : Written 23/11
SELECT Doc.RefDocumentTypeID, COUNT(DISTINCT Doc.ID) AS Stock_In_Documents, MIN(Doc.StockInNumber) AS Sample_No
FROM   InvStockIn AS Doc
WHERE  Doc.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596') AND Doc.DocumentStatusID = 2
GROUP BY Doc.RefDocumentTypeID;

SELECT Item.ItemName, Item.ItemNumber, Store.StoreName,
       -SUM(Line.BaseItemQuantity) AS Quantity, COUNT(*) AS Stock_Out_Lines
FROM   InvStockOutItem AS Line
JOIN   InvStockOut     AS Doc   ON Doc.ID   = Line.StockOutID
JOIN   InvItemUnit     AS Unit  ON Unit.ID  = Line.ItemUnitID
JOIN   InvItem         AS Item  ON Item.ID  = Unit.ItemID AND Item.DocumentStatusID = 2
JOIN   InvStore        AS Store ON Store.ID = Doc.StoreID
WHERE  Doc.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596') AND Doc.DocumentStatusID = 2
  AND  NOT EXISTS (SELECT 1 FROM InvItemService AS Svc WHERE Svc.ID = Item.ID)
  AND  NOT EXISTS (SELECT 1
                   FROM   InvStockInItem AS InLine
                   JOIN   InvStockIn     AS InDoc  ON InDoc.ID  = InLine.StockInID
                   JOIN   InvItemUnit    AS InUnit ON InUnit.ID = InLine.ItemUnitID
                   WHERE  InUnit.ItemID = Item.ID AND InDoc.StoreID = Doc.StoreID AND InDoc.DocumentStatusID = 2)
GROUP BY Item.ItemName, Item.ItemNumber, Store.StoreName
ORDER BY Item.ItemName;

-- For      : G-T10 Inventory counts with the developer rules (branch Alshellah)
-- Purpose  : Count items the way the dashboard does: submitted Product and ProductPackage items of the branch, every item x branch store pair (movement or InvStoreItem row), items with no pair count as Out of Stock, each category counts distinct items.
-- Expected : Same as the Inventory tab of 23/11: All 363, In Stock 353, Low Stock 1, Out of Stock 12, Negative 22.
-- Status   : Written 23/11
WITH BranchStores AS (
    SELECT ID AS StoreID FROM InvStore WHERE IsApplyToAllBranch = 1
    UNION
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
    SELECT ItemID,
           CASE WHEN Quantity < 0 THEN '4 Negative'
                WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity > 0 AND Quantity <= Min_Quantity THEN '2 Low Stock'
                ELSE '1 In Stock' END AS Category
    FROM   Rows
)
SELECT Category, COUNT(DISTINCT ItemID) AS Items, COUNT(*) AS Item_Store_Rows
FROM   Classified
GROUP BY Category
UNION ALL
SELECT '0 All', COUNT(DISTINCT ItemID), COUNT(*) FROM Classified
ORDER BY Category;

-- For      : G-T11 Negative and Out of Stock items by name (developer rules, branch Alshellah)
-- Purpose  : The item x store rows behind the Negative (29) and Out of Stock (11) counts of G-T10, with item name, number, store, quantity, to compare row by row with the Inventory tab (Negative 22, Out of Stock 12).
-- Expected : Shows which 7 negative items and which out of stock item differ from the screen.
-- Status   : Written 23/11
WITH BranchStores AS (
    SELECT ID AS StoreID FROM InvStore WHERE IsApplyToAllBranch = 1
    UNION
    SELECT StoreID FROM InvStoreBranch WHERE BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'
),
Items AS (
    SELECT Item.ID AS ItemID FROM InvItem AS Item
    WHERE  Item.DocumentStatusID = 2 AND Item.ItemTypeID IN (1, 3)
      AND (Item.IsApplyToAllBranch = 1 OR EXISTS (SELECT 1 FROM InvItemBranch AS IB WHERE IB.ItemID = Item.ID AND IB.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817'))
),
Pairs AS (
    SELECT Trx.ItemID, Trx.StoreID FROM InvStoreTransaction AS Trx
    WHERE  Trx.StoreID IN (SELECT StoreID FROM BranchStores) AND Trx.ItemID IN (SELECT ItemID FROM Items)
    UNION
    SELECT Setup.ItemID, Setup.StoreID FROM InvStoreItem AS Setup
    WHERE  Setup.StoreID IN (SELECT StoreID FROM BranchStores) AND Setup.ItemID IN (SELECT ItemID FROM Items)
),
Rows AS (
    SELECT Items.ItemID, Pairs.StoreID,
           ISNULL((SELECT SUM(Trx.BaseItemQuantity) FROM InvStoreTransaction AS Trx WHERE Trx.ItemID = Items.ItemID AND Trx.StoreID = Pairs.StoreID), 0) AS Quantity
    FROM   Items LEFT JOIN Pairs ON Pairs.ItemID = Items.ItemID
)
SELECT CASE WHEN Rows.Quantity < 0 THEN 'Negative' ELSE 'Out of Stock' END AS Category,
       Item.ItemName, Item.ItemNumber, ISNULL(Store.StoreName, '-- no store') AS Store_Name,
       CASE WHEN EXISTS (SELECT 1 FROM InvStoreBranch AS SB WHERE SB.StoreID = Rows.StoreID AND SB.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817') THEN 'Branch store' ELSE 'All-branch store' END AS Store_Kind,
       Rows.Quantity
FROM   Rows
JOIN   InvItem AS Item ON Item.ID = Rows.ItemID
LEFT JOIN InvStore AS Store ON Store.ID = Rows.StoreID
WHERE  Rows.Quantity <= 0
ORDER BY Category, Store_Kind, Item.ItemName;

-- For      : G-T12 Inventory counts with the developer rules, branch stores only (InvStoreBranch)
-- Purpose  : Same as G-T10 but without the IsApplyToAllBranch stores. Count items the way the dashboard does: submitted Product and ProductPackage items of the branch, every item x branch store pair (movement or InvStoreItem row), items with no pair count as Out of Stock, each category counts distinct items.
-- Expected : Same as the Inventory tab of 23/11: All 363, In Stock 353, Low Stock 1, Out of Stock 12, Negative 22.
-- Status   : Written 23/11
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
    SELECT ItemID,
           CASE WHEN Quantity < 0 THEN '4 Negative'
                WHEN Quantity = 0 THEN '3 Out of Stock'
                WHEN Min_Quantity > 0 AND Quantity <= Min_Quantity THEN '2 Low Stock'
                ELSE '1 In Stock' END AS Category
    FROM   Rows
)
SELECT Category, COUNT(DISTINCT ItemID) AS Items, COUNT(*) AS Item_Store_Rows
FROM   Classified
GROUP BY Category
UNION ALL
SELECT '0 All', COUNT(DISTINCT ItemID), COUNT(*) FROM Classified
ORDER BY Category;


