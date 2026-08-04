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
- **Next time:** use the workflow's `fallback_offline` branch immediately after a failed/terminated finder, and keep its required artifact isolated to the repository that owns it. See [[offline-fallback-scope-control]].
