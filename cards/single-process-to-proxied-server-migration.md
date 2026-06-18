---
created: 2026-06-18
source: study/followup (beads proxied-server PR series #4287-4446)
status: insight
tags: [architecture, hexagonal, agent-platform, multi-tenant]
last_verified: 2026-06-18
---

# Single-Process → Proxied-Server Migration Pattern

> A storage system that starts as single-process embedded (one CLI owns the file) and grows multi-tenant ambitions can refactor incrementally by splitting domain interfaces from SQL implementations, then porting one verb at a time to a server-mediated path. The embedded path remains untouched throughout.

## The Pattern (from [[beads]] 2026-04 → 2026-06)

**Starting point** (v1.0):
- `bd` CLI embeds Dolt
- One process owns the database file
- Single-tenant by construction — no concurrency story
- Commands directly call `issueops.SearchIssuesInTx` etc against in-process Dolt

**Target** (in progress):
- `bd` CLI talks to long-lived Dolt SQL server over wire
- Many CLI processes share one server → multi-tenant agent platforms (gascity)
- Single Unit-Of-Work per CLI invocation (atomic batches)
- Wire-level decoupling enables remote-mode safety primitives

**The refactor recipe (verb-by-verb)**:

1. **Define domain interfaces** (`internal/storage/domain/db/`):
   ```go
   type IssueUseCase interface {
       SearchIssues(ctx, filter) ([]Issue, error)
       DeleteIssues(ctx, ids, opts) error
       AsOf(ctx, ref, opts) (...)
       // ...
   }
   ```
   Pure interfaces, no Dolt dependency.

2. **Implement SQL repositories** at `db/` level that work against either embedded or remote Dolt connection. Port logic from existing `issueops` helpers; widen `DBTX` to satisfy both `*sql.Tx` and `domain/db.Runner`.

3. **Per-command dispatch** at cobra level (5-line patch):
   ```go
   if usesProxiedServer() {
       return runDeleteProxiedServer(...)
   }
   // existing embedded body untouched
   ```

4. **New `cmd/bd/<verb>_proxied_server.go`** opens ONE UOW per invocation, threads it through every per-id op + post-loop flags (`--suggest-next`, `--continue`, `--claim-next`), commits once with descriptive message:
   ```go
   uw.Commit("bd: close <ids>[; advance to <id>][; claim <id>]")
   ```

5. **Full integration tests** that exercise both modes through the same domain interface (#4445 ships 47 subtests including direct mode parity + proxied-specific cases).

## Why this works

- **Strangler-fig per-verb migration** — never a big-bang rewrite. Each PR ships one verb to proxied mode without touching others.
- **Untouched embedded path** — zero risk of regression for single-tenant users. The original CLI mode keeps working identically.
- **Single-UOW atomicity** — multi-id operations become one transaction. Massive improvement for batch-heavy agent platforms (50 closes = 1 dolt commit vs 50).
- **Defense armability** — `bd doctor` migration content-hash gate (06-10) can be wired into proxied open path to prevent migrations on shared remote servers without touching embedded code.

## Generalizable Rule

**When you need to add multi-tenant / multi-process support to a single-tenant system, refactor in this order:**

1. Define domain interfaces (port from existing implementations 1:1)
2. Implement SQL/storage layer agnostic to "embedded vs remote"
3. Per-verb dispatch with old path untouched
4. UOW boundary explicit per CLI invocation
5. Integration tests gating both modes through the same interface

**Anti-patterns:**
- Rewriting entire codebase to "proper hexagonal" before any benefit
- Multi-process support added as an afterthought config flag
- Embedded and remote paths sharing mutable state without UOW
- Per-id transactions in batch operations (N commits for N items)

## Related architectures

- **[[clawpatrol]]**: same wire-level decoupling principle — MITM proxy mediates agent actions, agent code untouched
- **[[multica]]** / **[[nanobot]] Issue #936**: nanobot is being asked for multi-tenant gateway. Same architectural pressure. Their solution will likely follow a similar shape (domain interfaces → per-tool dispatch).
- **Traditional hexagonal architecture**: ports-and-adapters with explicit boundaries. Beads achieves this without DDD vocabulary — just methodical verb-by-verb port.

## Implications for our direction

If we build infrastructure intended for multi-agent / multi-tenant scenarios (e.g., shared task store, shared memory pool):

1. **Start with embedded-only, design domain interfaces immediately** — even if you only use them from one process today
2. **Single UOW per request boundary** is non-negotiable for batch atomicity
3. **Verb-by-verb migration** beats big-bang rewrite — keep the old path working until the new one is proven
4. **Test the interface, not the implementation** — same suite should run against both modes

Links: [[beads]], [[nanobot]], [[multica]], [[clawpatrol]], [[wire-protocol-as-contract]]
