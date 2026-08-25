---
title: Loomfeed — Provenance-and-Reputation Social Substrate for Agents
source: https://github.com/surya-koritala/loomfeed
studied: 2026-08-11
status: watching
last_verified: 2026-08-25
---

# Loomfeed — Provenance-and-Reputation Social Substrate for Agents

**Snapshot (GitHub API, 2026-08-11):** 157★, 0 forks, created 2026-08-09, pushed 2026-08-10; Go backend with a Next.js frontend. Loomfeed is a self-hostable Reddit-shaped network where people and agents share one participant model, while agent content gains provenance, epistemic labels, reputation, and structured debates.

## What is actually implemented

- The project exposes REST, MCP, and a six-skill A2A gateway. `internal/gateway/a2a/handler_test.go` exercises API-key rejection, malformed RPC/skill rejection, and mappings such as search, feed, vote, comment, and agent-memory storage. Its A2A execution is deliberately synchronous: `tasks/get` always reports `completed`, so it is not a durable asynchronous task protocol.
- `internal/provenance/service.go` recomputes each agent's trailing 90-day source statistics after posts and has a sweep method; `service_test.go` validates the roll-up. The scorecard is likewise executable: `internal/scorecard/compute.go` calculates ten weighted signals and redistributes missing-data weight, with unit tests for normalization, tiers, weights, and missing signals.
- Reputation is an append-only event stream with decelerating positive rewards, uncapped negative events, and a daily gain cap (`internal/repository/reputation.go`). Acknowledging a correction is a +10 event; a refuted post is -100. This is a concrete form of the accountability link between [[agent-identity-protocol]] and [[agent-reputation-weaponization]].

## Architecture and the important trade-off

The distinctive choice is **social provenance rather than merely execution provenance**. A post can be cited with typed support/contradiction/extension/quotation edges, receive an epistemic status, and accumulate its author's score. That makes the system complementary to execution-trace systems such as [[halo-record]]: the latter can establish what an agent did, while Loomfeed tries to make public claims contestable and reputationally consequential.

The scorecard's strongest signal is epistemic accuracy (20%), followed by trust score and content quality (15% each). But the implemented definition is agreement between a post's current label and epistemic votes; it measures community alignment, not whether the claim later proved true. The code compensates for absent metrics by renormalizing remaining weights, which avoids treating a sparse record as automatically bad but also makes score comparability depend on data coverage.

## Critical evidence from the issue tracker

All 20 inspected issues were authored by the maintainer, so they are useful code audits but **not external validation**. They expose several gaps between the platform thesis and its enforcement:

1. `quality_gates` schema fields for provenance/confidence/human verification and agent posting rate have no Go reads or writes; the live creation gate is only a community trust threshold.
2. Retraction/correction data affects reputation, but correction *rate* is not a scorecard signal. The scorecard therefore rewards static alignment more directly than repair behavior.
3. The project has outgoing ActivityPub delivery and signed attestations, but its inbox handles only Follow/Undo; inbound replies and likes are not ingested. Its federation is currently one-way.
4. Embeddings are generated and used for “related posts,” while search currently fuses text and title signals only; a reported missing vector index also means similarity queries can degrade sharply with corpus size.

This is the useful inversion: an unusually broad trust surface is already coded, but **the enforcement surface is narrower than the data model**. Tables, labels, and scorecards do not become governance until they sit on the write path and affect admission or visibility.

## Relevance to Kagura

We should not adopt a public reputation score as a proxy for correctness. Our existing file-backed provenance and human approval boundary are closer to the right starting point: [[agent-memory-architecture]] treats retained memory as accountable structure, while Loomfeed shows that public reputation needs explicit correction and admission semantics. If we ever add a contribution/reputation layer, use an append-only evidence ledger and reward timely correction, but never let community votes authorize external action.

Loomfeed is worth tracking for two conditions: (1) the maintainer wires quality gates and correction-rate measurement into actual post admission/scorecard logic; (2) external users, issues, forks, or contributors appear. With 0 forks and maintainer-only issue critiques at this snapshot, the design is promising but its social trust model remains unvalidated.

## Sources inspected

- Repository README and `docs/ARCHITECTURE.md`
- `internal/provenance/{service.go,service_test.go,score.go}`
- `internal/scorecard/{compute.go,compute_test.go}`
- `internal/gateway/a2a/{handler.go,handler_test.go}`
- `internal/repository/{reputation.go,reputation_test.go}`
- GitHub issue list (all states, 20 entries), GitHub API snapshot above

## Followup — 2026-08-25

- **Stars**: 225 (+43% from 157, 08-11→08-25). Open issues 0→8.
- **Code**: active 08-13 batch — immutable release process (#73), docs align feature claims with implementation (#72), accessibility (#71), privacy deployment-aware (#70), durable bounded webhook delivery (#69). Notable: maintainer is honestly **aligning claims with implementation**, directly addressing the `quality_gates` dead-schema concern flagged 08-11.
- **Community**: still 0 external contributors (all commits surya-koritala + 1 dependabot). No external validation signal yet.
- **Assessment**: development is real and honest, but the trust-data-model-vs-enforcement gap remains. **Keep warm** (revisit 09-01) for external community signal + write-path enforcement; none → cool.

Links: [[agent-identity-protocol]], [[agent-reputation-weaponization]], [[halo-record]]
