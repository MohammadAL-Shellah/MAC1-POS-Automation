-- DB check: COGS of INV-TO_11000128, stock out x cost (TC-031, 032)
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