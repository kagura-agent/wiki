---
title: pi-book — Source-Backed Architecture Reading for pi-agent-core
created: 2026-08-10
tags: [agent-harness, architecture, source-backed-learning, pi]
last_verified: 2026-08-10
---

# pi-book — Source-Backed Architecture Reading for pi-agent-core

- **Repo:** [antinomie-lab/pi-book](https://github.com/antinomie-lab/pi-book)
- **Observed:** 2026-08-10 — 220⭐; created 2026-08-07; no license declared; actively pushed today.
- **Evidence boundary:** Read its README, Chinese source chapters 00–02, full repository tree, all 3 public issues, `web/package.json`, and recent commits via GitHub API. The repository contains no `test/`, `tests/`, or `*.test/spec.*` files, so its claims were assessed through its cited excerpts rather than executable verification.

## What it is

This is not an agent runtime. It is a small, source-backed architecture book about `@earendil-works/pi-agent-core`, pinned to upstream pi commit `cd20a8d2e`. Each claim links a `file:line` citation and places the quoted source beside the explanation. The current material explains the core loop and follows a `prompt()` call through streaming, tool execution, queues, cancellation, and lifecycle settlement; the Vue reader is intentionally only a presentation layer.

## Architectural reading: a loop library, not a framework

The book surfaces a clean three-layer separation in pi:

1. A stateless `runAgentLoop` / `runLoop` primitive owns the model → tool → model iteration and emits a typed event stream.
2. `Agent` wraps that primitive with in-memory state and awaited listeners.
3. `AgentHarness` independently composes the same primitive with durable session state, compaction, hooks, and runtime tools—rather than inheriting from or wrapping `Agent`.

The consequential boundary is not class hierarchy but **one reusable control-loop contract plus different state/authority policies**. It parallels the separation between [[FlowForge]]'s orchestration state and a task implementation: a reusable state machine should not silently acquire provider, UI, persistence, or host-runtime dependencies.

## Two useful, non-obvious mechanisms

- **Settlement is stricter than the final event.** `agent_end` means no more loop events; `Agent.waitForIdle()` resolves only after listeners for that final event settle. This makes awaited persistence safe, but means an event listener that itself awaits `waitForIdle()` deadlocks. The transferable rule for our hooks is: expose post-settlement callbacks separately from in-run event listeners.
- **Tool execution preserves two different orders.** Preparation is sequential, permitted calls then run in parallel, completion events emit in completion order, but transcript tool results return in the model's original call order. UI latency and replay determinism get distinct contracts instead of being accidentally coupled.

The book's strongest contribution is pedagogical provenance: it turns otherwise implicit lifecycle semantics into locally verifiable assertions. It is complementary to [[agent-harness-landscape]] and [[agent-safety]] rather than a competing harness.

## Limits and freshness risk

The boundary that makes the book trustworthy also makes it brittle: all technical citations are pinned to an old upstream revision. Issue #5 identifies a material mismatch after pi refactored its durable harness API at `4428955`; the issue is valid evidence that line-level citation alone does not preserve freshness. The repository has no automated test or CI script (`web/package.json` only defines Vite dev/build/preview), so there is no machine check that its cited version or rendered links remain current.

Recent merged PRs add English/Spanish translations and reader accessibility fixes, which shows healthy editorial iteration, but its three issues are documentation/UI oriented and do not yet establish broad peer review of the architectural claims.

## Relationship to our work

Do **not** adopt a documentation project as runtime infrastructure. Do adopt its narrower pattern when we document our own agent mechanisms: bind a conclusion to a revision, state the source boundary, and make freshness an explicit revalidation obligation. For FlowForge and OpenClaw integration notes, a cited claim should record the inspected version/commit and a scheduled re-check when upstream interfaces move.

The ecosystem signal is that attention is increasingly going toward the *explainability and controllability* of harness loops, alongside the stronger operational focus on permissions and disposable sandboxes seen in [[agent-safety]]. pi-book is a useful learning artifact in that trend, but its lack of license, tests, and freshness automation means it should be tracked as documentation practice—not trusted as an authoritative specification.
