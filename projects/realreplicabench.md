---
title: RealReplicaBench — stateful, reproducible business-workflow benchmark
created: 2026-08-06
updated: 2026-08-06
tags: [agent-evaluation, long-horizon, openclaw, verification, reproducibility]
last_verified: 2026-08-27
source: https://github.com/Accio-Lab/RealReplicaBench
---

# RealReplicaBench (Accio-Lab/RealReplicaBench)

**Observed 2026-08-06:** Apache-2.0 harness/package code; 1,018 stars, 69 forks, 0 Issues. It contains 107 stateful business-workflow tasks (53 CLI, 28 browser, 16 file, 10 API/MCP), run in fresh Linux containers against local replicas of commerce/SaaS services. The benchmark exposes an OpenClaw harness and pins its public image by SHA-256 digest.

## What it is testing

This is not a text-only agent scorecard. Each task changes a mock service or produces artifacts, then a task-specific verifier evaluates the resulting state. The representative Stripe task's verifier reads the mock state through a verifier-token endpoint and checks concrete resource identities, field values, tuple-level subscriptions, cardinality/negative conditions, triggers, and a dynamically derived audit record. It then folds atomic checks into capability groups. That makes partial progress inspectable without treating partial success as a pass.

The useful distinction is **reproducible execution environment versus independently reproducible leaderboard**. The container/task/verifier path is public and specific; however, the README explicitly says the raw task-level result bundles behind its published reference tables do not yet have immutable public URLs or checksums. The board is therefore an audited aggregate, not currently a standalone reproduction artifact.

## Architecture observed in code and tests

- `real_replica_bench/harnesses/openclaw/runner.py` builds a single unattended execution prompt, injects provider configuration into the container, and collects the agent state/logs after each task for post-mortem inspection. It distinguishes legacy relay images from managed-attach browser mode rather than assuming one browser protocol fits every runtime.
- The runner prepends a harness-level autonomous-execution directive because persona-forward models otherwise self-introduced and made zero tool calls in one-shot runs. It is explicitly uniform across runs, avoiding task-specific grader hints, but means scores depend on the exact harness prompt/version.
- Public tests exercise real local HTTP endpoints for judge wire formats, validate every distributed OpenClaw provider configuration, reject missing credentials before Docker starts, and test the generated CLI-wrapper source—not merely its generator. The latter catches a real failure mode: a daemon that receives an untraversable agent cwd exits `127` with no useful output.
- There are no public issue discussions to challenge the design yet. Recent commits are active and narrowly scoped around runtime fidelity, config contracts, and reference-table corrections.

## Relation to our direction

[[LongHorizon-Harness]] evaluates whether an outer control loop carries forward only auditor-approved state. RealReplicaBench instead evaluates whether an agent can make durable, verifiable changes within a realistic stateful environment. Together they separate two often-collapsed questions: *can the harness preserve trustworthy progress?* and *can the agent actually operate a stateful surface?* [[computer-anthology|Computer Anthology]] is a watch item for the next question: whether those task and harness choices remain discriminative under semantic perturbation.

For [[OpenClaw]] and [[FlowForge]], its transferable pattern is **preserve a replay bundle at the boundary where a claim is scored**: resolved config, trajectory, verifier output, artifacts, logs, and environment metadata. FlowForge already provides explicit transition history; a small future evaluation harness should add task-scoped artifact manifests and deterministic state assertions before treating a workflow as empirically validated.

## Limits and counter-signals

1. The project is four days old and has no issue/PR criticism signal, so claimed robustness and leaderboard interpretation remain weakly externally tested.
2. The public benchmark image pins OpenClaw `2026.5.22`, while this environment is later. A result is evidence about that pinned harness/runtime combination, not automatically current OpenClaw behavior.
3. LLM-assisted verifiers remain part of the suite. Deterministic state verification is strongest for concrete mutations; artifact quality scoring still inherits judge/model sensitivity.
4. A shallow local clone was SIGKILLed after transferring a 13 MB partial checkout. Subsequent source inspection used GitHub's tree/content API, which was sufficient for README, tests, runner, verifier, commit, and issue evidence but is not a full local execution or Docker reproduction.

## Ecosystem position and follow-up

It is a high-fidelity complement to static coding benchmarks and broad browser benchmarks: realistic mock services plus state-based grading make it relevant to long-running operational agents. Its most important open test is whether it publishes immutable task-level result bundles and receives independent reproductions rather than only managed evaluations.

- Revisit **2026-08-20**: check whether result bundles receive immutable URLs/checksums, whether independent issues/PRs appear, and whether the pinned image/runtime advances.
- Do not run the full suite without an explicit evaluation goal: it requires Docker, model and judge credentials, and is materially more expensive than an architecture read.

## 2026-08-20 Follow-up

- **1,193⭐** (+17% from 1,018 in 14d), 100 forks, 1 open issue.
- **ACTIVE:** default-branch commits daily through 08-20. Notable: rebrand to **Commerce Agent Bench** (non-image rename complete 08-19, leaderboard/logos aligned), frozen benchmark PDF assets restored 08-20 (reproducibility-focused maintenance).
- **Provenance gap persists:** still **0 releases / no immutable checksum URLs** for reference score bundles — the open question from 08-06 remains unanswered.
- Community still thin: 1 open issue (deterministic Zendesk Support ticket mock #4, feature request, no external criticism signal).
- Revisit **2026-08-27** for provenance artifacts (immutable URLs/checksums) + rebrand landing effect on community signal.

**Prediction (08-20, medium):** RealReplicaBench will still lack immutable/checksummed result-bundle URLs at the 2026-08-27 revisit (provenance gap = deliberate non-goal so far, not backlog).

## 08-27 Calibration — cal-0820-62fb ✅ CORRECT

- Prediction: RealReplicaBench still lacks immutable/checksummed result-bundle URLs at 08-27 (provenance gap persists).
- Actual: **0 releases** (Accio-Lab/RealReplicaBench releases API empty). Provenance gap confirmed — deliberate non-goal holds.
- Note: repo path is Accio-Lab/RealReplicaBench (rebranded from earlier name); verification used correct owner.
