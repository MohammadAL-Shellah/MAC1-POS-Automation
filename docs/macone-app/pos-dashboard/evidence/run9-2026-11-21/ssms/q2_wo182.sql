-- 21/11 Q2: WO-182 carried to next day (TC-071) and its invoice INV-137 (TC-067 Case A)
SELECT o.WorkOrderNumber, o.WorkOrderDate, o.DocumentStatusID, o.IsShiftedEOD, o.WorkOrderTotalAmount, w.OpenDate AS WorkingDayOpen, f.OpenDate AS ShiftedFromDayOpen,
       i.InvoiceNumber, i.InvoiceDate, i.InvoiceTotalAmount
FROM SalWorkOrder o JOIN SalWorkingDay w ON w.ID = o.WorkingDayID LEFT JOIN SalWorkingDay f ON f.ID = o.ShiftedFromWorkingDayID
LEFT JOIN SalInvoice i ON i.InvoiceNumber LIKE '%11000137'
WHERE o.WorkOrderNumber LIKE '%11000182';
