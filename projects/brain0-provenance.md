# brain0 — The Black Box for AI-Written Code

> `git` tells you *what* changed. brain0 tells you *why*: which prompt wrote it, what the agent read, and whether you can trust it.

- **Repo**: [Brain0-ai/brain0](https://github.com/Brain0-ai/brain0)
- **Stars**: 22⭐ (2026-07-05, 3 days old)
- **License**: Apache-2.0 (open-core: enterprise = AGPL + commercial)
- **Stack**: Rust (14 crates) + TypeScript (GUI/server/CLI), SQLite + sqlite-vec, PixiJS GUI
- **Status**: Active, dogfooding on itself

## What It Solves

Coding agents write most diffs now — continuously, in parallel, opaquely. Git tells you *what* changed but not *why*, not what agents *read* to write it, and not whether you can *trust* it. brain0 passively builds a decision graph linking every commit to the agent intents behind it, with three signals that exist nowhere else:

### Three Novel Signals

1. **Drift** — declared vs. done reconciliation. Agents narrate what they changed; git records what actually changed. brain0 computes the symmetric difference. Cumulative across session turns (avoids false positives from single-turn comparison). Score = |symmetric_diff| / |union| ∈ [0, 1].

2. **DLP Reads** — audit trail of what files (incl. secrets) reached the model's context. Secret scanning at ingest: regex patterns (12 types: API keys, JWT, PEM, env vars, URL creds) + Shannon entropy heuristic (≥32 chars, mixed, ≥4.0 bits/char). Redacted before storage — only KIND is recorded, never the value.

3. **Two-Dimensional Risk** — a-priori (centrality, blast radius, churn, test gap, diff size, drift) × a-posteriori (reverted, immediate fix, tests broken, linked issue). Probabilistic-OR fusion: `1 - (1-a)(1-p)`. The **gold signal**: `SafeToDangerous` transition — looked safe up front, proved dangerous later. This is the pattern worth studying.

## Architecture Insights

### Passive Observation Over Cooperation
brain0 never modifies repo, never hooks into agents. It reads git history + agent transcripts (Codex `~/.codex`, Claude Code `~/.claude/projects`, auto-discovered). Zero agent cooperation required. This is the right design — you can't trust the system you're auditing to participate honestly in its own audit.

### Deterministic Symbol Identity
`hash(repo + level + qualified_path + structural_fingerprint)` → two independent machines converge on the same graph without merge logic. Rename/move tracking via Jaccard similarity over AST fingerprint shingles (threshold 0.6). Preserves "no unjustified new nodes" — a renamed function stays the same node with new coordinates. Uses Tree-sitter for multi-language symbol extraction.

### Risk Transition Classification
Not just "how risky" but "how did risk evolve":
- `Pending` → no a-posteriori evidence yet
- `Stable` → looked safe, stayed safe
- `SafeToDangerous` → the gold signal ⭐
- `ConfirmedDangerous` → expected risk confirmed
- `OverestimatedRisk` → false alarm

This 2D model is more useful than a single score — it separates "we were wrong about risk" from "risk was always high."

### Signed Attestations
in-toto Statement (subject = commit, predicate = provenance) signed Ed25519. `compliance` command = auditor pack: AI-assisted commits, unreviewed commits, secret-bearing reads, drift events.

## Agent Ecosystem Position

- **Complements** [[ClawPatrol]] (wire-level security) — brain0 is post-hoc audit, ClawPatrol is real-time interception
- **Complements** [[Graphenium]] (structural memory with trust model) — brain0's risk model is evidence-driven per-commit, Graphenium's is per-knowledge-node
- **Adjacent to** [[halo-agent-trace-optimizer]] (agent trace optimizer) — but brain0 is provenance/audit, halo is performance optimization
- **New category**: "agent accountability" tools — distinct from agent memory, harnesses, or sandboxing

## Relevance to Our Direction

1. **Trust/accountability is real** — brain0 validates our thesis that trust in AI-written code is a genuine problem. The fact that a well-funded team built 14 Rust crates for this says the problem is large enough.
2. **Gold signal pattern** — the a-priori → a-posteriori transition classification is applicable to our own risk tracking (e.g., study predictions, PR quality assessment)
3. **Passive observation principle** — aligns with our "instrument, don't interfere" philosophy. The system being observed shouldn't know it's being observed.
4. **DLP for agents** — tracking what agents read is an underexplored dimension. We track what agents *write* but not what they *consume*. Worth thinking about for OpenClaw.

## Counter-Arguments / Limitations

- 22⭐ in 3 days, but this is enterprise-grade Rust + open-core. The team is building for enterprise sales, not GitHub stars.
- No issues yet — can't assess community health or architectural criticisms.
- CLA required — may limit community contributions (the Hashicorp pattern).
- The drift signal requires agent transcripts on disk — not all agents leave those (OpenClaw doesn't write session transcripts to `~/.openclaw/` in the same way).

## Patterns Worth Extracting

1. **Probabilistic-OR fusion for multi-signal risk**: `1 - (1-a)(1-p)`. Simple, monotonic, bounded. Better than weighted average for independent risk signals.
2. **Cumulative drift**: comparing session-cumulative declarations against commit-level actuals. Single-turn comparison produces false positives.
3. **Secret scanning as ingest filter**: scan + redact before ANY storage/embedding. The right layer to do it.

## Tracking status 2026-08-13 — Dropped

- **Stars DECLINED 397 → 369**, code still stale (last push 07-19, now 25 days), 0 open issues, 14 forks. No code resumption within the "watch for resumption" window set on 07-30.
- Meets drop criteria: declining stars + dead community + no commits ~25d. The `SafeToDangerous` risk-transition model and drift/DLP-read signals are already extracted above and stay in the wiki as patterns; only the tracking entry is removed.
