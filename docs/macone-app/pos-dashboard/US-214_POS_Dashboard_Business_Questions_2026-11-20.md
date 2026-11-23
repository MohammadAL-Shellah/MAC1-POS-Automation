# POS Dashboard (Story 214): Open Business Questions

| Item | Value |
|---|---|
| Date | 20 November 2026 |
| Build | MAC1 1.2.498 |
| From | QA, Mohammad Al Shellah |
| Why | 15 questions block 4 test cases (TC-POS-046, 064, 071, 085) and the final sign-off of the story. Each question shows what the app does today so you only need to confirm or correct it |

## 1. Inventory

| No | Question | What the app does today | Options |
|---|---|---|---|
| 1.1 | How is Inventory Value calculated? Which unit cost method, and how is negative stock handled? | The dashboard shows 64,510.00. The database value of the branch stores (quantity x cost) is about 662,219. After a purchase worth 200.00 the dashboard value rose by 5,000.00 | a. Average cost b. Last purchase cost c. Batch (FIFO) cost. Negative stock: count as 0, or subtract |
| 1.2 | Are the Inventory tab counts per item, or per item and store? | All shows 363, but In Stock + Low + Out + Negative add up to 388 | a. Per item (one row per item) b. Per item per store |

## 2. Sales figures

| No | Question | What the app does today | Options |
|---|---|---|---|
| 2.1 | Return Rate: is the base gross sales before discount, or net sales? | Today 2.9% = refunds 25.00 / gross sales 850.00 | a. Gross before discount (current) b. Net after discount |
| 2.2 | Should a fully refunded invoice still count under Fully Paid? | 4 invoices today, 1 fully refunded: Fully Paid shows 4 and Fully Refunded shows 1 | a. Count it in both (current) b. Only in Fully Refunded |
| 2.3 | In a period with refunds only, should Total Sales be negative? | Shows -51.00 | a. Negative (current) b. 0 |
| 2.4 | In a period with refunds only, should Gross Profit be negative? | Shows 0.00 while Net Sales is -44.35 | a. 0 (current) b. Negative |
| 2.5 | Top Selling: should returns be deducted, and what shows on a day with no sales? | Returns are deducted (Brake Check 50 sold - 25 returned = 25). On a no-sales day the card is blank and View All is hidden | a. Keep b. Show an empty-state message |

## 3. Cash and Work Orders

| No | Question | What the app does today | Options |
|---|---|---|---|
| 3.1 | Cash Sales % and Other Payments %: on net amounts after refunds? | Today 74.5% = net cash 615 / net total 825 | a. Net after refunds (current) b. Gross received |
| 3.2 | Voided Work Order amount in the list and export: original amount or 0? | New voided WOs show their amount (100.00); older voided WOs show 0.00 | a. Original amount b. 0 |
| 3.3 | After Close Day, what should the Current Cash Register block show? | It still shows the closed register TO_11000031 with Expected 2,060.00 | a. The last closed register b. No active register until Open Day |
| 3.4 | A Work Order carried to the next day at Close Day: on which day is it counted? | WO-182 was created on 20/11 and carried over. On 21/11 it counts as Total 1 and Pending 1 | a. The new day (current) b. Its creation day |
| 3.5 | Completing a carried-over Work Order changes its date to the completion day. Should the original creation date be kept? | WO-182's date changed from 20/11 7:09 PM to 21/11 12:10 AM | a. Keep the creation date b. The completion date is fine |

## 4. Items, tax and stock records

| No | Question | What the app does today | Options |
|---|---|---|---|
| 4.1 | RService is sold without VAT while other services carry 15%. Is this its intended tax setting? | Car Wash 100.00 carries 13.04 VAT, RService 100.00 carries 0.00 | a. Correct, RService is exempt b. Should carry 15% |
| 4.2 | Should a sales return's stock movement be linked to the return document? | The stock movement of RTN-TO_11000019 points to the original invoice INV-TO_11000132 | a. Link to the return b. Keep the invoice |
| 4.3 | Is an empty Stock Out record expected for service-only and voided Work Orders? | Each such WO creates a Stock Out header with 0 lines | a. Expected b. Should not be created |

## 5. Already reported as bugs (no answer needed)

Inventory Value not matching stock, negative Gross Margin shown in green, and returning a service item adding stock are treated as defects and will be opened as bugs.
