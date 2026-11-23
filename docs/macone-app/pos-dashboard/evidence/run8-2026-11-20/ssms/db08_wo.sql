-- DB check: Work Orders by status, today and MTD (TC-017, 018, 052, 053, 054)
SELECT CASE WHEN w.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END AS period,
       ds.DocumentStatusName AS status, COUNT(*) AS n, COUNT(DISTINCT w.CustomerID) AS customers
FROM SalWorkOrder w
JOIN GenLkpDocumentStatus ds ON ds.ID = w.DocumentStatusID
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.WorkOrderDate >= '2026-11-01'
GROUP BY CASE WHEN w.WorkOrderDate >= '2026-11-20' THEN 'Today' ELSE 'Before today' END,
         ds.DocumentStatusName;
