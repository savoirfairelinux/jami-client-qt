# Shared Set

This set documents repository-wide facts that future agents should not rediscover from scratch: the system shape, the repository map, build/test paths, the client/daemon seam, end-to-end flows, impact analysis, validation, glossary, and hotspots.

## Scope

- System-wide architecture and repository organization.
- Client/daemon boundaries and contract surfaces.
- Cross-cutting runtime flows.
- Impact analysis and validation strategy.
- Shared vocabulary and hotspots.

## Non-Scope

- Detailed client implementation playbooks. Use `client`.
- Detailed daemon implementation playbooks. Use `daemon`.
- Task routing and review protocol. Use `orchestration`.

## Relations

- Read this set before making ownership assumptions.
- Use this set to resolve `UNCERTAIN_REQUIRES_BOUNDARY_CHECK` tasks.
- Use this set for cross-layer review even when the implementation work is mainly in one set.

## Reading Order

1. `00-system-overview.md`
2. `01-repository-map.md`
3. `03-client-daemon-boundaries.md`
4. `04-cross-cutting-runtime-flows.md`
5. `05-change-impact-analysis.md`
6. `06-validation-matrix.md`
7. `08-hotspots.md`
