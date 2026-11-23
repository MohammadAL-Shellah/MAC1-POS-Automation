-- Stock chain check 2: store transactions of the day with item type (services must not move stock)
SELECT dt.DocumentTypeName, i.ItemNumber, i.ItemName, it.ItemTypeName,
       t.ItemQuantity, t.BaseItemQuantity, t.ItemCost, t.BaseItemQuantity * t.ItemCost AS value, s.StoreName, t.DocumentDate,
       (SELECT InvoiceNumber FROM SalInvoice x WHERE x.ID = t.DocumentID) AS linked_invoice,
       (SELECT ReturnNumber  FROM SalReturn  x WHERE x.ID = t.DocumentID) AS linked_return,
       (SELECT InvoiceNumber FROM ProInvoice x WHERE x.ID = t.DocumentID) AS linked_purchase
FROM InvStoreTransaction t
JOIN GenLkpDocumentType dt ON dt.ID = t.DocumentTypeID
JOIN InvItem i ON i.ID = t.ItemID
LEFT JOIN InvLkpItemType it ON it.ID = i.ItemTypeID
JOIN InvStore s ON s.ID = t.StoreID
WHERE t.DocumentDate >= '2026-11-20'
  AND t.StoreID IN ('621d731d-a397-43a7-aa4d-6dc8be591db7', 'f833caab-dc19-43e6-8c0e-f36b80763596')
ORDER BY t.DocumentDate;