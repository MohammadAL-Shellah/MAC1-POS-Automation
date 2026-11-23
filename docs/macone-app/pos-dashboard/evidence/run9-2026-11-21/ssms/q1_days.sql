-- 21/11 Q1: Open Day opening cash + 20/11 close + deposit link (TC-075, Open Day)
SELECT w.OpenDate, w.CloseDate, w.IsClosed, w.OpenBalanceCashAmount, w.OpenActualCashAmount, w.CloseSystemCashAmount, w.CloseDepositCashAmount, w.CloseLeftCashAmount, d.BankDepositNumber, d.DocumentStatusID AS DepositStatus, l.DepositAmount AS LinkedDeposit
FROM SalWorkingDay w LEFT JOIN SalBankDepositWorkingDay l ON l.WorkingDayID = w.ID LEFT JOIN SalBankDeposit d ON d.ID = l.BankDepositID
WHERE w.OpenDate >= '20261120 15:00' ORDER BY w.OpenDate;
