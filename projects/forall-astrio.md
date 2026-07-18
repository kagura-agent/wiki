# Forall (astrio-labs/forall)

> Coding agent that generates spec-driven code alongside machine-checkable proofs.

- **Stars:** 279 (as of 07-18)
- **Language:** Rust (core) + TypeScript/Java support
- **License:** Apache-2.0
- **Created:** 2025-07-18 (1 year old)
- **Status:** Active (pushed 07-18), steady growth

## What It Solves

The gap between "AI writes code fast" and "AI writes correct code." Instead of relying solely on tests (which AI can also write incorrectly), Forall adds formal contracts (pre/post conditions) that are machine-checkable — a fundamentally different verification layer.

## Architecture

**Two product paths:**
1. **Forall CLI** (closed-source binary) — Full coding agent with TUI, sandbox, native tools. BYOK (OpenAI/OpenRouter) or Forall account.
2. **MCP verify-only** (`@astrio/forall-mcp`) — Plugs into Cursor/Claude Code/Codex via MCP. Adds verification without workflow change.

**Open-source components:**
- `forall-authoring` — Project init, symbol discovery, contract scaffolding, requirement mapping, validation
- `forall-hosted-verify` — Snapshot packing + authenticated submission to hosted verification workers

**Closed-source:** The actual verification engine (formal proof checking).

## Key Patterns

### Contract Annotation (language-specific)
```typescript
// TypeScript: comment-style
export function clamp(x: number) {
  //@ requires Number.isFinite(x)
  //@ ensures result >= 0
  return x < 0 ? 0 : x;
}
```
```rust
// Rust: clause-style (native syntax extension)
pub fn clamp(x: i32) -> i32
    requires x >= i32::MIN,
    ensures result >= 0,
{ if x < 0 { 0 } else { x } }
```
```java
// Java: JML-style comments
//@ requires x >= 0;
//@ ensures \result >= 0;
public int clamp(int x) { return x < 0 ? 0 : x; }
```

### SHA256 Optimistic Locking
Every mutation carries `expected_sha256` for affected files. Stale content → entire multi-file mutation rejected atomically. Clean pattern for concurrent agent safety.

### Spec-Driven Workflow
```
propose → specs → design → verify → tasks → apply → archive
```
`.forall/verify/mapping.yaml` tracks requirements ↔ code ↔ contracts ↔ property tests. Machine-readable traceability.

### Snapshot Verification
Workspace packed as inline files, sent to hosted MCP endpoint for verification. Isolation between authoring and proving.

## Tradeoffs

| Pro | Con |
|-----|-----|
| Novel verification layer beyond tests | Verification is hosted/closed (vendor lock-in) |
| MCP integration = zero friction for existing agents | Only 3 languages (TS, Rust, Java) |
| Spec-driven workflow enforces rigor | Heavyweight for small changes |
| Clean Rust code, well-tested | Actual proof-checking is opaque |

## Ecosystem Position

- **Complementary** to [[coding-agent-ecosystem]] — adds verification layer that any MCP-compatible agent can use
- **Not competitive** with Claude Code/Codex — designed to work alongside them
- **Unique angle:** No other agent tool does formal verification. Closest is [[code-duo]] (cross-review) but that's heuristic, not formal
- Similar workflow structure to [[flowforge]] (spec-first, staged) but with mathematical guarantees

## Relevance to Us

1. **MCP verify-only pattern** — Clean example of "add capability without requiring tool switch." Could apply this pattern to other augmentation tools.
2. **SHA256 optimistic locking** — Already doing similar in FlowForge. Validates the approach.
3. **Contract-first development** — Interesting alternative to our "test-first" approach. For critical code paths, contracts + verification > tests.
4. **Integration opportunity** — Could add `@astrio/forall-mcp` to our coding workflow for high-stakes code.

## Anti-Intuitive Findings

- The open-source part is the "boring" authoring scaffolding, not the verification. The actual value prop (proof checking) is hosted/closed. This is "open-core done right" — the open-source part is genuinely useful (contract scaffolding, workflow) even without the hosted service.
- Issues on the repo are unrelated to the current Rust codebase (Python artifacts from a pivot?). Suggests the project was rewritten/pivoted at some point.
- 279 stars after 1 year = slow but steady. Not viral. Formal verification is a hard sell to developers who think tests are enough.

## Predictions

- Will remain niche (<1000 stars) unless a major coding agent integrates it by default
- Language support will expand (Go, Python next likely based on demand)
- The hosted verification model will face pushback from security-conscious teams

Links: [[coding-agent-ecosystem]], [[flowforge]], [[code-duo]], [[agent-infrastructure-trend]]
