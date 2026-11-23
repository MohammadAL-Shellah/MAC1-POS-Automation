-- Stock chain check 4: batch cost written by today's purchases
SELECT i.ItemNumber, b.BatchNumber, c.ItemBatchCost, c.ItemBatchCostDate
FROM InvItemBatchCost c
JOIN InvItemBatch b ON b.ID = c.ID
JOIN InvItem i ON i.ID = b.ItemID
WHERE c.ItemBatchCostDate >= '2026-11-20';