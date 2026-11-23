# Portal — automated tests (Playwright)

The tests run against the QA portal at `QA_BASE_URL` in `.env`. Docs and test cases live in [docs/portal/](../../docs/portal/).

## Layout

```
tests/portal/
├── portal.setup.js            # logs in once and saves playwright/.auth/portal-user.json
├── support/portal.js          # generic XAF helpers (openView, searchGrid, button, uniqueName…)
├── smoke/                     # quick checks that the environment and login work
└── <story-slug>/              # one folder per user story, e.g. service-item-group/
    ├── support/               # page objects for this story only
    └── <area>.spec.js         # e.g. list.spec.js, form.spec.js
```

## Commands

| Command | What it runs |
|---|---|
| `npm run test:portal` | All portal tests (login setup first) |
| `npm run test:portal:smoke` | Smoke checks only |
| `npm run test:portal:headed` | All portal tests in a visible browser |
| `npm run test:portal:ui` | Playwright UI mode |
| `npm run report` | Open the last HTML report |

Run a single story with `npx playwright test --project=portal tests/portal/<story-slug>`.

## Conventions

- **Test titles** start with the case ID, e.g. `test('TC-PRT-SIG-001 Group list shows ...')`.
- **Test data** is named with `uniqueName(tag)`, which gives `QA_AUTO_<RUN_ID>_<tag>`.
- **Grid layouts** are per user on the server, so restore any layout change a test makes.
