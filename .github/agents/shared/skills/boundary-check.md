# Name

Boundary Check

## Purpose

Determine whether a task belongs to the client, daemon, or a coordinated cross-cutting path by tracing the real seam through `src/app`, `src/libclient`, and `daemon/src`.

## When To Use

- The symptom is visible in UI but ownership is unclear.
- The task mentions calls, messages, accounts, transfers, devices, plugins, or settings with uncertain origin.
- The change may involve wrappers, callbacks, or libjami contracts.

## When Not To Use

- The task is clearly isolated to a single QML component with correct upstream state.
- The task is clearly isolated to an internal daemon runtime module with no contract/consumer changes.

## Required First Reads

- `src/app/lrcinstance.cpp`
- `src/libclient/lrc.cpp`
- `src/libclient/callbackshandler.cpp`
- relevant file in `src/libclient/dbus/` or `src/libclient/qtwrapper/`
- relevant header in `daemon/src/jami/`
- relevant implementation in `daemon/src/client/`

## Navigation Heuristics

- For user action flows, trace forward from QML or adapter to daemon interface.
- For wrong displayed state, trace backward from current-state singleton or model to the daemon event producer.
- Check both DBus and libwrap surfaces if the seam is touched.

## Investigation Strategy

1. Identify the consumer showing the symptom.
2. Identify the first adapter/model/current-state object feeding it.
3. Identify the wrapper/interface carrying the data.
4. Identify the daemon producer.
5. Decide whether the defect originates before or after `src/libclient` adaptation.

## Output Format

- Classification: `CLIENT_ONLY`, `DAEMON_ONLY`, `CROSS_CUTTING`, or `UNCERTAIN_REQUIRES_BOUNDARY_CHECK`
- Trace: `consumer -> adapter/model -> wrapper/interface -> daemon owner`
- Confirmed evidence: files/classes/functions
- Uncertainties: `To confirm`
- Recommended next specialist

## Success Criteria

- Ownership is justified with concrete code anchors.
- The next agent knows where to start editing.

## Risks / Pitfalls

- Treating `src/app` as the whole client.
- Forgetting the alternate DBus/libwrap path.
- Stopping before the first public contract surface is identified.

## Escalation Rules

- Escalate to cross-cutting review if any file in `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `src/libclient/callbackshandler.cpp`, or `daemon/src/jami/` must change.
