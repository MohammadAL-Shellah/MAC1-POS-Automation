-- DB check: Tire - Item stock per store (TC-063, 065, 066)
SELECT st.StoreName, SUM(t.BaseItemQuantity) AS qty,
       MAX(si.ItemMinQuantity) AS min_qty, MAX(si.ItemMaxQuantity) AS max_qty
FROM InvStoreTransaction t
JOIN InvItem i   ON i.ID = t.ItemID
JOIN InvStore st ON st.ID = t.StoreID
LEFT JOIN InvStoreItem si ON si.StoreID = t.StoreID AND si.ItemID = t.ItemID
WHERE i.ItemNumber = 'TO_1000001' AND t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
GROUP BY st.StoreName;