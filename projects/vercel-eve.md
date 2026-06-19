# Vercel Eve — Filesystem-First Durable Agent Framework

> A full agent platform from Vercel: filesystem-first authoring, durable sessions, typed tools, sandbox isolation, multi-channel support.

- **Repo**: https://github.com/vercel/eve
- **Stars**: 1,371 (06-19, 3 days old)
- **License**: Apache-2.0
- **Language**: TypeScript (monorepo, 714+ source files)
- **Created**: 2026-06-16
- **Status**: Beta, actively pushed

## 概要

Vercel 进入 agent framework 领域的重量级作品。不是一个 skill 或 wrapper，而是完整的 agent 运行时平台——和 OpenClaw 直接竞争的定位。

## 核心架构

### Filesystem as Authoring Interface
```
my-agent/
└── agent/
    ├── agent.ts            # model + runtime config
    ├── instructions.md     # system prompt (≈ SOUL.md)
    ├── tools/              # typed tool functions
    ├── skills/             # on-demand procedures (SKILL.md convention!)
    ├── channels/           # message channels (HTTP, Slack, Discord, etc.)
    ├── schedules/          # recurring cron jobs
    ├── subagents/          # declared specialist agents
    └── sandbox/            # isolated execution environment
```

### Durability Model
- Session = durable conversation, survives restarts and redeploys
- Turn = one user message → agent response
- Step = durable checkpoint within a turn
- Built on Workflow SDK (open source), with Vercel Workflow as platform option
- Crash recovery: resumes from last completed step, never replays

### Trust Boundary (Security)
| | App Runtime | Sandbox |
|---|---|---|
| Secrets/env | Yes | No |
| Node.js | Yes | No |
| Network | Unrestricted | Policy-controlled |
| Filesystem | App's own | Isolated /workspace |

Tools run in app runtime, proxy into sandbox. Model never sees secrets.

### Skill System
- **Identical convention to Agent Skills standard** — `SKILL.md` files
- `load_skill` tool for on-demand activation
- Skills listed in system prompt with descriptions as routing hints
- Active skill content comes from tool result (preserves prompt caching)
- Both markdown and `defineSkill()` TypeScript authoring
- Scoped per-agent (subagent skills isolated)

### Subagent Model
- **Built-in `agent` tool**: clone of self, shared sandbox, inherited tools
- **Declared subagents**: own directory under `subagents/<id>/`, own sandbox/tools/skills
- Complete isolation boundary for declared subagents
- Each gets own durable session and stream
- Parent communicates via `{ message, outputSchema? }` — child never sees parent history

### Channels
Built-in: Discord, GitHub, Linear, Slack, Teams, Telegram, Twilio, HTTP, custom
- Each channel handles its own auth/signature verification
- Fail-closed by default

### Built-in Tools
`bash`, `read_file`, `write_file`, `glob`, `grep` — all targeting sandbox
Also: `defineBashTool`, `defineGlobTool`, `defineGrepTool`, `defineReadFileTool`, `defineWriteFileTool` for custom variants

### Evals
Built-in evaluation framework with assertions, judges, reporters, targets

## 和 OpenClaw 的对比

| 维度 | Eve | OpenClaw |
|------|-----|----------|
| 定位 | Framework (你写代码构建 agent) | Runtime (配置 + skills，开箱即用) |
| Skills | 同一标准 (SKILL.md) | 同一标准 (SKILL.md) |
| 部署 | Vercel 一键部署 or self-host | Self-host |
| Sandbox | per-session microVM (Vercel) or local | Host-level |
| Durability | Workflow SDK 原生支持 | 靠 session 持久化 |
| Channel | 7+ built-in | Plugin 架构 |
| Subagent | 结构化声明式 | 动态 spawn |
| Auth | Route-level, fail-closed | Gateway-level |
| Target | 开发者构建 agent 产品 | 个人/团队使用 agent |

## 关键洞察

1. **Skill 标准的外部验证**：Eve 采用了和 OpenClaw 相同的 SKILL.md convention，证明这个标准在生态中获得认可
2. **Filesystem-first 是趋势**：和 Claude Code 的 CLAUDE.md、Codex 的 AGENTS.md、Eve 的 instructions.md + skills/ — 行业在收敛于"文件就是配置"
3. **Durability 是杀手特性**：Eve 最强的差异化是 Workflow SDK 支持的 durable sessions。OpenClaw 目前没有 step-level checkpointing
4. **Security by default**：Trust boundary 设计严格，secrets never in sandbox，auth fails closed。这是企业级的标配
5. **Vercel 的生态优势**：Next.js + Vercel 部署 + AI SDK 集成，前端开发者的 onboarding 路径极短

## 对我们的启示

- Eve 的 durable session 设计值得研究——step-level checkpoint 让长任务更可靠
- 我们的 skill 标准和 Eve 兼容，这是好事（portability）
- Eve 的 sandbox 隔离比我们严格得多——可能值得参考
- 声明式 subagent 定义（vs 我们的动态 spawn）各有优劣：声明式更可审计，动态更灵活

## 跟踪

- 3 天 1371⭐，82 forks — 增速极快
- 核心贡献者：ijjk (11 commits), AndrewBarba, ruiconti
- Topics: agent, framework, harness, sandbox, workflows
- 35 open issues — 社区活跃

## Issues 里的批评信号 (06-19)

- **#70**: `eve dev` requires Vercel login even with custom model providers → lock-in concern, community pushback
- **#44**: Request for Codex/Claude agent runtime support → eve is model-agnostic but agent-opinionated, can't plug in external coding agents yet
- **#100**: ACP server adapter request → interop with [[acp-protocol]] is a community demand
- **#80**: Compaction bug with Anthropic → context management for long conversations is hard
- **#75**: Session rewind/fork request → durable sessions create new UX expectations

## 生态位置

直接竞争者：[[openclaw]]（runtime vs framework 定位不同但目标用户重叠）
平行项目：[[valkor-ai-loom]]（delivery harness），[[paca-ai]]（Scrum platform）
上游依赖：Vercel AI SDK, Workflow SDK
下游：Vercel 部署生态，Next.js 开发者群体

Links: [[openclaw]], [[skill-ecosystem]], [[agent-harness-landscape]], [[acp-protocol]]

---
*Scout 2026-06-19. Deep read of README, architecture docs (execution model, security, skills, subagents, sandbox). Issues scan for architectural critique.*
