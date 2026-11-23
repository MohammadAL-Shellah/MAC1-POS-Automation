| Time | Step | Result |
|---|---|---|
| 17:58:34 | 1. Workorder, vehicle 4114BDR, Bay - QA_INT, add QA_INT Package Sum 1114 (pick Engine Oil 5W-40 1L), Confirm | WO No. #WO - TO_11000108. Cart: QA_INT Package Sum 1114 QAINT1114PS  175 .00 Each 1 |
| 17:58:37 | 2. Back (WO stays Pending) | Dashboard |
| 17:59:25 | 3. Workorder, vehicle 4115LGZ, Bay - QA_INT, add QA_INT Package 1114 (pick first oil), Confirm | WO No. #WO - TO_11000107. Cart: QA_INT Package 1114 QAINT1114P  100 .00 Each 1 QA_INT Package Sum 1114 QAINT1114PS  175 .00 Each 1 |
| 17:59:28 | 4. Back (WO stays Pending) | Dashboard |
| 17:59:41 | 5. Menu, System and Devices, Sync | Operation Error  An error occurred during operation.  Reason: The DELETE statement conflicted with the REFERENCE constraint "FK_SalWorkOrderService_SalWorkOrderItem". The conflict occurred in database "MacOne_255b989cce714d828b70d1f9e4367412", table "dbo.SalWorkOrderService", column 'WorkOrderItemID'. The statement has been terminated.  Please try again or contact technical support if the problem persists. |
| 17:59:50 | 6. Close the error, look at the Dashboard | see screenshot fin_4_dashboard |
| 18:00:20 | 7. Open vehicle 4114BDR again | WO No. #WO - TO_11000108. Cart: There are no items added |
| 18:00:27 | 8. Menu (three dots), Pending WOs | see screenshot fin_6_pending |
