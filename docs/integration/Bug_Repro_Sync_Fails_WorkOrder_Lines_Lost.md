# Repro: Sync fails and work order lines are lost or restored

| Item | Value |
|---|---|
| Date | 14 November 2026, 17:21 to 17:36 |
| Environment | QA Company, branch Alshellah, terminal M-ALSHELLAH, MacOne 1.2.484 |
| Video | `Videos\Captures\2026-11-14 17-21-40.mp4` (MAC1 window only, about 15 minutes, 581 MB). The microphone was on by mistake from 0:10:00 to 0:11:20 |
| Short video for the bug | `Videos\Captures\2026-11-14 17-57-38.mp4` (under 3 minutes). In this run the 4115LGZ WO (TO_11000107) already showed the Package Sum line of WO-108 with "The work order could not be saved", before any Sync. Sync then failed on FK_SalWorkOrderService_SalWorkOrderItem and WO-108 was empty. Screenshots: BUG_wo107_wrong_line, BUG_sync_error, BUG_wo108_empty_after |
| Related findings | 6.14, 6.17 and 6.18 in [Portal_MacOne_Integration_Report.md](./Portal_MacOne_Integration_Report.md) |

## 1. Preconditions

| No | Item |
|---|---|
| 1.1 | Two service packages exist in the portal and are synced: QA_INT Package 1114 (Labor and Item fixed, 100 with tax) and QA_INT Package Sum 1114 (Labor Only Summation, 175 with tax) |
| 1.2 | Customer QA Auto Customer 1114 with vehicles 4114BDR and 4115LGZ |
| 1.3 | Before the test, all open work orders were voided in MAC1 (WO 96, 99, 100, 101, 102). Dashboard: 0 Pending, 5 Voided |
| 1.4 | Sync before the test: Sync Completed |

## 2. Steps

| No | Step | Result |
|---|---|---|
| 2.1 | Workorder, vehicle 4114BDR, Bay QA_INT. New WO TO_11000103 | WO opened |
| 2.2 | Add QA_INT Package Sum 1114, go through its 3 steps, pick Engine Oil 5W-40 1L, Confirm | Cart: 1 line, quantity 1, 175.00 |
| 2.3 | Press Back. WO stays Pending | Dashboard |
| 2.4 | Workorder, vehicle 4115LGZ, Bay QA_INT. New WO TO_11000104 | WO opened |
| 2.5 | Add QA_INT Package 1114, pick the first oil, Confirm | Cart: 1 line, quantity 1, 100.00 |
| 2.6 | Press Back. WO stays Pending | Dashboard: 2 Pending |
| 2.7 | Menu, System and Devices, Sync | **Error** (see 3.1) |
| 2.8 | Sync again | **Same error** |
| 2.9 | Menu, Pending WOs, open each one | See 3.2 |

## 3. Actual result

### 3.1 Sync error

> The DELETE statement conflicted with the REFERENCE constraint "FK_SalWorkOrderItemBatch_SalWorkOrderItem". The conflict occurred in table "dbo.SalWorkOrderItemBatch", column 'WorkOrderItemID'.

An earlier run on the same day failed with the same kind of error on "FK_SalWorkOrderService_SalWorkOrderItem" (table dbo.SalWorkOrderService).

### 3.2 Work orders after the failed Sync

| WO | Before Sync | After failed Sync (MAC1) | Portal |
|---|---|---|---|
| TO_11000103 (4114BDR) | Pending, Package Sum x1, 175.00 | Pending, **no lines** | New, total 275.00, 2 lines, line 1 = Package Sum 175.00 |
| TO_11000104 (4115LGZ) | Pending, Package 1114 x1, 100.00 | Unchanged | New |
| TO_11000096 (1111AAA, other customer) | **Voided** | **Pending again**, RService | New |
| TO_11000099 (4115LGZ) | **Voided** | **Pending again**, QA_INT Package 1114 **x72** (7,200.29) and Package 2 services | New |
| TO_11000100 (4114BDR) | **Voided** | **Pending again**, no lines | New |

| No | Other effects |
|---|---|
| 3.3 | Dashboard changed from 2 Pending, 5 Voided to **5 Pending, 2 Voided** (Total WOs 9) |
| 3.4 | All pending WOs show the same time, 05:26 PM |
| 3.5 | Voids done in MAC1 never reached the portal. The voided WOs stay New there |
| 3.6 | Bay screen after voiding all WOs: Bay - QA_INT (2/3) and Bay - 01 (1/2), so voided WOs still hold bay places |

## 4. Expected result

| No | Expected |
|---|---|
| 4.1 | Sync completes while work orders with service packages are pending |
| 4.2 | A failed Sync does not change local data: lines stay on their own WO and voided WOs stay voided |
| 4.3 | Voids reach the portal and free the bay |

## 5. Notes for dev

| No | Note |
|---|---|
| 5.1 | With only one package WO pending (earlier runs) Sync passed 4 times. It failed as soon as **two** package WOs were pending |
| 5.2 | A package line has child rows (services, item batches). The error says Sync deletes WorkOrderItem rows before their child rows |
| 5.3 | The quantity issue (64, 32, 72) may be linked: Package 1114 grew from x70 to x72 on WO-99 after the failed Sync |

## 6. Evidence

All in [evidence/macone-app](./evidence/macone-app/), prefix R618:

| No | File | Shows |
|---|---|---|
| 6.1 | R618_wo103_before_sync | WO-103 with Package Sum 175.00 |
| 6.2 | R618_wo104_before_sync | WO-104 with Package 1114 100.00 |
| 6.3 | R618_sync_fail_batch | Sync error |
| 6.4 | R618_dashboard_after_fail | 5 Pending, 2 Voided |
| 6.5 | R618_pending_after_fail | Pending WOs list |
| 6.6 | R618_wo103_empty_after | WO-103 without lines |
| 6.7 | R618_wo99_back_x72 | Voided WO-99 back with x72 |
| 6.8 | R618_wo96_back | Voided WO-96 back |
| 6.9 | R618_wo100_back | Voided WO-100 back |
| 6.10 | R618_bay_after_void | Bay counts after voiding |
