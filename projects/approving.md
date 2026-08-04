# Approving — Visual, Recoverable Agent Delivery Workflows

> Follow-up: 2026-08-04. A self-hosted platform that runs coding agents in Docker sandboxes, exchanges structured artifacts between nodes, and stops at explicit human approval gates.

- **Repo**: [cocofhu/approving](https://github.com/cocofhu/approving)
- **License / stack**: MIT; Go backend + web UI
- **Current signal (2026-08-04)**: 74 stars (+1 from 07-28), 3 forks, no open issues; last push 2026-07-31.
- **Ecosystem position**: a delivery-oriented counterpart to code-first orchestration libraries: it makes agent progress reviewable to a human rather than merely executable by a runtime.

## Follow-up findings

The project is still shipping, but the changes after the initial read are refinement rather than an architectural shift:

- Pinned default GHCR images to `0.1.2-beta`, making the sandbox/runtime deployment target explicit.
- Improved artifact preview and output-source navigation, preserving the provenance of an agent result for a reviewer.
- Replaced a CSS token-model composition chart with SVG sectors because the global square-corner style broke the visual encoding.

The latter two changes are small but useful evidence that its product boundary is not simply “run agents in Docker.” It treats **review context** (artifact legibility, source adjacency, cost/model visibility) as first-class workflow output.

## Connection to our stack

[[FlowForge]] mechanically enforces that an agent traverses a task process; Approving couples the analogous execution graph to visible artifacts and a human decision point. That reinforces [[mechanism-vs-evolution]]: an approval gate is only a mechanism unless reviewers’ decisions alter later agent behavior, policies, or workflow design.

For our workflows, the portable lesson is narrow: when an action needs review, preserve the artifact, the source/provenance, and the execution/model context *at the gate*. A bare “approve/reject” prompt discards the evidence needed for a meaningful decision.

## Assessment

Early but active product polish. The small star increase and three-day quiet period do not establish durable adoption; retain the architectural idea, not a dependency decision.

## Links

- [[FlowForge]] — enforced task state machine
- [[flowforge-workflow-engine]] — workflow-engine design rationale
- [[mechanism-vs-evolution]] — governance mechanisms need behavioral feedback

---
*First tracked: 2026-07-28. Follow-up: 2026-08-04.*
