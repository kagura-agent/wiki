# MCPify — AI Enablement Compiler

## Overview

**MCPify** (amarnath3003/MCPify) — TypeScript CLI that auto-generates MCP servers from existing codebases. "Compile software into AI-operable systems."

- ⭐ 42 | Created: 2026-06-06 | MIT License
- npm: `mcpify-cli`

## What It Does

Scans a codebase and produces:
1. **MCP server** with typed tools from backend routes/controllers
2. **Frontend action extraction** — React/Vue/Svelte components → agent-controllable actions
3. **OpenAPI → MCP** conversion
4. **Workflow detection** — multi-step processes exposed as atomic capabilities
5. **Permission layer** — scopes, roles, audit trails at tool boundary
6. **Database intelligence** — Prisma/Drizzle/Mongoose schemas → queryable surfaces
7. **Self-updating sync** — regenerates on every commit

## Architecture

- Backend: AST analysis of routes, controllers, services
- Frontend: component action mapping
- Schema: Prisma, Drizzle, Mongoose adapters
- Output: runnable MCP server + AGENTS.md documentation

## Analysis

**Novel angle**: Most MCP tools are hand-written per-API. MCPify tries to automate the "make existing software agent-operable" step.

**Skepticism**: 
- 42 stars in 6 days = moderate traction, not breakout
- "AI Enablement Compiler" is ambitious naming for what's essentially code-to-MCP scaffolding
- Real test: does it handle non-trivial apps? The ecommerce example is their own
- Permission layer claims are interesting but unverified

**Relevance**: 
- For [[openclaw]]: if this works, it could reduce the effort to expose new services to agents
- Competing approach to [[agent-skills-eval]]: compile-time vs runtime skill discovery
- The "self-updating sync" claim is the most interesting — schema drift is a real problem

## Status

Following — revisit in 2 weeks to check traction and real-world usage reports.

Tags: #mcp #developer-tools #agent-infrastructure
