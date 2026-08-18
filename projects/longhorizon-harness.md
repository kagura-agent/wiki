---
title: LongHorizon-Harness — verified-state control loop for computer-use agents
created: 2026-08-05
tags: [agent-harness, computer-use, verification, long-horizon, orchestration]
last_verified: 2026-08-18
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

## Follow-up — 2026-08-10

GitHub API check at `7580d808285cb21d409adea48f4602d13c75aa97`: the project is no longer a launch-day paper/release burst. It reached **517 stars / 63 forks / 6 open items** and merged PR #15, adding a Terminal-Bench harness. The immediately preceding work adds a user-facing final reply and runs agents in the launch directory, so execution-environment ergonomics is receiving active attention.

External participation is now visible but immature: issue #13 proposes deterministic/cost-aware executor-tier escalation, and external PR #11 proposes loopback-Host plus JSON-content-type gates for the unauthenticated local dashboard. Neither change is merged as of this check; the latter is evidence that the dashboard control plane needs an explicit browser-origin boundary, not merely a loopback bind.

- Revisit **2026-08-17**: check whether Terminal-Bench ships reproducible results, whether the dashboard hardening lands, and whether user-reported nested-workspace/config inheritance is resolved.
- Do **not** adopt a new harness now: our FlowForge + evidence gates already cover the principle; a concrete recurring long-running GUI task would be the appropriate trigger for evaluating a small adaptation.

## Follow-up — 2026-08-17

**THRIVING**: 779⭐ / 90 forks / 24 open issues (517→779, +50.7% in 7d). Default-branch commits steady (08-14/12/11/10) — pushed_at 08-14 is real activity, not a stall. Merged since last check: PR #35 DeepSeek harness support, dashboard UI release (#22), Terminal-Bench already in (#15). The dashboard hardening and control-plane boundary from the 08-10 note: external PR #11 (loopback-Host + JSON content-type) is still open, joined by more control-plane work.

**Community is now real, not incidental** — 8 external contributors in 30 days: wang-kaopu (#43 Windows MIME fix, open), izaart95-jpg (#41 Opencode support, open), OrigamiKoala, TON14 (#33 EBADF, #28 guard failures), rajathpi, saikethan27 (#29), lunar-me (typo trio), SashaMIT (dashboard hardening). Fork network organic: newest forks all 0⭐ individual accounts with PR→fork contribution flow (wang-kaopu forked 08-16 then opened #43) — the opposite of [[multi-agent-workflow-lab]]'s coordinated fake fork network. 208-test suite added by external PR #29, no paid model calls.

### Pattern extraction from PR #29 — cost-aware executor tiering (deep read)

saikethan27's external PR adds a **tier dimension** (`cheap`/`strong`) orthogonal to the existing **type** (`gui`/`cli`), with cost-aware escalation. The genuinely transferable design decisions:

1. **Escalation never bypasses verification.** `cheap → Auditor → FAIL → strong → Auditor`. A passing audit clears the escalation and routing snaps back to cheap — the expensive model is scoped to exactly the stretch that is struggling. No un-audited strong-model shortcut.
2. **Failure taxonomy is the whole game.** An earlier version escalated on round 1 of every task because `incomplete + clean + aligned` (ordinary mid-run progress) was counted as failure. The fix distinguishes: `blocked`/`suspect`/`needs_revision`/error → `escalate_after_failures`; consecutive clean rounds naming the same unclosed gap → `escalate_after_stalled_rounds`; `incomplete` with a *new* gap each round → progress, not failure. This maps directly to our FlowForge branch-selection logic and the [[study-saturation]] signal taxonomy — *what counts as a trigger matters more than the trigger mechanism*.
3. **Escalation briefing with trust labels.** Episodes are one-shot (no session to resume across a backend swap), so the escalated executor is briefed with the prior attempt **labelled as that executor's own unaudited claim**, while the Auditor report is labelled authoritative — the same trust boundary our audit-discipline DNA draws. Bounded to 3 most recent failures, char-clipped.
4. **Shell-free agent path (Windows work, same PR).** Agent commands were POSIX shell strings → `create_subprocess_shell` (cmd.exe on Windows) → `mkdir -p` died instantly. Fix: argv lists + `cwd=`/`env=`/stdin, delete `shlex.quote` entirely — **no model-supplied value can reach a shell parser**. `Environment.exec` kept only as explicit escape hatch. This is the strongest practical confirmation of our [[exec-safety]] direction: remove the shell from the agent path rather than sanitize it. (Our own shell usage is a known debt — see [[shell-free-execution]] candidate.)
5. **Windows branches document what they can't reproduce.** POSIX `O_NOFOLLOW`/`dir_fd` guarantees get Windows branches that keep what the platform can express (reparse-point refusal, atomic replace) and explicitly document the un-anchorable guarantee (check-then-use window). Honest capability accounting rather than silent degradation.
6. **JSON-free manager protocol.** Manager emits plain natural language (`Next: cli` / `Executor tier: cheap` lines), never JSON — same convention as [[Lobster0]]'s exact-argv boundary.

PR #33 (TON14) adds tolerant-close discipline: EBADF in a `finally` close shouldn't take down a healthy run — a failed poll costs that poll, not the watcher; a stored watcher error never overrides a finished run's outcome. Small but exactly our kind of robustness rule.

### Relation to our direction

- [[FlowForge]] could adopt the tier concept wholesale: cheap default model + escalate-on-struggle + verified-return, with the failure-taxonomy rule as the guard against spurious escalation.
- The trust-label briefing (unaudited claim vs authoritative audit) matches our evidence-first audit discipline and could formalize subagent handoff briefings.
- Shell-free argv execution is a concrete safety upgrade for our own tool paths.

Revisit **2026-08-21**: whether #29/#41 merge, control-plane boundary lands, and whether the tier model survives maintainer review. Track, don't adopt — still no concrete long-running GUI task on our side.

## Delta — 2026-08-18 (quick scan catch, 811⭐)

Three of the four open questions from 08-17 resolved within hours: **PR #11 (control-plane boundary: loopback Host + JSON Content-Type + body cap) MERGED 08-17 08:15** (SashaMIT), **PR #41 (Opencode support) MERGED 08-17 03:31**, and new **PR #50 (Recover from local role timeouts) MERGED 08-17 13:48** (Upper9527, 171+/19-, 203 tests). PR #29 (cost-aware escalation) still open.

### PR #50 — timeout misclassification lesson (transferable)

Root cause: `CommandAgentAdapter` correctly returned `EpisodeResult(status="timeout")`, but the generic provider-error classifier matched the adapter's own synthesized `Episode timed out after ...` text against its network-timeout regex → failure kind became `network` → Manager terminated the whole run as provider failure.

Fix: keep local timeout status explicit and authoritative (don't let a synthesized message reclassify it), preserve timeout status + partial Executor output, let the next Manager round inspect the real workspace and recover; regression coverage for Manager/Executor/Auditor all three roles.

**Transferable rule: error taxonomy must key on status fields, not message-pattern matching — a synthetic message colliding with a provider-error regex turns a recoverable event into a fatal one.** Directly maps to our subagent handling: Copilot API ~60s streaming idle timeout is a *local budget* event (recoverable, partial output preserved, main agent takes over) vs genuine provider failure. We already practice "subagent 超时 → 主 agent 接手", but this is the first explicit argument for *preserving partial output as first-class state* rather than discarding the episode. Also: `incomplete + new gap each round` = progress ≠ failure (same taxonomy lesson as PR #29's failure taxonomy).

Revisit **2026-08-21**: #29 merge status + whether timeout-recovery holds in real runs.
