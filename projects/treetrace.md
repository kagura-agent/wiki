---
title: "TreeTrace — Correction-to-Eval Pipeline"
created: 2026-06-14
updated: 2026-06-14
tags: [agent-quality, eval, self-improvement, local-first]
stars: 28
repo: Tree-Trace/treetrace
last_verified: 2026-06-14
depth: deep-dive
---

# TreeTrace — Correction-to-Eval Pipeline

**Thesis**: The corrections humans make to AI agents are the highest-signal data in the session, and they vanish when it ends. TreeTrace captures them locally as deterministic regression and eval data, with no LLM judge.

## What It Does

Parses agent session transcripts (Claude Code JSONL, Codex, Cursor, Gemini, Copilot, Grok — 7 adapters) and:
1. Classifies prompts into a tree: root, direction, correction, scope-change, checkpoint, question
2. Detects abandoned branches (forks where the user rewound)
3. Identifies 13 failure types with confidence scoring (regex/heuristic, no LLM)
4. Links **correction chains**: failure → correction → resolution
5. Generates: lessons, eval candidates, agent memory, security report, hallucination detection
6. Redacts secrets before any output

**Zero dependencies. No telemetry. No uploads. Local-first.**

## Architecture Insights

### Prompt Tree as Data Structure
The core abstraction is a **prompt tree** — not a flat transcript. Each human prompt is a node; the tree tracks lineage (parent→child), forks (abandoned branches), and nudges (folded "continue" messages). This is more expressive than our flat memory/gradient log.

### 13 Failure Types (No LLM Judge)
All classification is regex-based — fast, deterministic, no false positives from LLM hallucination:
- `ignored_constraint`, `misunderstood_goal`, `scope_drift`
- `wrong_tool_choice`, `hallucinated_file_or_api`, `repeated_failed_fix`
- `overbuilt_solution`, `underbuilt_solution`, `security_or_privacy_risk`
- `dependency_or_environment_mismatch`, `format_violation`, `user_frustration`, `abandoned_path`

**Trade-off**: High precision, lower recall. Subtle corrections that don't match regex patterns are missed. But for automated eval data generation, precision > recall is the right trade-off.

### Eval Candidate Generation
Each failure is automatically converted to a structured eval candidate:
```json
{
  "type": "constraint_preservation",
  "task": "Continue development while preserving the corrected direction.",
  "input": "Honor this correction and keep building: \"<correction text>\"",
  "expected_behavior": ["Use the corrected prompt lineage as durable context"],
  "failure_mode": "Agent repeats ignored constraint despite prior correction."
}
```
These are model-agnostic regression tests generated from real sessions.

### Hallucination Detection
`hallucinate.js` (371 lines) checks agent-referenced files and imports against the actual filesystem/package.json. Detects when agents claim files exist that don't, or import packages not installed. Pure filesystem checks, no LLM.

### Agent Memory Output
Generates a structured handoff document: constraints enforced, lessons from lineage, known bad paths, security-sensitive actions, preferred next work. Designed to be injected into the next agent session as context.

## Comparison with Our Approach

| | TreeTrace | Our System (nudge/gradient) |
|---|---|---|
| **When** | Post-session analysis | Real-time during/after execution |
| **Signal source** | Human corrections in transcript | Agent self-reflection + feedback |
| **Classification** | Regex heuristics (13 types) | Free-form gradient text |
| **LLM involvement** | None | LLM generates the gradient |
| **Output** | Structured eval data, lessons | beliefs-candidates.md entries |
| **Scope** | One project's sessions | Cross-project behavioral patterns |

The approaches are **complementary**: TreeTrace captures signals from Luna's corrections that our real-time system misses (because the agent can't always recognize when it's being corrected). Our system captures cross-project behavioral patterns that session-level analysis can't see.

## Relevance to Our Direction

1. **[[eval-driven-self-improvement]]**: TreeTrace automates the "correction → eval" loop. Our current pipeline (nudge → gradient → beliefs-candidates → DNA) does this manually. TreeTrace's structured eval output could feed into automated regression testing.

2. **Failure taxonomy**: Their 13 types map well to common agent failure modes. We could adopt a similar taxonomy for classifying our gradients instead of free-form text.

3. **Session tree as provenance**: The prompt tree concept could improve our session logging — we currently log flat text, losing the tree structure of corrections/directions.

4. **Hallucination detection**: The filesystem-based hallucination check is cheap and useful. We don't currently validate agent claims about file existence.

## Transferable Patterns

- **Deterministic > LLM for classification at scale**: When you need to process every session reliably, regex beats LLM (no cost, no latency, no hallucination)
- **Correction chain linking**: failure → correction → resolution as a first-class data structure, not just sequential log entries
- **Constraint extraction**: Automatically extracting user-stated constraints from natural language and carrying them as structured data

## Status

- 28⭐ (2 days old, June 12 2026)
- Solo dev, 0 issues, 0 PRs — very early
- Clean codebase: 4664 lines JS, zero deps, Node 18+
- Well-documented schema (SCHEMA.md maps to W3C PROV)
- MCP server included (`src/mcp.js`)
- Apache-2.0 license

## Questions to Track

- Will community form? (0 issues/PRs at day 2 isn't unusual)
- Will other agent frameworks integrate TreeTrace output?
- Can we run TreeTrace on our own OpenClaw session logs? (would need an adapter for our format)
- How does the hallucination detection perform on non-trivial codebases?

## Ecosystem Position

Sits in the **agent quality layer** alongside [[eval-view]], [[architect-loop]], and [[ponytail-yagni-skill]], but approaches quality from a different angle: post-hoc analysis of human steering rather than in-process constraints. Complements rather than competes.

Most directly related to [[eval-driven-self-improvement]] — this is a concrete implementation of the "corrections as eval data" pattern.

---
*Deep read: 2026-06-14 11:10 CST*
