# Name

Account State Debug

## Purpose

Debug daemon-side account lifecycle, configuration, registration, and account-specific state issues.

## When To Use

- account creation/load/activation problems
- registration state issues
- account config or security/device behavior issues

## When Not To Use

- client-only settings presentation bugs

## Required First Reads

- `daemon/src/client/configurationmanager.cpp`
- `daemon/src/jami/configurationmanager_interface.h`
- `daemon/src/manager.cpp`
- `daemon/src/account.cpp`
- `daemon/src/sip/sipaccount.cpp`
- `daemon/src/jamidht/jamiaccount.cpp`

## Navigation Heuristics

- Identify whether the issue is account-type specific.
- Check public configuration methods before broader runtime code.

## Investigation Strategy

1. Identify the failing account operation or state signal.
2. Trace through configuration manager to `Manager` and the account type.
3. Check whether the issue is shared or account-type specific.
4. Note client-facing registration/detail implications.

## Output Format

- account operation/state
- owner path
- account type affected
- validation plan

## Success Criteria

- The account owner and type-specific path are explicit.

## Risks / Pitfalls

- assuming SIP and Jami account behavior share the same owner

## Escalation Rules

- Escalate when account detail or registration callbacks need client updates.
