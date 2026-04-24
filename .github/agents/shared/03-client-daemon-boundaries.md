# Client-Daemon Boundaries

This is the most important shared document for ownership decisions.

## Boundary Layers

Confirmed chain:

1. QML calls singleton adapters and reads singleton/models registered in `src/app/qmlregister.cpp`.
2. Adapters typically call `LRCInstance` in `src/app/lrcinstance.cpp`.
3. `LRCInstance` delegates into `lrc::api::Lrc` and per-account models in `src/libclient/`.
4. `src/libclient` talks to daemon-facing interfaces through either:
   - `src/libclient/dbus/` in DBus mode
   - `src/libclient/qtwrapper/` in libwrap/native mode
5. The daemon exposes public contracts in `daemon/src/jami/*.h`.
6. Concrete implementations live in `daemon/src/client/*.cpp` and delegate into `jami::Manager` and other daemon runtime modules.

## Exact Boundary Areas

Primary client-side seam files:

- `src/libclient/lrc.cpp`
- `src/libclient/callbackshandler.cpp`
- `src/libclient/dbus/configurationmanager.cpp`
- `src/libclient/dbus/callmanager.cpp`
- `src/libclient/dbus/instancemanager.cpp`
- `src/libclient/dbus/videomanager.cpp`
- `src/libclient/dbus/presencemanager.cpp`
- `src/libclient/dbus/pluginmanager.cpp`
- `src/libclient/qtwrapper/configurationmanager_wrap.h`
- `src/libclient/qtwrapper/callmanager_wrap.h`
- `src/libclient/qtwrapper/videomanager_wrap.h`
- `src/libclient/qtwrapper/instancemanager_wrap.h`

Primary daemon-side seam files:

- `daemon/src/jami/configurationmanager_interface.h`
- `daemon/src/jami/callmanager_interface.h`
- `daemon/src/jami/conversation_interface.h`
- `daemon/src/jami/datatransfer_interface.h`
- `daemon/src/jami/presencemanager_interface.h`
- `daemon/src/jami/videomanager_interface.h`
- `daemon/src/jami/plugin_manager_interface.h`
- `daemon/src/client/configurationmanager.cpp`
- `daemon/src/client/callmanager.cpp`
- `daemon/src/client/conversation_interface.cpp`
- `daemon/src/client/datatransfer.cpp`
- `daemon/src/client/presencemanager.cpp`
- `daemon/src/client/videomanager.cpp`
- `daemon/src/client/plugin_manager_interface.cpp`

## Contracts And Wrappers

- `daemon/src/jami/*.h` defines the public libjami method surface.
- `daemon/src/client/*.cpp` implements those methods against `jami::Manager`, account instances, conversation modules, and media runtime.
- `src/libclient/qtwrapper/*.h` exposes QObject-friendly wrappers around libjami calls and callback maps in native/libwrap mode.
- `src/libclient/dbus/*.cpp` creates DBus-backed interfaces in DBus mode and validates DBus connection/interface availability.

## State And Event Propagation

Client receives daemon-originated events through `CallbacksHandler`:

- `src/libclient/callbackshandler.cpp` connects `ConfigurationManagerInterface`, `CallManagerInterface`, `PresenceManagerInterface`, and `VideoManagerInterface` signals to Qt slots/signals.
- The wrapper or DBus interface emits daemon-originated signals.
- `CallbacksHandler` fans them into `AccountModel`, `CallModel`, `ConversationModel`, `BehaviorController`, and related consumers.
- `src/app` objects then consume these updated models or react to `LRCInstance`/behavior-controller changes.

Examples confirmed from code:

- Account and registration events: `daemon/src/client/configurationmanager.cpp` -> wrapper/DBus manager -> `src/libclient/callbackshandler.cpp` -> `AccountModel` and UI-facing state.
- Conversation/message methods: `MessagesAdapter` -> `ConversationModel` -> daemon `conversation_interface` implementation -> `JamiAccount::convModule(...)`.
- Call methods: `CallAdapter` or `CallModel` -> `CallManager::instance()` wrapper -> `daemon/src/client/callmanager.cpp` -> `jami::Manager`.

## What Typically Breaks When One Side Changes

- New or changed libjami methods without corresponding DBus/libwrap wrapper updates.
- New callback payloads or enum/string conventions not converted in `src/libclient/qtwrapper/*` or consumed correctly in `CallbacksHandler`.
- State ordering changes in daemon that break client assumptions in `CurrentConversation`, `CurrentCall`, `CallAdapter`, or `MessagesAdapter`.
- Changes made only for DBus mode or only for libwrap mode.
- A new signal connected in `src/libclient/callbackshandler.cpp` without a matching signal declaration in both the relevant `src/libclient/dbus/*.cpp` interface and the relevant `src/libclient/qtwrapper/*_wrap.h`. The signal will be silently dropped on whichever transport path was not updated.

## Always Inspect These Files When Boundary Impact Is Suspected

- `src/app/lrcinstance.cpp`
- `src/libclient/lrc.cpp`
- `src/libclient/callbackshandler.cpp`
- the relevant file in `src/libclient/dbus/`
- the relevant file in `src/libclient/qtwrapper/`
- the relevant interface header in `daemon/src/jami/`
- the relevant implementation file in `daemon/src/client/`

## Ownership Heuristic

- If the method or signal is wrong before it reaches `src/libclient`, investigate daemon ownership.
- If the method/signal is correct at the wrapper layer but wrong in model/state propagation, investigate client/libclient ownership.
- If both contract and consumer must change, keep the task `CROSS_CUTTING`.

## To Confirm

- Some less common plugin-specific and platform-specific boundary paths need deeper inspection when those tasks arise.
