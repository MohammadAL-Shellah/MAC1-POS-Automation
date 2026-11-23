# POS Dashboard — Bug Drafts (not logged)

Status on 2026-11-14: reviewed in chat, not opened on DevOps. The user will decide later which ones to open.

## 1. POS-D01

```
Title: MAC1 - Dashboard | Sales list and export don't have ZATCA Rejection Reason column
Severity: Medium
Test cases: TC-POS-049, TC-POS-081

Steps:
1. Open Dashboard > Sales.
2. Check the columns of the transactions list.
3. Click Export and open the CSV file.

Actual:
2. Columns are: Invoice # / Date, Customer, Customer Type, Plate Number, Items,
   Amount, Method, Status, ZATCA Status, ZATCA Status Time.
   ZATCA Rejection Reason is not there.
3. The CSV has the same columns, without ZATCA Rejection Reason.

Expected:
The list and the export show ZATCA Rejection Reason, as written in the story.

Evidence: sales_daily.png, export1.png, Transactions_20261112_144038.csv
```

## 2. POS-D02

```
Title: MAC1 - Dashboard | Cash tab has no Cash Deposit button
Severity: Medium
Test case: TC-POS-060

Steps:
1. Open Dashboard > Cash.
2. Check the Current Cash Register card.
3. Scroll down to the end of the page.

Actual:
2. There is no Cash Deposit button on the card.
3. No button at the bottom either.
Cash Deposit opens only from the side menu (Cash & Stock > Cash Deposit).

Expected:
The Current Cash Register card has a Cash Deposit button that opens the Cash Deposit screen.

Evidence: cash_tab.png, cash_tab_bottom.png, d2_cash.png
```

## 3. POS-D06

```
Title: MAC1 - Dashboard | Inventory Value jumps when stock changes in one store
Severity: High
Test cases: TC-POS-029, TC-POS-062

Precondition:
Branch Alshellah has 2 stores: Branch Store and Branch-2.
Engine Oil 5W-40 1L: Branch Store = 155, Branch-2 = 0, cost 100.70.

Steps:
1. Open Dashboard > Inventory. Note Stock Value.
2. Make a Stock In to Branch-2: Engine Oil 5W-40 1L +2, Tire - Item +12.
3. Go back to Dashboard > Inventory. Check Stock Value.

Actual:
1. Stock Value = 8,710.00.
3. Stock Value = 25,069.90 (+16,359.90).
   Engine Oil alone added 15,809.90 = 157 x 100.70.
   The 155 units in Branch Store were not counted before step 2,
   and were added only when Branch-2 changed from 0 to 2.

Also seen:
- Air Filter 039 (50 units in Branch Store) was never in the value.
- Rows with negative quantity are not counted.
- A new purchase price changes the value of all old stock of the item.

Expected:
Stock Value = sum of (quantity x unit cost) for all stores of the branch, all the time.
Stock In of 2 Engine Oil adds only 2 x 100.70 = 201.40.

Evidence: d2_inv.png, d2_inv_after_sa.png, stockadj_state.png
```

Note: depends partly on open business question 4 (negative stock and unit cost method).

## 4. POS-D08

```
Title: MAC1 - Dashboard | Date is cleared when clicked again and Apply gives no message
Severity: Low
Test cases: TC-POS-041, TC-POS-078

Steps:
1. Open Dashboard > Sales.
2. Choose a From date and click Apply.
3. Open the From date again and click the same selected date.
4. Click Apply.

Actual:
3. The field is cleared and shows "select a date".
4. No message. The list keeps showing the old data.

Expected:
3. Clicking the selected date keeps it selected.
4. If the date is empty, Apply shows a message and does not run.

Evidence: none yet, new screenshot needed.
```

## 5. POS-D09

```
Title: MAC1 - Dashboard | Dashboard doesn't refresh automatically while open, and keeps the previous day's data after midnight
Severity: Medium
Test case: TC-POS-076

Steps:
1. Open Dashboard > Overview. Note the time at the top and the numbers.
2. Leave the screen open without any action.
3. After 25 minutes, check the time at the top.
4. Switch to another tab and back.
5. Leave the dashboard open until after midnight, then check the data.

Actual:
3. The time at the top still shows 09:18 PM. The computer time is 09:43 PM.
4. The time stays 09:18 PM. Numbers are refreshed only after leaving
   the dashboard and opening it again.
5. After midnight the screen did not update. It still shows the previous
   day's data until the dashboard is closed and opened again.

Expected:
1. The dashboard refreshes by itself while open, and the time at the top is the current time.
2. When the day changes at midnight, the dashboard moves to the new day's data by itself.

Note: only one terminal was available, so no data could be changed from another device while the screen was open. The frozen clock and the midnight behaviour are the main evidence.

Evidence: rt_00_state.png, rt_076_idle_wo_after150s.png, rt_076_overview_tab.png
```
