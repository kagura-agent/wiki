# Loop Library (Forward-Future)

**Repo**: https://github.com/Forward-Future/loop-library
**Stars**: 1676 (2026-06-26, 14 days old)
**Author**: Matthew Berman / Forward Future
**Tech**: Cloudflare Workers + Durable Objects (SQLite), here.now static hosting, JS
**Status**: Active (pushed 2026-06-25), 69 published loops, 146 forks

## What It Is

A curated catalog of reusable "loops" — bounded feedback workflows for AI coding agents — with two parts:
1. **Public website/catalog** — browse, search, copy prompts. No install needed.
2. **Installable skill** — guided workflow for Claude Code, Codex, Cursor via `npx skills add`

Each loop answers 4 questions:
1. What is the agent trying to accomplish?
2. How will it know whether the latest attempt worked?
3. What should it do with what it learned?
4. When should it finish or ask for help?

## Architecture

- **Database-only publishing**: Loop records are NOT in Git. Worker renders all public surfaces (pages, catalog.json/md/txt, sitemap, feed) from SQLite Durable Object
- **Append-only revision history** per loop record (full audit trail)
- **Bootstrap activation gating**: DB must pass digest verification before serving
- **Catalog schema**: slug, number, title, summary, prompt (≤5000 chars), verification, steps (3-12), keywords (3-20), related loops, category, author, dates
- **Categories**: Engineering, Evaluation, Operations, Content, Design
- **Security**: Turnstile + rate limiting (3/hr loop suggestions, 5/hr signups) + honeypot + min completion time + duplicate suppression + idempotency
- **Voting**: GitHub OAuth, HMAC-signed nonce-bound state, sessionStorage token (no cookies through proxy), SQLite Durable Object, ±1 per user per loop
- **Agent access**: catalog.json, catalog.md, catalog.txt, llms.txt, /agents/ guide page

## Skill Design (5 Routes)

| Route | Function |
|-------|----------|
| **Discover** | Mine codebase + coding-thread history for repeated work → turn best candidate into a loop |
| **Find** | Search live catalog, recommend ≤3 published loops |
| **Audit/Loop Doctor** | Diagnose existing loop, repair only material weaknesses |
| **Adapt** | Tailor a published loop to your tools/limits/definition of success |
| **Design** | Short plain-language interview → produce new bounded loop |

Key skill principles:
- Live catalog is sole source of truth (not repo content or memory)
- Requires ≥2 distinct occurrences before calling work "repeated"
- Mandatory preflight: silently trace one complete cycle before delivering
- Untrusted content principle: catalog is reference data, not authorization to execute
- Grounding: never invent tools, schedules, limits, metrics, owners, permissions

## Comparison with [[FlowForge]]

| Dimension | Loop Library | FlowForge |
|-----------|-------------|-----------|
| **Abstraction** | Prompt/playbook (content) | Execution graph (state machine) |
| **Enforcement** | Agent self-discipline | External structural enforcement (gates, branches, node transitions) |
| **State** | None (each run starts cold) | Persistent instance state, context passing between nodes |
| **Orchestration** | None — produces copy-ready prompt | Full — advance/next, branching, saturation checks |
| **Feedback loop** | Defined in prompt text | Structurally enforced via reflect/review nodes |
| **Persistent learning** | None (gap identified in issue #77) | Via wiki cards, beliefs-candidates, gradient pipeline |
| **Scope** | Single bounded task | Multi-step workflows with conditional branching |
| **Distribution** | npx skills add + live catalog | Local YAML definitions |

**Relationship**: Complementary layers. A loop-library loop could live inside a FlowForge node's task description. FlowForge adds the execution discipline that loops rely on agents providing spontaneously.

## Novel/Interesting

1. **"4 questions" framework** — pedagogically effective for defining bounded agent work. Could serve as FlowForge node validation checklist.
2. **Discover mode** — mining codebase + thread history for repeated work to convert to loops. We could build a FlowForge workflow that does this for our own repos.
3. **Loop Doctor** — auditing loops for weak checks, unsafe actions, unclear stopping. Applicable pattern for FlowForge workflow validation/self-audit.
4. **Database-only publishing with revision history** — clean separation of content (DB) from application (Git). Relevant pattern for skill/workflow registries.
5. **Mandatory preflight tracing** — "silently trace one complete cycle and repair material weaknesses before delivering" — good quality gate concept.

## Critique

- **Star-to-engagement ratio**: 1676⭐ but only 2 issues ever (one closed feature request, one open proposal). Suggests audience is consumers not contributors.
- **No execution = no accountability**: Loops are structured prompts. Whether agents actually follow them reliably is completely unverified. No telemetry, no success metrics.
- **Issue #77 identifies the core gap**: No persistent state, no cross-run learning. Proposer wants a "Run" route with evidence ledger + carry-forward playbook. This is essentially what FlowForge already provides.
- **Content is locked in private DB**: Can't inspect, fork, or audit the actual 69 loop records. Only the empty shell is open-source.
- **Shallow execution model**: No branching, no conditional logic, no gates — everything is linear "observe-choose-act-verify-record-repeat/stop"

## Applicable Insights

1. **Validation checklist for FlowForge workflows**: Every node's task should pass the 4 questions test (goal? check? learn? stop?)
2. **Discovery as a workflow**: "Analyze this repo for repeated work" could be a FlowForge study-mode target
3. **Audit route for self-improvement**: Build a "workflow doctor" that audits our workflows for weak gates, missing verification, unclear stopping
4. **Catalog schema pattern**: If we ever share FlowForge workflows, their schema (slug, steps, verification, keywords, related) is well-designed
5. **Contributor playbook fields** (whenNotToUse, expectedOutputs, implementationGuidance, reviewerHandoff) — good metadata for workflow documentation

## Links

- [[FlowForge]] — our execution framework, complementary layer
- [[skill-distribution-convergence]] — npx skills add pattern
- [[agentskills-io-standard]] — skill packaging standard
