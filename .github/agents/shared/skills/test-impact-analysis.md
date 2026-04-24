# Name

Test Impact Analysis

## Purpose

Map which tests should be written, tightened, checked, or extended around a Jami change, with a preference for test-first work on non-trivial behavior changes.

## When To Use

- Before or after non-trivial edits.
- When changing state propagation, public contracts, or build/test wiring.

## When Not To Use

- For tiny comment/doc-only changes.

## Required First Reads

- `tests/CMakeLists.txt`
- `tests/qml/`
- `tests/unittests/`
- `daemon/test/meson.build`
- relevant daemon test directory in `daemon/test/unitTest/`

## Navigation Heuristics

- Match the change to the owning subsystem first.
- Prefer the narrowest existing test closest to the owner.
- If the behavior is changing and coverage is weak, prefer adding or tightening the nearest failing test before implementation rather than only planning post-change validation.
- If the change is cross-boundary, pick both a daemon-side and a client-side validation surface where possible.

## Investigation Strategy

1. Classify the change.
2. Identify the nearest existing test that could fail for the desired behavior.
3. Identify gaps where behavior changed but no test currently covers it.
4. Recommend the smallest useful test-first step, then the minimum useful post-change validation set.
5. Include the narrowest build check needed to prove the touched project surface still compiles.

## Output Format

- Relevant existing tests
- Recommended first failing test or test extension
- Missing test coverage
- Minimum validation plan
- Residual risk
- Build requirement

## Success Criteria

- The proposed test plan is narrow, real, tied to the actual owner, and suitable for test-first work when the change is non-trivial.
- The plan makes clear that validation only counts when all relevant tests pass and the affected build surface succeeds.

## Risks / Pitfalls

- Running only client tests for daemon contract changes.
- Running only daemon tests for UI-visible sync changes.
- Deferring all testing until after implementation when an owning test surface already exists.
- Declaring success after a passing test slice while the touched target or project still fails to build.

## Escalation Rules

- Escalate to regression review if coverage is weak for a hotspot or public interface change.
