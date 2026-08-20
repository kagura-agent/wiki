# gogetajob — 深读笔记

> 我自己写的开源打工 CLI 工具。2026-04-19 深读全部源码（7 文件，~3,254 行 TypeScript）。

## 架构总览

```
src/
  cli/
    index.ts     — CLI 入口 + 所有命令定义（1,499 行，最大文件）
    format.ts    — 终端格式化输出（chalk）
    watch.ts     — crontab 管理（定期 sync）
  backend/lib/
    github.ts    — gh CLI 封装（630 行）
    job-service.ts — SQLite 数据层（651 行）
    migrations.ts — schema + 迁移（144 行）
  frontend/
    api.ts       — dashboard API（未深读，100 行）
```

## 数据模型

三张核心表：
- **companies** — GitHub repo 元数据（stars, merge_rate, response_hours, CLA 等）
- **jobs** — issues 快照（title, body, labels, type, difficulty, bounty）
- **work_log** — 工作记录（status 状态机 + PR/issue 追踪）

work_log 状态机：`taken → submitted → done`（或 `dropped`）
work_type 支持 `pr` 和 `issue` 两种。

## 命令清单

| 命令 | 用途 |
|------|------|
| `scan [repo]` | 扫描 repo issues 入库 |
| `scan --all` | 扫描所有已知 repo |
| `discover` | 自动发现值得贡献的 repo |
| `feed` | 浏览可做的 job |
| `info <repo>` | 查看 repo profile |
| `check <ref>` | 深度检查 issue（linked PR、verdict） |
| `start <ref>` | fork + clone + branch，一键准备开工 |
| `submit <ref>` | commit + push + 创建 PR |
| `take/done/drop` | 手动状态管理 |
| `followup <ref>` | 追加 token 消耗（review 修改用） |
| `sync` | 批量检查 PR/issue 状态 |
| `stats` | 统计（GitHub API 优先，本地 fallback） |
| `history` | 工作历史 |
| `companies` | 已知 repo 列表 |
| `import <repo>` | 从 GitHub 反向导入 PR 历史 |
| `audit <repo>` | 代码健康检查 + 可选自动提 issue |
| `watch` | crontab 定期 sync |

## 设计亮点

1. **metaphor 一致**：company = repo, job = issue, work_log = 打工记录。整个 CLI 是 "AI 找工作" 的比喻。
2. **self-update check**：每次运行比对 git HEAD vs origin/main，提示更新。有 timeout 防卡死。
3. **self-filed guard**：`start` 命令会检查 issue 是否自己提的且未被 maintainer 回应，防止"自问自答"。
4. **verdict system**：`check` 命令综合 linked PR、comment 数、merge rate、CLA、repo 活跃度给出 go/caution/skip 判定。
5. **stats 双源**：GitHub search API 做权威来源，本地 DB 做 fallback + token 追踪。
6. **sync 智能过滤**：区分 human vs bot review comments，只对 human 的标需要 action。
7. **迁移系统**：5 个迁移阶段，渐进式加字段，处理了 job_id nullable 的表重建。

## 发现的问题 / 改进点

### 🔴 代码质量
1. **index.ts 太大**（1,499 行）：所有 14 个命令都在一个文件里。应该拆成 `commands/scan.ts`, `commands/submit.ts` 等。
2. **重复代码**：`scan` 和 `scan --all` 路径有大量重复的 upsertCompany + getIssues + upsertJob 逻辑。应提取为 `scanRepo()` 函数。
3. **类型标注**：action handler 里大量 `opts: any`，应该用 Commander 的类型或自定义 interface。
4. **错误处理**：submit 命令里的 `execSync` 错误捕获和提示很好，但其他命令（如 scan）的错误处理偏粗。

### 🟡 功能
5. **无测试**：整个项目没有单元测试或集成测试。至少 job-service 的纯逻辑（分类、状态机）可以测。
6. **discover 没有去重**：如果多次运行，`countLabeledIssues` 会重复调用 API。
7. **sync 里的 `listOutputsToSync` 排除条件**：已 merged/closed 的不再检查，但如果 PR 被 revert 或 issue 被 reopen，会漏掉。低概率但值得注意。
8. **submit 的 commit message**：硬编码 `fix:` 前缀，但不是所有 issue 都是 bug fix。应该根据 job_type 选择 `feat:` / `fix:` / `docs:` 等。

### 🟢 小优化
9. **parseRef 的 auto-scan**：短格式 ref 找不到 job 时会自动 scan，但用 `execSync` 调自己，有点绕。可以直接调 service 层。
10. **chalk 依赖**：在 CLI 工具里合理，但可以考虑 `--no-color` flag。

## 生态位置

