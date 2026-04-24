---
applyTo: "daemon/**/*"
---

- Treat daemon ownership in layers: public libjami contracts live in `daemon/src/jami/`, client-facing implementations live in `daemon/src/client/`, and runtime ownership usually lives under `daemon/src/manager.*`, `daemon/src/jamidht/`, `daemon/src/sip/`, `daemon/src/media/`, or `daemon/src/plugin/`.
- Use `.github/agents/daemon/00-daemon-architecture.md`, `.github/agents/daemon/01-daemon-runtime-flows.md`, and `.github/agents/daemon/03-daemon-change-playbook.md` as the default first reads.
- Start from the public entry point or emitted callback, then trace inward to the owning runtime class or module. Do not stop at `Manager` if a narrower owner exists.
- Communication-flow hotspots are `daemon/src/client/callmanager.cpp`, `daemon/src/client/conversation_interface.cpp`, `daemon/src/jamidht/conversation_module.cpp`, `daemon/src/jamidht/conversationrepository.cpp`, `daemon/src/call.cpp`, `daemon/src/sip/sipcall.cpp`, and `daemon/src/conference.cpp`.
- Account/runtime hotspots are `daemon/src/client/configurationmanager.cpp`, `daemon/src/account.cpp`, `daemon/src/sip/sipaccount.cpp`, and `daemon/src/jamidht/jamiaccount.cpp`.
- Contract or callback changes must be reviewed against `src/libclient/dbus/`, `src/libclient/qtwrapper/`, and `src/libclient/callbackshandler.cpp`.
- Prefer daemon-focused validation first. Use the smallest relevant test surface under `daemon/test/` when available.