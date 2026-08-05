---
title: "Ratchet — post-edit complexity guard for coding agents"
created: 2026-08-05
updated: 2026-08-05
tags: [agent-hooks, code-quality, verification, supply-chain-security]
last_verified: 2026-08-05
---

# Ratchet (0xwilliamortiz/ratchet)

**Repository:** https://github.com/0xwilliamortiz/ratchet
**Observed 2026-08-05:** 430 stars, 85 forks; JavaScript, MIT; default branch has two commits (both 2026-08-04), no releases, and no test files despite README claiming 115 tests.

> **Do not install / do not run on Windows.** The current default branch distributes an 80.5 MB `hooks/ratchetui.zip`. `bin/install.js` silently expands it with PowerShell using `-ExecutionPolicy Bypass`, then launches `ratchetui.exe` for every CLI command except `help`. Issue #1 contains detailed third-party malware allegations about earlier executable/DLL artifacts. I verified the current ZIP distribution and automatic launch path from the repository source; I did **not** download, execute, or independently reverse-engineer the archive/binaries.

## What it tries to solve

[[Ratchet]] closes the gap between prompt-only coding rules and actual edits. A `SessionStart` hook injects a minimalism ruleset; a `PostToolUse` hook measures each write, detects a small fixed set of patterns, and returns findings to the agent while the task is still active. It maintains a per-session budget for new files, dependencies, and net added lines, then records a per-repository baseline/ledger.

The model is a practical sibling to [[OpenLoop (thu-nmrc/openloop)]] and [[verify-claims]]: the builder does not self-certify. But it applies the gate to code-complexity heuristics rather than task outcomes.

## Architecture observed in source

- `hooks/ratchet-guard.js` handles `Edit`, `MultiEdit`, and `Write`; it compares input content with `HEAD`, scans only changed lines, deduplicates findings, and blocks only `certain` findings in `strict` mode.
- `hooks/lib/detect.js` grades results `certain`, `likely`, or `heuristic`. Its checks cover newly added manifest dependencies, hand-rolled stdlib/platform alternatives, shallow wrappers, duplicated normalized symbols, single-implementation abstractions, and complexity budgets.
- `.ratchet/mark.json` is an accepted code-size point; `.ratchet/ledger.jsonl` records session deltas. A baseline fingerprints pre-existing findings, so only new debt warns.
- Tests are intentionally excluded from both the guard and audit by default. This avoids fixtures causing alerts, but also leaves test-only complexity outside the claimed ratchet.

## The useful pattern

The strongest transferable idea is **graded, evidence-labeled feedback delivered at the edit boundary**. Ratchet does not pretend regex is a type checker: only manifest facts and a few syntactic matches are `certain`; structure and shape matches are weaker. That is a sharper interaction contract than a generic “keep it simple” prompt.

For our [[FlowForge]] workflow, the analogous safe adoption is already closer to [[regression-gate]] than to an edit hook: use deterministic verification for hard claims, surface advisory heuristics as advisory, and require an explicit reason when deliberately exceeding a budget. Do not adopt Ratchet itself or its launcher.

## Important limits and contradictions

1. Its “real diff” algorithm is line-multiset comparison rather than a true diff, so moved/repeated lines can distort added/removed counts.
2. `strict` blocks on an asserted `certain` match, but whether a host honors the emitted `decision: "block"` is host-dependent.
3. The repository has no visible `tests/` directory or test files on its current default branch, which conflicts with README’s “115 tests” and the `npm test` script (`node --test`).
4. The 80.5 MB ZIP and hidden Windows auto-launch conflict with a tool whose stated purpose is reducing unexamined complexity. The third-party security report warrants treating the entire distribution chain as untrusted until independently audited from source.

## Ecosystem position

The project sits between agent instruction files and full CI/static analysis: a local, hook-time policy guard for coding agents. The demand signal is real—agents need mechanisms that convert norms into observable feedback—but a supply-chain trust boundary is non-negotiable. This project is therefore useful as a design reference for *graded guardrails*, not as a dependency.

## Checkable prediction

The repository will either remove/disable the Windows ZIP launcher or be effectively abandoned before 2026-08-19; continued distribution of the current archive is incompatible with the unresolved public security report.
