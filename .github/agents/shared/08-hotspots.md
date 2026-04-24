# Hotspots

## Client Hotspots

### `src/app/mainapplication.cpp`

Why it matters:

- Startup orchestration, service initialization, `LRCInstance` creation, QML engine loading, daemon reconnect handling, systray/API wiring.

Typical change types:

- startup fixes
- app lifecycle behavior
- service exposure to QML

Danger signs:

- Adding more startup work before QML loads.
- Changing daemon availability handling without checking Unix reconnect flow.

### `src/app/qmlregister.cpp`

Why it matters:

- Single registry for adapters, models, image providers, and QML-visible singleton objects.

Typical change types:

- exposing new client capability
- registering new helper/model

Danger signs:

- Forgetting object ownership, context property setup, or singleton creation pattern.

### `src/app/lrcinstance.cpp`

Why it matters:

- App-side root object for account, call, conversation, connectivity, and plugin access.

Typical change types:

- state synchronization
- account switching
- app-wide behaviors tied to model ownership

Danger signs:

- stale per-account model references
- accidental cross-account assumptions

### `src/libclient/callbackshandler.cpp`

Why it matters:

- Central callback fan-in for configuration, presence, call, transfer, and related events.

Typical change types:

- signal wiring
- event adaptation
- contract-consumer synchronization

Danger signs:

- missing one callback path
- breaking signal ordering assumptions

### `src/libclient/conversationmodel.cpp`

Why it matters:

- conversation and interaction state, message loading, transfer interaction integration, search/load behavior.

Danger signs:

- touching message/transfer logic without checking conversation persistence and callback paths

### `src/libclient/callmodel.cpp`

Why it matters:

- call state, conference logic, current-call behavior, participant models, media change handling.

Danger signs:

- cross-account hold behavior changes
- conference participant assumptions

## Daemon Hotspots

### `daemon/src/manager.cpp` and `daemon/src/manager.h`

Why they matter:

- daemon control hub, runtime initialization, account/call/media ownership, and many public behaviors.

Danger signs:

- edits with unclear thread/state consequences
- global lifecycle changes without targeted validation

### `daemon/src/client/configurationmanager.cpp`

Why it matters:

- major account/configuration/device/security interface surface exposed to clients.

Danger signs:

- contract changes not mirrored in wrappers/consumers

### `daemon/src/client/callmanager.cpp`

Why it matters:

- primary call/conference interface surface exposed to clients.

Danger signs:

- changing call semantics without validating `CallModel` and current-call consumers

### `daemon/src/client/conversation_interface.cpp`

Why it matters:

- primary conversation/message interface surface exposed to clients.

Danger signs:

- changing message flags or conversation behavior without validating `ConversationModel` and `MessagesAdapter`

### `daemon/src/jamidht/conversation_module.cpp` and `daemon/src/jamidht/conversationrepository.cpp`

Why they matter:

- conversation lifecycle, sync, repository-backed interaction state.

Danger signs:

- persistence or sync behavior changes that look local but affect client message loading/search state

### `daemon/src/sip/sipcall.cpp` and `daemon/src/conference.cpp`

Why they matter:

- call negotiation/conference runtime details.

Danger signs:

- state transitions, conference binding, or media handling touched without call regression review

### `daemon/src/media/audio/ringbufferpool.cpp`

Why it matters:

- central audio mixing/binding hub affecting call/conference audio behavior.

Danger signs:

- apparently small audio changes causing broad runtime regressions
