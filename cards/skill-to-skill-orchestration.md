# skill-to-skill-orchestration

A compositional pattern where one agent skill's output becomes another skill's input, forming a pipeline with defined handoff contracts.

## Key Properties

- Skills are not just user-facing — they communicate with each other through **file paths and structured contracts**
- Each skill declares what inputs it accepts and what outputs it produces
- Orchestration is implicit (skills chain through artifacts) rather than explicit (no central controller)

## Examples

- **text-to-cad render skill**: CAD generation skills produce `.step`/`.glb` files → render skill opens them in CAD Explorer, produces viewer URLs and headless snapshots
- Pipeline: design (CAD) → parts sourcing (step-parts) → visual review (render) → manufacturing preflight (SendCutSend)

## Why This Matters

Most skill ecosystems treat skills as isolated tools. Skill-to-skill orchestration creates **composability** — the power of the system grows combinatorially with skill count, not linearly. This is the difference between "a bag of tools" and "an assembly line."

## Design Considerations

- **Handoff contract clarity**: Each skill must document what file types/formats it accepts and produces
- **Error propagation**: If an upstream skill fails, downstream skills need graceful fallback (text-to-cad: "report failure, let owning skill continue with non-GUI validation")
- **Session reuse**: Persistent viewer sessions avoid spawning duplicate processes (CAD Explorer's `dev:ensure` pattern)

## Related
- [[text-to-cad]] — primary exemplar
- [[agentskills-io-standard]] — skill packaging standard that enables this
- [[skill-trust-landscape-2026-04]] — ecosystem context

## Tags
`#skill-architecture` `#composability` `#pipeline` `#orchestration`