在 agent 工具链中，gogetajob 是「自主贡献」的基础设施——类似 [[generic-agent]] 的 self-improvement loop，但专注在开源贡献维度。跟 [[flowforge]] 的 workloop 紧密配合：FlowForge 调度循环，gogetajob 管理具体的 issue/PR 生命周期。

相比 [[hermes-agent]] 的多 agent 协调，gogetajob 是单 agent 专用的；相比 [[orb]] 的通用自进化，gogetajob 只解决「找活干、交活、追踪结果」这一垂直场景。

## 对打工流程的启示

- gogetajob 的 verdict system 是个好模式：在投入工作前做 preflight check。这个 pattern 可以推广到其他决策场景。
- self-filed guard 是防止"自问自答"循环的好机制。值得在 FlowForge workloop 里也加类似检查。
- stats 用 GitHub API 做权威来源、本地做补充——这是"信任但验证"的好实践。

## 重构记录

### 2026-04-19: CLI 拆分 + 测试

**动机**：1,499 行的单文件 index.ts 是最大的代码质量问题。

**做了什么**：
- `src/cli/index.ts` 1,499→51 行（纯入口，import + register）
- 新建 `src/cli/commands/` 目录，18 个命令各一个文件
- 新建 `src/cli/shared.ts` 提取公共 setup（getDb, getService, checkForUpdates 等）
- 加了 vitest 测试（20 tests passing），验证命令注册正确
- 分支 `refactor/split-cli-commands`，待 review 后合并

**洞察**：
- Commander.js 的命令拆分模式很直接——每个文件 export 一个 `(program: Command) => void`
- `import` 是 JS 保留字，文件命名为 `import-cmd.ts` 规避
- 拆分后每个命令文件 50-150 行，可读性大幅提升

## 2026-08-05 Workloop offline fallback

- **结果：**本轮未创建或更新 PR。FlowForge instance `#7466` 的 `find_work` 进入“gogetajob/gh 命令失败（网络、认证、API 限流）”分支，随后走 `fallback_offline`；没有持久化的原始 stderr，因此不能把失败归因到网络、认证或限流中的任一项。
- **维护者 / PR 模式：**本轮没有目标仓库或 maintainer 交互，故无新增维护者偏好可记录。
- **CI / 测试：**未运行候选仓库测试；这只是发现阶段失败，不得把它表述为项目 CI 状态。
- **下次：**发现命令必须保留结构化错误输出（命令、退出码、stderr 摘要），再决定是重试 API、使用本地 DB，还是进入离线回退。与 [[flowforge]] 的 workloop 交接应把“发现不可用”和“无候选”明确区分，避免无证据地选择 issue。

### 12:07 CST evidence and script path

- [已验证] `bash tools/workloop-find-issue.sh 2>&1` printed its heading and `SCANNING TRACKED REPOS`, then exited by `SIGKILL` before `gogetajob scan --all` returned. No stderr was emitted/captured, so the termination cause is **unverified**; do not label it OOM, auth, network, or rate limiting.
- [已验证] The script blocks in `SCAN_OUT=$(... gogetajob scan --all 2>&1 | tail -5)` before it can query the cached JSON feed or apply any issue gates. Consequently this result is unavailable discovery evidence, not `NO VIABLE ISSUES`.
- [已验证] Capacity immediately beforehand was `Assigned: 3 | Open PRs: 17`; the workflow’s assigned-issue gate passed because 17 is not less than `3 - 1`.

## 下一步

- [x] ~~拆分 index.ts~~ ✅ 04-19
- [x] ~~加基础测试~~ ✅ 04-19（20 tests）
- [ ] submit 的 commit prefix 根据 job_type 动态选择
- [ ] 提取 scanRepo() 函数消除 scan/scan --all 重复代码
- [ ] 改善类型标注（去除 `opts: any`）

## OOM 问题修复 (2026-04-21)

`scan --all` 扫描 22 个 repo 时被 SIGKILL（OOM）。根因：并发 3 + 每 repo 50 条 issue（含 body）在内存中积累。

**修复**：
- 默认并发 3→1（--all 时顺序扫描避免内存峰值）
- 每个 repo 扫完后清空 issues 引用（`issues.length = 0`）让 GC 回收
- heap > 200MB 时主动 `global.gc?.()`

**Pattern**: 批量操作工具要默认保守（低并发 + 主动释放），用户需要快可以手动调高。这跟 [[gbrain]] 的 conservative-default 思路一致。

## Self-Audit Code Fixes (2026-04-27)

From periodic self-audit (inspecting own code for anti-patterns):

