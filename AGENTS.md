# Jami Client Qt — Agent Routing

Cross-platform Qt 6.8 / QML GUI for the Jami distributed communication platform.
C++20 business logic; QML presentation layer; daemon interface via `src/libclient`.

> **Canonical rules and skills live in `.github/`.** This file is the universal entry
> point — follow the routing table below to avoid loading unnecessary context.

## Essential Commands

| Task | Command |
|------|---------|
| Build | `cmake -Bbuild -DCMAKE_PREFIX_PATH=/usr/lib/libqt-jami && cmake --build build -j$(nproc)` |
| Test | `cmake -Bbuild -DBUILD_TESTING=ON && cmake --build build && ctest --test-dir build` |
| Format | `python3 extras/scripts/format.py` |
| Full init | `python3 build.py --init --qt=/usr/lib/libqt-jami` |

## Routing Table

| You are working on… | Load |
|---------------------|------|
| C++ adapters, libclient models, signals | `.github/agents/cpp-expert.agent.md` |
| QML components, bindings, JS helpers | `.github/agents/qml-ui.agent.md` |
| CMake, build options, tests, CI | `.github/agents/build-tester.agent.md` |
| General coding rules & conventions | `.github/copilot-instructions.md` |

## Repository Map

```
src/app/         C++ adapters + QML UI
  commoncomponents/  reusable QML widgets
  mainview/          main window components
src/libclient/   C++ wrapper over libjami (models, signals)
  api/               public interfaces
  dbus/              D-Bus bindings (Linux)
tests/           GTest unit tests + Qt Quick integration tests
daemon/          libjami git submodule
3rdparty/        hunspell, md4c, tidy-html5, zxing-cpp
extras/scripts/  format.py, gen_qml_qrc.py
```

## Non-Negotiable Rules

- QML is presentation only — no daemon calls from QML JS.
- Every QML-exposed property needs `Q_PROPERTY(… NOTIFY …Changed)`.
- Column limit 120, indent 4 spaces, no tabs, pointer-left (`int* p`).
- Contributions go through Gerrit (`review.jami.net`), not GitHub PRs.
- Run `format.py` (or pre-commit hook) before every commit.
