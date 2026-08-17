---
title: "Prime Agent — Self-Improving RLM Agent for Coding"
created: 2026-08-10
last_verified: 2026-08-17
source: https://github.com/PrimeIntellect-ai/prime-agent
stars: 16584
status: track
tags: [agent-harness, self-evolution, rlm, subagent, provenance, ledger, observability]
---

# Prime Agent — Self-Improving RLM Agent

**Repo:** [PrimeIntellect-ai/prime-agent](https://github.com/PrimeIntellect-ai/prime-agent) · 16,584⭐ / 1,787 forks / 73 open issues (08-17)

## What it is

A self-improving RLM (recursive language model) agent for coding and long-running autonomous tasks. HN 253 points / 69 comments at first tracking (08-10). Growth is explosive: 10.9k → 16.6k⭐ in 7 days (+52%), with main-branch commits landing daily.

## Position in the ecosystem

Sits in the [[agent-harness-landscape]] category of self-evolving agents (alongside [[metaharness-agent-harness-generator]]-family and [[LoopX]]), but distinct in that it is *recursive* (RLM subagents spawn subagents) and production-grade (daemon-managed, 1,787 forks, real external contributor base — snimu alone has 8 open PRs).

Fork network is organic: newest forks are all 0⭐ individual accounts with natural timestamps — no coordinated star-farming accounts (contrast [[multi-agent-workflow-lab]]'s fake fork network). External PRs are real feature work, not drive-by typo fixes: edit-summary diffs (#1392), ACP MCP programs (#1378), fork-session preservation (#1389), capability admission/revocation fixes (#1357).

## Key insight: supervisor-owned RLM spawn ledger (#1387, merged 08-14)

**Problem:** family topology (which sessions form this agent's family) was reconstructed at read time by walking session headers + per-parent `rlm-subagents.jsonl` registries, validating shapes as it went. Three times in two weeks, real on-disk data violated an assumed shape (fork session headers, registry childIds, legacy depth fields) and the fail-closed validation broke family messaging for the whole profile. Each fix added more shape assumptions.

**Fix:** the daemon is the single writer that admits every rlm spawn, performs every rename, records every deletion — so it records that knowledge **firsthand at mutation time** in an append-only JSONL ledger at `<agentDir>/rlm-ledger/<hash-of-sessions-dir>.jsonl`, and family/sibling queries read from that ledger.

**Insight (generalizable):** write-time single-writer ledger beats read-time reconstruction from multi-writer files. When N writers can produce a file, every read-time shape assumption is a latent breakage; move authority to the one component that observes every mutation, and append-only logs serve both provenance and queries. This is the provenance analog of [[write-ahead-session-persistence]] and complements [[supervisor-pattern]] (supervisor observes without executing — here it *records* what it authorizes).

Follow-ups in the same direction: RLM subagent metadata consolidated onto the spawn ledger (#1390), supervisor authority records moved out of `$TMPDIR` (#1449, tmp cleanup would otherwise erase family authority), trusted contribution process (#1340).

## Relevance to us

- **[[FlowForge]] observability:** our workflow state is reconstructed from state files written by flowforge itself — single-writer, but we could adopt the same discipline for run history (append-only ledger of runs/nodes instead of rewriting one state file).
- **[[subagent]] / [[explicit-spawn-contract]]:** a spawn ledger is the *executed* counterpart of the explicit spawn contract — contract declares intent, ledger records what actually spawned (parent, child id, depth, rename, deletion).
- **[[mechanical-enforcement-via-topology]]:** topology derived from a single authoritative ledger is mechanically enforceable; topology inferred from heterogeneous writers is not.
- **Data discipline:** "authority records out of $TMPDIR" mirrors our own rule that evidence/provenance must live in durable, reviewable locations.

## Open questions / safety boundary (unresolved)

Original tracking note flagged: state mutation model, evaluator/provenance, and safety boundaries need mechanism-level review before adopting any pattern. The spawn ledger improves provenance but doesn't by itself answer who evaluates RLM child outputs or how recursive mutation is bounded. Worth a mechanism-level read before extracting further.

## Log

- 08-10 NEW: 10,931⭐, self-improving RLM agent, HN 253pts. Revisit 08-17.
- 08-17 followup: 16,584⭐ (+52%/7d), THRIVING. Spawn ledger pattern extracted. Revisit 08-20 for KB extraction of spawn-ledger pattern + safety-boundary review.
