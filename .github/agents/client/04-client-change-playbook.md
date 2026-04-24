# Client Change Playbook

## Bugfix Strategy

1. Start from the failing view, adapter, or current-state object.
2. Confirm whether the wrong state is already wrong in `src/libclient` or only wrong in `src/app`/QML consumption.
3. If the state is already wrong before QML, escalate to shared or daemon analysis.
4. Keep the fix close to the client owner: target component, adapter, state singleton, or app-local helper.

## Feature Strategy

1. Decide whether the feature is truly client-only.
2. If new runtime capability or new daemon event is needed, reclassify as `CROSS_CUTTING` before editing.
3. For client-only features, wire them through existing patterns:
   - register in `qmlregister.cpp` if new QML exposure is needed
   - use adapter singleton patterns for imperative actions
   - use model/current-state properties for reactive state

## UI-Only Change Strategy

- Prefer editing the narrowest target QML file.
- Check whether the view is created/presented by `ViewCoordinator.qml` or nested inside a larger shell component.
- Reuse existing adapter/model properties instead of creating duplicate local state when possible.

## State Synchronization Strategy

- For selection/account issues, inspect `LRCInstance`, `CurrentConversation`, `CurrentCall`, and `MessagesAdapter` first.
- Confirm that rebinding occurs on `currentAccountIdChanged` or `selectedConvUidChanged` where appropriate.
- If a fix touches derived state fed from daemon models, read the owning `src/libclient/*model.cpp` before editing.

## Escalate To Shared Or Daemon When

- The client is only exposing incorrect upstream state.
- The fix needs a new libjami method, signal, or payload.
- The touched path crosses `src/libclient/dbus/` or `src/libclient/qtwrapper/`.

## Client Review Checklist

- Is the state actually client-owned?
- Did the fix preserve account-switch and conversation-switch behavior?
- Did QML bindings continue to use existing singleton/model patterns?
- Was the narrowest matching QML/unit test updated or at least checked?
- If settings were touched, was post-settings refresh behavior considered?
