-- Stock chain check 3: service items that hold stock (should be none)
SELECT i.ItemNumber, i.ItemName, s.StoreName, SUM(t.BaseItemQuantity) AS qty
FROM InvStoreTransaction t
JOIN InvItem i ON i.ID = t.ItemID
JOIN InvItemService sv ON sv.ID = i.ID
JOIN InvStore s ON s.ID = t.StoreID
WHERE t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY i.ItemNumber, i.ItemName, s.StoreName
HAVING SUM(t.BaseItemQuantity) <> 0;