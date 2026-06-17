---
title: MetaHarness — Factory for Agent Harnesses
created: 2026-06-17
updated: 2026-06-17
status: deep-read
last_verified: 2026-06-17
---

# MetaHarness (ruvnet/agent-harness-generator)

**Repo**: [ruvnet/agent-harness-generator](https://github.com/ruvnet/agent-harness-generator) — 118⭐ (06-17), created 06-13
**License**: MIT | **Language**: TypeScript + Rust (kernel) | **Runtime**: Node.js/Bun
**Operator**: ruvnet (solo, extremely prolific, 62+ dev iterations in 4 days, agent-assisted)

## What It Is

A meta-layer for the agent ecosystem: **generates custom, branded agent harnesses per-repo**. The thesis: "the model is replaceable; the harness is the product."

Input: a GitHub URL (or blank slate) + host selection (claude-code, codex, pi-dev, hermes, openclaw, opencode, rvm).
Output: npm-publishable harness with CLI, MCP server, repo-scoped memory, skills, governance policy, witness-signed provenance.

```bash
npx metaharness my-bot --template vertical:coding --host claude-code
```

Also ships a browser-based Web UI scaffolder (zero-install, nothing leaves the page).

## Architecture

- **Scaffold pipeline**: Template catalog + per-host adapter files (CLAUDE.md, .opencode/agents/, rvm.manifest.toml, etc.)
- **Score command**: `npx metaharness score <repo>` — reads repo (never runs it), prints a harness-fit report card + estimated $/run
- **Router** (`@metaharness/router`): Cost-optimal model routing using FastGRNN neural router (`@ruvector/tiny-dancer`) — picks cheapest model that meets quality bar, learned from eval logs
- **DRACO benchmark**: Rigorous A/B testing system for measuring harness effectiveness
- **Witness provenance**: Ed25519-signed release verification (though Issue #4 exposed this is currently non-functional)
- **Kernel**: Rust/WASM + NAPI native substrate (`ruvector` family) for graph intelligence, routing, memory

## Key Insight: DRACO Negative Result (Issue #3)

The project's most intellectually honest contribution:

> **Harness structure does NOT beat vanilla model** on factual research tasks.

| Arm | Δ vs vanilla | Verdict |
|-----|--------------|---------|
| 6-stage harness | −0.10 | **LOSS** |
| fusion+harness | −0.07 | Loss |
| verify→prune | −0.028 | Loss |
| self-consistency | +0.0007 | Tie (noise) |

**Mechanism**: `grounding = live_URLs / total_URLs` — any transformation that adds/removes URLs can only dilute. A single careful direct call produces the tightest high-live-rate citation set.

**The REAL win is COST**: a cheap model + harness ≈ frontier quality at ~10× lower cost. This is the shippable finding.

## ADR-041: Future Vision — Harness Generation as Program Synthesis

Proposed evolution from template scaffolder → program synthesis under search:
- **MCTS** over harness topologies (add skill/tool/memory/verifier/MCP)
- **GNN value network** for partial-topology evaluation
- **Graph of Thoughts** for design-choice DAG
- **Contextual bandits** for cost-optimal routing
- **SAT/CSP** constraint solving for hard requirements

Ambitious but well-specified (each stage mapped to a concrete component).

## Issue #4: Adversarial Quality Review

External reviewer (`proffesor-for-testing`) did a full QCSD Development Swarm audit:
- **2 HIGH security issues**: witness verification is a no-op; secrets leak into bundles
- Mutation testing: 53.6% kill rate on critical code
- Owner's response: accepted all findings, fixed all P0s within hours, retracted DRACO claim

This response pattern (honest acceptance + immediate fix + no defensiveness) is rare and noteworthy.

## Issue #14: Lean Theorem Proving Swarm

Applied the algo stack to formal math (agenticsnz/unsorry benchmark):
- 222 distinct Lean 4 theorems proved + kernel-verified
- Used sublinear goal-selection + ruvector lemma-reuse + decomposition
- Encountered and honestly reported: spam/duplicate PRs from concurrent agents, then corrected approach

## Relevance to Us

1. **"Model is replaceable, harness is the product"** — aligns with our philosophy (skills/workflow > model choice)
2. **DRACO negative result** — strong evidence that harness complexity doesn't help factual quality; cost optimization is the real lever
3. **Cost-optimal routing** — their `@metaharness/router` pattern (pick cheapest model meeting quality bar) is relevant for our multi-model workflows
4. **Meta-harness pattern** — one tier above what we do (we manually configure per-project); interesting if skill count grows
5. **Honest self-criticism + adversarial review culture** — the operator's response to Issue #4 is a gold standard

## Tradeoffs & Critique

- Solo developer with extreme velocity → sustainability risk (bus factor = 1)
- 118⭐ in 4 days could be star-farming (20 example packages, broad topic tags)
- The ADR-041 vision (MCTS + GNN + Graph of Thoughts) is extremely ambitious for a solo project — likely aspirational
- Witness/provenance system is non-functional (confirmed by mutation testing) despite being marketed
- The "unsorry" application (222 PRs to a friend's repo in one session) shows aggressive agent-spam pattern, even though the proofs are valid

## Pattern Worth Noting

**"Publish the negative result"** — the DRACO finding that harnesses degrade quality is the project's most valuable intellectual contribution. Most projects would bury this; ruvnet published it prominently. This is the correct scientific attitude and builds trust.

## Tracking

- First deep-read: 06-17
- Revisit: 06-24 (check if growth stabilizes or accelerates; watch for community adoption signal beyond solo dev)
