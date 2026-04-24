---
applyTo: "CMakeLists.txt,src/**/CMakeLists.txt,tests/CMakeLists.txt,daemon/CMakeLists.txt,daemon/src/meson.build,daemon/test/meson.build,extras/ci/**/*"
---

- The root build is not client-only. It usually adds `src/libclient` and the embedded daemon submodule through `WITH_DAEMON_SUBMODULE` and `JAMICORE_AS_SUBDIR`.
- Read `.github/agents/shared/02-build-run-test.md`, `.github/agents/shared/03-client-daemon-boundaries.md`, and `.github/agents/shared/05-change-impact-analysis.md` before changing build logic or cross-layer wiring.
- `BUILD_TESTING` affects both client and daemon behavior. Do not introduce production assumptions that only work when tests are enabled.
- Packaging and CI paths under `extras/` may disable testing for release jobs. Check those flows before changing defaults or assumptions.
- When a build change touches daemon-facing contracts or wrapper selection, inspect `src/libclient/dbus/`, `src/libclient/qtwrapper/`, `daemon/src/jami/`, and `daemon/src/client/` together.
- Validate with the smallest build or test step that exercises the changed surface instead of defaulting to a full rebuild.
- Do not consider build-related work validated until the relevant tests pass and the affected build surface succeeds without errors.