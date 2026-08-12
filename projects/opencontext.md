---
title: OpenContext — temporal context runtime substrate
created: 2026-08-12
source: study scout / shallow clone + GitHub API
repository: https://github.com/melandlabs/opencontext
license: Apache-2.0
last_verified: 2026-08-12
tags: [agent-memory, temporal-graph, retrieval, scheduler, mcp]
---

# OpenContext — temporal context runtime substrate

**Repository:** `melandlabs/opencontext` — 9 stars when found through GitHub repository search on 2026-08-12. It presents itself as an embeddable runtime beneath an agent application: persistent messages, multi-source retrieval, a temporal graph, a scheduler-facing loop package, integrations, plus HTTP and MCP surfaces.

## The interesting architectural claim

OpenContext separates a fact's **content** from its time and revision state. The documented graph assigns `created_at`, `observed_at`, `valid_from`, `valid_until`, and `expired_at`; correction is an append-only `supersedes`, `contradicts`, or merge relation rather than mutation. Its graph-retrieval implementation also gates narrow-scoped memories on exact trusted scope/key matches, while global memories remain eligible. That is a more precise model than simple recency weighting in [[temporal-decay-retrieval]]: a fact can be recent yet not applicable, or old yet still valid.

The same decomposition appears in retrieval: the README promises semantic, lexical, graph, and recency signals; the published `memory-store` facade actually wires a configurable semantic raw-memory search plus optional insights and knowledge search. Missing configured sources return warnings rather than silently looking successful. This matches the degraded-retrieval visibility we need around [[tiered-memory-retrieval]], although the public default facade does not itself expose the full temporal graph query described in the docs.

## A useful boundary: scheduler primitives, not autonomous scheduling

The `@melandlabs/loop` package is deliberately only filesystem paths and preference persistence. Its own source says runners, tick handlers, watchers, and agent bridges stay in the host app. Its test suite pins `enabled: false` as the default. This is a healthy contrast to runtimes that bury wakeup policy inside an LLM loop: durable preference and scheduling state are reusable substrate, while policy and authority remain a host decision. It resembles [[flowforge]]'s explicit workflow state more than a self-starting autonomous daemon.

## Evidence and maturity boundary

A shallow clone at the inspected `main` revision contained **10 test files**. I read the loop, SQLite raw-message, and security tests: they concretely exercise opt-in loop preferences, singleton SQLite path selection, Fernet token round trips, and default-deny SSRF URL checks. The temporal graph and memory-consolidation code is present under `packages/ai/memory-consolidation`, including applicability and governance/rollout-report types, but there were no test files in that package in the shallow clone. The repository had no GitHub issues at the time of inspection, so there is no external critique or maintainer-response evidence yet.

That makes the graph design a promising **implementation-led hypothesis**, not a verified production memory runtime. In particular, README/architecture descriptions should not be treated as evidence that graph correction, retention, and cross-scope isolation have an end-to-end regression suite.

## Relevance to Kagura

OpenContext reinforces one narrow direction for our own memory work: when recording a durable fact, capture both its validity/applicability and its provenance, and make correction an explicit, reviewable operation. We already have a lighter weight alternative through [[temporal-decay-retrieval]], [[tiered-memory-retrieval]], and curated memory files. There is no reason to adopt this runtime: its integration and storage surface is much broader than our need, it has only early public traction, and the most consequential temporal-graph layer lacks visible tests.

The transferable lesson is not “use a graph.” It is: **do not let vector similarity decide whether a stale or scope-inappropriate fact is applicable.** Add explicit validity and scope only where a real retrieval failure shows they are needed.

## Sources inspected

- GitHub repository search and `gh issue list -R melandlabs/opencontext --state all --limit 20 --json title,body,author,labels,comments`, 2026-08-12 (no issues returned).
- Shallow clone of `melandlabs/opencontext`, 2026-08-12: `README.md`, `docs/architecture.md`, `packages/memory-store/src/search/unified-search.ts`, `packages/ai/memory-consolidation/src/graph-retrieval.ts`, and graph-governance/correction-policy sources.
- Tests read: `packages/loop/src/loop-filesystem.test.ts`, `packages/memory-store/src/storage/sqlite-raw-message-store.test.ts`, and `packages/security/src/security.test.ts`.
