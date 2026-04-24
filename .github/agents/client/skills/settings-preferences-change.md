# Name

Settings Preferences Change

## Purpose

Safely modify Jami settings UI and preference propagation.

## When To Use

- changes in `src/app/settingsview/` or app/account preference behavior.

## When Not To Use

- when the change is actually a daemon runtime feature with no client-side settings work yet

## Required First Reads

- `src/app/settingsview/SettingsView.qml`
- `src/app/settingsview/SettingsSidePanel.qml`
- target page in `src/app/settingsview/components/`
- `src/app/appsettingsmanager.*`
- `src/app/accountsettingsmanager.*`
- `src/app/utilsadapter.cpp`

## Navigation Heuristics

- Separate app-local settings from daemon-backed settings.
- Check for side effects on view refresh after settings changes.

## Investigation Strategy

1. Identify the target page and setting owner.
2. Confirm whether the setting is local or daemon-backed.
3. Update the narrowest UI and propagation path.
4. Check any required post-change refresh behavior.

## Output Format

- target setting
- owner
- affected page and propagation path
- validation plan

## Success Criteria

- The setting is changed at the correct owner and reflected in the right page/workflow.

## Risks / Pitfalls

- changing a daemon-backed setting as if it were only local

## Escalation Rules

- Escalate when new daemon configuration methods or state are required.
