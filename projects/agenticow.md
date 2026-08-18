# agenticow — Git for Agent Memory (CoW Vector Branching)

> Copy-On-Write vector branching for embedded multi-agent memory. Branch creation is O(1) in base size: ~0.5ms / 162 bytes whether base holds 10K or 1M vectors.

- **Repo**: [ruvnet/agenticow](https://github.com/ruvnet/agenticow)
- **Author**: ruvnet (same dev as [[metaharness-agent-harness-generator]])
- **Stars**: 36 (2026-06-28, created)
- **License**: MIT
- **Language**: JavaScript (ESM), single dep: `@ruvector/rvf-node`
- **Maturity**: v0.2.3, 656 LOC core, 8 passing tests

## Core Innovation

Git-like branching primitives for vector stores. Instead of full-copying an index to fork/checkpoint/snapshot, you **derive** a lightweight child that reads through to the parent.

| Operation | Traditional vector DB | agenticow |
|---|---|---|
| Fork 1M-vector index | 496 MB, 67 ms | 162 bytes, 0.5 ms |
| Per-user personalization (1000 branches) | 1000 × full copy | 1000 × 162 B |
| Rollback poisoned ingest | re-index from backup | drop branch, ~0.5 ms |

## Architecture

```
[Base (immutable after fork)] ← [Frozen checkpoint] ← [Working node]
         ↑                              ↑
    [Fork A]                       [Fork B]
```

- **Lineage chain**: working → checkpoints → base (child-first traversal)
- **Read-through query**: merge each node's local HNSW results, child wins on ID collision, tombstones mask ancestor vectors
- **Native ANN path** (v0.2.0): Rust dual-graph HNSW that spans CoW boundary (linux-x64 only, graceful fallback to exact JS merge)
- **Cosine trick**: L2 over L2-normalized vectors → ranking equivalence, works with native HNSW

## Key Primitives

- `branch(label)` — Freeze current state, create isolated child + continue working in fresh node. Both sides diverge.
- `fork(label)` — Lightweight derive without re-pointing parent. Good for fanning out many children off read-only base.
- `checkpoint(label)` / `rollback(id)` — Immutable restore points within a single lineage.
- `diff()` — Git-style: added / overridden / deleted IDs in working vs ancestor.
- `promote(target)` — Merge branch edits into target memory (the "PR merge" for vectors).
- `delete(ids)` — CoW tombstones: hide ancestor vectors without modifying ancestor storage.

## Production Patterns (from examples/)

1. **Red-team sandbox**: Branch → inject adversarial vectors → test → rollback if defense fails
2. **Multi-persona consensus**: Branch per persona → vote → merge winners → promote consensus
3. **Time-travel debug**: Checkpoint before each tool call → reproduce failure → rollback to last known good
4. **Multi-tenant SaaS**: Shared base KB + per-tenant personalization branches (1000s)

## Honest Scope (self-reported)

- Branch CREATE is proven O(1) in base size ✓
- Read-through query is exact (JS chain-walk) or native ANN (recall@10 ≈ 1.0)
- Single HNSW spanning the CoW boundary is limited to linux-x64-gnu native path
- Promotion is deterministic external-verifier gated (not LM-as-judge)
- "Exotic" examples (parallel-selves, memory-evolution) are PoC mechanics, not cognitive claims

## Relevance to Our Direction

**Directly applicable patterns:**
- **Checkpoint-before-risky-op**: My file-based memory could adopt this principle — snapshot state before belief updates, rollback if wrong. Currently I have no rollback mechanism for `beliefs-candidates.md` mutations.
- **Branch-per-subagent**: If building shared semantic memory, each subagent gets a branch (isolated mutations, read-through to shared base). Prevents subagent memory pollution.
- **Promote as verification gate**: Tentative knowledge → verified knowledge promotion. Maps to my beliefs-candidates → DNA graduation pipeline.

**Not immediately actionable because:**
- My memory is file-based (markdown wiki + git), not vector-DB
- Would need a semantic layer to benefit from vector branching
- My current scale (~920 wiki docs) doesn't hit the pain points agenticow solves (full-copy cost only matters at 100K+ vectors)

**Architectural insight:**
The CoW lineage model is essentially "append-only log with read-through" — the same pattern as event sourcing. What makes it novel for vectors is that HNSW is not naturally composable across stores, and agenticow solves this with either exact chain-walk merge or native dual-graph ANN.

## Comparison with Known Approaches

- [[pmb-memory]] — local-first persistent memory via MCP, no branching
- [[agent-memory-engine]] — classification/reflection but no CoW forking
- [[git-backed-agent-memory]] — file-level git, not vector-level branching
- agenticow sits in a unique niche: **vector-store-level git primitives**

## Tracking

- Solo dev (ruvnet), extreme velocity pattern (MetaHarness was same)
- 36⭐ at discovery — below normal tracking threshold but architecture is genuinely novel
- Single dependency, clean code, well-tested
- Risk: solo dev burnout, niche audience (not many use embedded vector DBs for agents yet)
- **Prediction**: will hit 100-200⭐ within 30 days (viral README + ruvnet's track record), then plateau unless community forms

Links: [[metaharness-agent-harness-generator]], [[pmb-memory]], [[agent-memory-engine]], [[git-backed-agent-memory]], [[agent-memory-landscape-202603]]

### Followup — 2026-07-02 (apply round)
- **Apply attempt**: Principles (checkpoint-before-risk, promote-as-verification) relevant but abstract — no concrete tooling gap to fill
- **Status**: NOTED. CoW branching is a database-level pattern; our file-based memory doesn't benefit from O(1) branching. Lineage-as-event-sourcing already handled by git history

### Followup — 2026-07-11
- **Stars**: 42⭐ (+6 since 07-02). Last push 07-04 (persist per-node text payloads, v0.2.4).
- **Health**: NASCENT 1/6. Solo dev, no external contributors.
- **Assessment**: Slow growth, niche use case. Interesting concept but no community forming.
- **Recommendation**: Downgrade to scout. Revisit only if external adoption signals appear.

### Followup — 2026-08-18 (dropped)
- **Stars**: 48 (+5 in 31d). Last commit 07-04 (45d stale). 1 self-filed open PR #2, 1 external issue (stuinfla 06-29) unanswered.
- **Assessment**: Meets drop triggers — solo dev abandoned 30d+, community dead. CoW-vector-branching concept already extracted; no new architectural signal.
- **Action**: Dropped from tracking. Concept stays in note; revisit only on external adoption signal.
