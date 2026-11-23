# Portal — QA documentation

The myShop web back-office (DevExpress XAF Blazor), QA environment at `QA_BASE_URL` in `.env`.

| Story | Folder | Status |
|---|---|---|
| _none yet_ | | |

## Starting a new portal story

1. Create `docs/portal/<story-slug>/` with `<Story>_Test_Cases.md` (see [../README.md](../README.md) for the layout).
2. Give the cases IDs `TC-PRT-<STORY>-NNN`, where `<STORY>` is a short code such as `SIG` for Service Item Group.
3. Put the automation in `tests/portal/<story-slug>/` (see `tests/portal/README.md`).
4. Record each run in `<Story>_Execution_Report.md`, with screenshots in `evidence/runN-YYYY-MM-DD/`.

## Things to know about the QA portal

- **Grid layouts are per user and stored on the server:** sort, page size, visible columns and split-button defaults. Parallel tests with the same user share them, so restore anything a test changes.
- **The toolbar "Cancel" is a workflow action:** on Submitted documents it saves and sets the status to Cancelled. Never use it to discard edits.
- **Some records cannot be deleted** (e.g. Service Item Groups). Prefix test data with `QA_AUTO_<runId>_` so it can be recognised.
- **Changes don't reach the MacOne app on their own:** they appear there only after Menu → System & Devices → **Sync**.
