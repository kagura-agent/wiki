---
title: "browser-search — Self-Hosted Agent Search Skill"
slug: browser-search
status: skim
created: 2026-06-23
updated: 2026-06-23
stars: 65
repo: Johell1NS/browser-search
tags: [agent-skill, web-search, anti-bot, self-hosted]
last_verified: 2026-06-23
---

# browser-search

> SKILL.md-based instruction set that teaches AI agents to search and browse using three orchestrated tools. Self-hosted, free, unlimited.

**Repo**: [Johell1NS/browser-search](https://github.com/Johell1NS/browser-search) | 65⭐ (1d, 06-22) | JavaScript | MIT

## Architecture: Three-Phase Escalation

1. **SearXNG** (Docker, :8080) — metasearch engine for initial search phase. JSON output. Fast (milliseconds).
2. **Camofox** (Docker, :9377) — Firefox browser via REST API. Navigate, click, eval JS, Readability.js extraction (~70% token savings).
3. **CloakBrowser** (npm) — stealth Chromium for anti-bot protected sites. Auto-detects Cloudflare/Akamai/DataDome and waits for challenge resolution.

Flow: Search → browse → stealth browse (escalation on block detection).

## Notable

- Runs on Raspberry Pi (lightweight)
- "Deep Research" mode instruction in SKILL.md
- Works with OpenCode, Claude Code, Cursor, [[OpenClaw]]
- All Docker-based, no API keys

## Key Pattern

> Three-tier escalation: fast-cheap → normal → stealth. Agent decides tier automatically. No human intervention. This is the [[progressive-degradation]] pattern in reverse: progressive *escalation* based on resistance.
