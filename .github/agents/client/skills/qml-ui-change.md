# Name

QML UI Change

## Purpose

Modify Jami QML safely by starting from the real view owner, navigation path, and bound client state.

## When To Use

- Visual/layout/component changes in `src/app/mainview/`, `src/app/settingsview/`, or `src/app/wizardview/`.

## When Not To Use

- When the underlying state is wrong before it reaches QML.

## Required First Reads

- target QML file
- `src/app/MainApplicationWindow.qml`
- `src/app/mainview/MainView.qml` or `src/app/ViewCoordinator.qml` if routing is involved
- relevant adapter/current-state singleton

## Navigation Heuristics

- Find who presents the view.
- Find which singleton/model the view binds to.
- Check whether the component already has a matching QML test in `tests/qml/src/`.

## Investigation Strategy

1. Identify the exact component and its parent flow.
2. Identify bound state and imperative actions.
3. Confirm the state is already correct.
4. Make the smallest view/component edit.

## Output Format

- target component(s)
- bound state sources
- minimal edit plan
- validation plan

## Success Criteria

- The change is localized and does not silently alter navigation or state ownership.

## Risks / Pitfalls

- fixing visuals while masking upstream state bugs
- changing a reused component without checking other screens

## Escalation Rules

- Escalate if the change needs new adapter properties or daemon-backed state changes.
