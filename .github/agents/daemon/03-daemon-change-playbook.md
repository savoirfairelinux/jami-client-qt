# Daemon Change Playbook

## Bugfix Strategy

1. Start from the relevant public interface method or runtime owner, not just the symptom.
2. Identify the exact interface path from `daemon/src/client/*.cpp` or `daemon/src/jami/*.h` into runtime ownership.
3. Confirm whether the problem is in public contract adaptation or in the runtime owner itself.
4. Keep the fix as local as possible to the true owner.

## Feature Strategy

1. Decide whether the feature changes a public client-facing contract.
2. If yes, immediately treat the task as `CROSS_CUTTING` until wrappers and client consumers are assessed.
3. If no, keep the change behind the existing public surface and validate the owning daemon runtime only.

## State-Machine / Lifecycle Caution Points

- call/conference transitions
- account activation/registration
- conversation sync/load behavior
- media device and stream lifecycle
- plugin loading/unloading and handler registration

## Contract Change Caution Points

- Any change under `daemon/src/jami/` needs boundary review.
- Any callback or signal behavior consumed by client wrappers needs wrapper and client-consumer review.
- Any change under `daemon/src/client/` should be checked against `src/libclient/dbus/` and `src/libclient/qtwrapper/` expectations.

## Escalate To Shared Or Client When

- The client wrapper or callback fan-in must change.
- A daemon fix depends on adapter, current-state, or QML consumption updates.
- Build mode differences between DBus and libwrap matter.

## Daemon Review Checklist

- Is the runtime owner correctly identified?
- Did the change alter a public contract or callback behavior?
- Were likely client consumers considered?
- Was the narrowest relevant daemon test checked or updated?
- Were high-risk state-machine paths reviewed for regressions?
