# FlowForge 架构深读

> 深读日期: 2026-04-19 | 版本: 1.1.2 | 670 行 TS, 4 文件

## 架构

YAML 定义的有限状态机，SQLite 持久化，CLI 驱动。

```
index.ts (CLI, commander) → engine.ts (状态机逻辑) → db.ts (SQLite)
                                                    → workflow.ts (YAML 解析)
```

### 核心概念
- **Workflow**: name + start node + nodes map（YAML 定义）
- **Instance**: workflow 的一次运行，跟踪 current_node + status
- **History**: 每个 instance 经过的节点记录（entered_at/exited_at/branch_taken）
- **Node**: task 描述 + next/branches/terminal 三选一

### 执行模式
- `executor: 'inline'`（默认）→ 主 agent 自己执行，CLI 输出 task 文本
- `executor: 'subagent'` → `run`/`advance` 命令返回 `type: 'spawn'` JSON，供调度器 spawn subagent

### 数据流
1. `flowforge start <yaml>` → 加载 YAML → define → createInstance → addHistory
2. `flowforge next [--branch N]` → 读当前节点 → 计算下一节点 → closeHistory + updateNode + addHistory
3. `flowforge run/advance` → JSON API 模式，供程序化调用

### 设计特点
- **防跳步**: agent 必须通过 `next` 推进，不能直接跳到任意节点
- **自动清理**: start 时如果有同名 active instance，自动关闭旧的
- **auto-load**: 启动时扫描 `./workflows/` 和 `~/.flowforge/workflows/`
- **分支决策**: branches 数组 + --branch N 索引选择
- **advance 解析**: 从结果文本中正则匹配 `branch: N` 自动选择分支

## 改进想法

1. **无测试**: 0 个测试文件。核心逻辑（engine.ts 的分支/terminal/advance）应该有单元测试
2. **advance 正则脆弱**: `/\bbranch:?\s*(\d+)\b/i` 可能误匹配结果文本中的 "branch" 一词
3. **无超时/重试**: 节点没有 timeout 概念，subagent 挂了 workflow 就卡住
4. **无条件执行**: branches 靠人选，没有自动条件求值（比如检查文件是否存在）
5. **History 只记节点名**: 不记录节点的实际输出/结果，回溯时丢信息
6. **engines.node >= 22 但 target=node18**: esbuild target 和 engines 不一致

## 与其他系统对比

对比 [[skvm]]、[[genericagent]]、[[evolver]] 等自进化系统：

| 维度 | FlowForge | SkVM | GenericAgent |
|------|-----------|------|--------------|
| 粒度 | workflow 节点 | skill 编译 | 执行路径结晶 |
| 持久化 | SQLite | 文件 | memory |
| 自进化 | 无 | 静态 | 每次任务后自动 |
| 复杂度 | 670 行 | ~2K 行 | ~3K 行 |

## 关联
- 与 [[gogetajob]] 配合：打工循环通过 FlowForge workloop 驱动
- [[openclaw]] 的 cron 触发 flowforge start
- 设计思路接近 [[mechanism-vs-evolution]] 中的 mechanism 端——显式约束而非自动进化
- [[approving|Approving]] — 在状态机执行图上补足可审阅产物与显式人工决策门

## 测试覆盖 (04-19 新增)
- vitest, db 模块全 mock（in-memory store 模拟 SQLite 行为）
- engine.test.ts: 23 tests — define/start/status/next/log/list/active/reset/getAction/advanceWithResult
- workflow.test.ts: 14 tests — parseWorkflow 正例 + 所有 error path
- PR #4, 已合并

## 行动项
- [x] ~~给 FlowForge 加基本测试（engine.test.ts）~~ ✅ 04-19
- [ ] 考虑 advance 正则改为显式 `BRANCH:N` 前缀避免误匹配

## Stale Instance Warning (2026-04-27)

Added `console.warn()` in `engine.start()` when auto-closing a stale active instance. Previously this happened silently — the return value had `previouslyClosed` but library consumers and CLI users saw nothing. Now the warning includes instance ID and node name for debuggability.

