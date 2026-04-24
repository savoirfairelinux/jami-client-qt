# Daemon Hotspots

## `daemon/src/manager.cpp` and `daemon/src/manager.h`

- Main runtime hub for init, accounts, calls, conferences, and media coordination.
- Large blast radius for lifecycle and state changes.

## `daemon/src/client/configurationmanager.cpp`

- Broad client-facing configuration/account/device/security surface.
- High risk for contract drift with client wrappers.

## `daemon/src/client/callmanager.cpp`

- Primary public surface for call and conference actions.
- High risk for client-visible behavior changes.

## `daemon/src/client/conversation_interface.cpp`

- Primary public surface for Jami conversation/message operations.
- High risk for message, reaction, preference, and search regressions.

## `daemon/src/jamidht/conversation_module.cpp`

- Core Jami conversation ownership and behavior.
- High risk for sync, lifecycle, and repository integration regressions.

## `daemon/src/jamidht/conversationrepository.cpp`

- Persistence-heavy hotspot for conversation history/state.
- High risk for load/search/history regressions.

## `daemon/src/sip/sipcall.cpp`

- SIP call behavior and state transitions.
- High risk for negotiation/hold/resume/recording/media regressions.

## `daemon/src/conference.cpp`

- Conference lifecycle and participant coordination.
- High risk for multi-party call behavior.

## `daemon/src/media/audio/ringbufferpool.cpp`

- Central audio mixing/binding point.
- High risk for broad call/conference audio regressions.

## `daemon/src/plugin/`

- Plugin runtime and service hooks.
- High risk when client-visible plugin behavior or lifecycle changes.
