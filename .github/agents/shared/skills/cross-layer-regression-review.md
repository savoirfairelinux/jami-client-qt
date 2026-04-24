# Name

Cross-Layer Regression Review

## Purpose

Review a proposed or completed change for regressions across client UI, libclient synchronization, daemon contracts, and runtime behavior.

## When To Use

- After cross-cutting edits.
- When public interfaces or callbacks changed.
- When a local fix touches a hotspot with broad blast radius.

## When Not To Use

- For strictly local, non-behavioral documentation changes.

## Required First Reads

- changed files
- `.github/agents/shared/03-client-daemon-boundaries.md`
- `.github/agents/shared/08-hotspots.md`
- relevant tests in `tests/` and `daemon/test/`

## Navigation Heuristics

- Compare producer/consumer assumptions.
- Check whether DBus and libwrap stayed aligned.
- Review account-switch, conversation-switch, and current-call behavior whenever state propagation changed.

## Investigation Strategy

1. Identify the changed contract or state path.
2. Verify all consumers of that path.
3. Verify all relevant validation surfaces.
4. Flag missing tests or mismatched assumptions.

## Output Format

- Findings ordered by severity
- Affected flow
- Missing validation
- Cross-review recommendation

## Success Criteria

- The review catches cross-layer risks before or after merge.

## Risks / Pitfalls

- Reviewing only the edited layer.
- Missing alternate startup/build modes.

## Escalation Rules

- Escalate to build/test specialists when validation coverage is weak.
