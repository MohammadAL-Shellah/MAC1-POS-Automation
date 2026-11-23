# MacOne app — QA documentation

The MAC One Windows POS desktop app (`Minerets.Shop.MacOne.exe`, .NET MAUI / WinUI 3), connected to the QA - Company environment.

| Story | Folder | DevOps | Status |
|---|---|---|---|
| POS Dashboard (User Story 214) | [pos-dashboard/](./pos-dashboard/) | Plan 1882 / Suite 1885 | Executed: Runs 1–3, 2026-11-12/13 |

## How the app is tested

- The app has native screens with no WebView2, so **Playwright cannot drive it**. Execution is manual-assisted: Windows UI Automation reads the screen, and real mouse clicks drive it.
- Test case IDs use the story code, e.g. `TC-POS-001`.
- Refunds are **Cash only** (business rule), and a refund needs enough cash in the drawer.
- Portal changes reach the app only after Menu → System & Devices → **Sync**.
- The branch "Alshellah" has 2 stores: *Mohammad store - Branch Store* and *Mohammad Store Branch - 2*.
