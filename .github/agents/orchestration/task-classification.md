# Task Classification

Use one of these categories for every task:

- `CLIENT_ONLY`
- `DAEMON_ONLY`
- `CROSS_CUTTING`
- `UNCERTAIN_REQUIRES_BOUNDARY_CHECK`

Do not classify from symptoms alone. A QML regression can still be caused by model state from `src/libclient`, and a daemon-side contract change can show up as a client crash or stale UI.

## `CLIENT_ONLY`

Definition:

- The requested behavior is owned by QML, app-level QObject adapters, view navigation, local settings/UI policy, or client-side presentation logic.

Typical triggers:

- Layout, navigation, styling, selection behavior, local keyboard shortcuts, tray/UI reactions.
- QML component bugs in `src/app/mainview/`, `src/app/settingsview/`, `src/app/wizardview/`.
- Adapter-local behavior where daemon contracts are consumed but not changed.

Typical code locations:

- `src/app/MainApplicationWindow.qml`
- `src/app/mainview/`
- `src/app/settingsview/`
- `src/app/ViewCoordinator.qml`
- `src/app/*adapter.cpp`
- `src/app/currentconversation.cpp`
- `src/app/currentcall.cpp`
- `src/app/currentaccount.cpp`
- `src/app/appsettingsmanager.*`

Validation strategy:

- QML tests in `tests/qml/src/` when a matching component exists.
- Unit tests in `tests/unittests/` for adapter/helper logic.
- Manual reasoning against the bound singleton/model and view transitions.

Common mistakes:

- Treating `src/app` as the whole client when the bug is in `src/libclient` signal/model synchronization.
- Missing per-account model rebinding on account or conversation switches.

Misclassification signals:

- The fix needs changes in `src/libclient/` or contract wrappers.
- The bug involves incorrect account, call, message, or transfer state delivered from daemon callbacks.

Escalate when:

- A client adapter calls into `LRCInstance` or a model and the state itself appears wrong.
- The task needs new libjami methods, new callback payloads, or daemon-side event timing changes.

## `DAEMON_ONLY`

Definition:

- The requested behavior is owned by libjami or daemon runtime and can be changed without modifying client-side consumption semantics.

Typical triggers:

- Account lifecycle, SIP or Jami registration, call negotiation, conferences, message routing, conversation persistence, media pipeline, plugin engine, transport/network issues.
- DHT state, swarm routing topology, distributed routing tables, network peer connectivity \u2014 these originate in `daemon/src/jamidht/` and must be audited there first, even when the end goal is a UI visualization.

Typical code locations:

- `daemon/src/manager.*`
- `daemon/src/client/*.cpp`
- `daemon/src/jami/*.h`
- `daemon/src/jamidht/`
- `daemon/src/sip/`
- `daemon/src/media/`
- `daemon/src/plugin/`
- `daemon/test/unitTest/`

Validation strategy:

- Daemon unit/simulation tests in `daemon/test/`.
- Targeted runtime flow validation through existing client-facing interfaces.
- Build validation through daemon CMake/Meson surfaces when contracts or options move.

Common mistakes:

- Assuming the client does not need changes when libjami payload shape, state sequencing, or callback timing changes.
- Ignoring DBus/libwrap wrapper expectations in `src/libclient`.

Misclassification signals:

- The visible bug is caused by client-side selection, filtering, formatting, or QML-only state.
- The change requires new adapter properties, QML exposure, or client-side rebinding logic.

Escalate when:

- Any interface header under `daemon/src/jami/` changes.
- Any daemon signal or manager method exposed through `src/libclient/dbus/` or `src/libclient/qtwrapper/` changes.

## `CROSS_CUTTING`

Definition:

- The task requires coordinated changes on both sides of the client/daemon boundary, or it affects shared contracts, callback sequencing, or wrapper logic.

Typical triggers:

- New call/message/account capabilities that need daemon support and client exposure.
- Contract changes in libjami methods or callback payloads.
- State propagation issues that cross `daemon/src/client/*.cpp`, `src/libclient/callbackshandler.cpp`, and `src/app/*` consumers.
- Build option or packaging changes that alter how daemon and client are wired.

Typical code locations:

- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`
- `src/libclient/dbus/`
- `src/libclient/qtwrapper/`
- `src/libclient/callbackshandler.cpp`
- `src/libclient/lrc.cpp`
- `src/app/lrcinstance.cpp`
- top-level `CMakeLists.txt`

Validation strategy:

- Validate contract compilation/build surfaces.
- Validate both producer and consumer paths.
- Run the narrowest relevant client and daemon tests that cover the touched flow.

Common mistakes:

- Making only the producer or only the consumer change.
- Updating DBus path but not libwrap path, or vice versa.
- Forgetting that client builds can use `ENABLE_LIBWRAP` and non-libwrap modes.

Misclassification signals:

- The work unexpectedly touches wrapper conversion, callback fan-out, or signal handling.
- Tests fail in both client and daemon surfaces after an apparently local change.

Escalate when:

- Contract, callback, wrapper, or startup/build wiring changes are involved.

## `UNCERTAIN_REQUIRES_BOUNDARY_CHECK`

Definition:

- Ownership is not yet proven. Start from the boundary and classify only after reading the real code path.

Typical triggers:

- A user-facing bug where the state source is unknown.
- Regressions involving message lists, calls, account state, transfers, device state, or plugin behavior.
- Any task described in product terms rather than file/module terms.

Typical first reads:

- `src/app/lrcinstance.cpp`
- `src/libclient/lrc.cpp`
- `src/libclient/callbackshandler.cpp`
- matching wrapper under `src/libclient/dbus/` or `src/libclient/qtwrapper/`
- matching daemon interface in `daemon/src/jami/`
- matching daemon implementation in `daemon/src/client/`

Validation strategy:

- Identify the producer of the state and the consumer of the state.
- Confirm whether the wrong behavior originates before or after `src/libclient` adaptation.

Common mistakes:

- Starting in QML because the symptom is visible there.
- Starting in daemon because the feature sounds backend-heavy without checking local client filtering/binding.

Escalate when:

- The first boundary read shows data shape or event timing crossing multiple layers.