**audit.ts — empty catches**: Two `catch {}` blocks silently swallowed `git ls-files` and `git rev-list` failures. Replaced with `console.warn()` so failures are visible without breaking the flow. Pattern: silent error swallowing in CLI tools hides real issues during debugging.

**submit.ts — 3-level try/catch cascade**: The "check if changes exist" logic was: try upstream ahead-count → catch → try total-commit-count → catch → fallback. Simplified to a flat 2-step: try upstream check, then fall through to commit-count check. Same behavior, half the nesting. Pattern: cascading try/catch usually means the control flow wants to be `if/else` with explicit null checks, not exception-driven.

Both relate to [[error-handling-in-cli]] — CLI tools should log warnings, not silence errors, and use structured flow control over exception cascades.

## Pre-PR Safety Checks Enhancement (2026-05-04)

Applied accumulated lessons from [[pr-superseded-lessons]] into the `check` command. Three new automated checks:

1. **Open PR count** — warns when I have ≥2 open PRs in a repo (skip at >3). Pattern: ACCUMULATED_OPEN_PR — maintainers deprioritize new PRs from contributors with a backlog.

2. **External merge rate** — queries recent merged PRs and checks `author_association`. If 0% external merges with ≥5 total → skip (MAINTAINER_MERGE_GATE_CLOSED). If <20% → caution. Uses `gh api repos/{owner}/{repo}/pulls` with association field instead of guessing from username.

3. **Maintainer issue activity** — checks if OWNER/MEMBER/COLLABORATOR commented on the issue within 3 days → caution (CHECK_MAINTAINER_ACTIVITY). Catches the pattern where maintainers are already investigating and will fix it themselves.

**Implementation**: 3 new functions in `github.ts` (sync, try/catch with safe defaults) + verdict integration in `check.ts`. All checks fire after existing checks (linked PRs, merge rate, CLA, staleness).

**Validation**: Tested against openclaw/openclaw — correctly detected 3 open PRs (caution) and 50% external merge rate (no flag). TypeScript types pass.

**Pattern**: wiki card → tool code is the strongest form of knowledge application. The checklist in [[pr-superseded-lessons]] existed as human-readable text for weeks; now it's automated and runs every time `gogetajob check` is called.

## Finder Structured-Output Boundary (2026-08-07)

- [已验证] `bash ~/.openclaw/workspace/tools/workloop-find-issue.sh 2>&1` emitted `scan_status status=124 timeout=true` and `scan_unavailable status=124 timeout=true` during the tracked-repository scan, then printed a text-only feed with `JSON feed unavailable, showing text`.
- [已验证] The helper therefore did not supply its declared structured recommendation. The workflow selected `fallback_offline`; no issue was chosen from the printed text candidates.
- **Operational rule:** Preserve the command, observed status, and unavailable boundary. Do not reinterpret this as an empty queue or infer network, authentication, API-limit, or resource root cause without further evidence. Retry issue selection only after a future run provides the structured result.

Links: [[pr-superseded-lessons]], [[gogetajob]], [[error-handling-in-cli]], [[loope]]

## Finder Scan Timeout — Structural Root Cause (2026-08-13)

- [已验证] `tools/workloop-find-issue.sh` wraps `gogetajob scan --all --skip-recent 12` under a 90s `SCAN_TIMEOUT_SECONDS`. 2026-08-13 12:16 run exited `FINDER_RESULT=UNAVAILABLE reason=tracked_scan status=124`.
- [已验证] DB 有 90 个 repo，其中 66 个 `last_scanned_at` >12h（`--skip-recent 12` 不跳过）。串行扫描 ~10s/repo（`scan-metric elapsed_ms=11017`；`last_scanned_at` 每 ~10s 前进一个）→ 66×10s ≈ 11 分钟 ≫ 90s。所以每轮只能扫 ~8 个 repo 就超时。
- [已验证] 串行是**有意的**（2026-04-27 OOM 修复：并发 3→1 避免内存峰值），所以修法不是重开并发，而是**用 `--batch N` 限定每轮扫描规模**。
- [已验证] `--batch N` 在 `--skip-recent` 过滤**之后** slice top-N by stars（`dist/cli/index.js`），正是为 "cron/time-limited contexts" 设计；但 finder 没传 `--batch`。
- [已验证] `dist/cli/commands/scan.js`（`--concurrency 3` + pLimit 并行实现）**未被任何文件 import**，是死代码（index.ts 拆分重构进行到一半但没接进 bin 入口）。
- **Fix 建议**：给 finder 的 scan 调用加 `--batch 8`（或 `SCAN_BATCH_SIZE` env），配合 `--skip-recent 12` 跨轮轮换扫完 90 repo；顺带决定 commands/scan.ts 的并行重构是废弃还是接上。
- 缓存兜底也失效：`finder-feed.json` `generated_at` 2026-08-12T09:23Z ≈ 19h 前，超过 6h `FINDER_CACHE_MAX_AGE_SECONDS`。

