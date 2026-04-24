# Name

Daemon Bugfix Triage

## Purpose

Localize a daemon/runtime bug to the correct public interface or owning subsystem before editing.

## When To Use

- daemon-owned registration, call, conversation, media, plugin, or runtime bugs

## When Not To Use

- when the issue is already proven to be only client-side consumption

## Required First Reads

- relevant file in `daemon/src/client/`
- relevant header in `daemon/src/jami/`
- relevant runtime owner in `daemon/src/`
- matching client boundary file if contract consumption is questioned

## Navigation Heuristics

- Start from the public method or emitted callback, then step inward to the owner.
- Do not start broad inside `Manager` if a narrower interface file already identifies the domain.

## Investigation Strategy

1. Identify the public entry point or emitted event.
2. Identify the runtime owner.
3. Confirm whether the defect is contract adaptation or runtime logic.
4. Scope the smallest daemon-owned fix.

## Output Format

- public entry point
- runtime owner
- root-cause hypothesis
- minimal fix scope
- validation plan

## Success Criteria

- The correct daemon owner is identified before editing.

## Risks / Pitfalls

- editing `Manager` when a narrower account/call/conversation/media owner is responsible

## Escalation Rules

- Escalate if client wrappers or consumers also need to change.
