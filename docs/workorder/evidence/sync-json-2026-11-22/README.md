# Work Order Sync: one JSON with the full Work Order

| Field | Value |
|---|---|
| Date | 2026-11-22 |
| Environment | QA, build 1.2.498 (About) |
| Work Order | WO - TO_11000185, vehicle 5281DRB, left Pending |
| Story | Not given |
| Expected (Mohammad, 2026-11-22) | Every save writes one JSON with the full Work Order |
| Result | Failed (Defect) |

| Save | Action | One upload row | Full Work Order |
|---|---|---|---|
| 01 | Create | Yes | Yes |
| 02 | Add Car Wash | Yes | Yes |
| 03 | Add Brake Check | Yes | Yes |
| 04 | Change quantity | Yes | Yes |
| 05 | Edit Work Order note only | Yes | **No: WorkOrderNote and ID only** |
| 06 | Apply 10% discount | Yes | Yes |
| 07 | Press minus at quantity 1 | Yes | Yes |
| 08 | Remove Brake Check | Yes | Yes |

1. Files: the exact GZip BLOB read from SyncUpload and its decompressed JSON, per save. watch.log has the row IDs and times.
2. Queries: G-L6 (capture), G-L7 (item type) and G-S1 (server) in QA-Database-Reference/Database-Queries/General-Queries.sql.
3. Screenshots: QA-Database-Reference/Screenshots/General-WO-Sync-JSON.
4. The final server state matches the screen and the last JSON. The server was not checked after each intermediate save.
5. Not tested: products and stock lines, packages, item discount, item note, mileage, service date edit, payment, void, offline and retry.
