# Libclient Boundary Agent Guidance

- `src/libclient` is the boundary layer between the app shell and libjami or daemon-facing integrations, not just generic client internals.
- Read `.github/agents/shared/03-client-daemon-boundaries.md`, `.github/agents/client/00-client-architecture.md`, and `.github/agents/daemon/00-daemon-architecture.md` before editing.
- Start from the relevant model, wrapper, or callback path, then trace both upstream producers and downstream consumers.
- Boundary hotspots include `lrc.cpp`, `callbackshandler.cpp`, `conversationmodel.cpp`, `callmodel.cpp`, `dbus/`, and `qtwrapper/`.
- When changing daemon-facing methods or callbacks, inspect both `dbus/` and `qtwrapper/`. Do not update only one mode unless the flow is proven to use only that path.
- If a change affects callback payloads or ordering, review likely consumers in `src/app/currentconversation.cpp`, `src/app/currentcall.cpp`, `src/app/calladapter.cpp`, and `src/app/messagesadapter.cpp`.
- Escalate to daemon review when the method, signal, or state is already wrong before it reaches libclient.
- Do not treat boundary work as validated until the relevant tests pass on the affected side or sides and the touched build surface still succeeds.
- After meaningful `src/libclient` changes or verified new boundary facts, update the smallest affected agent or instruction doc so boundary guidance stays accurate.
