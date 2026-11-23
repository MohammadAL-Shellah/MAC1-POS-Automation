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
