---
name: cpp-expert
description: >
  Use for C++ work: adapters in src/app/, models and interfaces in src/libclient/,
  daemon signal connections, Q_PROPERTY definitions, and libclient API changes.
tools:
  - read_file
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

# C++ Expert — Jami Client Qt

## Scope

- `src/app/*adapter.cpp/.h` — Qt adapters (bridge between QML and libclient)
- `src/libclient/api/` — model interfaces and data types
- `src/libclient/qtwrapper/` — daemon bindings
- `src/libclient/dbus/` — D-Bus interfaces (Linux)

## Architecture

```
QML  ──►  Adapter (src/app/)  ──►  libclient model  ──►  libjami daemon
              Q_INVOKABLE             QObject signals
              Q_PROPERTY
```

Adapters own the Qt-to-daemon translation. Models own data and emit signals. QML binds — it
never calls daemon APIs directly.

## Code Conventions

- C++20. Column limit 120. Indent 4 spaces, no tabs. Pointer-left (`int* p`).
- Run `python3 extras/scripts/format.py` after every change.
- All data exposed to QML: `Q_PROPERTY(Type name READ get NOTIFY nameChanged)`.
- Callable from QML: `Q_INVOKABLE void doThing(const QString& arg)`.
- Connect signals in adapter constructor via `QObject::connect`.
- Emit targeted signals — avoid broad model resets.

## Checklist Before Done

- [ ] `.clang-format` applied (run `format.py`)
- [ ] New properties have `NOTIFY` signals
- [ ] Signal connections are in constructor, not scattered
- [ ] No direct daemon calls from QML-facing code
- [ ] GTest case added in `tests/unittests/` if logic is non-trivial
