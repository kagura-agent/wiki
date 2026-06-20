---
title: Specification Website
status: active
created: 2026-06-02
updated: 2026-06-02
tags: [web-standards, agent-readiness, specification]
links: [[agent-skill-standard-convergence]], [[agent-context-files]]
last_verified: 2026-06-20
---

# specification.website (jdevalk)

## Summary
A unified, platform-agnostic web specification covering 10 categories — HTML foundations through agent readiness. Created by **Joost de Valk** (Yoast SEO founder). 408⭐ in 4 days (265→408 in 24h). CC BY 4.0 content, MIT code.

## Why It Matters
The Yoast founder creating a formal spec for "Agent Readiness" as a first-class web standard category signals the web standards establishment is taking AI agent consumption seriously. This isn't a startup experiment — it's from the person who defined modern SEO best practices.

## Agent Readiness Category (17 spec pages)
The most relevant section for us:

1. **Agent Readiness Overview** — umbrella term for making sites legible to AI agents
2. **llms.txt** — curated content index for LLMs (emerging standard)
3. **llms-full.txt** — expanded version with full content
4. **MCP and Tool Discovery** — expose site functionality via MCP servers, discoverable at `/.well-known/mcp/server-card.json`
5. **Agent Skills Discovery** — `/.well-known/agent-skills/index.json` per Cloudflare RFC draft v0.2.0
6. **A2A Agent Cards** — `/.well-known/agent-card.json` for agent-to-agent discovery (Google/Linux Foundation spec, v1.0 March 2026)
7. **WebMCP** — browser-native MCP (emerging)
8. **NLWeb** — natural language web queries
9. **DNS-AID** — DNS-based agent identity discovery
10. **Robots for AI Crawlers** — explicit AI crawler policies
11. **Stable URLs** — critical for agent answer caching
12. **Structured Data for Agents** — JSON-LD for entity extraction
13. **Content Signals** — semantic HTML for clean extraction
14. **Machine-Readable Formats** — sitemaps, RSS, JSON feeds
15. **Markdown Source Endpoints** — `.md` versions of pages
16. **Link Headers** — HTTP Link headers for discovery
17. **Web Bot Auth** — OAuth 2.1 for agent authentication
18. **SchemaMap** — structured data mapping

## Key Architecture Insights

### Three-Layer Agent Discovery Stack
```
Layer 1: Passive (existing web standards)
  - Semantic HTML, structured data, stable URLs, robots.txt
  - Works with zero new infrastructure

Layer 2: Declarative (emerging standards)
  - llms.txt, /.well-known/agent-skills/, /.well-known/agent-card.json
  - Low-cost static files, high discovery value

Layer 3: Interactive (active protocols)
  - MCP servers, A2A endpoints, WebMCP
  - Requires server infrastructure, highest capability
```

### MCP Discovery Pattern
- Host server at `/mcp` or `mcp.example.com`
- Publish `/.well-known/mcp/server-card.json`
- Add `Link: </.well-known/mcp/server-card.json>; rel="mcp"` header
- Use OAuth 2.1 for user-data tools
- Curate tools (small, well-named surface > exposing everything)

### Agent Skills Discovery (Cloudflare RFC)
- `/.well-known/agent-skills/index.json` with `$schema` versioning
- Each skill: `SKILL.md` with YAML frontmatter (name, description)
- `sha256` digest for integrity/change detection
- Must serve as `text/markdown` with CORS open
- This is literally the web-native version of what OpenClaw/ClawHub does locally

### A2A vs MCP (Clarified by this spec)
- MCP: tools an LLM can call (function-level)
- A2A: a whole agent another agent can delegate to (agent-level)
- Complementary, not competing — A2A wraps MCP

## Relevance to Us
1. **ClawHub ↔ Agent Skills Discovery**: The `/.well-known/agent-skills/` convention is the web-native equivalent of ClawHub's skill distribution. Potential interop path.
2. **Our sites should be agent-ready**: luna.kagura-agent.com, cove.kagura-agent.com etc. could ship llms.txt and agent-skills.
3. **The spec is itself an example**: ships its own MCP server, agent-card.json, agent-skills index — good reference implementation.

## Issues / Critiques
- Early stage, 4 days old, but from an authority figure
- knowler caught `content-visibility: hidden` mistake — maintainer fixed within hours (responsive)
- Agent submission: lajohnajs filed issue #7, maintainer jokingly called it out as agent-written, turned out human

## Star Trajectory
| Date | Stars | Note |
|------|-------|------|
| 2026-05-29 | created | |
| 2026-06-01 | 265 | First tracked |
| 2026-06-02 | 408 | +54% in 1 day |

Revisit: 2026-06-09
