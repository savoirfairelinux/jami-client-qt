# Daemon Testing

## Confirmed Test Surfaces

Daemon tests are organized under `daemon/test/` with broad `unitTest/` coverage and support code in `dst/` and related helpers.

Observed coverage areas from `daemon/test/meson.build` and directory structure:

- account archive and account factory
- call and conference
- conversation and conversation repository
- file transfer
- ICE and media negotiation
- media codec/decoder/filter paths
- namedirectory and presence
- plugin-related tests
- simulation/deterministic scenarios through DST support

## Safe Validation Strategy

- Prefer test-first work for non-trivial daemon behavior changes when a nearby owner-side unit or simulation test can express the expected runtime behavior.
- Choose the narrowest daemon test matching the owning subsystem first.
- For public contract changes, also check the relevant client wrapper/consumer path.
- For state-machine changes, prefer targeted tests over broad rebuild-only confidence.
- Daemon-side validation is only complete when the relevant daemon tests all pass and the affected daemon or top-level build surface still builds cleanly.

## TDD Guidance

- Public interface or runtime behavior change with an existing nearby daemon test: tighten or extend that test first so it fails before the code change.
- State-machine fixes in calls, conversations, accounts, or media: prefer the smallest deterministic daemon test that captures the transition instead of relying on rebuild-plus-manual confidence.
- If the daemon-side behavior is hard to isolate but the client-visible contract is easy to assert, note that and use the closest consumer-facing test as the first executable check.
- After the fix, rerun the same narrow daemon test before widening to client-facing validation.
- Before closing the work, make sure every selected daemon-side validation test passes and that the corresponding build target still compiles without errors.

## Runtime-Sensitive Areas

- call/conference state changes
- account registration and activation sequencing
- message/conversation sync and persistence
- media device lifecycle and audio/video paths
- plugin lifecycle

## Regression Patterns

- contract changed but wrappers/consumers were not updated
- daemon-only test passed but client-visible sequencing regressed
- conference/media changes broke neighboring call flows
- simulation-sensitive conversation behavior changed without scenario review
- implementing daemon behavior first and discovering too late that the change was not captured by a deterministic owner-side test

## To Confirm

- Some test scenario details and platform-specific coverage need deeper inspection when working in those exact areas.
