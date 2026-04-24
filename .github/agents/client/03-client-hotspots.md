# Client Hotspots

## `src/app/mainapplication.cpp`

- Central startup and app-service initialization.
- Touches daemon reconnect handling, type registration timing, API server exposure, and tray setup.
- Risk: startup regressions and invisible QML/context-property failures.

## `src/app/qmlregister.cpp`

- Registry for adapters, models, and singleton objects.
- Risk: features silently missing from QML or object-ownership mistakes.

## `src/app/lrcinstance.cpp`

- Central app-side access to account, conversation, call, AV, and plugin models.
- Risk: stale current-account/current-conversation assumptions and cross-account behavior bugs.

## `src/app/currentconversation.cpp`

- Aggregates selected conversation state for the UI.
- Reads conversation mode, title, members, call state, preferences, and temporary/contact flags.
- Risk: stale or partially updated derived state after account or conversation switches.

## `src/app/currentcall.cpp`

- Aggregates current call state and drives call-centric UI.
- Risk: incorrect rebinding when account/call context changes.

## `src/app/calladapter.cpp`

- Bridges QML call actions to `CallModel` and handles notification behavior.
- Risk: mismatched call/account context, notification side effects, and multi-account call edge cases.

## `src/app/messagesadapter.cpp`

- Bridges conversation messaging UI to `ConversationModel` and swaps the source model when selection changes.
- Risk: stale model binding, message-list regressions, and preview/parsing side effects.

## `src/app/mainview/MainView.qml` and `src/app/ViewCoordinator.qml`

- Drive main navigation and view stack behavior.
- Risk: apparently simple routing changes affecting many views.

## `src/app/settingsview/SettingsView.qml`

- Routes all settings pages and mixes app-local with daemon-backed settings.
- Risk: hidden coupling across settings pages and stale post-settings behavior.

## `src/libclient/callbackshandler.cpp`

- Although shared with the boundary, this is also a client hotspot because many client-visible state changes depend on its signal wiring.
