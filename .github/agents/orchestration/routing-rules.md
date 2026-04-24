# Routing Rules

## Start In `client` When

- The task is explicitly about QML structure, visual behavior, navigation, settings screens, shortcuts, or tray/UI interactions.
- The touched files are in `src/app/mainview/`, `src/app/settingsview/`, `src/app/wizardview/`, or app-local adapters.
- The expected fix does not require new daemon methods or callback payload changes.

## Start In `daemon` When

- The task is explicitly about registration, networking, conversation sync, call negotiation, conference logic, media devices, audio/video pipeline, plugins, or DBus service behavior.
- The issue reproduces independently of the specific QML view.
- The likely owners are in `daemon/src/manager.*`, `daemon/src/client/`, `daemon/src/jamidht/`, `daemon/src/sip/`, or `daemon/src/media/`.
- The feature involves DHT state, swarm topology, routing tables, connectivity graphs, or network peer visibility — these are produced by `daemon/src/jamidht/` and must be audited there before touching `src/libclient` or any adapter.

## Start In `shared` When

- The task description is user-facing but the ownership is unclear.
- The change may involve wrappers, callbacks, libjami contracts, or startup/build wiring.
- The first suspected files include both `src/libclient` and `daemon/src`.

## Request Cross-Review When

- A libjami interface header changes.
- A daemon callback shape or signal timing changes.
- `src/libclient/dbus/` and `src/libclient/qtwrapper/` both should stay aligned.
- `src/app/lrcinstance.cpp`, `src/libclient/lrc.cpp`, or `src/libclient/callbackshandler.cpp` changes.
- Build options affecting daemon embedding or tests change.
- Any new signal is wired in `src/libclient/callbackshandler.cpp`: verify the matching interface exists in both `src/libclient/dbus/` (DBus mode) and `src/libclient/qtwrapper/` (libwrap mode) before committing.

## Escalation Signals

- The task unexpectedly crosses `src/app`, `src/libclient`, and `daemon/src`.
- A visible UI bug is traced to `ConversationModel`, `CallModel`, `AccountModel`, or callback fan-in.
- A daemon change requires corresponding updates in adapters, current-state singletons, or QML registration.
- Tests fail in another set after a seemingly local fix.

## Routing Priority

1. If uncertain, classify as `UNCERTAIN_REQUIRES_BOUNDARY_CHECK`.
2. Read `orchestration/task-classification.md` and assign a classification before modifying any file.
3. Determine whether the incorrect behavior originates before or after `src/libclient` adaptation.
4. Route local consumer issues to `client`.
5. Route local producer/runtime issues to `daemon`.
6. Keep `CROSS_CUTTING` when the contract or callback seam is touched.
