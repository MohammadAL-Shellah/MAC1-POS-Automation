-- =====================================================================
-- Story US-1718  myShop POS - Vehicle Advisory (VIS) in Work Order (MacOne app)
-- Environment: QA/Test database on qadb.minerets.com,55009 (ReadUser), read only (SELECT queries only)
-- Pick the company database in SSMS before running (no database prefix in queries).
-- QA vehicles: 5281DRB Sportage, 5282GZT Tahoe (my customers). Never 1111AAA.
-- Scope note: Development field (2026-11-25): "anything related to license now not supported".
-- Format: every query has Test case, Purpose, Expected and Status (README.md, "Query block format").
-- Status: Written = in the file, Executed = run in SSMS, Verified = result matched the screen.
-- Created 2026-11-26. Build: read from System & Devices > About before execution.
-- =====================================================================

-- =====================================================================
-- Section A: Schema discovery (screen-to-database mapping)   |   2026-11-26   |   Build: TBD
-- =====================================================================

-- Test case: Preparation (mapping)
-- Purpose  : Find any table or column created for VIS, fitment, compatibility, advisory, OEM, usage or maintenance intervals.
-- Expected : List of new objects for the story; empty result means VIS data is not stored in this database.
-- Status   : Written
SELECT t.TABLE_NAME, c.COLUMN_NAME, c.DATA_TYPE, c.IS_NULLABLE
FROM INFORMATION_SCHEMA.TABLES t
JOIN INFORMATION_SCHEMA.COLUMNS c ON c.TABLE_NAME = t.TABLE_NAME
WHERE t.TABLE_NAME LIKE '%VIS%' OR t.TABLE_NAME LIKE '%Fitment%' OR t.TABLE_NAME LIKE '%Compatib%'
   OR t.TABLE_NAME LIKE '%Advis%' OR t.TABLE_NAME LIKE '%Usage%' OR t.TABLE_NAME LIKE '%License%'
   OR c.COLUMN_NAME LIKE '%Fitment%' OR c.COLUMN_NAME LIKE '%Compatib%' OR c.COLUMN_NAME LIKE '%OEM%'
   OR c.COLUMN_NAME LIKE '%NextDue%' OR c.COLUMN_NAME LIKE '%Interval%' OR c.COLUMN_NAME LIKE '%Mileage%'
   OR c.COLUMN_NAME LIKE '%Viscosity%' OR c.COLUMN_NAME LIKE '%OilGrade%'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;

-- Test case: Preparation (mapping)
-- Purpose  : Columns of the vehicle tables (VIN, Make, Model, Year, mileage) used by the fitment lookup and the VIN flow.
-- Expected : AutVehicle and related lookup tables with their columns.
-- Status   : Written
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME LIKE 'Aut%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Test case: Preparation (mapping)
-- Purpose  : Foreign keys of the vehicle and Work Order tables, from metadata (never from column names alone).
-- Expected : FK list for AutVehicle, SalWorkOrder and their line tables.
-- Status   : Written
SELECT fk.name                                   AS FK_Name,
       OBJECT_NAME(fk.parent_object_id)          AS Child_Table,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id)         AS Child_Column,
       OBJECT_NAME(fk.referenced_object_id)      AS Parent_Table,
       COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Parent_Column
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
WHERE OBJECT_NAME(fk.parent_object_id) LIKE 'Aut%'
   OR OBJECT_NAME(fk.parent_object_id) LIKE 'SalWorkOrder%'
   OR OBJECT_NAME(fk.referenced_object_id) LIKE 'Aut%'
ORDER BY Child_Table, Child_Column;

-- Test case: Preparation (mapping)
-- Purpose  : Item columns used for matching VIS results (item code, kind, status) and service interval setup.
-- Expected : Column list of InvItem and InvItemService.
-- Status   : Written
SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN ('InvItem', 'InvItemService', 'InvLkpItemType')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- =====================================================================
-- Section B: Test data for my QA vehicles   |   2026-11-26   |   Build: TBD
-- =====================================================================

-- Test case: Preparation (test data)
-- Purpose  : My QA vehicles with plate, VIN and all vehicle columns, to know which have full details and which need the VIN flow.
-- Expected : 5281DRB and 5282GZT rows.
-- Status   : Written
SELECT *
FROM AutVehicle
WHERE VehiclePlate IN ('5281DRB', '5282GZT');

-- Test case: Preparation (History tab baseline)
-- Purpose  : Work Orders of my QA vehicles, newest first, as the baseline for the History tab (visit date, WO number, status, user).
-- Expected : Visits listed in the History tab (N and status rules pending business questions).
-- Status   : Written
SELECT v.VehiclePlate,
       wo.*
FROM SalWorkOrder wo
JOIN AutVehicle v ON v.ID = wo.VehicleID
WHERE v.VehiclePlate IN ('5281DRB', '5282GZT')
ORDER BY v.VehiclePlate, wo.WorkOrderDate DESC;
