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
