# Client Testing

## Confirmed Test Surfaces

### Unit Tests

Located in `tests/unittests/`.

Observed coverage includes:

- account behavior
- contact behavior
- conversation switching
- message parsing
- preview engine
- API token manager
- API server

### QML Tests

Located in `tests/qml/src/`.

Observed coverage includes:

- `tst_MainView.qml`
- `tst_ConversationListView.qml`
- `tst_ChatView.qml`
- `tst_MessageListView.qml`
- `tst_OngoingCallPage.qml`
- `tst_SettingsSidePanel.qml`
- `tst_WizardView.qml`
- several focused component tests

## Validation Strategy By Change Type

- Prefer test-first work when a nearby client test already exists or can be added cheaply.
- QML component change: run the closest matching QML test if it exists.
- Adapter/helper change: run or extend the relevant unit test if it exists.
- State-sync change: validate both the bound UI object and the underlying `src/libclient` model assumptions.
- Navigation/settings-shell change: check `MainView.qml`, `ViewCoordinator.qml`, or `SettingsView.qml` behavior explicitly.
- Client-side validation is only complete when the relevant client tests all pass and the affected client build target still builds cleanly.

## TDD Guidance

- QML behavior change with an existing `tests/qml/src/` case: update that test first so it fails on the intended behavior, then make the QML change.
- Adapter or helper change with nearby unit coverage: add or tighten the narrowest unit test first, then implement.
- State-sync change without a clean UI test: start from the narrowest model or helper test you can make deterministic, then use QML or manual validation as the second step.
- If the nearest realistic test is expensive or brittle, say that explicitly and fall back to the narrowest executable validation you can run.
- After the implementation, rerun every relevant client-side test you selected and confirm the touched build target still compiles before calling the change validated.

## Common Regression Risks

- account switch or selected-conversation rebinding
- stale message list source model after conversation changes
- call UI regressions that are really call-model sequencing issues
- settings changes that do not refresh affected views/data
- UI-only fixes that accidentally depend on one startup mode
- implementing UI behavior first and only afterwards discovering there is no deterministic client-side regression check

## To Confirm

- Some QML tests are component-scoped and may not capture the full end-to-end behavior of a boundary-sensitive change.
