---
title: LongHorizon-Harness — verified-state control loop for computer-use agents
created: 2026-08-05
tags: [agent-harness, computer-use, verification, long-horizon, orchestration]
last_verified: 2026-08-05
source: https://github.com/AMAP-ML/LongHorizon-Harness
---

# LongHorizon-Harness — verified-state control loop for computer-use agents

**Repository:** [AMAP-ML/LongHorizon-Harness](https://github.com/AMAP-ML/LongHorizon-Harness) — MIT; inspected 2026-08-05 at 180 stars / 14 forks, created 2026-08-04. The repository had no Issues at inspection time, so there is no external criticism signal yet.

## What it is

A Python harness that wraps Claude Code, Codex CLI, or OpenClaw for multi-round GUI/CLI tasks. Its central claim is not more capable per-turn agents, but a durable task state made only from independently audited outcomes. It places a **Manager → Executor → Auditor** control loop around fresh-context agent episodes; the manager routes each subtask to GUI or CLI, while the auditor alone provides trusted carry-forward state.

The public evaluation assets enumerate 114 WeaveBench tasks and 108 OSWorld-v2 tasks. README performance numbers (e.g. WeaveBench 51.8→80.7) are project claims, **not independently reproduced** in this study.

## Architecture observed in code

- `manager.run()` persists a per-round ledger: inputs, visible executor output, auditor report, `rounds.jsonl`, events, and final report. The manager sees original task, compact maintained state, and auditor reports—not raw prior trajectories. That is deliberate context compression with an evidence boundary.
- Completion is a two-key condition: a manager may request `done`, but `_latest_auditor_is_clean_complete()` must find a prior report whose status is `complete` **and** integrity is `clean`. Otherwise the harness injects a synthetic repair finding and continues.
- The manager can only route one dominant state change per round (`GUI`, `CLI`, `ask`, `done`, `blocked`). The prompts require an explicit dependency judgment before routing, preventing a broad “do everything” task from crossing state boundaries invisibly.
- Auditors have a strict two-line control header (`状态` plus `完整性`). A malformed report becomes `blocked/suspect`; the harness may spend a bounded repair episode on formatting rather than infer completion from prose. Auditor workspace mutation is detected and normally restores the pre-audit snapshot.
- The OpenClaw adapter is thin: it shells out to `openclaw run --prompt-file … --max-turns … --timeout …`. The differentiation is therefore the outer evidence protocol, not an OpenClaw-specific integration.

## Key insight: verified state is a narrower interface than memory

[[agent-harness-landscape]] already identifies durable sessions and first-class verification as ecosystem convergence. This project sharpens the interface: **the next executor gets only auditor-approved state, not conversational continuity**. That makes recovery possible after fresh contexts, but trades away rich situational detail and makes auditor quality/format reliability the harness's critical dependency.

The useful transferable unit is therefore not the three-role naming; it is the completion invariant:

> Executor self-report can inform an audit, but cannot advance persistent task state or close the task.

This agrees with [[FlowForge]]'s explicit transitions and our verification-first DNA. Its strongest extra mechanism is a machine-checkable integrity status beside completion, so “finished” and “trustworthy” cannot collapse into one label.

## Limits and open questions

- The repo is only one day old, has no published issue discussion, and the promised trajectory release is marked “coming soon”; durability and real-world adoption remain unverified.
- The benchmark runners are substantial frozen evaluation packages with heavyweight VM requirements. This study inspected the task-set manifests and reproduction instructions, not a full run.
- Independent auditors reduce executor self-verification bias, but do not eliminate correlated model/tool bias when every role uses the same backend. The project allows separate role backends, yet does not demonstrate a cross-model audit comparison in the inspected sources.
- This is structurally adjacent to [[OpenClaw]], [[FlowForge]], and [[agent-harness-kit]], rather than a replacement: it is a task-level control loop for long-running computer use, whereas FlowForge governs our higher-level workflows.

## Ecosystem position

LongHorizon-Harness is evidence-first orchestration at the computer-use boundary: it combines the durable-state/verification strand in [[agent-harness-landscape]] with GUI/CLI routing and replayable per-round artifacts. Its emergence alongside HN discussion about the GUI for agents suggests attention is moving from single-agent desktop control toward controls that make multi-hour computer work inspectable. Track it for whether the verified-state protocol survives beyond a paper/release burst.

## Follow-up

- Revisit **2026-08-12**: check trajectory publication, commits, issue/PR participation, and whether the OpenClaw CLI adapter matches current OpenClaw invocation semantics.
- Do **not** adopt a new harness now: our FlowForge + evidence gates already cover the principle; a concrete recurring long-running GUI task would be the appropriate trigger for evaluating a small adaptation.
