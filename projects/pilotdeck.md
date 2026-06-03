---
title: PilotDeck — Task-Oriented Agent OS
created: 2026-06-03
updated: 2026-06-03
tags: [agent-platform, workspace-isolation, smart-routing, mcp]
links: [[openclaw]], [[agent-harness-kit]], [[skill-ecosystem-wave-2026-05]]
last_verified: 2026-06-03
---

# PilotDeck (OpenBMB/PilotDeck)

**Repo**: github.com/OpenBMB/PilotDeck | **Stars**: 2837 (12 days, high velocity) | **Lang**: TypeScript | **License**: MIT
**Org**: OpenBMB (Tsinghua THUNLP + ModelBest + AI9Stars) — same org behind ChatDev, AgentVerse

## What It Is

Agent OS built around "WorkSpace" concept — per-project isolation of files, memory, and skills. Three pillar capabilities:
1. **White-box Memory**: Traceable memory generation/retrieval; user can inspect and edit individual memory entries; "Dream Mode" consolidates memory during idle time; one-click rollback
2. **Smart Routing**: Auto-detects task difficulty → routes complex tasks to flagship models, simple ones to lighter models. Claimed 5x cost reduction on content workflows
3. **Always-on**: Background task discovery and execution; agent proactively finds work, reports progress, lands files

## Architecture (OpenClaw Comparison)

| Aspect | PilotDeck | OpenClaw |
|--------|-----------|----------|
| Multi-channel | ✅ Discord/Feishu/Telegram/WhatsApp/WeChat/Slack/Matrix/DingTalk/Email/SMS/HomeAssistant | ✅ Similar coverage |
| Session model | WorkSpace isolation (per-project) | Session-based (main/isolated/named) |
| Memory | White-box: visible entries, Dream Mode consolidation, rollback | File-based: MEMORY.md + memory/*.md, manual |
| Model routing | Auto task-difficulty routing | Manual model override, no auto-routing |
| Cost tracking | Per-task token cost tracking | Session-level cost tracking |
| Background exec | Always-on agent proactively finds tasks | Heartbeat + cron scheduled tasks |
| Skills | MCP-native, per-workspace skills | Plugin skills, shared across sessions |
| Subagents | ✅ Agent tool with typed presets (general/explore/plan) | ✅ sessions_spawn with runtime types |

## Key Observations

1. **Positioning**: "Agent OS" framing vs OpenClaw's "agent gateway" — PilotDeck emphasizes workspace/productivity, OpenClaw emphasizes connectivity/orchestration
2. **Smart Routing is the killer feature**: Auto model selection by task difficulty is genuinely useful. OpenClaw could benefit from this (currently manual model override only)
3. **White-box Memory**: Exposing memory internals to users is philosophically different from OpenClaw's file-based approach. Both have tradeoffs: file-based is simpler but less structured; white-box is more powerful but more complex
4. **Dream Mode**: Background memory consolidation during idle — clever use of downtime. Similar concept to what heartbeat could do but more structured
5. **Early-stage stability**: Issues show Docker deployment pain, Windows not ready, Feishu integration breaking on user prompts, skill import failures. Classic week-2 open-source growing pains
6. **Chinese community first**: Issues mostly in Chinese, targeting Chinese IM ecosystem (Feishu, WeChat, DingTalk, QQ)

## Lessons for OpenClaw

- **Smart Routing**: Worth proposing as feature — auto model selection based on task complexity. Would save cost on simple tasks while maintaining quality on hard ones
- **Per-task cost tracking**: More granular than session-level — useful for understanding which tasks burn tokens
- **Dream Mode pattern**: Structured idle-time memory consolidation vs ad-hoc heartbeat memory work

## Verdict

Credible competitor in the agent OS space. Same multi-channel approach as OpenClaw but with stronger workspace isolation and cost optimization. Worth tracking — high star velocity suggests market demand for these features. Not a contribution target (closed ecosystem feel despite MIT license, Chinese-first community).

**Track**: Revisit 2026-06-10 — check if star growth sustains and whether architecture stabilizes.
