---
name: qml-ui
description: >
  Use for QML/frontend work: creating or editing QML components in src/app/,
  binding to C++ adapter properties, JS helpers in src/app/js/, and UI layouts.
tools:
  - read_file
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

# QML UI Expert — Jami Client Qt

## Scope

- `src/app/commoncomponents/` — shared reusable QML widgets
- `src/app/mainview/components/` — main window components
- `src/app/settingsview/` — settings panels
- `src/app/wizardview/` — account creation wizard
- `src/app/js/` — JavaScript helpers

## Component Placement

| Type | Location |
|------|----------|
| Shared primitive (button, dialog, bubble) | `src/app/commoncomponents/` |
| Main window feature component | `src/app/mainview/components/` |
| Settings panel | `src/app/settingsview/components/` |

After creating a new file, add it to the `qmldir` or re-run:
```bash
python3 extras/scripts/gen_qml_qrc.py
```

## QML Conventions

- File names: `PascalCase.qml`. Internal IDs and properties: `camelCase`.
- Format with `qmlformat` via `python3 extras/scripts/format.py`.
- Bind to adapter `Q_PROPERTY` values — never call daemon code from JS.
- Call adapter actions via `Q_INVOKABLE` slots.
- All user-visible strings: `qsTr("...")`.
- Use `Connections { target: AdapterName; function onXxxChanged() { … } }` for signals.

## Checklist Before Done

- [ ] `qmlformat` applied (run `format.py`)
- [ ] No business logic or daemon calls in QML JS
- [ ] All user-visible strings wrapped in `qsTr()`
- [ ] New files registered in `qmldir` or QRC
- [ ] Component works on all three platforms (Linux, Windows, macOS) if applicable
