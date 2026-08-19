---
title: "ProofRun — Local Verification Receipts for AI Coding Agents"
created: 2026-08-19
last_verified: 2026-08-19
source: https://github.com/yebiguo/ProofRun
stars: 14
status: track
tags: [verification, evidence, trust, test-gating, ai-agent, safety]
---

# ProofRun — Local Verification Receipts for AI Coding Agents

**Repo:** [yebiguo/ProofRun](https://github.com/yebiguo/ProofRun) · 14⭐ / Go 1.22+ / 65 commits / MIT / CI+codecov (08-19). Found via HN Show HN (08-17) + GitHub search `topic:ai-agent created:>08-12`. Young (~2w), tiny, but unusually well-scrutinized for its age.

## What it is

Answers one question: **did a check actually run against the exact code you have right now?** An AI agent says "all tests pass" — ProofRun closes the gap between "I ran it and it passed" and "I'm pretty sure it would pass." Not by making the agent more honest, by making the claim itself checkable.

```bash
proofrun run test -- pytest        # runs for real, binds result to git state
proofrun status --strict           # non-zero exit if anything isn't PASS
```

Core mechanism: **no LLM anywhere.** Verifies AI with a real subprocess + real exit code. Four statuses, never a guess: `PASS` / `FAIL` / `STALE` / `NOT RUN` — "there's no fifth 'probably fine'."

## Key design decisions

### 1. STALE is computed at read time, never stored (receipt.go)
A stored CheckResult only records one of two literal outcomes of a real execution: `pass` or `fail`. `STALE` and `NOT RUN` are never written to disk — they're derived at read time by comparing the stored result's fingerprint against the current one. Package comment states the principle: *"Only an observed execution can produce a stored result, but staleness is a fact about the present, not about what happened when the check last ran."* This split means storage stays append-only-truthful and the staleness logic can't be fooled by editing the receipt.

### 2. Fingerprint = git HEAD + SHA-256 of `git diff HEAD` + untracked non-ignored files
Change a single byte (staged, unstaged, or untracked) → result flips to `STALE` automatically. Nobody has to remember to ask "does this PASS still count?"

### 3. Argv-exact comparison, never string-matched (docs/case-study.md — MUST READ)
The original implementation compared `strings.Join(storedCommand, " ")` against a declared command string. Two *different* argvs join to the *same* string:

```go
[]string{"go", "test", "-run", "TestCritical", "./..."}   // 5 elements
[]string{"go", "test", "-run", "TestCritical ./..."}      // 4 elements
```

Both join to `"go test -run TestCritical ./..."`. The second is what a stray quote produces — and it runs **zero tests, exits 0**: `go test -run "TestCritical ./..."` → "warning: no tests to run" → PASS. A check that never ran, reporting PASS, blocking nothing. Fixed by comparing real argv arrays element-for-element. **This is the canonical false-PASS trap for any test-gating tool.**

### 4. Tamper-evident (not tamper-proof) receipts
Every stored result is HMAC-SHA256 signed with a machine-local random key (`.proofrun/secret`, kept out of git via `.git/info/exclude`; if the key is ever git-tracked, ProofRun refuses to trust it). Hand-edited receipt.json — even with a fingerprint that matches perfectly — fails verification → shows as `NOT RUN` (declared checks) or is discarded entirely (one-off runs). Honest limits documented in README:
- **Not tamper-proof**: a sophisticated attacker who can read `.proofrun/secret` can forge matching signatures (inherent to any local-only scheme)
- **Machine-local, not portable**: copy receipt.json elsewhere without the key → won't verify. Third-party evidence is the GitHub Action's independent re-run, which **clears `.proofrun/` first and never trusts a checked-out receipt**
- **No rollback/replay defense**: a genuinely signed receipt from an earlier real run restores fine against the same fingerprint

### 5. v0.3 security fix: symlinked parent + planted key (parent_symlink_test.go)
A symlinked `DirName` (`.proofrun -> planted`) lets a repo plant a git-tracked key at `planted/secret`: `IsTracked` checks the logical path string (`.proofrun/secret`), Lstat resolves through the symlinked parent and sees a regular file → attacker's known key adopted as "this machine's" signing key → they can forge signatures for any predictable commit. Caught by independent adversarial review before shipping. Fix rejects the symlinked-parent case. **Path checks must resolve real paths, not logical strings.**

### 6. Self-scrutiny as method (AGENTS.md + case-study)
Built by Claude Code under human direction; **every change** goes through independent read-only adversarial review by a second AI (Codex) before merge; the human merges; neither agent's "this works" claim is sufficient. Every fix verified against a real reproduction before acceptance. Two shipped bugs caught this way (argv-join, symlink-key). Quote: *"A tool built to hold AI agents accountable has no business existing if it can't survive that same scrutiny applied to itself, continuously, not as a one-time gate."*

## External critique (issue #12 — the one real issue, high quality)
From the Show HN thread: local HMAC proves a receipt wasn't hand-edited on the signing machine, but a stranger receiving `receipt.json` must still trust that *your* machine's key wasn't the one signing (or leaking/rotating). Maintainer's answer: deliberate non-goal; execution-binding (local) vs third-party vouching are two different legs. The critic then **built** the complementary leg (invinoveritas, third-party signed verdict) and composed both with ProofRun v0.3 + 3 tests — both legs real calls, not mocked. Maintainer engaged well; critic credited the exchange. Good example of critique → complementary-tool resolution.

## Ecosystem position
Not a harness — a **trust layer for harness claims**. Complementary to [[agent-harness-landscape]] verification tooling; philosophically adjacent to [[lobster0]]'s honest PASS-gate discipline (IMPLEMENTATION PASS vs LIVE PASS) and our own [已验证] data discipline. Distinct from LLM-judge verification (e.g. MAWL's rules-not-judge principle is about *classifying* injection; ProofRun is about *proving execution*). No overlap with existing tracked portfolio items — NOVEL.

## Relevance to us
- **Automates our Definition of Done "tests pass locally"**: currently that's a claim in a report; `proofrun status --strict` wired into pre-commit/CI makes it checkable. Candidate for our own repos (workspace, flowforge).
- **argv-join trap applies to our own shell/tooling**: whenever we compare "what command was run" vs "what was declared" (approval flows, test gates, compress-output), compare argv arrays, never flattened strings.
- **STALE-at-read-time principle** maps to our memory/wiki discipline: freshness should be derived from state, not asserted (analogous to [[pushed-at-misleading]] — don't trust timestamps, recompute against current state).
- **Symlink/real-path lesson** for our security-sensitive path handling (teams-relay file API, lobster0 approval paths).
- **Two-agent adversarial review** validates our own practice; also a model for open-source contribution hygiene (reviewer ≠ author, fixes repro-verified).

## Follow-up
- Revisit 08-26: community growth (currently 1 issue — external engagement exists but tiny), GitHub Action maturity, whether it survives real-world "agent fakes receipt" attempts (rollback/replay defense remains open by design).
- Candidate apply: try ProofRun on one of our repos' test gates; report whether STALE detection catches a real drift (failable verification).
