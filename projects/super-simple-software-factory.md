---
title: "Super Simple Software Factory — Deterministic ADW Skill"
created: 2026-08-06
updated: 2026-08-06
tags: [deep-dive, workflow, agent-harness, observability, safety]
tracking: scout
stars: 432
last_verified: 2026-08-11
---

# Super Simple Software Factory (disler/super-simple-software-factory)

**Repo**: [disler/super-simple-software-factory](https://github.com/disler/super-simple-software-factory) | **432⭐** | MIT | Python + Claude Code skill

## What it is

A portable skill that stamps an AI Developer Workflow (ADW) factory into a target repository. The stamped Python code owns phase sequencing, retries, acceptance, typed JSON envelopes, Git permissions, and SQLite tracing; coding agents (currently Pi only) occupy bounded `agent` phases. Its central claim is: **agent proposes, code disposes**.

This is closest to [[agentic-sop-to-work]] and [[flowforge]], but is aimed at a repository-local SDLC rather than a general agent workflow runtime. It makes the execution trace a first-class product: phase/event/envelope/gate data is written to SQLite during a run and a visualizer polls it.

## Architecture observed

- **Three phase kinds**: human `engineer`, model `agent`, and deterministic `code`. Known invocations such as tests and commits are explicitly code phases rather than delegated rediscovery.
- **Typed seam contract**: an agent final response parses into an `EnvelopeBase` subtype; artifacts, a persisted `envelope.json`, and a next-agent prompt transfer information between phases without relying on conversation continuity. [[goal-flow]] applies a related boundary at a graph/agent seam, where a typed adapter owns state updates and routing.
- **Correction rather than restart**: parse or gate failure re-prompts the same Pi session, preserving working context.
- **Acceptance has two levels**: individual phases can complete while the overall `run.finish(accepted=...)` still rejects the run. This distinguishes “a red test executed successfully” from “the change is accepted.”
- **Post-hoc write enforcement**: `permissions.snapshot()` fingerprints the Git worktree before and after every agent call. The harness compares the change set to `writes` and `protected_files`, rolls back unauthorized changes it introduced, then raises a non-retriable breach. It correctly treats a malicious `git checkout` that erases prior dirty work as a change.
- **Observe live, not from transcripts**: Pi JSONL output is tailed into a SQLite trace database; the stated schema includes sessions, phases, events, envelopes, gate results, agent sessions, and processes.

## The revealing boundary: gates versus authority

The implementation separates an agent’s authority from whether its report is mechanically true. This is a useful sharpening of the [[deterministic-envelope-for-small-agents]] pattern and of [[authority-breach-vs-quality-gate]]: permissions abort a phase because a breach cannot be safely corrected by another prompt, while gates can return an actionable violation to the same session.

However, the top-level safety claim is not yet fully realized. `diff_matches_claims()` only verifies that every claimed path exists; it does **not** compare claims with the actual Git diff. A detailed open issue demonstrates both false passes: unchanged files can be claimed, and unclaimed changes can still reach `commit_all()` because it commits the whole tree. The project already has the needed `git status --porcelain` plumbing, so bidirectional claimed-vs-actual reconciliation is a concrete missing control rather than a conceptual impossibility.

## Tests and operational maturity

The repository’s skill branch contains SDLC workflow scripts named `adw_*_test.py`, but no standalone unit-test directory or test suite. That matters because the project advertises repeatable, gated execution while its low-level guards presently lack regression fixtures in the distributed skill.

The issue tracker is unusually high-signal for a young project: reports identify a fresh-install crash before `pi --list-models` fallback, a Windows launcher/newline bug, thinking-channel-only final responses, and a Windows visualizer path bug. The upstream commit history visible in the shallow clone contained one initial commit (2026-08-02), so these reports are evidence of early external pressure, not yet evidence of a proven maintenance loop.

## Ecosystem position

SSSF sits between prompt disciplines such as [[fable-mode]] and a full harness: its differentiated value is making phase boundaries, envelopes, permissions, and acceptance executable Python instead of behavioral instructions. It overlaps with [[agentic-sop-to-work]] on deterministic orchestration, but SSSF favors a reusable repo-stamping kit, live tracing, and multi-model phase rosters; agentic-sop-to-work has a stronger explicit trace-provenance gate and forward-only control-flow safety.

## Relevance to Kagura

- **Validated**: our [[flowforge]] direction—deterministic state transitions and failable checks outside the model—is aligned with a broader shift from prompt-only agent control to executable control planes.
- **Transferable distinction**: FlowForge should continue treating external-action authorization as a hard, non-retriable boundary, separate from ordinary task-quality retry loops.
- **Not a direct adoption candidate**: it is Pi/Claude-Code-oriented and stamps a large local harness into each repo, whereas Kagura needs runtime-level cross-session governance. Its `agent_cc.py` is still stubbed in v1.
- **Open question to watch**: whether maintainers turn the concrete issue-derived failures into tests and make `diff_matches_claims` truly compare against the diff. That will show whether the project’s “code owns acceptance” principle survives its own edge cases.

## References

- README and source inspected: 2026-08-06
- Issues inspected: #1–#4, all states, 2026-08-06
- Related: [[deterministic-envelope-for-small-agents]], [[agentic-sop-to-work]], [[flowforge]], [[agent-security]]
