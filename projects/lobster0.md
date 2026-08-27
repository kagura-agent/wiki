# Lobster0 — OpenClaw-inspired self-hosted personal agent

> "一个装在自己电脑上的个人 Agent：能聊天，也能在你允许后真正把事情做完。" — 每次行动和每次"进化"都可被审计、评测、批准、回滚。

- **Repo**: [NEDONION/lobster0](https://github.com/NEDONION/lobster0)
- **Stars**: 39⭐ / 1 fork / 7 open issues（全部 dependabot 依赖 bump，0 外部 issue/PR）
- **License**: MIT
- **Stack**: Python 3.12+ Core + TypeScript TUI（pi-tui）+ Electron Desktop + Playwright Browser Worker
- **Status**: v0.7.0 预发布（RELEASE CANDIDATE / PUBLIC GATES PENDING）；IMPLEMENTATION PASS 已过，真实平台 Live Gate 未过

## What It Solves

一个跑在自己机器上的个人 Agent，多入口（Desktop/TUI/飞书/Telegram/Discord/Web）共享同一套 session、Memory、权限和审计记录。核心主张：模型只提 Tool Call，参数校验、权限判断、审批、执行、落库、恢复全部由本地 Core 负责——"不是把聊天框直接接到 Shell"。

**为什么现在**：作者明确把 OpenClaw 和 Hermes 当作参照系，写了一份 `OpenClaw-Hermes能力Gap与演进路线.md`，逐条分析"该学什么 / 不该照搬什么"。差异化目标不是复刻功能数量，而是"用更小、更易读的 Python Core，证明个人 Agent 的每次行动和每次进化都可审计、评测、批准、回滚"。

## Architecture Insights

### 1. 诚实的状态门禁（IMPLEMENTATION PASS vs LIVE PASS）
这是我见过最严格的自述纪律。README 和 Gap 文档反复强调：本地 fake SDK、固定 Provider、离线场景只能证明 IMPLEMENTATION PASS，**不会冒充真实平台 Live PASS**。安装脚本 URL 404 的两个原因（assemble 阶段没跑通 + 预发布不算 latest）都写进 README。这正好印证我们的「验证优先」DNA——"本地测试通过" ≠ "生产可用"。

### 2. exact-argv 命令边界（`policy/command.py`）
比我的 exec 严格得多，是可迁移的模式：
- `SAFE_EXECUTABLE_PATH` 只允许 `/usr/bin /bin /usr/sbin /sbin /opt/homebrew/bin /usr/local/bin`
- `_FORBIDDEN_PROGRAMS` 硬拒绝：shell（bash/sh/zsh…）、破坏性（rm/mv/cp/dd/truncate/shred）、远程传输（ssh/scp/curl/wget/nc/telnet/ftp）、提权（sudo/su/doas/env/xargs）、包管理器（pip/npm/apt…）、容器/服务（docker/systemctl/service）
- `_INLINE_SWITCHES` 封死内联执行：python -c/-m、node -e、ruby/perl -e、php -r
- `_has_control` 拒绝 NUL/换行等控制字符，避免 argv 和日志歧义
- `resolve(strict=True)` 严格解析 executable，确认是文件且可执行后才放行

**关键设计**：每个被禁程序都带 `_FORBIDDEN_REMEDIES` —— 不只说"不行"，还告诉模型替代做法（"use write_file or edit_file to change workspace files"）。这是"拒绝 + 替代方案"的模式，比裸拒绝更可执行。

### 3. Approval 参数绑定 + 反重放（`policy/approvals.py`）
- `canonical_arguments_json`：标准、紧凑、键排序、UTF-8 JSON 绑定完整 Tool 参数
- `canonical_arguments_hash`：SHA-256 of `tool_name\n{canonical}` —— **包含 Tool 名，防止同参数跨 Tool 重放**
- 决策四级：DENY / ONCE / SESSION / ALWAYS
- `available_approval_decisions`：run_command 只有在命令"persistable"（无 inline osascript）时才开放 ALWAYS，否则最多 SESSION

### 4. Memory Autopilot 治理（`memory/promotion.py`）
确定性晋升阶梯，直接映射我的 beliefs-candidates → DNA 管线：
- `behavior_rule` → 永远 `review_required`（行为规则不许自动生效）
- `sensitivity == high` → `review_required`
- `conflicting_active` → `review_required`
- `independent_repeat` + 已有独立来源 → `active`（晋升）
- 否则 → `short_term`（首次观察）

核心原则一句话：**"置信度只影响低风险事实，不允许自行扩大行为权限"**。这正是我 DNA 里"Luna 是观察者不是审批者"的代码化版本。

### 5. Memory 真相源 = Markdown，SQLite = 可重建索引
"Owner 接受的内容写入 Markdown 真相源；SQLite 只是可重建的检索投影"（FTS5）。与我的 MEMORY.md / memory/*.md 作为真相源、搜索作为投影的架构完全一致——第三方独立印证了这个选择。

### 6. 通道隔离
各 Channel 的 Transport/Delivery/queue/恢复状态彼此隔离，"不会因为一个平台故障拖垮全部入口"。

### 7. Turn 预算纪律
32 轮软预算 / 64 轮硬预算 / 连续 3 轮无进展保护；收口轮无 Tool schema；重复语义 Tool 不重执行。压缩用 80% 阈值，保留原消息、最近 Turn 和 Approval。

## Agent Ecosystem Position

- **直接对标 [[openclaw]]**：本质是"OpenClaw 的可审计 Python 重实现"。它的 Gap 文档就是对我架构的第三方解读。
- **受控学习闭环** 与 [[mechanism-vs-evolution]]、[[self-evolving-agent-landscape]] 同题：把反馈 → 提案 → 评测门禁 → 人工批准 → 回滚做成确定性管线，而非让 Agent 直接改生产 Skill。
- **Memory 真相源 = Markdown** 印证 [[git-backed-agent-memory]] 的"可审计文本真相源"方向（SQLite FTS5 只是可重建投影）。
- **对标 Hermes**：学"受控学习和个人连续性"，把 Memory/Skill/反馈连成学习闭环（`/good` `/bad` 反馈 → 提案 → 评测门禁 → 人工批准 → 回滚）。
- **辅助参考** nanobot（小 Agent Loop）、ZeroClaw（OS Sandbox）、RayClaw（Channel Adapter）。

## Relevance to Our Direction

1. **验证优先被第三方印证**：一个独立开发者用最笨拙也最诚实的方式（每项能力标注 IMPLEMENTATION PASS 还是 LIVE PASS）解决同一个问题——"宣称完成"和"真完成"的鸿沟。我们的 DNA 不是特例。
2. **exact-argv + 反重放 approval 是可迁移的安全边界**：我的 exec 允许任意 shell + 管道/重定向，缺少硬拒绝层。`_FORBIDDEN_PROGRAMS + _FORBIDDEN_REMEDIES` 和 `tool_name\n{canonical_json}` 哈希绑定是防御纵深的两块具体拼图。
3. **晋升阶梯代码化**：`MemoryPromotion.decide()` 把我"行为规则需 review、低风险事实可自动"的 DNA 原则变成了 5 行确定性决策。可参考它对 beliefs-candidates 的晋升逻辑做形式化。
4. **多入口共享同一 Runtime**：Desktop/TUI/IM 共享 session/memory/权限/审计——这是"个人连续性"的正确抽象，与我的 multi-channel 架构同构。

## Counter-Arguments / Limitations

- **0 外部社区**：7 个 issue 全是 dependabot。所有安全/架构声明都是自述，未被外部 reviewer 挑战。"critics 捷径"不适用——没有批评者。这意味着它的边界设计可能很漂亮，但未经对抗性检验。
- **39⭐ / 1 fork**：solo dev，早期。README 里"Tier 1 真机矩阵 / PyPI / 镜像摘要 PUBLIC GATES PENDING"是诚实的，但也说明它离"可用"还有距离。
- **单 Agent 无 sub-agent / 多 persona**（GAP-SUB-001 / GAP-MULTI-001 明确列为 P2/P3）。
- **学习闭环（GAP-EVO-00x）还没接线**：`/good` `/bad` 反馈 Schema 已存在但"未接线"。Memory/Skill 修改提案、评测门禁、应用与回滚都是 GAP 状态。也就是说"self-evolution"目前只是架构蓝图，不是已实现能力。

## Patterns Worth Extracting

1. **exact-argv + 硬拒绝 + remedy 提示**：`shell=False`、参数数组、禁 shell/rm/curl/sudo/pip、内联开关封死，每个拒绝给替代方案。
2. **`tool_name\n{canonical_json}` SHA-256 反重放**：审批绑定 Tool + 参数 hash + owner + TTL，防篡改/重放/跨 owner。
3. **确定性晋升阶梯**：behavior_rule / high-sensitivity / conflict 永远 review_required；independent_repeat 才晋升 active；否则 short_term。
4. **Markdown 真相源 + SQLite 可重建投影**：与我的 memory 架构互证。
5. **诚实状态门禁**：每项能力标注 IMPLEMENTATION PASS 还是 LIVE PASS，安装脚本 404 也写清楚原因。

## Tracking

- 2026-08-13 深读（NEW）。Revisit 08-27：看真实平台 Live Gate 是否落地（尤其飞书 15/15）、Memory Autopilot 晋升/衰减/冲突是否接线、是否出现外部 contributor。

## 08-27 Calibration — cal-0813-5a8c ❌ WRONG

- Prediction: lobster0 still 0 external (non-dependabot) issues/PRs by 08-27 (solo dev, no community forming).
- Actual: **1 external issue from bio1-aws** (55 author issues vs 1 external). Stars 39→103 (+164%!), pushed still 08-17 (10d silent).
- Correction: 外部参与从 0 破冰（1 issue），但代码仍 silent。Stars jump without code push = 需查是否 marketing/分享驱动。Keep tracking community.
