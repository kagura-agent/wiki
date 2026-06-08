---
title: Structural Fix Over Behavioral Rule
created: 2026-06-08
tags: [design-principle, self-evolution, mechanism]
last_verified: 2026-06-08
---

Design principle: when a constraint can be enforced structurally (via tool code, workflow topology, or automation), prefer that over adding a DNA/behavioral rule that relies on the agent remembering to comply.

**Core insight**: Tool code > rules > nothing. Behavioral rules get rationalized away, especially when embedded in long task descriptions. Structural enforcement through workflow topology or tool checks is harder to bypass.

**Examples from practice**:
- [[flowforge]] gradient_gate node: instead of instructing "write a gradient before finishing," a separate workflow node checks `git diff` for actual modifications — the agent *cannot* proceed without writing one
- FlowForge study freshness gate: instead of a DNA rule "don't do followup when nothing changed," the workflow topology enforces a mandatory check at the top of the followup node
- dna-preflight counter fix: changed the tool code rather than adding another rule about counting correctly
- evaluate-candidate.sh pattern-tag alignment: when data format evolves (section headers to inline bullets), all consuming scripts must be updated — structural format tracking across consumers

**Relationship to other patterns**:
- Extension of [[mechanical-verification]] — don't depend on subjective judgment
- Same philosophy as [[tool-shapes-behavior]] — tools determine what you see and do
- Operationalization of [[mechanism-vs-evolution]] leaning toward the mechanism end
- Contrasts with behavioral approaches that rely on agent compliance

**When to apply**: Whenever a pattern recurs 2+ times despite having a DNA rule, ask: "Can the tool/workflow enforce this instead?" If yes, fix the tool. The rule can stay as documentation, but enforcement should be structural.
