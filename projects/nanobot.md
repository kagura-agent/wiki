# nanobot (HKUDS)

> Ultra-Lightweight Personal AI Agent — OpenClaw-inspired, 99% fewer lines of code

## 概要
- **Repo**: https://github.com/HKUDS/nanobot
- **语言**: Python
- **Stars**: 43,842 (2026-06-08, was 39,131 on 04-12)
- **Created**: 2026-02-01
- **最新版**: v0.2.1 (2026-06-01)

## 定位
OpenClaw 的轻量替代品。强调 "core agent functionality with 99% fewer lines of code"。
支持多渠道（WeChat, Discord, Telegram, Matrix, Feishu, WhatsApp）。

## 关键特性
- **Dream single-phase memory** (v0.2.0+, PR #3990) — unified consolidation replacing two-phase pipeline
- **Skill Discovery via Dream** (2026-04-12) — 从对话模式自动生成 SKILL.md
- **Programming Agent SDK** — 可编程 agent
- **Production-ready sandboxing** (v0.1.5)
- **Composable agent lifecycle hooks** (v0.1.4+)
- **disabled_skills** (PR #2959, 2026-04-12) — 配置排除 builtin skill
- 去掉了 litellm，直接用 openai + anthropic SDK
- Jinja2 response templates
- Interactive setup wizard

## 跟我们的关系
- 竞品/替代品位置，不是研究方向
- "Dream memory" 概念值得了解 — 两阶段记忆 vs 我们的 daily + long-term
- lifecycle hooks 跟 OpenClaw nudge plugin 类似
- 增长极快（2 个月 39k stars），说明 lightweight personal agent 有巨大需求

## Dream + Skill Discovery 深读 (2026-04-12)

### 架构概览
Dream 是 nanobot 的重量级 cron 调度记忆整合器。两阶段 pipeline：

**Phase 1 (分析)**：纯 LLM 调用，扫描 history.jsonl 和当前文件（MEMORY.md/SOUL.md/USER.md），产出三种标签：
- `[FILE]` — 新事实（atomic fact）
- `[FILE-REMOVE]` — 需删除的过时内容（14天规则）
- `[SKILL]` — 可复用的行为模式（**新增 2026-04-12**）

**Phase 2 (执行)**：AgentRunner + 工具（read_file/edit_file/write_file），根据 Phase 1 标签编辑文件。
- write_file 范围锁定在 `skills/` 目录（安全沙箱）
- 传入现有 skill 列表用于去重
- 引用 builtin skill-creator/SKILL.md 作为格式参考

### Skill Discovery 机制 (commit 2a243bf)

Phase 1 新增 `[SKILL]` 识别，条件严格：
1. 特定、可重复的 workflow 在对话历史中出现 2+ 次
2. 有清晰步骤（不是模糊偏好如"喜欢简洁回答"）
3. 足够实质性（不是琐碎操作如"读文件"）
4. 去重由 Phase 2 负责（Phase 1 不看已有 skill 列表）

Phase 2 创建 skill：
- 读 skill-creator SKILL.md 获取格式规范
- 检查已有 skill 是否功能冗余
- YAML frontmatter (name + description)
- 限 2000 词以内
- 必须包含：何时使用、步骤、输出格式、至少一个示例

### 与我们的进化系统对比

| 维度 | nanobot Dream+Skill | 我们 (Kagura) |
|---|---|---|
| 触发 | cron 调度，自动扫描 history.jsonl | nudge hook (agent_end)，手动分流 |
| 模式识别 | LLM 从对话历史提取 | 人工在 beliefs-candidates 记录 |
| Skill 生成 | 自动写 SKILL.md | 手动用 skill-creator |
| 去重 | 自动（列出已有 skill 对比） | 手动（靠记忆） |
| 质量门控 | 格式规范 + 2000词限制 | skill-creator SKILL.md 规范 |
| 安全 | write_file 范围锁定 skills/ | 无限制（agent 有完整文件权限） |

### 关键洞察

1. **Memory consolidation 是 skill generation 的天然入口** — 不需要单独的 skill discovery 系统，在已有的记忆整合流程中加一个标签就行。这比 SkillClaw 的独立 proxy+evolver 优雅得多。

2. **严格的触发条件避免 skill 泛滥** — "2+ 次出现 + 有清晰步骤 + 足够实质" 三重门槛。这解决了 SkillClaw 论文中提到的 "skill 生成过多导致检索噪音" 问题。

3. **Phase 分离是好设计** — Phase 1 不关心去重，Phase 2 才检查已有 skill。分析和执行解耦，Phase 1 可以大胆识别模式而不被现有知识限制。

4. **对我们的启发**：
   - 可以在 nudge hook 中增加 `[SKILL]` 识别逻辑（目前 nudge 只产出 beliefs-candidates）
   - 或在 daily-review 中增加 skill discovery 步骤：扫描近 N 天 memory 找可复用模式
   - 关键差异：我们的 beliefs-candidates 是 free-text gradient，nanobot 的 `[SKILL]` 是结构化输出 → 他们的自动化程度更高

### 同日其他变更 (2026-04-12)

- **disabled_skills** (PR #2959): 配置排除不需要的 builtin skill，对应我们 skill lazy-loading 方向
- **Shell 安全修复**:
  - 拒绝 LLM 提供的 working_dir 跑出 workspace (#2826)
  - 禁止写 history.jsonl 和 cursor 文件 (#2989)
  - 允许只读复制 internal state 文件
  - → 安全方向：nanobot 在认真做 LLM 沙箱限制

## Cron 噪声问题与解法 (2026-04-12 deep read)

### 问题
nanobot 用户今天报了两个 cron 相关 issue (#3064, #3066)：cron job 执行时，agent 的中间思考消息（"Checking...", "Connecting to provider..."）泄漏到 channel，导致定时任务非常吵。

### nanobot 解法 (PR #3065, +4/-0 code + 100 行测试)
```python
# 在 on_cron_job handler 中传入 no-op progress callback
async def _silent(*_args, **_kwargs) -> None:
    pass

await loop.process_direct(
    session_key=f"cron:{job.id}",
    on_progress=_silent,  # ← 关键：阻断 _bus_progress 回调
)
```
- `process_direct()` 接受 `on_progress` 参数，默认是 `_bus_progress`（发到 message bus → channel）
- 传 no-op 就阻断了中间消息，只保留最终结果
- heartbeat handler 已经用了同样模式，cron 漏掉了

### 测试设计优秀
- 正向测试：传 `_silent`，验证 outbound queue 无 `_progress` metadata 消息
- 反向测试：不传 `on_progress`，验证 `_progress` 消息确实出现（证明 bug 存在）
- 用 `MessageBus.outbound.get_nowait()` drain queue 检查

### 我们的对比
我们的 channel 架构天然避免了这个问题：
- cron 执行结果写入 `memory/YYYY-MM-DD.md`，不直接发到 channel
- 主 session 读 memory 获取 cron 输出
- 但如果未来 Workshop 的 cron scheduler 直接发消息到 channel，就会遇到同样问题
- **启发**：Workshop cron 实现中应预留 progress suppression 机制

## Task Timeout 机制 (PR #3063)
- `NANOBOT_TASK_TIMEOUT_MINUTES` env var (default: 60)
- `asyncio.wait_for()` 包裹 `_process_message()`
- 超时返回友好错误消息
- 与我们的 Copilot API ~60s 流式空闲超时不同：nanobot 的是整体任务超时，解决无限循环/资源泄漏
- 我们的 subagent 超时是 API 层面限制，不是 agent 层面控制

## 统计 (2026-04-13 09:56)
- ⭐ ~39,200+ | 持续高频 push
- v0.1.5 (Apr 6) — latest release
- 社区快速提 cron/timeout/progress/safety 相关 issue → production 使用阶段确认

### Dream Skill Discovery Bug Fix (7a7f5c9, 2026-04-12)
- **问题**: `WriteFileTool` 以 `skills/` 为 workspace root，但 prompt 要模型写 `skills/<name>/SKILL.md` → 路径解析失败
- **修复**: `WriteFileTool(workspace=workspace_root, allowed_dir=skills_dir)` — workspace 改回项目根目录，allowed_dir 仍限制在 skills/
- 同时修了 Dream Phase 2 里 `skill-creator/SKILL.md` 的路径引用 — 从硬编码相对路径改为 Jinja2 变量 `{{ skill_creator_path }}` 指向 builtin skills
- +28 行测试（test_skill_phase_uses_builtin_skill_creator_path + test_skill_write_tool_accepts_workspace_relative_skill_path）
- **启发**: 写工具做路径限制时，workspace root 和 allowed_dir 是两个独立关注点，不能混为一谈

## Provider Dialects PR #263 (2026-04-13 跟进)

### 重大架构变化
- **新 Dialect 类型**: 用 dialect 选择 LLM client 实现，而不是依赖 model name 推断
- **新 `llmProviders` 配置**: 多 provider 支持，通过 `{provider}/{model}` 引用
- **统一 agents 目录**: `agents/*.md` 即使 `nanobot.yaml` 存在也会被读取，markdown 优先
- 后向兼容: openai/anthropic 内置，无 provider 前缀默认 OpenAI

### 设计洞察
- **Dialect 模式跟 OpenClaw execution contract 异曲同工**: 都是根据 provider/model 组合决定运行时行为，但 nanobot 更显式（dialect 类型），OpenClaw 更隐式（自动激活）
- **markdown-first agents**: nanobot 也在走「markdown 定义 agent」路线，跟 [[multica]] 的 skills.sh import 和 OpenClaw 的 AGENTS.md 异曲同工
- 这个 PR 开了 11 天未合并，规模较大（统一多个关注点）

## Infinite Tool Call Loop Detection (PR #3077, 2026-04-13)

### 问题
Agent 反复调用同一个 tool、相同参数，烧完 max_iterations 也不产出结果。典型场景：问"最近发生了什么"→ 模型反复 `read_file(history.jsonl, limit=50, offset=1)` 15+ 次。

### 解法 (57 行新代码 + 165 行测试)

**核心组件**：
1. `tool_call_signature(name, args)` — JSON序列化 + sort_keys，确定性 key
2. `repeated_tool_call_error(name, args, seen_counts, max_repeats=3)` — 计数器，超 3 次返回错误消息
3. Runner 层集成：`tool_call_counts: dict[str, int]` 在 `run()` 范围内维护，`_run_tool()` 每次调用前检查

**设计亮点**：
- 与已有的 `repeated_external_lookup_error`（web_search/web_fetch 专用, max=2）并行，general guard 作为第二道防线
- 不同参数 = 不同签名 → 读 10 个不同文件完全不受影响
- 每次 `run()` 重置计数 → 跨 turn 不误判
- 阈值 3（宽松够 retry，严格够防循环）
- 错误消息引导模型总结已有信息并回复用户

**测试设计**（5 个新测试）：
- 签名确定性（参数顺序无关）+ 参数差异区分
- 阈值行为（前 3 次 None, 第 4 次 error）
- Runner 集成（模型被阻断后正确产出 final response）
- 负面用例（不同参数不被阻断）
- 已有的 subagent max_iterations 测试也更新了（使用不同参数避免误触 stagnation guard）

### 与我们的关联
- **我们没有类似机制** — OpenClaw exec/tool 执行由 gateway 管理，但无 stagnation detection
- **Workshop agent runner 应考虑加入** — cron 场景尤其需要（无人值守时 infinite loop 浪费 token 更严重）
- **可提 OpenClaw issue** — suggest adding tool stagnation guard in the agent runner
- 与 [[berkeley-benchmark-gaming]] 关联：benchmark gaming 也是 tool 行为偏离预期的表现

## User Message Pre-persistence (PR #3076, 2026-04-13)

### 问题
`_process_message` 在 turn **结束**才写 user message 到 session history。如果进程在 turn 中被杀（OOM/SIGKILL/self-restart），用户消息丢失不可恢复。

### 解法 (20 行改动)
- turn 开始前立即 `session.messages.append({role:"user", ...})` + `sessions.save()`
- `_save_turn()` 时 skip offset +1（避免重复写入）
- 只处理 text content；media blocks 仍走原路径（需 sanitization）
- `process_direct()` (CLI) 不受影响

### 启发
- **我们的 cron session 也可能有类似问题** — 如果 cron 执行中被 SIGKILL（我们 04-12 就遇到了），context 可能丢失
- **Write-ahead pattern** 是 production agent 基本要求：先持久化输入，再执行

## Provider Hardening (2026-04-13 凌晨)
- `fix: add guard for non-dict tool call parameters` — 模型返回 list 等非法参数类型时，registry 返回清晰错误让模型自纠正
- `fix(mcp): hint on stdio protocol pollution` — MCP stdio 协议污染提示
- `fix(provider): preserve static error helper compatibility` + `clarify local 502 recovery hints`
- 模式：nanobot 在做 **defensive programming against model misbehavior** — 不信任模型输出格式

## 下一步
- [x] 实验：在 nudge hook 中加 `[SKILL]` 标签 (2026-04-12, NUDGE.md Step 5 重写)
- [ ] 对比 Dream 的 staleness 规则和我们的 memory hygiene（14天 vs 我们的 ad hoc）
- [ ] 看 lifecycle hooks 设计，跟 OpenClaw hooks 对比
- [ ] Workshop cron scheduler 添加 progress suppression（借鉴 PR #3065）
- [ ] 跟进 PR #263 合并后的 dialect 实际使用效果
- [ ] 考虑向 OpenClaw 提 issue: tool stagnation guard（借鉴 PR #3077）
- [ ] Workshop agent runner 加入 stagnation detection（参考 nanobot 实现）

## Links
- [[self-evolving-agent-landscape]]
- [[skillclaw]]
- [[metaclaw]]
- [[skill-trigger-eval]]
- [[skill-trajectory-tracking]]
- [[session-state-isolation]]

## Session Resilience Sprint (2026-04-13, 5 commits in ~4h)

### Three-Layer Crash Recovery

nanobot shipped a coordinated session resilience sprint (Apr 12 20:57 - Apr 13 03:30 UTC):

**Layer 1: Write-Ahead User Message** (ea94a9c, +20/-1)
- Problem: `_save_turn()` writes user message at turn END → OOM/SIGKILL mid-turn = prompt silently lost
- Solution: Append user message + flush to disk BEFORE agent loop. Skip offset adjusted in `_save_turn()` to avoid duplication
- Scope: Text content only; media blocks still go through end-of-turn sanitization
- Uses `pending_user_turn` metadata flag as transaction marker

**Layer 2: Interrupted Turn Closure** (6484c7c, +30/-0)
- Problem: After crash, dangling user message with no response confuses next turn
- Solution: `_restore_pending_user_turn()` on session load — if flag exists + last msg is user, inject synthetic `"Error: Task interrupted"` assistant message
- Design choice: Explicit error > silent deletion — preserves user's question, signals interruption

**Layer 3: Auto-Compact Protection** (becaff3, +13/-4 code + 98 lines tests)
- Problem: Proactive session compaction archives expired sessions, truncating context of active tasks
- Solution: `check_expired()` accepts `active_session_keys` (from `_pending_queues.keys()`), skips active sessions

**Bonus: Provider Defensiveness** (ac71480)
- Subagent result as assistant → role alternation drops it → [system only] → Zhipu/GLM 1214 error
- Recovery: convert last-popped assistant to user message when no user/tool messages remain

### Write-Ahead + Flag Pattern (Key Innovation)
```
1. Write user message → set pending_user_turn flag → flush
2. Run agent loop
3. Save turn → clear flag → flush
4. On crash recovery: flag present + last=user → inject error → clear
```
Effectively a **mini write-ahead log** using session metadata as transaction marker. No separate WAL file, no transaction log — just a boolean flag distinguishing "user saved but turn incomplete" from "turn completed normally".

→ New card: [[write-ahead-session-persistence]]

### Testing Quality
- 98 lines autocompact tests (3 scenarios: skip active, archive after complete, partial set)
- 48 lines user persistence tests (crash→close→new turn lifecycle)
- 47 lines provider alternation tests (recovery + 2 negatives)
- Test:code ≈ 3.5:1

### Relevance
- OpenClaw cron sessions could lose context on SIGKILL (we experienced this 04-12)
- Workshop agent runner should consider write-ahead for user inputs
- The flag pattern is reusable anywhere with two-phase persistence

## Tool Stagnation Detection 深度对比（2026-04-13）

PR #3077 的方案 vs OpenClaw `tool-loop-detection.ts` 对比后发现：
- nanobot 更简单（57 行 vs 400 行）、更激进（阈值 3 vs 10/20/30），per-run reset 避免跨轮误报
- 两者共同盲区：**creative retry**（变参数、同结果）
- nanobot 的 instructive error message 设计值得借鉴：不只是 "blocked" 而是引导模型 "summarize + respond"
- 详见 [[loop-detection-comparison]]

### 04-13 晚间跟进

**可靠性打磨阶段**：
- **#3081 Skip auto-compact for active sessions** — 有 in-flight agent task 时跳过 proactive auto-compact，防止 mid-turn 上下文截断。`_pending_queues` 显式传入（clarity > implicit state check）
- **#3082 Trailing assistant message recovery** — subagent 结果作为唯一内容注入时，`_enforce_role_alternation()` 把最后的 assistant 消息也删了 → Zhipu 1214 "messages 参数非法"。Fix: 把最后 popped 的 assistant 恢复为 user message
- **#3099/#3094 Log noise reduction** — auto-compact `archived=0, summary=False` 不再产生日志输出。跟 OpenClaw 的 "reduce plugin registration log noise" (#65680) 同天同方向

**Pattern**: nanobot 在做 provider 兼容性的 last mile — 不同 provider (Zhipu/DashScope/DeepSeek) 对 message 格式有不同要求，`_enforce_role_alternation()` 是统一适配层但需要精细化处理。这类 edge case 只有实际接入多 provider 后才会暴露

## Cross-Session State Isolation Fix (2026-05-01)

**PR #3576** — bugfix for #3571: `ReadFileTool` was saying "File unchanged since last read" across different sessions.

### Root Cause

Module-level `_state: dict[str, ReadState]` was shared across all sessions in the same process. When session A reads `foo.py`, session B's subsequent read of the same file gets the dedup stub instead of full content.

### Fix: `FileStates` class + `contextvars.ContextVar`

**Before**: Single global dict at module level.

**After**: `FileStates` class owns its own `_state` dict. Active session bound via Python's `contextvars.ContextVar`:
```python
_current_file_states: ContextVar[FileStates | None] = ContextVar("_current_file_states", default=None)

def bind_file_states(fs: FileStates) -> Token:
    return _current_file_states.set(fs)

def reset_file_states(token: Token) -> None:
    _current_file_states.reset(token)
```

Agent loop binds at session start, resets in `finally`. Shared tool instances read from the context var, getting session-scoped state automatically.

**Backward compat**: Module-level `_default = FileStates()` preserved for existing code that doesn't bind.

### Architecture Insight

This is the classic **shared-process multi-session state leak** pattern:
1. Agent framework runs multiple sessions in one process (for efficiency)
2. Tool state stored at module level (natural Python pattern)
3. Cross-session contamination creates confusing bugs

The `ContextVar` pattern is the async-safe equivalent of `threading.local` — works correctly with `asyncio` task switching. This is cleaner than:
- Passing state through every function call (invasive)
- Per-session tool instances (wasteful)
- Thread-local storage (broken with async)

### Relevance

- OpenClaw runs multiple sessions per process too (cron, heartbeat, subagents). Our tool state (e.g., file read caching in browser skill) should be audited for similar leaks.
- The `bind → try → finally reset` pattern using ContextVar is a reusable recipe. See [[session-state-isolation]].
- +307/-124 lines — significant refactor, well-tested (61 new test lines, explicit cross-session isolation test).

### Other 05-01 Changes

- **#3574 Native AWS Bedrock Converse support** (+1226 lines) — full Bedrock provider: streaming, tool calling, usage mapping. Expanding provider matrix.
- **#3539 Upgrade wizard skill** — two-phase: builtin `update-setup` wizard generates a personalized update skill in user's workspace. Self-service upgrade pattern.
- ⭐ 41,423 (steady growth, +252 since 04-28)

*Followup: 2026-05-01. Source: GitHub API + PR diffs.*

## AI Contributor Onboarding System (2026-05-09 followup)

### `.agent/` Directory + CLAUDE.md Pattern

nanobot added a structured four-layer AI contributor guidance system (commit 6eef3d0, 2026-04-29; refined 7c1aa5a, 2026-05-09):

**Layer 1: `CLAUDE.md`** — Project overview, architecture map, dev commands, code style. Answers "what is this project and how do I build it?"

**Layer 2: `.agent/design.md`** — Architectural constraints:
- "Core stays small; extend at edges" (loop.py/runner.py are sacred)
- "Prefer duplication over premature abstraction" (channels/providers stay self-contained)
- "Minimal change that solves the real problem" (no bundled refactors)
- "Explicit over magical" (Pydantic config, clear exceptions)

**Layer 3: `.agent/security.md`** — Hard boundaries:
- All paths through `_resolve_path` (workspace restriction)
- All HTTP through `validate_url_target` (SSRF protection)
- Shell sandbox via `bwrap` backend registry

**Layer 4: `.agent/gotchas.md`** — Pitfalls that waste time:
- Don't `ruff format` (destroys git blame)
- `${VAR}` in config is NOT shell-style (no defaults, raises ValueError)
- Windows compat: `cmd /c`, UTF-8 stdout, pathlib only
- Context pollution persists (sanitize before it becomes examples)
- Heartbeat = virtual tool call, not string parsing
- Session writes must be atomic (fsync + rename)

### Design Insight

The separation is smart: **CLAUDE.md is cartography** ("what exists where"), **.agent/ is governance** ("how to work here safely"). Most projects dump everything into CLAUDE.md, creating one huge doc. nanobot's factored approach is better because:
1. AI agents can selectively load relevant docs (security.md for tool changes, design.md for architecture changes)
2. Gotchas evolve independently from architecture
3. Security boundaries are explicit and auditable

Compare with OpenClaw's approach: single `CLAUDE.md` + inline comments. The factored `.agent/` pattern is worth adopting.

### Image Generation Tool (PR #3695, merged 2026-05-08)

- First-class `generate_image` tool with provider abstraction (OpenRouter, AIHubMix)
- Artifact persistence for iterative editing (reuse prior outputs as references)
- WebUI Image Generation mode with aspect ratio selection
- Similar to our [[kagura-canvas]] but more tightly integrated into core
- Signals: image gen becoming expected capability for personal agents

### AgentLoop.from_config() Refactor (#3708, 2026-05-09)

- Centralizing duplicated bus/provider/loop initialization from CLI+facade into single classmethod
- Part 1/4 of model-preset feature decomposition
- Pattern: extract factory method before adding new functionality that needs it

### Stats (2026-05-09)
- ⭐ 42,045 (+623 since 05-01)
- 5 active contributors (chengyongru, Re-bin, eugenechae, vystartasv, yorkhellen)
- v0.1.5.post3 (2026-04-29) — still patching, no minor version bump
- Daily pushes, reliability hardening + feature additions in parallel

### Applied: Factored AI Contributor Docs → FlowForge (2026-05-09)

Adopted nanobot's `.agent/` pattern for [[FlowForge]]:
- `CLAUDE.md` — cartography (structure, concepts, quick start)
- `.agent/design.md` — 8 architectural constraints (minimal engine, YAML-first, one active instance, etc.)
- `.agent/gotchas.md` — 9 traps (1-based branches, auto-close on start, DB-stored YAML, etc.)

FlowForge had zero contributor docs before. Now AI agents can selectively load governance docs relevant to their change type. Commit: `e2f71b7`.

### Applied: Factored AI Contributor Docs → GoGetAJob (2026-05-09 PM)

Second application of nanobot's `.agent/` pattern, now to [[GoGetAJob]]:
- `CLAUDE.md` — quick orientation (structure, build, 5 rules)
- `.agent/design.md` — architecture decisions (why gh CLI, why SQLite, why no ORM, command architecture, data model)
- `.agent/gotchas.md` — 7 traps (stderr capture, data dir resolution, migration idempotency, rate limits, no test runner, large index.ts)
- `AGENTS.md` → trimmed to pointer file

GoGetAJob had a monolithic AGENTS.md (53 lines mixing everything). Now factored into 3 focused docs totaling 128 lines with clear separation of concerns. Commit: `2109fe8`.

Pattern validation: "Identified pattern → applied to first repo → applied to second repo" confirms this is a reusable, mechanical transformation. Remaining candidates: kagura-story, study repo.

*Followup: 2026-05-09 PM. Source: local changes.*

## Sustained Goal State Architecture (PR #3788, 2026-05-15)

4864-line PR introducing `/goal` command — chat-scoped persistent objectives.

### Three-Layer Design

**Data Layer** (`session/goal_state.py`):
- JSON blob in session metadata: `{status, objective, ui_summary, started_at}`
- Two projections: runtime context (4000 char) and WebSocket (600 char)
- Legacy key migration for backward compat

**Tool Layer** (`agent/tools/long_task.py`):
- `long_task(goal, ui_summary?)` — registers objective. Rejects if one already active
- `complete_goal(recap?)` — marks done with honest recap (success, cancel, or redirect)
- Both inherit `_GoalToolsMixin` for session + WebSocket bus access

**Loop Integration** (`agent/loop.py`):
- `goal_state_runtime_lines()` injected via `supplemental_lines` param each turn
- Goal state broadcast on `_turn_end` metadata for WebUI sync
- Turn latency tracking added (`turn_wall_started_at → latency_ms`)

### Key Design Decisions

1. **No sub-agent orchestrator** — explicit choice. Work stays on main agent with normal tools
2. **Compaction-safe** — goal text re-injected from metadata every turn, not from message history
3. **Single-goal constraint** — one active goal per session, must complete before starting another
4. **Idempotent goal wording mandated** — tool description requires reading `long-goal` skill for outcome-focused, retry-safe phrasing

### Architectural Insight

The "supplemental_lines in runtime context" pattern is the key innovation:
- Session metadata stores durable state
- Runtime context injection makes it visible to the model every turn
- Decoupled from message history → survives compaction, session restore, etc.

This is essentially **metadata-driven context injection** — a general pattern for any persistent state that needs model awareness:
- Active goals/objectives → `supplemental_lines`
- Active workflow state → `supplemental_lines`
- Priority overrides → `supplemental_lines`

### Relevance

Our [[FlowForge]] workflow state partially serves this role (current node = persistent objective) but:
- FlowForge state is NOT injected into agent context automatically — model must `flowforge status` to check
- This means FlowForge state can be "forgotten" after compaction
- Adopting nanobot's pattern would mean: inject current FlowForge node task into every turn's runtime context

OpenClaw's heartbeat/cron tasks also have no persistent objective tracking. Each run starts fresh from `HEARTBEAT.md`. The `/goal` pattern shows how to make objectives compaction-proof.

### Also Landed

- **Signal channel support** (#3852) — signal-cli daemon via HTTP JSON-RPC. DMs + groups, markdown conversion, typing indicators
- **Atomic Chat local provider** (#3750) — OpenAI-compatible local LLM registration
- **CI Python 3.13/3.14** — dropping older runtimes

### Stats (2026-05-16)
- ⭐ 42,549 (+290 from 05-12, +0.7%)
- Pushed today (Saturday) — healthy activity
- v0.1.5.post3 still latest release

## Links
- [[write-ahead-session-persistence]]
- [[session-state-isolation]]
- [[FlowForge]]

## v0.2.0 (2026-05-16)

Major release. 105 PRs, 33 contributors (20 new).

### `/goal` — Sustained Objectives
- `long_task` tool marks thread as sustained objective
- Active goal pinned in Runtime Context every turn — survives compaction
- Wall-clock timeout auto-widens while goal active
- WebUI shows goal in chat header
- `complete_goal` to close

### Architecture Changes
- `_process_message` → functional state machine (explicit transitions)
- `AgentLoop.from_config()` for clean embedding
- Tools → self-describing plugin architecture
- `ask_user` removed (replaced by structured message-tool choices)
- `GlobTool` retired (→ `read_file` glob support)
- Archived summary moved into system prompt (KV cache stability)
- Runtime context appended AFTER user content (prompt cache key preservation)

### Model Ecosystem
- `fallback_models`: list secondary models for failover
- 5 new providers: AWS Bedrock Converse, NVIDIA NIM, LongCat, Atomic Chat, MiMo
- Model presets: named bundles switchable at runtime via `/model`

### Security
- SSRF blocked in DingTalk outbound media
- Feishu media filename confinement
- Local media attachment confinement
- Chat-native DM pairing (approve from chat, not config)

### WebUI Graduation
- Shipped inside pip wheel (no separate build step)
- Image generation tool + inline preview
- Settings/BYOK redesign, localized slash palette
- LAN access gated by token

## v0.2.0 Update (2026-05-16)

**105 PRs merged, 20 new contributors.** Major release.

### Key Changes
1. **`/goal` + `long_task` tool** — Mark a thread as sustained objective. Active goal pinned in Runtime Context every turn, survives compaction and long tool chains. `complete_goal` to finish. Wall-clock timeout auto-widens during active goals. This is their answer to "agent forgets what it's doing mid-way."
   - Relevance: We handle this via FlowForge workflows + plan tool. Their approach is lighter (single tool call vs workflow engine) but less structured.

2. **Image generation built-in** — prompt-to-picture inline in chat via new tool + WebUI mode.

3. **WebUI shipped in wheel** — `pip install nanobot-ai` now bundles WebUI. No separate build step. Settings redesign, BYOK, streamed reasoning, LAN token gate.

4. **5 new providers** — AWS Bedrock Converse, NVIDIA NIM, LongCat, Atomic Chat, MiMo. Plus `fallback_models` for automatic failover.

5. **Core refactor** — `AgentLoop.from_config()`, `_process_message` as functional state machine, tools as self-describing plugin architecture, `ask_user` removed, `GlobTool` retired.

6. **Security** — SSRF blocked in DingTalk, Feishu media path confinement, local media attachment confinement, chat-native pairing for DM approvals.

7. **Model presets** — Named model+provider bundles, runtime switching via `/model`.

### Stars
- 39,131 (2026-04-12) → 42,865 (2026-05-21). +9.5% in 5 weeks.

### `/goal` Architecture Deep Read (2026-05-22)

Code-level analysis of the sustained goal system:

**Implementation**: Two tools (`long_task`, `complete_goal`) + session metadata + Runtime Context injection.
- `goal_state.py` (85 lines): Pure functions for reading/writing goal blob in session metadata. Key: `GOAL_STATE_KEY = "goal_state"` stored as JSON in session metadata dict.
- `long_task.py` (233 lines): Tool definitions. `LongTaskTool.execute()` writes `{status: "active", objective, ui_summary, started_at}` to session metadata. Enforces single-goal constraint (error if goal already active).
- Context injection: `goal_state_runtime_lines()` produces lines appended to Runtime Context block. Max 4000 chars for objective in context, 600 for WebSocket.
- Timeout override: `runner_wall_llm_timeout_s()` returns `0.0` (disable timeout) when goal active, `None` (use default) otherwise. Comment: "idle stall is still capped by NANOBOT_STREAM_IDLE_TIMEOUT_S" — so they disable wall-clock but keep idle timeout as safety net.

**Design decisions worth noting:**
1. **No orchestrator** — Explicit comment: "There is no sub-agent orchestrator and no special WebSocket agent_ui stream." Goals don't change the agent loop, just inject context and widen timeouts.
2. **Compaction-safe by injection** — Goal is re-injected every turn from session metadata, so even if conversation history is compacted, the goal persists. This is elegant — no need to "protect" messages from compaction.
3. **Single-goal constraint** — Must `complete_goal` before starting another. Prevents goal drift.
4. **Legacy key migration** — `_LEGACY_GOAL_STATE_SESSION_KEY = "thread_goal"` shows they iterated on the storage key. Backward compat in metadata is important.
5. **`/goal` command → prompt injection** — `/goal` doesn't call `long_task` directly; it creates a template prompt that nudges the agent to call `long_task` itself. Indirect but lets the agent refine the objective.

**Comparison with our approaches:**
- FlowForge: Multi-step branching workflows, external state machine. Heavier, more structured, good for complex multi-phase work.
- `update_plan`: Session-scoped plan tool, similar lightweight feel but no persistence across sessions.
- nanobot `/goal`: Session-persistent, compaction-safe, single objective. Sweet spot between ad-hoc and structured.
- **Key insight**: Their "inject from metadata every turn" pattern is the right way to survive [[context-compaction]]. We should consider this for any state that must persist across compaction boundaries.

### Stars
- 39,131 (2026-04-12) → 42,963 (2026-05-22). +9.8% in 6 weeks.

### Takeaways
- `/goal` pattern is interesting: lightweight persistent context injection. Simpler than our FlowForge but less capable (no branching, no multi-step workflow). Good for single sustained objectives.
- "Inject from metadata every turn" is the load-bearing architectural insight — makes any state compaction-safe without modifying the compaction logic.
- `fallback_models` is a pattern we should watch — automatic provider failover.
- Their pace: 105 PRs in ~3 weeks from 33 contributors. Community is thriving.

### Post-v0.2.0 Development (2026-05-22)

**Coding Workflow Optimization (PR #3923)** — Major tools overhaul:
- `apply_patch` tool: multi-file unified-diff patches with dry-run, rollback on write failure, closest-match hunk diagnostics
- `exec` session mode: `yield_time_ms` returns `session_id` for background commands, `write_stdin` for interactive I/O, `list_exec_sessions` for recovery after context shifts
- `find_files`: first-class file discovery (replaces `GlobTool`)
- `edit_file` improvements: `occurrence`, `line_hint`, `expected_replacements` safety guards
- Tool contract prompt moved from workspace `TOOLS.md` → bundled `templates/agent/tool_contract.md`

Comparison with OpenClaw:
- OpenClaw's `exec` sessions (yield/poll/write) predate this — nanobot is converging on the same pattern
- OpenClaw's `edit` tool is text-matching based; nanobot's `apply_patch` is unified-diff based — different tradeoffs (text-match is simpler for models; unified-diff is more precise for multi-hunk edits)
- The `find_files` tool is what OpenClaw handles via `exec` + `find`/`fd` — nanobot wrapping it as a first-class tool reduces shell-out risk

**Other changes:**
- Novita AI provider added
- WebUI collapsible sidebar performance improvements
- Provider `reasoning_effort` handling fixes (Kimi thinking models)
- Gateway reasoning control centralized

**Stars**: 42,963 (05-22) → 43,013 (05-23). Still climbing steadily.

### Weekend Activity (05-23)

Minimal new development: Windows CI for CLI Apps (#3965), locale key fills. No new features or architectural changes. Consistent with weekend slowdown pattern across tracked repos.

### CLI Apps: CLI-Anything Integration (PR #3963, merged 2026-05-22)

New first-class **CLI Apps** capability surface:
- Users install CLI adapters from a registry (CLI-Anything public + official registries) via Settings
- Installed apps are mentionable in chat with `@app`
- Agent gets a `run_cli_app` tool that only executes installed registry CLIs through subprocess
- Backend service handles registry fetch/merge/cache/status-check
- 4,338 lines added across 44 files — substantial feature

**Architecture pattern:** Registry-driven tool expansion without modifying core tool loader. Each installed CLI app becomes an addressable tool at runtime. Contrast with OpenClaw's skill system where tools are defined in plugins — nanobot is adding a more dynamic, user-driven tool surface.

**CLI-Anything registry** is an external standard for wrapping arbitrary CLIs into agent-invocable tools. Interesting ecosystem play — they're not building all tools themselves, they're building the adapter layer for the entire CLI world.

**Relevance to us:** ClawHub skill marketplace aimed at similar goal (dynamic tool expansion) but took a different path (SKILL.md packaging vs CLI adapter wrapping). nanobot's approach is more Unix-philosophy (wrap existing CLIs) while OpenClaw's is more structured (purpose-built skills). Both valid tradeoffs.

### Other Changes (05-22)
- Security fix: redirect target validation in web handler (#3928)
- Locale expansion: zh-TW, ja keys filled
- Image provider HTTP handling unified with Gemini image base URLs

### MECE Memory & SNIP Consolidation (PR #3952 → #3990, 2026-05-24)

Major memory architecture evolution. PR #3952 (closed, not merged) proposed MECE long-term memory with routing tags. PR #3990 (open, active) adapts the same ideas to a new single-phase Dream architecture.

**Problem identified (3 core issues):**
1. **Memory duplication bloat** — "user communicates in Chinese" appeared 10+ times across entries. Consolidator was unaware of existing memories
2. **Non-MECE information ownership** — user preferences scattered across SOUL.md, USER.md, and MEMORY.md simultaneously
3. **No lifecycle management** — 14-day flat threshold, no importance distinction between "user height" and "today's arxiv done"

**Solutions:**
- **SNIP principle** for memory eligibility: Signal, Novel, Important, Persistent
- **Attribute tags**: `[permanent]`/`[durable]`/`[ephemeral]`/`[correction]`/`[skip]`
- **MECE routing**: `→USER` (preferences) / `→SOUL` (behavior) / `→MEMORY` (knowledge) — facts routed to single canonical location
- **Dedup context injection**: Consolidator receives current MEMORY.md + USER.md summary, enabling source-level deduplication
- **Merge operation**: duplicate facts consolidated into one rather than merely flagged for deletion

**Experimental results (426 history entries, 222 lines MEMORY.md):**
- Enhanced consolidator: 13 entries → 6 (-54%), 100% valid fact rate
- Successfully marked duplicates as `[skip]`
- Automatic decay level annotation

**Architecture shift (#3990):** Two-phase Dream merged into single-phase. Phase 1 (pure LLM analysis) eliminated — fact extraction, dedup, expiry, and skill discovery all happen in one AgentRunner pass.

**Relevance to us:**
- We already have MECE-ish separation (SOUL.md/USER.md/MEMORY.md) but no enforcement mechanism. nanobot is adding what we do by convention as a system feature
- SNIP principle maps well to our [[beliefs-candidates]] Triple Verification (repeated signal ≈ Signal+Novel, impact ≈ Important, durability ≈ Persistent)
- Dedup context injection is the key innovation — making the consolidator aware of what's already stored before writing more. Our daily memory entries don't do this
- `[skip]` tag is elegant: still written to history for audit, but filtered from Dream processing. Audit trail without memory bloat

See also: [[memory-trash-filter]], [[context-compaction]], [[self-evolving-agent-landscape]]

### Per-Subagent Temperature (PR #3975, merged 2026-05-24)

Simple but useful: `spawn` tool now accepts optional `temperature` param. 4 files, 60 lines. Pipeline already existed — just wired into spawn interface.

**Stars**: 43,084 (05-25). Steady growth continues.

See also: [[self-evolving-agent-landscape]], [[agentskills-io-standard]]

## 跟进 2026-05-26: 43,181⭐, Dream Single-Phase PR + Telegram Webhook

Stars: 43,181 (was 43,084). Steady.

### Dream Single-Phase Consolidation (PR #3990, open)

Major architecture refactor — the previously noted architecture shift now has a full PR with 62 tests. Key details:

**What changed:**
- Removed `dream_phase1.md` and `dream_phase2.md`, replaced with unified `dream.md` (61 lines)
- Dream now driven through `AgentLoop._process_dream_batch` — standard bus → dispatch → batch handler flow
- Goal-state lifecycle: `active` → `completed` with recap, inherits WebSocket sync and LLM timeout disabling
- Internal `while` loop processes all backlog — no bus self-chaining, avoiding deadlock risk
- All changes from a batch folded into single git commit
- Session persistence: `.dream_session.json` with messages, tool events, changelog, commit_sha
- Model override preset support — Dream keeps its own model even when user changes main preset

**Unified prompt design (dream.md):**
- Lifecycle-aware: starts with `long_task` goal, ends with `complete_goal` + recap
- MECE routing table: SOUL.md (behavior) / USER.md (personal) / MEMORY.md (knowledge) / skills/ (workflows)
- "Cross-boundary rule" prevents fact scatter: no technical configs in USER.md, no user facts in SOUL.md
- Delete-or-keep taxonomy: always delete (dupes, resolved PRs, verbose entries), likely delete (debugging steps, ephemeral facts), never delete (preferences, active projects, behavioral rules)
- Default tool: `apply_patch` over `edit_file` — batch surgical edits

**Significance:** This is the move from "memory system" to "memory infrastructure." Phase separation was an early design choice that introduced latency and double LLM cost. Merging them shows maturity — they're confident enough in the routing logic to not need a separate analysis pass.

**Relevance to us:** Our nudge hook runs in-context (no separate session). nanobot's Dream runs as a system session with its own lifecycle. The goal-state pattern (active → completed with recap) is worth noting — it gives the consolidation process the same observability as user-facing goals. We could apply this to our MEMORY.md curation: make it a first-class observable task rather than inline side-effect.

### Telegram Webhook + Ordered Message Queue (merged 05-26)

165-line addition to `channels/telegram.py`:
- Webhook mode alongside polling (configurable)
- Per-session message reorder window — stages incoming messages and drains them in order by message ID
- Validation: HTTPS-only webhook URLs, Telegram secret token
- 107 lines of tests
- Docs for webhook + reverse proxy setup

Message ordering is a real problem for Telegram bots (updates can arrive out of order). The reorder window approach is clean.

### Sustained Goal Continuation Fix (merged 05-25)

Subtle but important: goal-continuation injections no longer count toward `_MAX_INJECTION_CYCLES`. Previously, a sustained goal's "keep going" messages would exhaust the injection budget, causing the goal to stop prematurely. Fix separates `real_injection` from goal-continuation.

**Architecture (from code, 05-27):**
- `AgentRunSpec` gets `goal_active_predicate: Callable[[], bool]` and `goal_continue_message: str | None`
- In `_try_drain_injections`, after checking real injections, if `allow_goal_continue=True` and predicate returns True, injects a continuation prompt
- Only the final-response exit path passes `allow_goal_continue=True` — mid-turn tool calls don't trigger it
- `SUSTAINED_GOAL_CONTINUE_PROMPT`: "You have an active sustained goal. Please continue working toward the objective using your tools, or call complete_goal if the work is truly finished."
- 211 lines of tests: mock LLM returns text (would normally exit) → predicate returns True → runner injects continuation and loops

**Pattern:** Injection budget should only count externally-triggered injections (user actions, tool completions), not internal continuation signals. This is a lifecycle management insight — internal and external triggers need different accounting.

**Design insight:** The predicate-based approach decouples goal state from run-loop logic. The runner doesn't know what a "goal" is — it just checks a boolean. This makes the pattern reusable for any "don't exit yet" condition (e.g., pending file edits, active background tasks).

**Related issues (architecture critiques):**
- Issue #2576: "Deterministic Finalization Protocol" — user reports runner exits with blank response after successful tool calls. Proposes: (1) auto-synthesize action summary when LLM returns empty, (2) forced summary round via system prompt injection, (3) enhanced state observability. 4 comments, active discussion. The sustained goal fix (PR#3999) is the flip side: preventing premature exit when work remains. Together they define the runner exit contract.
- Dream Hunger issue: Dream system starves because Consolidator only writes to history.jsonl when token budget exceeded. Short sessions never trigger → Dream has nothing to process. Proposes: (1) lower consolidation threshold, (2) session-end flush. Relevant because sustained goals + Dream interact — a sustained goal that runs long enough triggers consolidation, but short goal sessions don't.

See also: [[self-evolving-agent-landscape]], [[dream-single-phase-consolidation]]

### Followup 2026-05-27: Codex Transport + WebUI Fixes

**Stars**: 43,214⭐ (was ~43,181 on 05-26, steady).

**Codex transport error handling** (+450/-11): Handles blank Codex transport errors — likely related to streaming timeouts when Codex API returns empty responses. Same class of problem as the Copilot 60s idle timeout we know about.

**WebUI maintenance**: rollup libc selectors restored, ESLint enabled for WebUI.

**Kagi search API integration fix**: Updated search integration.

**Assessment**: Incremental maintenance. The Codex transport fix is a signal that nanobot is adding Codex as a supported backend alongside their existing model integrations. No major architectural changes.

**Revisit**: 06-02.

### Update 2026-05-31 — v0.2.0 deep read + post-release activity

**Stars**: 43,409 (was 39,131 on 04-12 → +4,278 in 7 weeks)

**v0.2.0 (05-16)**: 105 PRs, 20 new contributors. Three headline stories:

1. **`/goal` persistent objective system** — `long_task` / `complete_goal` tools. Goal stored in session metadata, injected via `goal_state_runtime_lines()` every turn. See [[persistent-goal-injection]] and [[metadata-driven-context-injection]]. Wall-clock timeout auto-widens during active goals. WebUI shows goal in chat header. Runner exit guard (PR #3999, documented in our cards) adds `goal_active_predicate` to prevent premature exit.

2. **WebUI shipped in pip wheel** — `pip install nanobot-ai` now bundles WebUI. BYOK redesigned, slash palette localized, reasoning streams live, image generation inline.

3. **Engine refactor** — `AgentLoop.from_config()` for clean embedding. `_process_message` rewritten as functional state machine. Archived summary moved to system prompt for KV cache stability. Tools converted to self-describing plugin architecture. `ask_user` and `GlobTool` retired.

**New providers**: AWS Bedrock Converse, NVIDIA NIM, LongCat, Atomic Chat, MiMo + `fallback_models` safety net.

**Post-v0.2.0 fixes (05-16→05-31)**:
- **Per-session lock in process_direct** (PR #4104): `process_direct` (API/cron/webui/SDK calls) bypassed `_session_locks`, allowing concurrent turns on same session → history corruption. Fix: reuse same `asyncio.Lock`. OpenClaw has analogous `session-write-lock` module.
- **IPv6-mapped IPv4 SSRF bypass** (PR #4086): `::ffff:127.0.0.1` bypassed IPv4 blocklists. Fix: `_normalize_addr()` converts `ipv4_mapped` to IPv4 before matching. OpenClaw also handles this pattern.
- **Dream enabled toggle** (PR #3885): Can now disable Dream job registration — useful for agents that don't need memory consolidation.
- **Matrix SAS verification**: Device verification for encrypted Matrix rooms.
- **Anthropic content block coercion**: Handle typeless content blocks from Anthropic API.
- **Issue #4111**: Heartbeat sends 'All clear.' to Feishu when no tasks — same anti-pattern we guard against with HEARTBEAT_OK.

**Architectural convergence with OpenClaw**:
- Session write locks: both projects have per-session serialization
- SSRF protection: both handle IPv6-mapped IPv4
- Heartbeat quiet mode: both face the "don't spam when idle" problem
- Context injection: nanobot metadata→runtime_context ≈ OpenClaw AGENTS.md session startup

**Assessment**: v0.2.0 marks maturation from "lightweight alternative" to full-featured personal agent platform. `/goal` + runner exit guard is their most interesting architectural innovation — solving agent drift in long tasks at the loop level rather than the workflow level (our FlowForge approach). Growth acceleration (+4.3K stars in 7 weeks) validates the market.

**Revisit**: 06-04.

## 跟进 2026-05-31: Heartbeat Fail-Closed + Gateway HTTP Extraction

⭐43.4K (stable). Active development: 5 commits in 2 days.

### Heartbeat Fail-Closed (PRs #4112, #4114)

**Problem**: Heartbeat runs push routine "All clear." to Feishu/channels when no real tasks. Empty HEARTBEAT.md or any wording edit triggers delivery.

**Fix approach (dual-layer)**:
1. **Evaluator `default_notify` parameter** (#4112): Heartbeat passes `default_notify=False` — if the notification evaluator (LLM judge deciding "should we notify?") fails, errors out, or returns malformed response, the default is now **don't notify** (fail closed). User reminders keep `default_notify=True` (fail open). Previously all evaluator failures defaulted to notify.
2. **Message tool suppression** (#4114): During heartbeat internal checks, direct `message-tool` invocations by the model are suppressed — even if the model tries to bypass the evaluator gate by calling the messaging tool directly, delivery is blocked.
3. **Skip detection improvement**: Template matching now looks for real task lines (ignoring headers/comments), so minor wording changes to HEARTBEAT.md don't trigger a run.

**Transfer value for [[OpenClaw]]**: OpenClaw's heartbeat uses `HEARTBEAT_OK` as the quiet signal — a convention-based approach vs nanobot's evaluator-based approach. OpenClaw's is simpler (model returns magic string → no delivery) but relies entirely on the model following the convention. Nanobot's fail-closed evaluator is more robust — if the model goes off-script, delivery is still blocked. The message-tool suppression layer is particularly interesting: it handles the case where the model circumvents the intended flow.

### GatewayHTTPHandler Extraction (PR #4115)

868 lines extracted from `WebSocketChannel` into `GatewayHTTPHandler` — separating HTTP routing from WebSocket transport. Prerequisite for hot-reload capabilities.

**Signal**: nanobot is investing in architectural refactoring for maintainability, not just features. This is a maturity indicator — projects at 43K stars need clean internals for sustainable contribution.

Links: [[loop-detection-comparison]], [[persistent-goal-injection]]

## Followup 2026-06-02: 43,491⭐, Event-Driven Refactoring

**Stars**: 43,491 (stable). Active development: 10 commits on 06-01.

### Event-Driven Architecture Refactoring (06-01)

Major decoupling sprint — 6 refactoring commits in one day:
- `refactor: decouple webui runtime state via events` — webui no longer polls runtime state directly
- `refactor: route file edit progress via channel capability` — progress updates go through capability abstraction
- `refactor: subscribe to runtime event types` — typed event subscriptions replace ad-hoc listeners
- `refactor: move runtime event publishing out of loop` — event emission extracted from hot path
- `fix: tolerate missing runtime event state in direct loop tests` — test isolation for event refactoring

**Pattern**: Moving from direct method calls to event bus for runtime→UI communication. This enables multiple UI frontends (webui, TUI, CLI) to receive the same events without coupling to runtime internals.

### DingTalk Group User Isolation (06-01)

`feat(dingtalk): add group_user_isolation` — separates sessions per user in group chats. Previously all users in a DingTalk group shared one session. This is the same problem OpenClaw solved from day one with session-per-user architecture.

### WebSocket Error Handling

`fix: close websocket turns after errors` — proper cleanup on WS failures. Standard robustness.

### Assessment

No architectural novelty — standard maturation work. The event bus refactoring is well-executed but not conceptually new. DingTalk user isolation is a table-stakes feature that confirms nanobot's multi-channel ambitions but doesn't change its trajectory.

### Runtime Event Bus — Implementation Detail

Read `nanobot/bus/runtime_events.py` in full. Clean design:
- **Typed frozen dataclasses**: `SessionTurnStarted`, `TurnRunStatusChanged`, `TurnCompleted`, `GoalStateChanged`, `RuntimeModelChanged` — explicit event taxonomy
- **Separate from message bus**: runtime events are in-process state notifications, not user delivery
- **Ordered execution**: `publish()` awaits async handlers sequentially, `publish_nowait()` for sync contexts creates a task
- **Turn-scoped metadata**: `RuntimeEventPublisher` carries per-turn latency and runtime state, with `clear_turn()` cleanup
- **Lazy init**: `ensure_runtime_event_publisher()` creates missing state on access — defensive against initialization order

This is textbook event sourcing for agent internals. OpenClaw uses a similar but more implicit approach (heartbeat events, system events via cron). The explicit event type hierarchy is cleaner.

### Issue #4128: Session Retention Bug

`retain_recent_legal_suffix` has an edge case: when the last N messages are all assistant/tool (no user message), the `cut` calculation uses `len(tail) - len(kept)` which can duplicate user messages across archive and kept. A subtle bug that exposes the fragility of positional session truncation — any cut-based approach risks this. Our approach ([[context-compaction]]) avoids positional cuts.

### Issue #4133: Silent Tool Call Delivery Failure

After tool calls, agent response silently fails to deliver — persists after a previous fix (#4080). This is the classic "tool output consumed the response" bug. Multiple channels affected.

Links: [[self-evolving-agent-landscape]], [[OpenClaw]], [[context-compaction]]

## Followup 2026-06-02

**Stars**: 43,496 (was 41,316 last noted — steady growth)

Recent activity is maintenance/polish, no new architectural signals. DingTalk group_user_isolation and event bus refactor already noted on 06-01. Today's commits are docs-only for the DingTalk feature.

Open PRs of interest:
- #3723 Local whisper transcription — still open, would add offline voice-to-text
- #4143 Refactor session retention result — session lifecycle cleanup

## Followup 2026-06-03: PR #3990 Merged — Dream Single-Phase Shipped

**Stars**: 43,551 (was 43,496 on 06-02)

### Dream Two-Phase → Single-Phase (PR #3990, MERGED 06-02)

The long-anticipated architecture simplification is now shipped. Key implementation details from code review:

**MemoryStore gains Dream responsibilities:**
- `build_dream_prompt(max_entries=20)` — reads unprocessed history via cursor, renders unified `dream.md` template with truncated conversation snippets, returns `(prompt, last_cursor)` or `None` if nothing to process
- `build_dream_tools()` — restricted `ToolRegistry` with only `ReadFileTool`, `EditFileTool`, `ApplyPatchTool`, `WriteFileTool`. Write restricted to `skills/` dir, edit restricted to `memory_dir` + soul/user/skills roots
- `dream_run_completed()` — checks `_stop_reason == "completed"` from ephemeral response metadata

**AgentLoop integration:**
- `TurnContext` gets `ephemeral: bool` and `tools: ToolRegistry | None` fields
- `_run_agent_loop` accepts `ephemeral=True, tools=...` — suppresses extra hooks (no nudge, no progress during Dream)
- `_build_initial_messages` gains `include_memory_recent_history=False` for Dream (avoids circular injection)

**Unified dream.md prompt (105 lines) — notable design:**
- MECE routing table: SOUL.md (behavior) / USER.md (preferences) / MEMORY.md (project context) / skills/ (workflows)
- Cross-boundary rule: no technical configs in USER.md, no user facts in SOUL.md
- Attribute tags: `[permanent]`/`[durable]`/`[ephemeral]`/`[correction]`/`[skip]` as routing/retention hints
- Delete-or-keep taxonomy: always/likely/never delete + migrate-to-skill
- Skill discovery integrated: create when repeatable workflow appears 2+ times
- "Facts easily discoverable via a quick web search" — explicit exclusion rule

**Safety:** Cursor advances ONLY on successful completion. Ephemeral sessions excluded from AutoCompact. Hook suppression via `ephemeral=True`.

**What was removed:** `Dream` class, `dream_phase1.md`, `dream_phase2.md`. 817 lines deleted, 949 added.

### Architectural Insight: Processor → Loop Reuse

Key pattern: **reuse `process_direct()` with ephemeral mode** instead of maintaining parallel execution path. Dream inherits all loop improvements automatically. Single prompt template easier to iterate than coordinated two-template pipeline.

Validates: specialized agent tasks (consolidation, review, cleanup) should reuse the main agent loop with mode flags, not build parallel execution paths. Our nudge hook follows this (runs in-context). Our cron jobs create isolated sessions — middle ground.

### GenericAgent Quick Check (06-03)

⭐12,417. External PRs active (#559, #550). `goal_hive` rewritten to 49-line fractal loop (detect→design→execute→check). Community: 🟢 THRIVING.

### mercury-agent Quick Check (06-03)

⭐2,535. v1.1.11 "Skilly Mercury" shipped skill system (CLI + registry + install + search). v1.1.12 daemon hotfix. The skill runtime layer we noted was missing is now live.

Links: [[dream-single-phase-consolidation]], [[metadata-driven-context-injection]], [[context-compaction]], [[self-evolving-agent-landscape]]

## Followup 2026-06-03: v0.2.1 Release + Cost Optimization Discussion

### v0.2.1 Release (84 PRs, 17 new contributors)

Three stories: (1) WebUI as daily workbench — live file edits, tool traces, sidebar perf, settings. (2) Long-running work durability — session locks, AutoCompact/consolidation race fixes, heartbeat on cron. (3) Extension ecosystem — CLI Apps + MCP unified, extension registry.

Notable: gateway cold start optimized from ~4.6s to ~480ms (#3918). Signal channel support added.

### Issue #4142: Cache-Miss Cost Optimization (Architectural Critique)

Community member @hamb1y quantified the cost problem with real data (DeepSeek V4):
- Cache-hit tokens: 64.8M tokens → $0.18
- Cache-miss tokens: 12.7M tokens → $1.77 (10x cost from ~6x fewer tokens)
- Output tokens: 1.1M → $0.30

**Cache-miss is 78% of total cost despite being 16% of token volume.**

Proposed 6 optimizations, all well-grounded in code paths:
1. Split stable system prompt from dynamic memory/history (context.py mixes them → cache invalidation)
2. Shrink replayed tool results (1200-char preview per result is cache-miss heavy)
3. Tighten _microcompact (waits for 10+ results, too late for cache-miss cost)
4. Strip reasoning replay (persisted reasoning tokens are volatile tail, always miss)
5. Add proactive replay budget below context limit ("fits in context" ≠ cost-efficient)
6. Move subagent current time out of system prompt

**Relevance to us**: OpenClaw's system prompt includes dynamic context (time, memory refs). Same cache-miss pattern likely applies. The "stable prefix + dynamic suffix" split is a general principle for any agent paying per-token for cache misses.

### Issue #4153: Tool Result Persistence Infinite Loop

Bug: `read_file` on a large file → result offloaded to `.nanobot/tool-results/` → agent calls `read_file` on *that* path → offloaded again → infinite loop. The recovery mechanism (read_file) is subject to the same offloading it's trying to recover from.

**Pattern**: when a tool is both the producer and consumer of offloaded content, exempting the recovery path from offloading is necessary. This is a general agent architecture trap — any "too large" handling must not apply to the recovery mechanism.

### Issue #4128: Session Retention Duplicate Bug

Positional session truncation (`retain_recent_legal_suffix`) can duplicate user messages across archive and kept portions when the tail is all assistant/tool messages. Confirms fragility of cut-based session management — our [[context-compaction]] approach avoids positional cuts.

Links: [[dream-single-phase-consolidation]], [[context-compaction]], [[cache-miss-cost-optimization]]

## Followup 2026-06-04: 43,609⭐, Dream Dual-Phase Rewrite + Sensitive Info Redaction

### PR #4186: Major Memory System Overhaul (5 changes)

1. **Sensitive info redaction**: Auto-redact PEM keys, Bearer tokens, API keys, GitHub tokens, emails, ID numbers before persisting to history/memory/soul/user files. "Over-redact > under-redact" policy. Each regex independent.
2. **Dream dual-phase rewrite**: Replaced old single-phase dream with structured pipeline:
   - Phase 1: Pure LLM analysis of history.jsonl → structured JSON output
   - Phase 2: AgentRunner with read_file/edit_file/write_file for incremental edits
   - EditFileTool restricted to memory/ + SOUL.md + USER.md + skills/ (prevents prompt injection)
   - Cursor advances only on stop_reason==completed + git commit
3. **Atomic writes**: `_write_text_atomic` (tmp → fsync → os.replace → fsync parent) replaces all bare write_text calls
4. **Session summary**: Keep 5 recent summaries (was 1), unified formatting, identity-aware compaction
5. **AutoCompact simplified**: Removed internal session prefixes, Dream no longer uses temp sessions

**Relevance to us**: The dual-phase dream is an evolution from the single-phase we noted on 06-03. Phase 1 (structured analysis) + Phase 2 (tool-assisted editing) mirrors a compile→execute pattern. The atomic write guarantee is something we lack — our memory writes are bare file ops. The redaction-before-persist approach is worth noting for our privacy guidelines.

### Issue #4179: Native A2A Orchestration

Feature request for horizontal agent-to-agent collaboration within group chats (Telegram/Discord). Proposes: agent registry, mention-based routing, horizontal message bus. Currently subagent is vertical (parent→child) and silent. This would make multi-agent collaboration visible to humans in-channel.

**Relevance**: OpenClaw's subagent model is also vertical. The horizontal peer model with mention-based routing in group chats is a different paradigm — agents as peers rather than hierarchical workers.

### MCP Reconnect Hardening (PR #4186 adjacent commits)

Two commits fixing MCP session reconnection, architecturally interesting:

**Pattern**: Base class extraction (`_MCPWrapperBase`) unifying `MCPToolWrapper`, `MCPResourceWrapper`, `MCPPromptWrapper` with a shared reconnect handler via DI callback. Each wrapper gets `set_reconnect_handler(callback)` injected at connection time by `_attach_reconnect_handlers()`.

**Retry layering**: Two orthogonal recovery mechanisms in `execute()`:
1. **Transient retry** (ClosedResourceError, EndOfStream) — retry once, same session
2. **Session termination reconnect** ("Session terminated", "Connection closed") — full server reconnect via callback, get new session

Both are independent flags (`retried_transient`, `refreshed_session`) — can trigger both in one call if transient retry reveals terminated session.

**Concurrent dedup**: `_refresh_terminated_server()` acquires `_reload_lock`, then checks `current_tool is not stale_tool` — if another concurrent call already reconnected, reuse the fresh session instead of reconnecting again. Clean lock-then-check pattern.

**Relevance to us**: OpenClaw's MCP tool execution currently doesn't have session-level reconnection. The stale-tool identity check (`is not stale_tool`) is a elegant dedup pattern worth noting for any shared-resource reconnection logic.

### GenericAgent 06-04: Output Injection Refactoring

Per-instance `no_print` flag via dependency-injected print function. Pattern: `self.print = safe_print` on handler, passed through to code_run as `myprint` parameter. Makes instances testable/composable for headless execution. EXIT sentinel for clean run loop shutdown. Checklist poll hard cap (1000 iterations) prevents infinite loops.

**Pattern**: DI for I/O is the right way to make agent instances embeddable — GenericAgent moving from "always interactive" to "embeddable component."

### nanobot v0.2.1 (2026-06-01, 84 PRs, 17 new contributors)

Major release themes:
1. **WebUI as daily workbench** — live file edit visibility, activity rendering, source favicons, settings/sidebar/model controls unified, Thought/response ordering fix
2. **Long-running agent stability** — sustained goals keep runner alive, per-session locking, AutoCompact/Consolidator race fix, archive retention data-loss fixes
3. **CLI Apps + MCP unification** — CLI-native tools → preset setup → capability mentions → extension registry. Clearer path from local tool to agent-invokable workflow
4. **Provider expansion** — Ant Ling, Skywork, Novita, Step Plan, StepFun/Zhipu/Ollama image gen, OpenAI API type selection, `extraBody`
5. **Gateway cold start optimization** — ~4.6s → ~480ms (10x improvement)
6. **Security hardening** — WebSocket auth for token issuance, redirect validation, IPv6-mapped IPv4 SSRF normalization, bounded Matrix media downloads

**Stars**: 43,683 (up from 28K at v0.2.0)

**Notable patterns**:
- Cold start optimization (4.6s→480ms) is impressive for a Node.js gateway — likely lazy module loading + deferred initialization
- CLI Apps + MCP convergence mirrors OpenClaw's skill/tool unification direction
- Per-session locking for process_direct prevents overlapping turns from corrupting state — same problem OpenClaw solves with session locks

### Post-v0.2.1 Development (2026-06-04 → 06-07)

**PR #4195 — Desktop Shell (merged 06-06)**: The biggest architectural move — 10,478 additions, 998 deletions, 103 files. Adds Electron desktop app while keeping WebUI as the shared UI layer.

Architecture split:
- `desktop/` → Electron host, local gateway lifecycle, Unix socket, preload bridge, packaging
- `webui/` → chat, settings, file preview, skills, token usage, automations (shared between browser + desktop)
- `nanobot/webui/*` → WebUI-specific gateway APIs and transcript shaping
- `nanobot/channels/websocket.py` → pure transport (delegates UI logic to `WebUITranscriptRecorder`)

**Key design principle**: "desktop app should feel native without becoming a second UI implementation." The core agent loop (`nanobot/agent/loop.py`) has zero diff — clean separation of concerns.

**Bundle ID**: `wiki.nanobot.desktop` — interesting domain direction signal.

**Why this matters**: nanobot is transitioning from "chat platform connector" to "native desktop agent" while OpenClaw already has this via node apps. The shared-WebUI pattern (browser + desktop from same codebase) is the right architecture — avoids the dual-implementation trap.

**Other notable changes (06-04 → 06-07)**:
- **Custom image provider support** (06-05): Pluggable image gen backends, `extraBody` null-dropping for provider compat
- **/skill command** (06-05): New slash command to list enabled skills — user-facing skill discoverability
- **WhatsApp LID mentions** (#2663, merged 06-07): Handles WhatsApp's new Local ID format for group mentions
- **SDK teardown** (06-06): Proper MCP connection cleanup from Nanobot facade — important for embedding scenarios
- **Session history hardening** (#4219, open): Drop orphan tool results before trimming — prevents history corruption when trimming cuts mid-tool-call
- **Security PRs** (open): Symlink escape blocking (#4119), unsafe HTTP URL rejection (#4123), read-only root protection (#4053) — systematic security hardening sprint
- **Testing harnesses** (#3982, #4193, open): Scripted agent runner + memory lifecycle test harnesses — investing in test infrastructure
- **Cron silent mode + lock_recipient** (#4225, open): From WhatsApp contributor — scheduled jobs can now run silently and lock delivery target

**Growth**: 43,817⭐ (+0.5% from 43,609 on 06-04). 7,748 forks. 863 open issues. External contributor PRs active (WhatsApp, httpx timeout, reasoning_content preservation).

Links: [[dream-single-phase-consolidation]], [[context-compaction]], [[cache-miss-cost-optimization]], [[atomic-writes]]

### Multi-Provider Transcription System (2026-06-08)

Nanobot added a full multi-provider STT pipeline in a single day (3 PRs merged):

**Architecture** — clean two-layer design:
- **Registry** (`transcription_registry.py`): `TranscriptionProviderSpec` dataclass with lazy adapter import via `importlib` + Protocol-based interface
- **Application** (`transcription.py`): config resolution, MIME validation, temp-file handling, dispatch. Zero provider-specific HTTP knowledge

**Providers** (5 total):
| Provider | Default Model | Notes |
|----------|--------------|-------|
| groq (default) | whisper-large-v3 | Fast, free tier |
| openai | whisper-1 | Baseline |
| openrouter | openai/whisper-1 | Single credential, route to multiple STT models |
| xiaomi_mimo | mimo-v2.5-asr | Chinese market; aliases: "mimo", "xiaomi" |
| assemblyai | universal-3-pro,universal-2 | Comma-separated model fallback |

**Pattern value**: Protocol-based adapter (`__init__` + `async transcribe(path) -> str`) is minimal surface — easy to add new providers. Our single-provider Whisper setup could adopt this if we need multi-provider STT.

**Cross-Agent Messaging (PR #3992, closed)**: Attempted NATS/Redis message bus for multi-instance agent communication. Closed due to scope creep (698K additions). The concept — agents delegating tasks across instances — remains an unsolved problem in open-source personal agents.

**Open Issues Signal** (06-09):
- bwrap sandbox `$HOME` leak (#4237) — identical risk class for any bwrap sandbox
- Ubuntu 24.04 user namespace restriction (#4236) — AppArmor blocks unprivileged bwrap
- `max_messages` truncation invalidates [[cache-miss-cost-optimization|prefix caching]] — architectural tension we share
- Per-conversation model override request — routing granularity demand

**Growth**: 43,897⭐ (+0.2% from 43,817 on 06-07). Steady.
**Growth**: 43,910⭐ (06-09). Adding multi-provider transcription (AssemblyAI, Xiaomi MiMo ASR, OpenRouter STT) — expanding voice/audio input pipeline.

Links: [[cache-miss-cost-optimization]], [[context-compaction]], [[OpenClaw]], [[agent-trust-hierarchy]]

### Followup 2026-06-10

**Stars**: 43,966⭐ (was 43,910 on 06-09, +56). 7,788 forks. 866 open issues.

**Key changes since 06-09**:
- **PR #4208 (merged)**: WebUI fork-from-here — users can branch conversation from any assistant reply. Clean WebSocket isolation for the fork handler. UX pattern that none of the other tracked agents have.
- **PR #4190 (merged)**: Stricter tool call validation — tightening the runtime safety net.
- **PR #4252 (merged)**: TeX math delimiter rendering in WebUI.

**Notable open PRs**:
- **#4270**: Archive full session history during idle compact — currently truncation is lossy, this preserves full history in archive before compacting. Addresses the prefix-caching vs context-trimming tension noted before.
- **#4269**: Improve max-iteration final responses — better UX when agent hits iteration limits.
- **#4268**: `max_completion_tokens` for GPT-5/o-series — provider compatibility fix.
- **#4256**: Monotonic history cursor — prevents cursor regression during concurrent access.

**Assessment**: Steady incremental improvement. Fork-from-here is a nice UX feature (conversation branching). The idle compact archive PR (#4270) is architecturally interesting — it addresses context window management by archiving before truncating, rather than just dropping old messages.

**Revisit**: 06-15.

## Followup 2026-06-17

**Stars**: 44,343⭐ (+377 from 06-10's 43,966). 7,838+ forks. 881 open issues. Steady growth, no breakout.

**v0.2.1 still the latest tagged release** — but the trunk is shifting defaults and addressing memory-path correctness.

### Key Defaults Shift (PR #4370 merged 06-16)

`agents.defaults.idleCompactAfterMinutes`: `0` (disabled) → `15` (enabled). Tiny 3-file change, big semantic impact:

- **Reasoning**: "Dream is enabled by default, but short WebUI chats only become Dream input after history compaction. With idle auto-compact disabled by default, new users can chat in short sessions forever without producing `memory/history.jsonl` entries, making long-term memory appear broken."
- **Pattern**: This is *default-on memory pipeline* — same direction OpenClaw has taken (nudge auto-fires reflect every 5 turns). The implicit assumption: long-term memory is only useful if it's reachable by default.
- **Tradeoff acknowledged**: Users wanting raw transcript trails (audit/debug) must opt out (`= 0`). Low-level `AutoCompact` constructor default remains `disabled` — the change is purely at the config schema layer for config-driven runs.
- **Generalization**: When you ship a memory subsystem that depends on a separate trigger (compact → consolidate → archive), shipping with that trigger disabled makes the whole pipeline look broken in first-run UX. This is the same class of failure as nudge with `triggerEveryN = 0`.

### Architectural Critique: Issue #4307 (open) — Post-Turn Consolidation Wipes Delivery Message

Reporter's deep code analysis is one of the highest-signal bug reports nanobot has received this quarter. Five distinct production instances, all sharing the same failure mode: agent proposes options → consolidation wipes the proposal → user replies "Option 2" → agent has no idea what Option 2 was.

**Code-level root causes (cited with file:line):**
| File | Lines | Problem |
|------|-------|---------|
| `agent/loop.py` | 1382, 1486-1490 | Consolidation only runs pre/post turn, never mid-turn |
| `agent/loop.py` | 789-823 | `_run_agent_loop()` — no prompt budget check mid-iteration |
| `agent/memory.py` | 781-888 | `maybe_consolidate_by_tokens()` only callable between turns |
| `agent/memory.py` | 746-779 | `archive()` — lossy SNIP filter, options/decisions marked `[skip]` |
| `agent/autocompact.py` | 18 | `_RECENT_SUFFIX_MESSAGES = 8` — too small to overlap delivery message |
| `templates/agent/consolidator_archive.md` | 1-24 | SNIP criteria filters out ephemeral decision points |

**Four proposed fixes (ordered by impact):**
1. **Preserve last assistant delivery message through consolidation** — simplest, highest impact. Agent's own delivery message must survive in the "recent suffix" window.
2. **Mid-turn prompt budget enforcement** — currently 40k `context_window_tokens` can grow to 100k+ before any check fires. Mid-iteration check + trigger consolidation if exceeded.
3. **Smarter consolidation summaries for decision points** — modify `consolidator_archive.md` SNIP template to recognize numbered options/proposals/findings as `[durable]` rather than `[skip]`.
4. **Increase `_RECENT_SUFFIX_MESSAGES`** from 8 → 16-20 so suffix window overlaps delivery + tool results.

**Why this matters for our direction:**
- Our [[persistent-goal-injection]] card already captures how goals survive compaction via metadata. But goals are the *task*; this issue exposes that **the agent's own conversational outputs (proposed options, findings, decision points) are equally ephemeral** and equally need preservation.
- OpenClaw's MEMORY.md + heartbeat compaction has the same structural risk. The reporter's framing — "decision points" vs "conversational filler" — is a useful distinction we don't currently make.
- The "5 production instances, 1 self-reported on its own session recovery work" story (Instance 4: "the active goal was literally 'improve the session recovery tool' — and the very next turn, it lost context") is a meta-failure of exactly the kind we should be designing against.
- New card: [[delivery-message-preservation]] for the broader pattern.

### PR #4359 — Lazy Goal Continuation Refresh

Already captured in earlier followup, but worth re-noting: goal continuation now refreshes from a **dynamic provider** instead of a **snapshot**. This is the right direction for [[persistent-goal-injection]] — but does not address Issue #4307 (because the issue is about the *agent's outputs* getting wiped, not the goal).

### Other Notable Merged PRs (06-16)
- **#4369** "Explain empty Dream runs" — visibility fix, helps debugging the memory pipeline
- **#4368** macOS installer Python externally-managed fix — packaging friction relief
- **#4363** validate stream idle timeout config — schema validation hardening
- **#4361** thinking parameter for Kimi K2.7 — provider expansion

**Assessment**: nanobot's quarterly direction is becoming clear: ship memory-path defaults that actually work, tighten the consolidation/preservation correctness, and continue provider expansion. The fact that a 5-instance critique can be filed with this level of code analysis is itself a signal — production users are running long enough to hit this and care enough to file detailed reports. That's a kind of community maturity most "agent" projects don't have yet.

**Revisit**: 06-24.
### Memory Provenance Gating (PR #4424, 2026-06-21)

New pattern: classify archived facts by **source quality** to prevent agent speculation from polluting durable memory.

**Consolidator source discipline rules:**
1. User-stated/confirmed facts → [permanent], [durable], [ephemeral], or [correction] (full range)
2. Tool outputs & source-code observations → [durable] when concrete, not when speculative
3. Agent-only guesses/inferences/interpretations that user did NOT confirm → [skip] or [ephemeral] with "(agent-inferred)" marker
4. Facts already in long-term memory excerpt → [skip] unless conversation corrects/narrows them
5. "Preserve the narrowest true scope" — don't broaden project-specific observations into global preferences

**Dream promotion guard:**
- Entries marked "(agent-inferred)" cannot be promoted to USER.md or SOUL.md
- Cannot be broadened into durable preferences or project facts
- Only promotable when a **later user turn** explicitly confirms them

**Why this matters for us:**
- Our MEMORY.md currently doesn't distinguish "Luna told me" from "I inferred from context"
- Potential application: add source markers to memory entries (e.g. `[Luna said]` vs `[inferred]`)
- Key insight: the provenance gate is at **write time** (consolidator), not read time — cheap enforcement

See also: [[memory-trash-filter]], [[dream-single-phase-consolidation]]

## 2026-06-22 Followup: Streaming Tool ID Poisoning

**Issue #4442**: Streaming Anthropic provider can persist duplicate `tool_use` IDs in one assistant message during parallel tool calls. Once stored to session history, the malformed message is re-sent every turn → permanent session brick (Anthropic returns 400 "tool_use ids must be unique").

**Root cause**: Stream assembly race — parallel tool_call chunks can duplicate IDs before dedup.
**Fix pattern**: Dedup tool_use IDs before persisting to session history.
**Relevance**: Any streaming agent framework that stores raw streamed messages is vulnerable. This is a cross-cutting concern — see also [[session-state-isolation]].

Also: Proposal #4440 for `search_history` tool to recall memory/history.jsonl — recency-weighted search over past interactions. Pattern: making session history explicitly searchable (vs implicit context window).

**Status**: v0.2.1 still current (since Jun 1). Maintenance/polish phase. No architectural shifts. Growth steady but slowing. Consider downgrade to "following" tier on next check.

Links: [[delivery-message-preservation]], [[write-ahead-session-persistence]], [[session-state-isolation]]
