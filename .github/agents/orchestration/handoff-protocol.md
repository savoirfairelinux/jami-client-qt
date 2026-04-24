# Handoff Protocol

Use this format whenever work moves between `client`, `daemon`, `shared`, or the orchestrator.

## Required Handoff Contents

- Task summary
- Why another set is likely impacted
- Relevant files, classes, functions, and runtime flow
- Hypotheses to verify
- Risk if not escalated
- Expected validation
- Recommended next specialist

## Handoff Template

```text
Task summary:
<one paragraph>

Why another set is likely impacted:
<what changed or what seems owned elsewhere>

Relevant anchors:
- file/class/function
- file/class/function
- runtime flow: QML -> adapter -> model -> wrapper -> libjami -> daemon

Hypotheses to verify:
- hypothesis 1
- hypothesis 2

Risk if not escalated:
- risk 1
- risk 2

Expected validation:
- test/build/check 1
- test/build/check 2

Recommended next specialist:
<agent or set>
```

## Client -> Daemon

Use when:

- The client state appears to mirror incorrect daemon data.
- The adapter/model path is intact but the source contract or runtime behavior is wrong.
- A new client feature needs new libjami support.

Typical anchors to include:

- `src/app/*adapter.cpp`
- `src/app/lrcinstance.cpp`
- `src/libclient/callbackshandler.cpp`
- `src/libclient/dbus/*.cpp` or `src/libclient/qtwrapper/*.h`
- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`

## Daemon -> Client

Use when:

- Daemon behavior is correct but the client does not expose or consume it correctly.
- The contract is present but not surfaced to QML or not rebound across account/conversation changes.

Typical anchors to include:

- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`
- `src/libclient/callbackshandler.cpp`
- `src/app/currentconversation.cpp`
- `src/app/currentcall.cpp`
- `src/app/messagesadapter.cpp`
- related QML file under `src/app/mainview/` or `src/app/settingsview/`

## Either Side -> Shared / Boundary Analyst

Use when:

- Ownership is still ambiguous after one or two local reads.
- The task touches wrappers, callback sequencing, build flags, startup modes, or both DBus and libwrap paths.

Typical anchors to include:

- `src/libclient/lrc.cpp`
- `src/libclient/dbus/`
- `src/libclient/qtwrapper/`
- `daemon/src/jami/*.h`
- `daemon/src/client/*.cpp`
- top-level `CMakeLists.txt`

## Router -> Specialist

The router should hand off only after classifying the task. If classification remains unclear, route to boundary analysis before assigning client or daemon ownership.