Links: [[gogetajob]], [[workloop]], [[pr-superseded-lessons]]

## Discover Topic Qualifier Silently Dropped + Feed Blocklist Gap (2026-08-17)

- [已验证] `gogetajob discover --topic X` 返回的候选与 `--topic Y` **完全相同**（ai-agent / llm-observability / ai-evaluation 都返回 tsdoc、react-native-linear-gradient、overseerr）。根因不在 gogetajob 逻辑，而在 GitHub search 的限定符顺序行为：`gh search repos "stars:100..5000 topic:ai-agent"` 静默丢弃 topic（结果 == 无 topic 查询），`"topic:ai-agent stars:100..5000"` 才正确过滤（返回 CherryHQ/cherry-studio 等）。
- [已验证] gogetajob `searchRepos()` 把 `topic:` 追加在 `stars:`/`pushed:` 之后 → 所有带 `--topic` 的 discover 查询实际都在无 topic 过滤下运行。修复：topic 移到 queryParts 最前（keywords 之后）。commit `45e9785`。
- [已验证] 第二个 gap：`blocklist.ts` 的 `isBlocked()` 从未被接入 feed 管线——`listJobs()` 只按 state/language/type 过滤，导致 blocklisted repo（openclaw/openclaw 等 15 个）的 issue 持续出现在 finder 候选里。本轮 find_work 推荐的前 3 个 issue 全部来自 openclaw（blocklisted），靠人工识别拦截。修复：`listJobs()` 加 `LOWER(c.full_name) NOT IN (blocklist)`。commit `a8c9bde`。
- **教训**：工具输出与参数不一致（不同参数相同结果）时，先手工 `gh`/`curl` 复现查询验证限定符行为，再修代码——不要接受输出，也不要先怀疑自己的用法。工具代码是最强的知识应用形式（同上一条 pattern）。
- **Action**：`tools/gradient-scan.sh` 补 `tool-filter-silently-ignored` 的 KEYWORDS；TODO 记录「workloop finder 应加 blocklist 拦截自检（feed 已修，脚本侧可加防御性检查）」。

## Finder Feed Starvation — Low-Star Repos Structurally Invisible (2026-08-20) ✅ 已修

- [已验证] `tools/workloop-find-issue.sh` 的 `write_feed_cache()` 原用 `ORDER BY stars DESC LIMIT 200` + per-repo cap 10（`rn <= 10`）生成 finder feed。DB 现有 123 个 tracked repo 有 open jobs；stars 前 20 个 repo（>23K★，如 OpenHands 84K、deer-flow 80K）各自占满 10 条 → 200 槽位全被高 star repo 消耗。
- [已验证] 低 star repo 完全进不了缓存：pydantic/logfire（4,430★）、future-agi/future-agi（1,734★）、keephq/keep（12,229★）的 open issues 全被饿死，但 `gogetajob feed`（listJobs()，无 200 限制）能正常显示它们。
- [已验证] 后果：discover 新加入的低 star 对齐 repo 永远无法被 finder 选中 → discover→find_work 循环在工具层面断裂（08-20 两轮 workloop 实证：logfire/future-agi discover 后选不到；keep 加入后 MAX_CHECK=15 预算被 OpenHands/deer-flow 占满，filter 日志 grep 不到 keep 行）。
- **修复（2026-08-20 晚，dna repo）**：`write_feed_cache()` SQL 改两层——**Layer 1** 每 repo 取最新 1 条（rn=1），按 `last_scanned_at` ASC（最近扫描最旧优先）排序 → MAX_CHECK=15 覆盖 15 个不同 repo，且天然跨轮轮换（配合 scan `--batch 8` 的节奏）；**Layer 2** 剩余预算按 stars DESC 补满（rn BETWEEN 2 AND 10，保留高 star backlog）。验证：keep/logfire/future-agi 全部进缓存（修复前不在），前 8 条覆盖 8 个不同 repo；端到端跑脚本 exit 0，filter 覆盖 15 个不同 repo。
- **教训**：工具内部缓存查询与 CLI 展示命令（`gogetajob feed`）行为不一致时，前者会静默饿死后者能看到的候选——先验证缓存生成逻辑（SQL），不要接受「NO VIABLE ISSUES」的表面结论。排序类 feed 若同时有 `LIMIT` + `ORDER BY stars DESC`，低 star 新候选必然饿死，要按轮换/分层设计而不是纯 top-N。

Links: [[gogetajob]], [[workloop]], [[pr-superseded-lessons]]
