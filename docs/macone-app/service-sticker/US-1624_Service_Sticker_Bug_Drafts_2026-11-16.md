# Service Reminder Sticker: Bugs (Story 1624)

Found on MAC1 1.2.490 and 1.2.491 (16/11/2026), retested on 1.2.494 (17/11/2026). None of these is saved on Azure DevOps yet: each one is an unsaved New Bug tab in Edge and a draft on the QA dashboard. Reviewed with the user on 17/11/2026: 3 bugs remain. Bug Type is left empty. Priority 2.

| # | Dashboard draft | Title | Severity | Issue Type | QA Bug Type | Screen | Found in | Parent | Cases |
|---|---|---|---|---|---|---|---|---|---|
| 1 | e-20261116-021 | MAC1 - Service Sticker \| Service package doesn't use the shortest interval, product value always wins | 3 - Medium | Incorrect Functionality | Happy Scenario | Service Reminder Stickers | 1.2.494 | Story 1624 | TC-SST-049, 050 |
| 2 | Bug 2167 (saved 17/11) | MAC1 - Service Sticker \| Wrong and cut texts on the sticker and sticker screen | 4 - Low | Cosmetic | Happy Scenario | Service Reminder Stickers | 1.2.490 | Story 1624 | Observation. Closed 18/11/2026, retest Pass on 1.2.495 |
| 3 | Bug 2168 (saved 17/11) | MAC1 - Items \| User without My Items Edit permission can open Edit Item Info and save changes | 2 - High | Incorrect Functionality | Happy Scenario | My Items | 1.2.494 | Story 1624 | TC-SST-052. Retest Pass on 1.2.495 (18/11/2026), set to Closed, waiting for the save |

Status 19/11/2026: bug 1 is cancelled, not a bug. The business answered (question e-20261117-010) that the item's own data always wins, so the product value is used even when longer. TC-SST-049, 050 Pass on 1.2.494. Older bugs of this story: 1824 and 1830 closed (Pass on 1.2.494), 2165 Pass on 1.2.498 (20/11/2026): changing RService from WO-TO_11000182 updated both mileage and date on the other open WO-TO_11000181. Waits to be closed on DevOps.

Removed: "No way to enter the mileage when Mileage entry is Optional". It is not a bug: with Optional the Enter mileage panel offers Skip and Save Mileage.

Removed on 17/11/2026 after the review with the user (not bugs):
1. "Screen says No items or services in the cart when the cart has items": by business rule a product alone gets no sticker, it must come with a service (TC-SST-018 is Pass). The cut header text from that report moved to bug 2.
2. "Service package created on the POS does not appear in the Work Order catalog": the POS package story is not ready yet; the package was hidden because it had no Business Category.
3. "Product Package option on New item does not open": Product Package is not supported yet.
4. "Product items with reminder configuration don't appear on the sticker screen": a product gets a sticker only inside a package with a service. Products inside a package are listed on 1.2.491 (TC-SST-014 is Pass).
5. "Mileage can't be entered after Skip or updated on an open Work Order": the mileage is entered from the pencil next to the customer > Customer actions > Mileage > Enter mileage. Checked on 17/11/2026 on MAC1 1.2.494 on a WO created without mileage and on an open WO (TC-SST-034, 035 Pass).
6. "Sticker templates have no Active flag and no Company or Branch link" (portal): moved to a business question (dashboard e-20261117-008). TC-SST-019 and 020 wait for the answer.
7. "Work Order Detail (A4 layout) is offered as a sticker template": this is the data definition on the portal (the layouts linked to Work Order Sticker), not a bug.
8. "User without Workorder Print permission can open and print service stickers" and "No Service Sticker permissions": the Permissions screen now has Service Reminder Sticker (Edit, Print). Checked on 17/11/2026 on MAC1 1.2.494 with Role User: with Print not allowed the Print button is hidden, with Print allowed it shows, and with Edit not allowed the pencil is hidden (TC-SST-026, 051, 053 Pass).

---

## 1. (Cancelled 19/11/2026, not a bug) MAC1 - Service Sticker | Service package doesn't use the shortest interval, product value always wins

Steps:
1. Open a WO for 1111AAA (byd) with mileage 50,000 km.
2. Add "Package 2 services" (TO_2000006): Car Wash (1 km / 1 Year) and Service - R (4 km / 4 Week), with product Back Break under each service.
3. WO menu > Other Actions > Service Reminder Stickers.
4. Set Back Break to 10 km (no period), check the Calculation table.
5. Set Back Break to 2 km / 6 Week, check the Calculation table and print.

Actual result:
- Step 4: Result is 10 km for both services, although Car Wash is 1 km and Service - R is 4 km.
- Step 5: Result is 2 km / 6 Week for both services. Service - R prints 28/12/2026 (6 weeks) although its own period is 4 weeks.
- The note on the screen says: "a product under a service lowers that service's value when its interval is shorter". The calculation does the opposite: the product value is always used.

Expected:
- Story section 8, Minimum Interval Rule: the shortest interval is used, and mileage and period are evaluated separately. Step 5 should give Service - R 2 km / 4 Week and Car Wash 1 km / 6 Week.
- If product priority is the intended rule, the note on the screen must be corrected.

Note: Back Break was set only for the test and was cleared afterwards.

Retest on 1.2.491 (16/11 evening): still fails. Package 1, service Brake Fluid Level Check 10 km / 10 Day with product Engine Oil 033 20 km / 20 Day gives 20 km / 20 Day. Service Oil Drain Plug Replacement 5 km / 5 Day with product Engine Cleaner 048 set to 3 km / 9 Day gives 3 km / 9 Day.


Retest on MAC1 1.2.494 (17/11/2026, WO-TO_11000152): still fails with the same values. Service 1 gives 20 km / 20 Day, Service 2 gives 3 km / 9 Day.

On hold (17/11/2026): story section 8 also says "Product-level configuration has priority over service-level configuration" (Priority Rules), which matches the current behaviour, while the Minimum Interval Rule asks for the shortest interval. Kept as a draft until the business answers which rule wins (dashboard question e-20261117-010).
---

## 2. MAC1 - Service Sticker | Wrong and cut texts on the sticker and sticker screen

Steps:
1. Open a WO with QA_SST Oil Change Service and open Service Reminder Stickers.
2. Select one item, check the button, then print and check the sticker.

Actual result:
- The sticker label is "On or date".
- The button says "Print 1 stickers".
- The header card text is cut: "Service completion d" and "0 of 0 selecte".

Expected:
- The label reads "Or on date" (or the approved wording).
- The button says "Print 1 sticker" for one item.
- The header card text is fully shown.

---

## 3. MAC1 - Items | User without My Items Edit permission can open Edit Item Info and save changes

Steps:
1. Administration > Permissions > My Items: role Branch Manager, set Edit to not allowed (View allowed). Save, then Sync.
2. Log in with a user of role Branch Manager (test user "Role User").
3. Cash & Stock > My items > open QA_SST Oil Change Service > pencil > change Next Reminder Mileage 5000 to 5001 > Save.
4. Open the item again.

Actual result:
- Edit Item Info opens for a user without Edit.
- Save works and the item now has 5001.

Expected:
- Without the My Items Edit permission the pencil is hidden or the fields are read-only, and nothing can be saved.

Note: retested on 17/11/2026 on MAC1 1.2.494. The value was set back to 5000. The sticker screen part is fixed: with the new Service Reminder Sticker permission (Edit not allowed) the pencil on the sticker screen is hidden.
