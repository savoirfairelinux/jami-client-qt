# Name

Build Breakage Investigation

## Purpose

Trace build failures to the owning build surface in the combined client/daemon repository.

## When To Use

- CMake configuration/build failures.
- Missing targets, test wiring failures, option mismatches, or packaging/CI build regressions.

## When Not To Use

- Runtime bugs with no build symptoms.

## Required First Reads

- root `CMakeLists.txt`
- `src/libclient/CMakeLists.txt`
- `tests/CMakeLists.txt`
- `daemon/CMakeLists.txt`
- `daemon/src/meson.build`
- `daemon/test/meson.build`
- relevant file in `extras/scripts/`, `extras/ci/`, or `extras/packaging/`

## Navigation Heuristics

- Determine whether the failure is in client CMake, daemon CMake, daemon Meson metadata, or packaging/CI.
- Check whether the break depends on options like `BUILD_TESTING`, `ENABLE_LIBWRAP`, `JAMI_DBUS`, `JAMI_VIDEO`, or `JAMI_PLUGIN`.
- Before blaming build metadata, compare the checked-out `daemon/` submodule commit with the gitlink pinned by the client superproject. A mismatched daemon checkout can fail the top-level build inside `daemon/contrib` even when CMake arguments are correct.

## Investigation Strategy

1. Pin the failing target or phase.
2. Check whether the checkout is coherent, especially the embedded `daemon/` submodule revision.
3. Identify the build file that owns that phase.
4. Check relevant option guards.
5. Check whether client and daemon build metadata drifted apart.

## Output Format

- Failing phase/target
- Checkout state, including submodule mismatch if present
- Owning build file and option guard
- Root cause hypothesis
- Minimal fix scope
- Validation command(s)

## Success Criteria

- The failure is tied to the correct build surface.
- The reported validation path uses the real local mode, typically the existing Debug build directory and tasks when present.

## Risks / Pitfalls

- Treating the top-level CMake file as the only owner.
- Missing that the daemon also maintains Meson metadata.
- Treating a source-state mismatch as a build-system regression.

## Escalation Rules

- Escalate for cross-review if the fix changes shared build flags or packaging logic.
