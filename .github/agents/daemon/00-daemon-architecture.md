# Daemon Architecture

## Lifecycle Entry Points

Confirmed path:

- `daemon/bin/dbus/main.cpp` is the DBus service entry point.
- It calls `libjami::init()` and `libjami::start()`.
- `daemon/src/jami.cpp` implements those libjami lifecycle entry points and delegates runtime ownership into `jami::Manager::instance()`.
- `daemon/src/manager.cpp` and `daemon/src/manager.h` define the main daemon control hub.

## Major Subsystems

### Manager And Global Runtime Ownership

Primary files:

- `daemon/src/manager.h`
- `daemon/src/manager.cpp`

Responsibilities:

- daemon init/finish
- preferences and global runtime configuration
- account collection and lookup
- outgoing/incoming call orchestration
- conference operations
- media driver setup
- connection/channel inspection helpers

### Public Client-Facing Contracts

Primary files:

- `daemon/src/jami/callmanager_interface.h`
- `daemon/src/jami/configurationmanager_interface.h`
- `daemon/src/jami/conversation_interface.h`
- `daemon/src/jami/datatransfer_interface.h`
- `daemon/src/jami/presencemanager_interface.h`
- `daemon/src/jami/videomanager_interface.h`
- `daemon/src/jami/plugin_manager_interface.h`

These headers are the stable contract surface consumed through DBus wrappers or libwrap wrappers.

### Client-Facing Interface Implementations

Primary files:

- `daemon/src/client/callmanager.cpp`
- `daemon/src/client/configurationmanager.cpp`
- `daemon/src/client/conversation_interface.cpp`
- `daemon/src/client/datatransfer.cpp`
- `daemon/src/client/presencemanager.cpp`
- `daemon/src/client/videomanager.cpp`
- `daemon/src/client/plugin_manager_interface.cpp`

These files translate public libjami calls into `Manager`, account objects, conversation modules, media managers, and plugin services.

### Account Subsystems

Primary files:

- `daemon/src/account.*`
- `daemon/src/account_factory.*`
- `daemon/src/sip/sipaccount.*`
- `daemon/src/jamidht/jamiaccount.*`

Split:

- SIP accounts are owned under `daemon/src/sip/`.
- Jami/DHT accounts are owned under `daemon/src/jamidht/`.

### Conversation / Messaging Subsystems

Primary files:

- `daemon/src/client/conversation_interface.cpp`
- `daemon/src/jamidht/conversation_module.cpp`
- `daemon/src/jamidht/conversationrepository.cpp`
- `daemon/src/jamidht/conversation.cpp`
- `daemon/src/im/instant_messaging.cpp`
- `daemon/src/im/message_engine.cpp`

### Call / Conference Subsystems

Primary files:

- `daemon/src/client/callmanager.cpp`
- `daemon/src/call.*`
- `daemon/src/call_factory.*`
- `daemon/src/conference.*`
- `daemon/src/sip/sipcall.*`
- `daemon/src/sip/sipvoiplink.*`

### Media Subsystems

Primary directories:

- `daemon/src/media/audio/`
- `daemon/src/media/video/`
- `daemon/src/client/videomanager.cpp`

Important supporting files:

- `daemon/src/media/system_codec_container.*`
- `daemon/src/media/audio/ringbufferpool.*`

### Plugin Subsystems

Primary directory:

- `daemon/src/plugin/`

Important files:

- `jamipluginmanager.*`
- `pluginmanager.*`
- `callservicesmanager.*`
- `chatservicesmanager.*`
- `preferenceservicesmanager.*`
- `webviewservicesmanager.*`

## Data And Control Flow

- External client calls enter through libjami interface methods.
- Interface implementations use `Manager` and account-specific modules.
- Runtime state is distributed across accounts, calls/conferences, conversation modules, media layers, and plugins.
- Signals/callbacks are published back through the client-facing signal system consumed by wrappers and the client.

## Integration Points Exposed To The Client

- libjami interface headers under `daemon/src/jami/`
- DBus managers instantiated by `daemon/bin/dbus/main.cpp`
- signal/callback registrations used by wrappers on the client side

## Central Files And Classes

- `jami::Manager`
- `JamiAccount`
- `SIPAccount`
- `ConversationModule`
- `ConversationRepository`
- `Call`
- `Conference`
- `SIPCall`
- video/audio manager implementations

## To Confirm

- Some thread and ownership details inside media, conference, and plugin internals need deeper task-specific inspection before risky refactors.
