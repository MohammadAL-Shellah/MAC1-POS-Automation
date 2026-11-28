# US-1718 myShop POS: Vehicle Advisory (VIS) in Work Order, QA document

## 1. Story
| Item | Value |
|---|---|
| Story | 1718, State Resolved, Area Shop\myShop |
| Tasks | 1821 Story Analysis (New), 2297 VIS Without a License (Closed), 2303 QA Task (New) |
| Development field | "anything related to license now not supported" (Haitham Tarakhan, 2026-11-25) |
| Bugs, comments, attachments | None |
| QA delivery date | 2026-12-05 |
| SQL file | [US-1718-Vehicle-Advisory-VIS.sql](../../../QA-Database-Reference/Database-Queries/US-1718-Vehicle-Advisory-VIS.sql) |
| Screenshots | [US-1718-Vehicle-Advisory-VIS](../../../QA-Database-Reference/Screenshots/US-1718-Vehicle-Advisory-VIS/) |

## 2. Scope
| # | Area | Requirement | Scope |
|---|---|---|---|
| 1 | Vehicle eligibility, VIN flow | BR-01 | In |
| 2 | VIS Compatible Items, Add button, external references, messages, retry | BR-1, BR-07 | In |
| 3 | Oil recommendation | BR-1 | In |
| 4 | History tab | BR-2 | In |
| 5 | Maintenance tab and statuses | BR-2 (second) | In |
| 6 | Compatibility filter | BR-05 | In, license condition excluded |
| 7 | Compatibility indicator | BR-06 | In |
| 8 | License validation | BR-1.1 | Out (Development field) |
| 9 | Usage counter | BR-1.2 | Pending Q1 |

## 3. Acceptance Criteria coverage matrix (test cases in [US-1718_Vehicle_Advisory_Test_Cases.md](US-1718_Vehicle_Advisory_Test_Cases.md))
| AC | Scenario | Scope | Test cases | Coverage status |
|---|---|---|---|---|
| AC-01 | Vehicle selected, VIS enabled | In, vehicle part only | TC-VIS-003, 010 | Not Tested |
| AC-02 | No valid license | N/A, license not supported | | Not Applicable |
| AC-03 | Compatible products retrieved | In | TC-VIS-011 | Not Tested |
| AC-04 | External products cannot be added | In | TC-VIS-013, 020 | Not Tested |
| AC-05 | Customer products can be added | In | TC-VIS-012, 014 | Not Tested |
| AC-06 | Filter enabled | In | TC-VIS-030 | Not Tested |
| AC-07 | Filter disabled | In | TC-VIS-031 | Not Tested |
| AC-08 | Compatibility indicator | In | TC-VIS-036, 037, 038 | Not Tested |
| AC-09 | Missing in story | Q11 | | Needs Clarification |
| AC-10 | Vehicle changes | In | TC-VIS-039, 040 | Not Tested |
| AC-11 | Fitment request fails | In, method Q13 | TC-VIS-024 to 027 | Not Tested |
| AC-12 | Usage recorded | Q1 | TC-VIS-051 | Needs Clarification |
| AC-13 | WO eligibility rules still apply | In | TC-VIS-018 | Not Tested |
| AC-14 | Filter combined with other filters | In | TC-VIS-032 | Not Tested |

## 4. Screen to database mapping (to be verified, see KB section 5 items 17 to 20)
| # | Screen and action | Expected tables | Status |
|---|---|---|---|
| 1 | WO, VIS opens for the WO vehicle | SalWorkOrder.VehicleID to AutVehicle.ID | FK Verified (KB row 10) |
| 2 | VIN flow saves vehicle details | AutVehicle (columns from query A2) | Unknown |
| 3 | Add compatible item to WO | SalWorkOrder line tables, InvItem | Assumed |
| 4 | Item match by code | InvItem code column | Assumed |
| 5 | History tab | SalWorkOrder and lines, SecSystemUser | Assumed |
| 6 | Maintenance tab intervals | InvItemService or new columns (query A1, A4) | Unknown |
| 7 | Usage counter | Unknown (query A1) | Unknown |
| 8 | No item created by VIS | InvItem count before and after | To verify |

## 5. Regression impact
| # | Area | Why |
|---|---|---|
| 1 | WO item, service and package selection | New filter and Add path |
| 2 | Existing WO filters (name, number, brand, kind) | Must work with Compatibility |
| 3 | Quick Sales | Vehicle change named in BR-05 |
| 4 | Vehicle tracking setting and vehicle entry | Eligibility and VIN flow |
| 5 | Price list, contract, stock, branch, permissions | BR-07 rules unchanged |
| 6 | WO totals and stock chain after closing | Items added through VIS |

## 6. Business questions (dashboard 2026-11-26, entries 006 to 018)
| # | Entry | Topic |
|---|---|---|
| Q1 | e-20261126-006 | License and usage counter scope |
| Q2 | e-20261126-007 | Fitment provider in QA and known vehicles |
| Q3 | e-20261126-008 | Minimum vehicle details |
| Q4 | e-20261126-009 | VIN flow storage |
| Q5 | e-20261126-010 | History tab N, statuses, total |
| Q6 | e-20261126-011 | Maintenance intervals source |
| Q7 | e-20261126-012 | Item code matching rules |
| Q8 | e-20261126-013 | OEM tag |
| Q9 | e-20261126-014 | Filter screens |
| Q10 | e-20261126-015 | Caching |
| Q11 | e-20261126-016 | AC-09 missing |
| Q12 | e-20261126-017 | Final tabs |
| Q13 | e-20261126-018 | Simulating fitment failure |

## 7. Environment checklist before execution
| # | Item | Status |
|---|---|---|
| 1 | MAC1 build with VIS (read from System & Devices > About) | Open |
| 2 | Company confirmed in Portal, MAC1 and SSMS | Open |
| 3 | Vehicle tracking setting known (on and off cases) | Open |
| 4 | QA vehicles 5281DRB, 5282GZT details (query B1) | Open |
| 5 | Vehicle with no VIN or details for the VIN flow | Open |
| 6 | Customer items whose codes match VIS results (needs Q2, Q7) | Open |
| 7 | Services with intervals for Maintenance statuses (needs Q6) | Open |
| 8 | Way to fail the fitment service (needs Q13) | Open |
| 9 | Run section A and B queries in SSMS | Open |