This surfaced from self-audit: the auto-close behavior is correct (prevents "instance already active" errors), but silent auto-closes violate [[observability]] — the user should know their previous run was abandoned.

## Defender/Tolerator Audit (2026-04-28)

Applied [[claude-mem]]'s Defender/Tolerator lens to FlowForge error handling. Found 2 actionable Tolerator patterns:

1. **autoLoadWorkflows silent catch** — `catch(e) {}` when loading YAML files. User gets zero feedback on invalid workflows, then later "workflow not found" with no clue why. **Fixed**: `console.warn` with filename and error message.
2. **advanceWithResult branch regex** — silent failure when result text doesn't match `/branch:?\s*(\d+)/i`. Branch stays `undefined`, then `next()` throws a confusing error. **Fixed**: explicit warning when current node has branches but no branch detected in result.

Also fixed stale data: two broken symlinks in `~/.flowforge/workflows/` (workloop.yaml, workloop-night.yaml) pointing to old path. The new warning surfaced them immediately — **the fix validated itself on first run.**

**Remaining Tolerator** (not fixed, acceptable): `engine.start()` auto-closing stale instances. The `console.warn` from 04-27 already makes this visible. Auto-close is the right UX for CLI — forcing confirmation would break non-interactive use.

## Workflow Packaging Evaluation (2026-05-04)

