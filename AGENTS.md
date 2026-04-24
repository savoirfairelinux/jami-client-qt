# Jami Agent Entry Point

- Use `.github/copilot-instructions.md` as the repository-wide instruction file and `.github/instructions/*.instructions.md` for path-specific guidance.
- Use `.github/agents/README.md` as the detailed repository map.
- Treat the repository as four cooperating sets: `shared`, `client`, `daemon`, and `orchestration`.
- Start from ownership instead of symptom location. `src/app` is the QML/application shell, `src/libclient` is the service and boundary layer, and `daemon/src` is the libjami/runtime layer.
- When ownership is unclear, inspect `.github/agents/shared/03-client-daemon-boundaries.md` before editing.
- Contract and callback changes require cross-layer review across `daemon/src/jami/`, `daemon/src/client/`, `src/libclient/dbus/`, `src/libclient/qtwrapper/`, and `src/libclient/callbackshandler.cpp`.
- For deeper task-specific guidance, continue into the relevant files under `.github/agents/client/`, `.github/agents/daemon/`, `.github/agents/shared/`, and `.github/agents/orchestration/`.
- After meaningful code changes or verified new repository facts, update the relevant agent or instruction docs so the repository guidance improves with the codebase.
