# Gemini QA Agent

The CLI uses Gemini to turn a user story into a JSON test plan of up to 100 focused cases, with comprehensive coverage of distinct requirements and scenarios. It can run those steps against either the QA web portal using Playwright or the native Minerets Shop MacOne desktop app using Windows UI Automation.

## Setup

1. Keep the rotated Gemini API key in `MAC1-Desktop-QA-Assistant/.env` as `GEMINI_API_KEY`. Do not commit or share the key. The default model is `gemini-flash-lite-latest` through the Gemini Interactions API (`v1beta`); optionally override it with `GEMINI_MODEL`.
2. The browser target reads `QA_BASE_URL`, `QA_USERNAME`, and `QA_PASSWORD` from the repository-root `.env`.
3. The desktop target defaults to the provided `Minerets.Shop.MacOne.exe` path. Set `PORTAL_EXE_PATH` in the agent `.env` to override it.
4. Install dependencies if needed: `npm.cmd install` from `MAC1-Desktop-QA-Assistant`.

## Team knowledge

Every Gemini request includes the Markdown files in `MAC1-Desktop-QA-Assistant/knowledge/`, so the agent works by the team's rules:

1. `01-how-we-work.md`: language and question rules (Arabic replies, English names on their own line), safety rules, and how to judge a result.
2. `02-macone-app-map.md`: exact labels of the MacOne dashboard tabs, cards, filters, search boxes, and columns.
3. `03-business-rules.md`: confirmed business rules, decisions still pending, and known open defects.
4. `04-bug-and-report-style.md`: the bug draft format and the Arabic run summary format.

The files are read on every request, so edit them to teach the agent something new; no restart is needed. Do not put secrets or personal data in them, because their text is sent to Gemini.

You can write requests in Arabic or English. Gemini answers the summary, acceptance criteria, and questions in Arabic, and keeps test steps and bug drafts in English. After a run, it writes an Arabic summary and English bug drafts (never opened in DevOps), saved as `output/qa-agent-<id>-report.md`. A `screenshot` step saves evidence images in `output/`.

## Calculations

Plans can check numbers the way a QA engineer does: read them, then calculate (`calc.js` parses expressions safely, without `eval`).

| Step | What it does |
|---|---|
| `{"action":"readValue","target":{"by":"text","name":"Invoices Today"},"as":"inv"}` | Reads the number next to a label (to its right or below it). Also reads "All (21)" by "All" and "2 Pending" by "Pending". |
| `{"action":"readCell","row":"INV - TO_11000093","column":"Method","as":"method"}` | Reads one cell of a list; `rowAlso` picks between rows with the same text. Desktop only. |
| `{"action":"expectNumber","expression":"{p} / {total} * 100","op":"=","value":"{rate}","tolerance":0.05}` | Computes both sides with `+ - * / ( )`, `round`, `abs`, `min`, `max`, then compares with `=`, `!=`, `<`, `<=`, `>`, `>=`. |
| `{"action":"expectValue","var":"method","contains":"Cash"}` | Checks the text of a value read earlier (`equals` or `contains`). |

Values belong to one test case and survive tab changes. Every value read and every check, with both sides, is saved in the results and shown in the UI and the Arabic report. The formulas Gemini uses are in `knowledge/03-business-rules.md`. Each desktop case starts on the dashboard Overview tab.

## Use

Start the simple local UI from `MAC1-Desktop-QA-Assistant`:

```powershell
npm.cmd run ui
```

Open `http://127.0.0.1:4173` in your browser. Paste a story of up to 100,000 characters, choose the desktop app (the default) or QA web portal, answer any Gemini follow-up questions, review the plan, and select **Run tests**. The UI asks for final confirmation before any test runs.

The UI listens only on `127.0.0.1`; it does not expose a public server or send the API key to the browser. Stories and answers are sent to Gemini from the local Node process. Plan and result JSON files are saved in `MAC1-Desktop-QA-Assistant/output/`.

To import existing manual cases, choose a `.md` file in **Or import existing test cases** and select **Import Markdown**. The file must contain cases formatted with `#### TC-ID — Title` headings and `Category`, `Preconditions/data`, `Steps`, and `Expected` fields. Files up to 128 KB and plans up to 100 cases are supported. Gemini converts cases in small batches while preserving IDs, titles, and order, asking at most three focused clarification questions per batch. If a batch needs more detail, the UI collects its clarification questions and retries only unresolved batches; completed batches are retained. The converted plan appears for review; importing does not run tests. Review every generated step before selecting **Run tests**.

Gemini requests have a 90-second timeout and no automatic retries. If Gemini is overloaded or times out, the UI shows a clear error and you can retry with **Generate test plan**.

The MacOne app is native .NET MAUI / WinUI 3 with no WebView2, so Playwright cannot attach to it. The desktop target therefore uses Windows UI Automation (`desktop-driver.ps1` driven by `desktop-session.js`):

- It attaches to the running MacOne window, or starts the app if it is not running, then brings it to the front and maximizes it.
- Before any step it checks that a QA label (for example "QA - Company") is visible. Sign in to the QA company first; the agent does not sign in to the desktop app.
- Steps use the same plan format. `role`, `text`, `label`, and `placeholder` locators are matched against the visible element names; clicks use the real mouse and typing uses keyboard input, because MAUI buttons ignore UI Automation invoke.
- `open` steps are skipped with a note, because the app has no page paths. Plans generated for the desktop target tell Gemini to navigate by clicking visible labels instead.
- Clicks, typing, and screenshots run only while MacOne is the foreground window. Keep the screen unlocked and do not use the mouse while tests run; a locked or disconnected RDP session stops the run.
- When a desktop case fails, a screenshot is saved next to the results in `MAC1-Desktop-QA-Assistant/output/`.

`PORTAL_CDP_URL` is still supported for a future desktop build that exposes a localhost WebView2 debugging endpoint. The web target is a separate alternative and uses the repository-root `.env`, requiring an HTTPS QA hostname.

The CLI is also available from the repository root:

```powershell
node .\MAC1-Desktop-QA-Assistant\qa-agent.js --target web "As a user, I want to ..."
node .\MAC1-Desktop-QA-Assistant\qa-agent.js --target web --execute "As a user, I want to ..."
node .\MAC1-Desktop-QA-Assistant\qa-agent.js --target desktop --execute "As a user, I want to ..."
node .\MAC1-Desktop-QA-Assistant\qa-agent.js --plan .\MAC1-Desktop-QA-Assistant\output\qa-agent-<id>-plan.json --execute
```

Without `--execute`, the agent only generates and saves a plan. With `--execute`, it displays the plan and asks for confirmation before opening the portal. To review a plan first and then execute that exact plan, use its saved path with `--plan ... --execute`; plan files must be inside `MAC1-Desktop-QA-Assistant/output/`. `PORTAL_CDP_URL` can be used to connect to an app that was started with debugging enabled, and must be a localhost URL.

Gemini receives the user story, not page contents, credentials, screenshots, or browser data. Generated actions use a small allow-listed UI-step format rather than executable model-generated code. External-origin navigation and destructive controls such as Delete, Remove, Cancel, Void, and Refund are rejected. Named records should use the unique `QA_AI_{RUN_ID}_...` prefix.

Plans and results are written under `MAC1-Desktop-QA-Assistant/output/` (ignored by Git). Tests may create or update records in the QA environment, so review each plan before confirming execution. The agent refuses a non-QA web hostname and checks for a QA label in the desktop app.

Run the local validation tests with `npm.cmd test` from `MAC1-Desktop-QA-Assistant`.
