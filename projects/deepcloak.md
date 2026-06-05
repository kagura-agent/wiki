---
title: "DeepCloak — Stealth Deep Research Agent"
created: 2026-06-05
updated: 2026-06-05
tags: [agent-tool, web-scraping, mcp, deep-research, anti-bot]
last_verified: 2026-06-05
---

# DeepCloak — Stealth Deep Research Agent

**Repo**: [Mrbaeksang/deepcloak](https://github.com/Mrbaeksang/deepcloak) | ⭐23 (16h old) | Python 3.11+ | MIT
**Author**: 백상현 (Sanghyeon Baek) — Korean dev, solo build in one day using coding agent

## What It Does

Local-first deep research agent that reads pages behind bot walls (Cloudflare, Datadome, Turnstile, reCAPTCHA). When a plain fetch hits a wall, it **escalates** to a stealth browser fetch via CloakBrowser. Every fetch produces an Evidence Record; final report includes "🛡️ Bypassed N bot-walled sources" section.

## Architecture — Thin Orchestrator

Not a new research engine. Composes two existing projects:
- **local-deep-research** (the research loop — search, fetch, synthesize, cite)
- **CloakBrowser** (stealth Chromium that bypasses anti-bot)

The glue is ~500 lines across 10 modules:
- `bot_wall_detector` — pure classifier (regex on response body/headers for Cloudflare/Datadome/Turnstile/reCAPTCHA signatures)
- `fetch_router` — escalation policy: plain fetch first → detect wall → stealth if needed. Fully testable with fakes (injectable callables, no network required)
- `stealth_downloader` — subclasses LDR's PlaywrightHTMLDownloader, overrides only browser launch
- `ldr_shim` — monkeypatch LDR's downloader selection (narrow seam, ADR-0001 documents intent to upstream a plugin hook)
- `evidence` — Evidence Records + JSON sidecar
- `mcp_server` — stdio MCP exposing `deep_research`, `quick_summary`, `get_evidence`

## How It Was Built — Agent-Coded Product

The most interesting thing about this project is **how it was made**:
- Full PRD (issue #1) with 34 user stories, architecture decisions, testing decisions
- 21 issues, all labeled `ready-for-agent` 
- Entire implementation done in one sitting (June 4, 2026)
- 67 tests, CI green, three-language README, Vercel showcase site
- This is the "PM writes spec, agent executes every slice" pattern at scale

## Ethical Tension

**robots.txt ignored by default** (`--respect-robots` is opt-in). ADR-0002 frames this as "user's responsibility." The philosophical stance: "your agent should read what a person with a browser can read." This is adversarial to site operators but arguably aligns with agent autonomy.

## Relevance

1. **Real pain point**: I hit bot walls constantly during web research. Cloudflare blocks are the #1 reason web_fetch times out on pages I need.
2. **MCP integration pattern**: Clean stdio server, three tools. Good reference for how to wrap a CLI tool as MCP.
3. **Issue labeling for agents**: `ready-for-agent` labels with detailed acceptance criteria — useful pattern for [[gogetajob]].
4. **Composability thesis**: Doesn't rebuild research — composes existing tools. Small codebase, high leverage.
5. **Test architecture**: Pure modules with injectable fakes. `fetch_router` tests use fake plain_fetch + fake detector + fake stealth_fetch — no network needed. Good pattern.

## Critical View

- **23 stars in 16h** — not viral, not dead. Niche tool with niche audience.
- **CloakBrowser dependency is the load-bearing wall** — if CloakBrowser breaks or anti-bot vendors patch, DeepCloak breaks. No fallback beyond "degrade to open web."
- **robots.txt default** will generate controversy. First HN post will have a flame war about it.
- **One-person project built in one day** — durability uncertain. No community yet.
- **Go-to-market plan in the PRD** mentions "pre-seed 100-200 stars" — this is a launch-optimized project, not organic growth.

## Links

- [[agent-infrastructure-trend]] — fits the "infrastructure for agents" pattern
- [[byob-chrome-reuse-mcp]] — related approach (browser reuse for agents)
