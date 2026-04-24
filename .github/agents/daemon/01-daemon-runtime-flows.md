# Daemon Runtime Flows

## Startup / Init

Confirmed path:

- `daemon/bin/dbus/main.cpp` parses daemon CLI options and calls `libjami::init()`.
- `daemon/src/jami.cpp` configures logging/debug flags and forces `Manager::instance()` creation.
- `libjami::start()` delegates to `Manager::init(...)`.
- `Manager::init(...)` sets up runtime services, configuration parsing, account loading, media support, and related daemon services.

## Account Lifecycle

- Configuration/account methods enter through `daemon/src/client/configurationmanager.cpp`.
- `Manager` owns account lifecycle and looks up the correct account type.
- `AccountFactory` creates `SIPAccount` or `JamiAccount` implementations.
- Registration and account details propagate back out through configuration signals/callbacks.

## Conversation / Message Handling

Jami conversation path:

- client-facing method enters via `daemon/src/client/conversation_interface.cpp`
- for Jami accounts, the code uses `JamiAccount::convModule(true)`
- `ConversationModule` owns conversation actions such as start, accept, remove, load, message send, edit, react, member changes, and search
- persistence/sync-related state is handled through conversation repository and related JamiDHT modules

SIP/account-message path:

- account message methods also exist through configuration/call/messaging support in the daemon
- `daemon/src/im/instant_messaging.cpp` and related helpers are part of the messaging path

## Call Flow

Confirmed public path:

- client-facing call operations enter via `daemon/src/client/callmanager.cpp`
- `callmanager.cpp` delegates into `jami::Manager` or directly into account/call/conference objects where appropriate
- `Manager` coordinates outgoing call creation, accept/refuse, hold/resume, transfer, conference operations, and current runtime ownership

Relevant runtime owners:

- `Call`
- `Conference`
- `SIPCall`
- `SIPVoIPLink`

## Media Handling

- client-facing media and device operations use configuration/video manager interfaces
- runtime audio ownership is under `daemon/src/media/audio/`
- runtime video ownership is under `daemon/src/media/video/`
- codec/container support is coordinated through `system_codec_container` and related media helpers

## Transport / Network / Protocol Flow

- SIP transport/runtime lives under `daemon/src/sip/`
- Jami/DHT transport and sync live under `daemon/src/jamidht/`
- connection/channel inspection helpers are exposed through configuration methods and `Manager` helpers

## Persistence / State Transitions

- account configuration is parsed and loaded during manager init
- conversation history and repository-backed state are owned by Jami conversation modules/repositories
- call and conference state transitions propagate through call-related classes and then back out via callbacks

## To Confirm

- Some exact persistence boundaries and lower-level transport sequencing require deeper inspection for risky daemon changes.
