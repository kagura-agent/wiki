---
title: diagram-maker
created: 2026-06-14
tags: [skill, visual-output, diagrams, openclaw]
last_verified: 2026-07-13
---

# diagram-maker

OpenClaw skill for generating diagrams from natural-language descriptions. Produces self-contained SVG/HTML or Excalidraw `.excalidraw` files.

## Capabilities

- **Architecture diagrams** — system components, data flow, service maps
- **Sequence diagrams** — interaction flows between actors/services
- **Concept maps** — relationships between ideas or entities

Output formats: inline SVG in HTML (standalone, dark-mode aware) or Excalidraw JSON for interactive editing.

## Design Notes

- Single-file output — no external dependencies, works offline
- Operates in adjacent space to [[effective-html-skill]]'s `html-diagram` sub-skill, but targets technical architecture diagrams rather than polished visual artifacts

## Links

- [[effective-html-skill]]
- [[skill-type-taxonomy]]
- [[flint-chart]] — Microsoft's semantic-level visualization IL for agent-driven chart generation
- [[officecli]] — agent-first Office suite with render→look→fix visual feedback loop
- [[fablecut]] — agent-drivable video editor with document-as-interface pattern
