---
applyTo: ".github/agents/**/*.md,.github/copilot-instructions.md,.github/instructions/**/*.md,AGENTS.md"
---

- Keep repository guidance code-grounded and Jami-specific. Prefer concrete file and subsystem references over generic Qt, C++, or daemon advice.
- Route by ownership: `client` for QML/app behavior, `daemon` for libjami/runtime behavior, `shared` for cross-layer boundaries and impact analysis, and `orchestration` for routing, handoff, and review rules.
- When a claim is based on partial inspection, mark it as `To confirm` instead of presenting it as settled fact.
- Keep repository-wide instruction files concise enough to stay useful in Copilot code review. Put detailed architecture maps in `.github/agents/` and keep `.github/` files as entrypoints.
- Treat `.github/agents/` and related instruction files as living documentation. After code changes or newly verified repository facts, update the affected agent docs when the discovery is durable and likely to help future work.
- Prefer small maintenance updates over broad rewrites: record the verified workflow, owner, boundary rule, hotspot, or test/build fact that changed, and do not restate unchanged areas.