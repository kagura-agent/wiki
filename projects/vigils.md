# Vigils — Local-First Agent Control Plane

**Repo**: [duncatzat/vigils](https://github.com/duncatzat/vigils)
**Stars**: 199 (2026-06-03, was 50 on 06-01 → 100 on 06-02 → 199 on 06-03; 4x in 3 days)
**Stack**: Rust workspace + Tauri 2 + Vue 3 + Chrome MV3
**License**: Apache-2.0

## What It Does

A local-first control plane that sits between AI agents and their tools/data. Four guarantees: see (audit), approve (HITL), redact (secrets/PII), contain (sandbox).

```
AI agent → [redact → firewall → approve → sandbox → audit] → tools/data
```

## Architecture (Key Patterns)

### 1. Tamper-Evident Audit Ledger
SHA-256 hash chain over SQLite. Each event hashes: domain tag + previous hash + JCS-normalized payload + timestamp. Cross-version test vectors are locked as contracts — changing hash algorithm without ADR upgrade = regression. FTS5 full-text search over redacted trail.

**Why it matters**: Most agent audit solutions use append-only logs. Hash chain makes tampering *detectable*, not just difficult. JCS normalization (RFC 8785) ensures key ordering doesn't affect hashes.

### 2. Default-Deny Policy DSL
Rust-native policy engine. Rules have `match_effects`, `conditions`, `action`, `priority`. Evaluation: descending priority, fail-closed bias (`Deny > Approve > Allow`), no-match = Deny. Per-agent rules, OAuth scope allowlists.

**Relevance to OpenClaw**: OpenClaw's tool policy is currently string-based allow/deny lists. vigils' `EffectVector` extraction (paths, URLs, SQL, shell commands, secrets, browser actions, emails) + risk scoring is more granular — could inspire richer tool policy expressions.

### 3. Credential Lease Broker (Novel)
Short-lived secret leases with bound triple validation (session + server + tool). Flow:
1. Firewall approves → Hub calls `mint_lease` just-in-time before spawn
2. Lease injected as child process env (RAII revoke)
3. Call ends → immediate `revoke_lease` (Zeroizing clears memory)
4. Bound triple mismatch at resolve → `secret.lease_misuse_attempt` audit event

**Key insight**: Secrets never appear in prompts, logs, or UI. Only the `SecretValue.expose()` method accesses plaintext. Audit events contain only alias + metadata.

**Relevance to OpenClaw**: OpenClaw uses `pass` for secrets but injects them as env vars with no TTL or scoping. Lease pattern would prevent leaked credentials from being reusable.

### 4. MCP Descriptor Drift Detection
Pin tool descriptors by hash at first approval. On every subsequent call, hash the current descriptor and compare. Three outcomes: `FirstSeen`, `Unchanged`, `Drifted{old, new}`. Drift triggers re-approval.

**Why it matters**: A compromised MCP server could change a tool's behavior (e.g., `read_file` gains `write_file` capability) without the user noticing. Descriptor pinning catches this.

### 5. Preflight PII/Secret Scanning
Runs *before* policy evaluation. 13+ credential class hard-fingerprint detection + optional ML ensemble. Fail-closed: scan failure = deny (never proceed without knowing if PII is present).

### 6. Sandbox Runner
Fail-closed default. Wasm (Wasmtime) or native + Linux Landlock LSM filesystem isolation + `env_clear` so children don't inherit environment.

## Code Quality Assessment

- **45 test files**, including acceptance tests, state machine tests, cross-version hash vectors
- Bilingual comments (zh/en) — clearly Chinese-speaking developer
- ADR-driven development (each feature references its ADR)
- `#![forbid(unsafe_code)]` across all crates
- Iteration-tagged (`I01`..`I07`) — clear development phases

## Relevance to Our Work

| vigils Feature | OpenClaw Equivalent | Gap |
|---|---|---|
| Hash chain audit | Session logs (JSONL) | No tamper detection |
| Default-deny firewall | `tools.exec.security` allowlist | Less granular (no effect extraction) |
| Credential lease broker | `pass` + env vars | No TTL, no triple binding |
| Descriptor drift detection | None | No tool definition change detection |
| PII redaction | None | No automatic PII filtering |
| Sandbox (Landlock) | Sandbox mode | Similar concept |

### Actionable Ideas
1. **Descriptor drift detection for MCP tools** — hash tool schemas at registration, alert on changes. Low effort, high security value.
2. **Credential lease pattern** — scoped, TTL'd secret access instead of permanent env vars. Medium effort.
3. **Effect extraction** — parse tool call arguments to detect paths, URLs, shell commands before execution. Would improve tool policy expressiveness.

## Update — 2026-06-03

### Growth
50→100→199⭐ in 3 days. 4x growth rate. 5 releases in 3 days (v0.1.1→v0.1.7). vigil-sdk published to crates.io.

### Security Audit (Self-Assessment, 9.9/10)
Comprehensive: OWASP Top 10 + STRIDE + supply-chain + Vigils-invariant verification across ~50k Rust LOC.
- 0 Critical, 0 High, 3 Medium, 5 Low, 1 Info
- Hash chain v2: now binds `session_id`, `event_type`, `redacted_text` (was a gap in v1 — partial tampering was undetectable)
- Version monotonicity enforcement (v2→v1 downgrade rejected)
- OTA signed updater pipeline added
- `#![forbid(unsafe_code)]` across all crates

### Architecture (15 crates)
vigil-audit, vigil-browser, vigil-firewall, vigil-http-auth, vigil-http-transport, vigil-lease, vigil-mcp, vigil-policy, vigil-redaction, vigil-runner-types, vigil-runner, vigil-sandbox-linux, vigil-sdk, vigil-types, vigil-ui-protocol

### Community
- 🔴 SOLO — 0 external PRs, 0 issues. Pure single-developer project despite 199⭐
- All releases, commits, and security audit by maintainer only
- Star growth driven by README quality + category momentum, not community

### Assessment
Architecturally excellent. Best-in-class agent security design (hash-chain audit, credential lease broker, MCP drift detection, Landlock sandboxing). But 0 community signal despite rapid star growth.

**Contribution opportunity**: Low — Rust workspace, complex domain, solo developer hasn't invited PRs. Better as study target than contribution target.

**Transfer value**: High — several patterns directly applicable:
1. Hash chain v2 design (bind all auditable fields, version monotonicity) — general audit pattern
2. Credential lease broker with bound triple validation — applicable anywhere secrets are injected
3. MCP descriptor drift detection — simple hash-compare, high security value
4. Preflight PII scanning with fail-closed merge — applicable to any pipeline

## Tracking Decision
🟡 WATCHING → 🟢 CONFIRMED INTERESTING. 199⭐, strong architecture, rapid iteration. But SOLO (0 community). Worth monitoring for community formation. Revisit 06-10.

Tags: #agent-safety #audit #mcp #governance #rust
Links: [[agent-budget-control]], [[mcp-ecosystem]], [[coding-agent-ecosystem]]
