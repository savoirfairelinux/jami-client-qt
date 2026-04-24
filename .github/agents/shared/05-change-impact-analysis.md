# Change Impact Analysis

## Safe Order Of Investigation

1. Classify the task.
2. Identify the visible consumer.
3. Identify the first model/adapter/wrapper feeding that consumer.
4. Identify the producing daemon interface or runtime owner.
5. Decide whether the change is local or cross-cutting.
6. Only then edit.

## Impact Patterns

### Local UI / View Impact

Typical indicators:

- QML-only behavior is wrong.
- The underlying client state is already correct.
- No wrapper or model contract changes are needed.

Typical blast radius:

- one view/component
- one adapter or one current-state object
- matching QML tests

### Client State Synchronization Impact

Typical indicators:

- State is wrong in `CurrentConversation`, `CurrentCall`, `CurrentAccount`, or adapter-facing properties.
- Account or conversation switches produce stale state.
- `CallbacksHandler` and model rebinding matter.

Typical blast radius:

- `src/app/lrcinstance.cpp`
- `src/app/current*.cpp`
- `src/app/*adapter.cpp`
- matching `src/libclient/*model.cpp`

### Boundary / Contract Impact

Typical indicators:

- New daemon method or event needed.
- Existing payload shape or meaning changed.
- Both DBus and libwrap paths matter.

Typical blast radius:

- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`
- `src/libclient/dbus/`
- `src/libclient/qtwrapper/`
- `src/libclient/callbackshandler.cpp`

### Runtime Core Impact

Typical indicators:

- Call, conversation sync, registration, media, or plugin engine behavior changes at the daemon owner.

Typical blast radius:

- `daemon/src/manager.*`
- domain runtime module under `daemon/src/jamidht/`, `daemon/src/sip/`, `daemon/src/media/`, `daemon/src/plugin/`

## Local-vs-Cross-Cutting Signals

Likely local:

- Only QML binding or view coordination is wrong.
- The model data already matches expectations.

Likely cross-cutting:

- `src/libclient` wrappers or callbacks are touched.
- The same concept appears in client UI, libclient model, and daemon interface.
- Build flags or startup mode affect the behavior.

## Dependency Tracing Strategy

- For QML-initiated actions, trace forward:
  - QML -> adapter -> `LRCInstance` or model -> wrapper/interface -> daemon implementation
- For bad displayed state, trace backward:
  - QML binding -> current-state singleton/adapter -> model -> callback/wrapper -> daemon event producer

## Regression Patterns

- DBus mode updated but libwrap mode forgotten.
- Current-account or selected-conversation rebinding not updated.
- Callback fan-in updated but downstream current-state/QML assumptions unchanged.
- Cross-account call behavior changed by touching current call focus logic.
- Build/test toggles changed without validating both client and daemon surfaces.