**Question**: Can FlowForge YAML workflows be distributed as packageable skills (like [[evanflow]]'s process-skill pattern)?

**Comparison with evanflow (161⭐)**:
- evanflow = 16 SKILL.md files + 2 subagents, zero runtime dependency. Drop into `.claude/skills/` and it works.
- FlowForge = single YAML, requires `flowforge` CLI runtime. More powerful (branching, state, instances) but less portable.

**Distribution options evaluated**:
1. **ClawHub package** (YAML + flowforge dependency) — only works in [[openclaw]] ecosystem, marketplace is empty
2. **Transpile YAML → multi-skill** (like evanflow) — loses programmatic flow control, gains portability

**Verdict: NOT NOW.**
- Our workflows are personal (study, workloop, reflect) not generalizable to others
- The ecosystem isn't mature enough to warrant building distribution tooling
- If we ever want to share, the evanflow multi-skill pattern is more portable without building anything new
- FlowForge's value is in *structured self-discipline* for one agent, not in being a shareable framework

## Tracking-Due Integration (2026-05-04)

**Problem**: 43 open "Track:" items in TODO.md with manual Revisit dates. During followup mode, scanning all items visually to find due ones wastes time and risks missing overdue items.

**Applied insight**: From [[agent-install]]'s well-known index pattern and general automation-first thinking — if we have structured data (dates in consistent format), parse it programmatically.

**Implementation**:
- Created `study/tracking-due.sh` — extracts open Track items, filters by Revisit date ≤ today
- Integrated into study.yaml followup node as step 0 (before memex search)
- Now followup mode starts with a prioritized list of due items instead of manual scanning

**Effect**: Followup selection is now data-driven rather than memory-dependent. Should reduce "forgot to check X" misses and focus attention on items actually due.

## --workflow Flag (2026-05-06)

**Problem**: When multiple workflows are active simultaneously (e.g. study + workloop), `next`, `status`, `log`, `reset`, and `advance` operate on whichever instance has the highest DB ID. This silently targets the wrong workflow — you think you're advancing study but you're actually advancing workloop.

**Applied insight**: From the [[mechanical-enforcement-via-topology]] pattern — if misuse is possible, make it structurally harder. The engine already supported `workflowName?` parameters throughout; the CLI just didn't expose them.

**Implementation**:
- Added `-w, --workflow <name>` option to `next`, `status`, `log`, `reset`, `advance` commands
- `printStatus()` now accepts optional workflow name to stay consistent
- Without `-w`, behavior is unchanged (most recent instance by ID)

**Effect**: `flowforge next -w study` is unambiguous. Eliminates silent cross-workflow contamination. 80 tests pass.

## Gradient Gate Node (2026-05-21)

**Problem**: Self-evolving observations (Issue #9, Day 33+) showed the reflect→gradient pipeline producing **zero self-generated gradients**. All beliefs-candidates.md entries came from Luna's feedback, none from self-reflection on execution. The reflect node already had a "step 2.5: mandatory gradient" instruction, but it was buried in a 400-word task description and consistently skipped.

**Applied insight**: From [[self-evolving-observations]] Issue #9 (reflect→gradient disconnect) + [[mechanical-enforcement-via-topology]] pattern. Instructions embedded in long task descriptions get rationalized away. Structural enforcement through workflow topology (separate nodes) is more effective than behavioral instructions.

**Implementation**:
- Added `gradient_gate` node between `reflect` and `done` in workloop.yaml
- The gate checks `git diff HEAD -- beliefs-candidates.md` for actual modifications
- If no diff → forces agent to write at least one gradient before completing
- Two branches both lead to `done` (already written vs. just-now written)

**Bonus fix**: Discovered and fixed a pre-existing YAML parse error — unescaped ASCII `"` inside double-quoted YAML strings in the `study` and `reflect` nodes (`"上次做过"`, `"这轮没什么好写的"`). This had silently broken `flowforge start` for workloop (js-yaml parse error at line 160). The workflow still worked via DB-cached version for `next/status` commands, masking the issue.

**Effect**: 
- `flowforge start workloop.yaml` now works again (was silently broken)
- Gradient extraction becomes structurally enforced, not just instructed
- Addresses the 33-day gap of zero self-generated gradients

**Verification**: YAML valid (js-yaml parse), 84 FlowForge tests pass, `flowforge start` succeeds.

## Analytics Completion Rate Bug Fix (2026-05-22)

**Problem**: `flowforge-analytics.sh` reported **0% completion rate** across all workflows (2,550+ instances). Discovered via the first run of the analytics tool itself — the tool found its own bug.

**Root cause**: The analytics SQL queried `status = 'completed'`, but the [[flowforge]] engine (`engine.ts`) sets finished instances to `status = 'done'`. Only 14 out of 2,548 finished instances had "completed" status (likely from an earlier code path or manual edits). The status string mismatch meant 99.5% of finished instances were invisible to the analytics.

**Fix**: Changed the SQL predicate from `status = 'completed'` to `status IN ('completed','done')` in `flowforge-analytics.sh`.

**Effect**: Completion rates now accurate — study 100%, workloop 100%, review 100%, etc. Average durations now computed from all finished instances instead of a tiny sample. 13/13 tool self-tests pass.

**Pattern**: [[eat-your-own-dogfood]] — tools that analyze their own data should be run immediately after creation. This bug was caught because we ran the analytics tool and noticed the nonsensical 0% result.


## Study Followup Freshness Gate (2026-06-08)

**Applied insight**: From `study-followup-freshness-gate` gradient (06-07) — a followup round where all repos were QUIET and nothing was due produced zero new information, a predictable no-op.

**Implementation**: Added a mandatory freshness gate to the `followup` node in `study.yaml`. Before doing any followup work, the agent must run `tracking-due.sh` + `tracking-activity.sh`. If both return zero (0 due items AND 0 ACTIVE repos), the agent must immediately exit to the "no new activity" branch instead of proceeding through the full followup steps.

**Design principle**: [[structural-fix-over-behavioral-rule]] — instead of a DNA rule saying "don't do followup when nothing changed", the workflow topology enforces the check. The gate is at the top of the task description with ⛔ marker, before steps 0-3. Combined with the existing saturation system (followup ≥4/day cap), this creates layered prevention at both the frequency level (cap) and the content level (freshness).

**Effect**: Eliminates wasted followup rounds when the entire portfolio is quiet. Saves API calls (tracking-activity checks pushed_at via GitHub API) and agent time. The pre-existing steps 0a/0a3 already ran these checks but only used them informationally — now they become a hard gate.

## Offline Fallback Execution Note (2026-08-04)

During workloop instance `#7342`, the capacity gate passed (`Assigned: 4 | Open PRs: 15`); the finder script was then terminated before it produced a recommendation. The workflow correctly routed through `fallback_offline`, whose completion criterion requires a meaningful local artifact and a commit.

**Operational detail**: the workspace already contained unrelated modified files. For an offline fallback artifact, inspect `git status` first and stage only the file produced in the current workflow run (`git add <path>`), rather than using a broad staging command. This keeps the required commit attributable and avoids absorbing concurrent work.

### Reflection

- **Goal / approach:** complete the mandatory workloop path despite the issue finder not returning a candidate. The capacity gate was recorded before the finder was invoked; the failure path then produced and committed a scoped offline artifact.
- **What worked:** explicit workflow targeting (`-w workloop`) avoided ambiguity while a `study` instance was active; committing from the nested `wiki` repository preserved unrelated workspace and wiki changes.
- **Ĵ vs. J\*:** aligned. This was not an issue-selection round after the finder was terminated, so inventing a candidate or doing a contribution outside the fallback branch would have solved the wrong problem.
- **Failure point:** `workloop-find-issue.sh` did not finish within its execution window, so no recommendation was available. Treat its result as unavailable rather than interpreting the scan's partial banner as an empty issue list.
- **Next time:** use the workflow's `fallback_offline` branch immediately after a failed/terminated finder, and keep its required artifact isolated to the repository that owns it.

## Repeated Finder Termination (2026-08-04)

A second `workloop-find-issue.sh` invocation started normally but was SIGKILLed before producing `RECOMMENDED ISSUES`, despite the capacity gate passing (`Assigned: 4 | Open PRs: 15`). Treat this as an unavailable finder result, not as evidence that the tracked-repository queue is empty. The workflow must take `fallback_offline`; it must not select an unsourced issue or silently bypass the remaining nodes.

**Follow-up:** profile the finder’s resource use and provide a bounded, machine-readable fallback candidate source. Until then, preserve the script output and use the existing offline-artifact path.

## Engine Execution Semantics Review (2026-08-04)

Read `flowforge/src/engine.ts` while completing an offline workloop fallback.

- `next()` closes the prior history row, updates `current_node`, then opens history for the destination. If the destination is terminal, it immediately closes that new history row and changes the instance status to `done`; a separate terminal `next` call is therefore unnecessary after arriving at a terminal node.
- `--from-node` is a compare-and-advance guard: if a subagent and its parent both attempt to advance, the second caller receives `skipped: true` rather than moving the workflow twice. This is the mechanism behind the subagent self-advance footer generated by `getAction()`.
- Loop protection is measured on the *destination* node. At its configured `max_visits` it emits a reflection warning; at `max_visits + 2` it refuses the transition unless `--force` is supplied. It does not automatically select a different branch.
- `start()` still auto-closes any active instance with the same workflow name. Operational cron recovery should therefore inspect age/status before starting a replacement rather than relying on `start()` to distinguish a healthy active run from a stale one.

**Verification:** `npm test` in the FlowForge repository completed successfully on 2026-08-04: 4 test files, 84 tests passed (source and built test suites). The standard check command is `npm test`.

## Offline Fallback Reflection — Instance #7364 (2026-08-04)

- **Goal / approach:** resume the active `fallback_offline` node rather than start a replacement; inspect local state, deep-read the FlowForge engine, update this project note, and commit only the generated note.
- **What worked:** `flowforge status -w workloop` supplied the current-node contract; `git status` exposed unrelated workspace and wiki changes before staging. The artifact was committed in the clean owning repository as `e8392bd`.
- **Ĵ vs. J\*:** aligned. The workflow required offline work after `gh`/network failure; selecting a new issue or changing unrelated source would have violated that fallback scope.
- **Failure point / prevention:** the initial gradient text duplicated the already-recorded `offline-fallback-scope-control` lesson. The mandatory gradient was consolidated into that existing pattern (now **第2次**) instead of creating a near-duplicate. When the gradient helper flags a duplicate, consolidate or increment the existing pattern before proceeding.
- **Flywheel:** no guide or workflow change was warranted: the current recovery procedure, explicit `-w` targeting, and scoped-commit discipline all operated as intended.

**Publication:** local wiki commit completed; push intentionally not performed because this scheduled run has no explicit authorization for an external Git remote operation.

## Offline Fallback — Instance #7381 (2026-08-04)

- **Evidence:** capacity gate passed with `Assigned: 4 | Open PRs: 16`. `workloop-find-issue.sh` was invoked twice but produced only its scan banner; the second run was terminated by the execution timeout with `SIGKILL` before emitting `SUMMARY` or `RECOMMENDED ISSUES`.
- **Decision:** the finder outcome was unavailable, so the workflow advanced to `fallback_offline` rather than treating the partial output as an empty queue or selecting an unsourced issue.
- **Deep read:** reviewed `flowforge/src/engine.ts`. `requireActiveInstance()` deliberately rejects unqualified operations when more than one instance is active, while `status(workflowName)` and `next(..., workflowName)` select the named active instance. This directly explains—and validates—the required `-w workloop` recovery commands used in this run.
- **Operational boundary:** the `SIGKILL` establishes only that the finder did not finish within the available execution window; it does **not** establish an OOM root cause. Resource profiling is still needed before attributing the recurring termination to memory pressure.

## Finder Timeout Signaling — Offline Fallback (2026-08-07)

Source review: `tools/workloop-find-issue.sh`, after a run whose internal `gogetajob scan --all` returned status `124`.

- The script bounds only the scan stage with `timeout --signal=TERM --kill-after=10s "${SCAN_TIMEOUT_SECONDS}s"`; it captures stdout and stderr in temporary files, prints their tails, and emits `scan_status status=<n> timeout=<bool>` plus `scan_unavailable` for every non-zero scan result.
- **Important control-flow boundary:** after reporting that scan failure, the script continues to `gogetajob feed`. If JSON feed retrieval also fails, it prints a manual text feed and exits **0** after `CANDIDATES (text mode — parse above)`, without `RECOMMENDED ISSUES` or a structured `SUMMARY`.
- Therefore the runner must treat either `scan_unavailable` or text-only output without a structured recommendation as **finder unavailable**, even when the wrapper's exit status is zero. The process exit code alone cannot decide `find_work → fallback_offline`.
- The source establishes the reporting/control-flow behavior, not the root cause of the scan timeout. It does not demonstrate a network, authentication, API-limit, or resource failure.

Operational follow-up: retain the exact command/output boundary in the daily record, take the workflow fallback branch, and do not select an issue from the unvalidated text feed. This is already structurally aligned with the finder output gate; do not create a new near-duplicate behavioral gradient for each recurrence.

## Study Task Selection Ambiguity (2026-08-05)

A scheduled study run exposed a boundary in the `align` branch: the instruction says to choose `todo_task` when `TODO.md` has a specified learning task, but the section contained open `Track:` entries whose revisit dates were all in the future and several already stated “deep read done.” Those are portfolio records, not executable tasks for the current run. The manual branch interface cannot distinguish them, so selecting `todo_task` based merely on an unchecked tracker creates a no-op and can pressure the executor to fabricate a study result.

**Operational rule:** only select `todo_task` for a concrete unfinished action, or a `Track:` item with `Revisit ≤ today`; otherwise select `entry` and let the mode-specific freshness/due gates choose work. This tightens the existing observation that FlowForge branches rely on executor judgment: a branch description needs a machine-checkable predicate when a false positive would lead to invented work. See [[structural-fix-over-behavioral-rule]].

## Fallback Recovery and Qualified Advancement (2026-08-05)

- **Evidence preserved:** workloop capacity gate returned `Assigned: 3 | Open PRs: 17`. The subsequent `workloop-find-issue.sh` invocation emitted only its scanning banner and was terminated with `SIGKILL`; no stderr was retained. This establishes an unavailable finder result only, not a network/authentication/limit diagnosis and not an empty issue queue.
- **Deep read:** `requireActiveInstance(workflowName?)` rejects an unqualified command whenever multiple instances are active, before it looks up an active row. Passing `-w workloop` therefore is not merely defensive convention: it is required to target the intended instance. `status(workflowName)` and `next(branch, workflowName, ...)` forward that selector through the same guard.
- **Maintenance command:** `npm test` remains the repository's standard regression command (84 tests passed in the 2026-08-04 verification). No FlowForge source changed in this fallback, so this run limited verification to source inspection and a scoped wiki commit.

## Terminal Transition and Loop-Guard Ordering (2026-08-04)

Deep-read `flowforge/src/engine.ts` during workloop offline fallback instance `#7385`.

- A transition **into** a terminal node passes through the destination-node visit check before `next()` closes its history row and marks the instance `done`. Consequently a terminal destination can be blocked by its `max_visits` guard; `--force` is required only when that guard reaches its block threshold, not merely because the node is terminal.
- `next()` returns the origin from the instance object after `updateInstanceNode()`. Because the in-memory `inst` is not mutated by that database call, the returned `from` remains the prior node as intended. The terminal fast path returns `hasNext: false`, while a direct `next()` called on an already-terminal current node returns `to: "(end)"`.
- Tests should cover both terminal paths separately: arriving at a terminal node (automatic closure) and invoking `next()` while already on one (explicit closure). They exercise different branches despite both producing `done` status.

**Operational implication:** automation should treat `terminal: true` from a transition as completion and must not issue a redundant final `next`; doing so will find no active instance after automatic closure.

## Offline Fallback — Instance #7488 (2026-08-05 14:02 CST)

- **Failure evidence:** ran `ASSIGNED=$(gh search issues --assignee kagura-agent --state open --json number --jq "length"); OPEN_PRS=$(gh search prs --author kagura-agent --state open --json number --jq "length"); echo "Assigned: $ASSIGNED | Open PRs: $OPEN_PRS"; bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1`. The capacity gate printed `Assigned: 3 | Open PRs: 16`, so its assigned/PR inequality did not block discovery. The finder emitted only `FIND WORK — 2026-08-05 14:02` and `SCANNING TRACKED REPOS`, then the process ended with `SIGKILL`. No stderr was retained.
- **Decision:** this is an unavailable finder result, not a GitHub/network/authentication diagnosis and not proof of an empty queue. Advanced through `flowforge next -w workloop --branch 3` to the required offline fallback.
- **Local maintenance:** workspace `git log @{upstream}..HEAD` contains four unpushed commits (`d18cf00`, `c787ed8`, `889a9be`, `b94b92c`); no new unpushed commit was found or altered. Existing unrelated workspace and wiki modifications were left unstaged.
- **Deep read:** in `flowforge/src/engine.ts`, `requireActiveInstance(workflowName?)` rejects unqualified commands when more than one workflow is active, then retrieves only the named active instance. The failed unqualified `flowforge next --branch 3` and succeeding `flowforge next -w workloop --branch 3` directly verify that the selector is operationally required in concurrent runs.
- **Belief review:** `bounded-finder-failure-evidence` is still at its first recorded occurrence (the earlier same-day entry predated this run); no promotion or duplicate candidate was added.

## Offline Fallback — Instance #7494 (2026-08-05 15:04 CST)

- **Failure evidence:** the capacity gate returned `Assigned: 3 | Open PRs: 16`. `workloop-find-issue.sh` printed its scan banner, produced no recommendation or stderr, and was terminated with `SIGKILL`. This is only an unavailable finder result; it does not identify a network, authentication, rate-limit, or resource root cause.
- **PR maintenance:** local cove `git log @{upstream}..HEAD` returned no unpushed commits. Existing unrelated workspace and wiki changes were not staged.
- **Deep read:** `engine.start(workflowName)` always marks an existing active instance with that name `done` before creating the replacement; it has no age/staleness check. Thus the workloop's required `active → log age → cleanup only if >2h → resume otherwise` sequence is a necessary safety boundary, not redundant ceremony: calling `start` on a healthy instance would discard its active state.
- **Artifact discipline:** this note is the scoped offline-fallback artifact. Stage only `projects/flowforge.md` when committing, because the wiki worktree contains concurrent unrelated changes.

## Offline Fallback — Instance #7504 (2026-08-05 17:49 CST)

- **Feedback triage:** GitHub PR `TencentCloud/TencentDB-Agent-Memory#729` remains `OPEN` and `CLEAN`, with no reviews, review decision, inline comments, or checks. Its only conversation item is collaborator Maxwell-Code07’s acknowledgement: “We have received all your PR submissions from today. We will arrange unified review later.” It contains neither a requested correction nor a question, so no patch or reply was warranted.
- **Failure evidence:** ran `ASSIGNED=$(gh search issues --assignee kagura-agent --state open --json number --jq 'length'); OPEN_PRS=$(gh search prs --author kagura-agent --state open --json number --jq 'length'); echo "Assigned: $ASSIGNED | Open PRs: $OPEN_PRS"; bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1`. The capacity gate printed `Assigned: 3 | Open PRs: 17`; the finder printed only its scan banner and then ended with `SIGKILL`, without a recommendation or retained stderr.
- **Decision:** the capacity inequality did not block discovery, but the finder result is unavailable—not an empty candidate queue and not evidence of a network/authentication/rate-limit/resource cause. The required fallback was used.
- **Local PR check:** the TencentDB-Agent-Memory checkout is on `main...upstream/main` with no worktree changes; the PR commit is available via GitHub but is not in this local main checkout, so no local unpushed change was found to repair or publish.
- **Belief review:** relevant fallback/actionability patterns already exist; this repeated observation alone does not establish an independent third occurrence suitable for promotion.

## Offline Fallback — Instance #7515 (2026-08-05 19:06 CST)

- **Failure evidence:** capacity gate returned `Assigned: 3 | Open PRs: 17`. The exact finder command was `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1`; it emitted the `FIND WORK` and `SCANNING TRACKED REPOS` banners, then was terminated with `SIGKILL` before `gogetajob scan --all` returned. No stderr was retained. This records an unavailable discovery result only; it does not establish a network, authentication, rate-limit, or OOM root cause, and it is not a `NO VIABLE ISSUES` result.
- **Local PR maintenance:** workspace-only commits not present on a remote were listed (`5582fab`, `fe08e8c`, `d18cf00`, `c787ed8`, `889a9be`, `b94b92c`, `6526b6d`). The active Cove PR #510 worktree was clean and had no unpushed `fix/506-final-reply-delivery` commit. Existing unrelated workspace and wiki edits remain unstaged.
- **Deep read:** the finder has a serialized first stage: `SCAN_OUT=$(... gogetajob scan --all 2>&1 | tail -5)`. Every later feed and candidate gate is downstream of that command substitution, and it has no script-level timeout or partial-result fallback. Therefore, when the scan does not finish, the script cannot emit a feed, candidate summary, or a meaningful branch recommendation. This is source-verified control flow, not an attribution for why the scan was terminated.
- **Belief review:** `bounded-finder-failure-evidence` is already at its second occurrence and `finder-termination-fallback` has several near-duplicate records. The durable next action is structural profiling/bounded scan behavior, not another behavioral gradient; no candidate was added.

## Active Workloop Recovery — Instance #7588 (2026-08-06 11:02 CST)

- **State check:** `flowforge active | grep workloop` found active instance `#7588` at `reflect`. `flowforge log -w workloop` shows it entered that node at 02:57:09 CST, well below the two-hour stale threshold at the 11:02 cron check; it was resumed rather than replaced.
- **Outcome:** the preceding path was `followup` (bot/non-actionable only) → `find_work` (no viable issue) → `discover` (no suitable project). No PR, repository contribution, maintainer feedback, or project-specific artifact exists to attribute to this round.
- **Reflection:** the recovery guard matched the actual need: preserve in-flight workflow state and execute the outstanding `reflect` contract, rather than treating a repeated cron trigger as permission to start a duplicate instance. [[workloop]] and [[mechanical-enforcement-via-topology]].
- **Tool follow-up:** `add-gradient.sh` accepted the mandatory gradient but warned that `gradient-scan.sh` has no keyword mapping for its new pattern. This is an observability gap: the entry is stored but future evidence will not be automatically counted. Track a scoped tooling repair before relying on automated graduation.

## Offline Fallback — Instance #7592 (2026-08-06 12:02 CST)

- **Failure evidence:** capacity gate completed: `Assigned: 2 | Open PRs: 16`. `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1` emitted its scan banner and then exited with `SIGKILL` before producing `SUMMARY` or `RECOMMENDED ISSUES`; no stderr diagnostics were emitted. The finder was therefore unavailable. This does not establish a network, authentication, rate-limit, or resource root cause, and it is not evidence of an empty issue queue.
- **Local PR check:** began checking fork worktrees for unpushed commits. The broad scan encountered several independently dirty worktrees (including large generated/untracked/deleted trees) and was stopped to avoid interacting with concurrent work. No change was made in any fork.
- **Deep read:** reviewed `flowforge/src/engine.ts`. `requireActiveInstance()` makes `-w workloop` mandatory in a multi-active-instance environment. `next()` checks the optional `fromNode` compare-and-advance guard before selecting the successor, then applies visit-count loop protection to the destination; terminal destinations are closed and marked `done` in the same transition.
- **Maintenance:** `npm test` is documented as the FlowForge regression command; this offline note changes no source, so no test run was required. The note is staged and committed alone in the wiki repository; no push is performed.

## Offline Fallback — Instance #7608 (2026-08-06 15:06 CST)

- **Recovery:** the active instance had entered `plan` at 14:49 CST, below the two-hour threshold. Its prior issue/plan context was absent from FlowForge history, which stores node transitions but not node outputs. Rather than invent a plan, the required `plan → find_work` re-selection branch was used.
- **Failure evidence:** the capacity gate completed with `Assigned: 2 | Open PRs: 18`, so its inequality did not block discovery. `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1` printed `FIND WORK — 2026-08-06 15:06` and `SCANNING TRACKED REPOS`, then ended with `SIGKILL` without `SUMMARY`, `RECOMMENDED ISSUES`, or stderr diagnostics.
- **Decision:** discovery was unavailable; this is neither evidence of an empty issue queue nor a diagnosis of network, auth, rate-limit, or resource failure. The workflow advanced to `fallback_offline` exactly as specified.
- **Local maintenance:** `git log --all --not --remotes --oneline -20` showed existing workspace-only commits; `git status` found concurrent unrelated workspace/wiki changes. They are left unstaged. This scoped note is the fallback artifact.

## Offline Fallback — Instance #7617 (2026-08-06 16:04 CST)

- **Failure evidence:** `bash ~/.openclaw/workspace/tools/workloop-followup.sh 2>&1` began normally and reported two assigned issues as fulfilled. It then reported `Total open PRs: 19` and partial status through `anomalyco/opencode#39425`, but was terminated with `SIGKILL` before emitting the required `SUMMARY` or `RECOMMENDED BRANCH`; no stderr diagnostic was retained.
- **Decision:** followup output is incomplete and therefore unavailable for branch selection. The termination does not establish a GitHub/network/authentication/rate-limit/resource root cause, does not prove that the remaining PRs have no action items, and does not authorize an out-of-workflow PR operation. The workflow took its prescribed offline fallback.
- **Local maintenance:** the workspace and wiki worktrees already contained unrelated modifications. This note is the sole fallback artifact and must be staged independently.

## Offline Fallback — Instance #7628 (2026-08-06 18:07 CST)

- **Followup triage:** the helper completed and identified four comments: GitHub Actions preview-deployment notices on `kagura-agent/cove#514` and `#487`, collaborator Maxwell-Code07’s acknowledgement on `TencentCloud/TencentDB-Agent-Memory#729`, and maintainer arnestrickmann’s thank-you on `generalaction/emdash#2902`. Reading the complete comments confirmed none requested a change or answer, so `handle_feedback → find_work` correctly took the non-actionable branch.
- **Capacity evidence:** `Assigned: 2 | Open PRs: 19`; the capacity inequality did not block discovery.
- **Failure evidence:** the exact finder command, `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1`, emitted `FIND WORK — 2026-08-06 18:07` and `SCANNING TRACKED REPOS`, then ended with `SIGKILL` before it emitted a recommendation, `SUMMARY`, or stderr diagnostics. This establishes only an unavailable finder result—not a network, authentication, rate-limit, resource, or empty-queue diagnosis.
- **Local maintenance:** a read-only scan of fork worktrees found no uncommitted or local-only commits to repair or publish. The workspace itself contains concurrent unrelated modifications; this single-file wiki note is staged and committed independently.
