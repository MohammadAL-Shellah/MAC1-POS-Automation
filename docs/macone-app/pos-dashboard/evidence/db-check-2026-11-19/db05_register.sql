-- DB check: Working day and opening cash today (TC-021, 022, 061)
SELECT w.OpenDate, w.OpenBalanceCashAmount AS opening_cash, w.IsClosed,
       (SELECT COUNT(*) FROM SalInvoice s WHERE s.WorkingDayID = w.ID) AS invoices
FROM SalWorkingDay w
WHERE w.BranchID = 'ff31fb19-e1c3-4f75-834b-7341cfe74817' AND w.OpenDate >= '2026-11-19'
ORDER BY w.OpenDate;