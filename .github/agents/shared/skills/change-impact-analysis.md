# Name

Change Impact Analysis

## Purpose

Estimate blast radius before editing by following the concrete ownership path through Jami’s client/libclient/daemon layers.

## When To Use

- Before non-trivial edits in hotspots.
- When a task might cross account, call, conversation, media, or plugin flows.
- When changing build flags or public interfaces.

## When Not To Use

- For purely local typo or doc fixes.

## Required First Reads

- `.github/agents/shared/05-change-impact-analysis.md`
- relevant hotspot in `.github/agents/shared/08-hotspots.md`
- owning source file(s)
- relevant test/build file if the change affects contracts or options

## Navigation Heuristics

- Find the owner, not just the caller.
- For shared state, check both production and consumption points.
- For runtime changes, inspect the nearest public interface before broader daemon internals.

## Investigation Strategy

1. Identify touched files and the owning abstraction.
2. List direct dependents and upstream producers.
3. Mark whether DBus/libwrap, startup, or tests are affected.
4. Decide if the change is local, boundary, or cross-cutting.

## Output Format

- Change class
- Primary owner
- Likely impacted files/modules
- Tests/build surfaces to revisit
- Regression risks

## Success Criteria

- The planned edit order is safe.
- The likely regressions are explicit before implementation.

## Risks / Pitfalls

- Underestimating `src/libclient` as a boundary layer.
- Ignoring test/build wiring when changing flags or interfaces.

## Escalation Rules

- Escalate when the impact list crosses both `src/libclient` and `daemon/src`, or when top-level CMake/Meson surfaces are involved.
