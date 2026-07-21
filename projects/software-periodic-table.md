# Software Periodic Table (NullLabTests)

- **Repo**: NullLabTests/software-periodic-table
- **Stars**: 69 (07-21, 2 days old)
- **Language**: TypeScript | **License**: MIT
- **Status**: Very early. Solo dev, no community, no issues.
- **Category**: Code generation methodology / Agent prompting

## Core Thesis

Most business application software is **composed from ~115 recurring patterns**, not invented fresh. Providing these as a curated, retrievable library turns LLM code generation into **selection + wiring** — a smaller, more reliable search space than free generation.

The metaphor: just as chemistry explains substances via combinations of elements, application software can be explained by combinations of a finite set of "software atoms."

## Architecture

6 families with reserved ID ranges:
- **Objects (1–35)**: Domain nouns — User, Task, Invoice, Project, Contact…
- **Properties (36–60)**: Typed fields — Status, Date, Currency, Priority, Owner…
- **Actions (61–85)**: Operations — Create, Update, Delete, Assign, Notify, Approve…
- **Interfaces (86–100)**: Views — Table, Kanban, Form, Chart, Calendar…
- **Intelligence (101–108)**: AI primitives — Search, Summarize, Classify, Recommend…
- **Rules (109–115)**: Governance — Permission, Trigger, Condition, Audit, Policy…

Each element: `{id, symbol (2-char), name, family, description}`.

## Key Design Decisions

1. **Application-oriented** — targets SaaS/internal tools, not language constructs or infra
2. **Finite and slow-growing** — new elements only when widely recurring AND not composable from existing ones
3. **Domain packs** — domain-specific concepts (insurance "Claim", retail "SKU") stay outside core table
4. **Framework-agnostic** — no React/Vue lock-in; atoms are typed interfaces
5. **Actions as intent** — `ActionRequest` is pure description; execution delegated to host
6. **Composition system prompt** — explicit instructions to agents: "prefer selecting atoms over regenerating known patterns"

## Evaluation Harness

- 6 benchmark scenarios (task board, CRM, invoices, user/role mgmt, notification rules, product catalog)
- Mock mode (deterministic, uses expected atoms) and LLM mode (real API: baseline vs composition comparison)
- Metrics: atom count, family coverage, within-table validation, token estimate, acceptance criteria
- **No published real eval results yet** — only mock passes exist

## Strengths

- Novel framing makes the finite-element thesis concrete and actionable
- Includes practical agent integration (system prompts, retrieval patterns, tool configs)
- Testable thesis via evaluation harness (baseline vs composition)
- The "composition plan schema" gives agents structured output format

## Weaknesses / Open Questions

- Brand new (2d), solo dev, zero community — could easily die
- 115 elements feel arbitrary — where's the empirical evidence for sufficiency?
- Business-app scoped — doesn't cover systems programming, CLI tools, agent frameworks
- Token savings unproven — retrieval overhead + ontology context might negate composition benefit
- No real-world usage evidence (the README admits this is a "concrete artifact" of an observation)

## Relationship to Agent Ecosystem

- Sits alongside [[ace-agentic-context-engineering]] and [[vibecode-pro-max-kit]] in the "structured agent context" space
- Different from [[skill-type-taxonomy]] — this is domain atoms, not agent capabilities
- The meta-pattern (**finite enumerable patterns → selection over generation**) could inform skill library design: each skill as an "atom" with typed interface and composition rules

## Relevance to Our Direction

**Low direct applicability** — we build agent harnesses/tools, not business apps. But the meta-insight is worth keeping:
- "Composition over generation" as a principle for skill design
- Evaluation methodology (baseline vs. composition) adaptable for measuring skill effectiveness
- The "element symbol" shorthand could work for skill references in prompts

## Verdict

Interesting conceptual framework. Not tracking long-term (outside our portfolio focus). Recorded for reference.

---
*Deep read: 2026-07-21*
