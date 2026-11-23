# QA documentation

The documentation is split by **product**. Use the same name for a product everywhere: in `docs/`, in `tests/`, in npm scripts, and in test case IDs.

| Product | What it is | Docs | Automated tests | Test case ID prefix |
|---|---|---|---|---|
| **Portal** | myShop web back-office (DevExpress XAF Blazor) at `QA_BASE_URL` | [portal/](./portal/) | `tests/portal/` (Playwright) | `TC-PRT-<STORY>-NNN` |
| **MacOne app** | MAC One Windows POS desktop app (.NET MAUI) | [macone-app/](./macone-app/) | none: the app cannot be driven by Playwright | `TC-<STORY>-NNN` (e.g. `TC-POS-001`) |

Cross-product work, such as data moving between the Portal and the MacOne app, lives in [integration/](./integration/).

## Layout for one user story

```
docs/<product>/<story-slug>/
├── <Story>_Test_Cases.md          # the cases (specification)
├── <Story>_Execution_Report.md    # results of each run (append new runs)
├── <Story>_AzureDevOps_Map.csv    # TC ID -> DevOps work item (if pushed)
└── evidence/
    ├── runN-YYYY-MM-DD/           # screenshots per run
    ├── bugs/                      # annotated screenshots used in DevOps bugs
    └── exports/                   # CSV / report exports
```

- **`<story-slug>`:** lower-case kebab-case, e.g. `pos-dashboard`, `service-item-group`.
- **`<Story>`:** PascalCase words joined with underscores, e.g. `POS_Dashboard`.
- **Screenshot names:** short and descriptive, e.g. `overview_after_return.png`. Prefix bug screenshots with the defect ID, e.g. `D04_card_annotated.png`.
