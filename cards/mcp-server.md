---
title: "MCP Server"
created: 2026-08-01
tags: [architecture, agent-tooling, mcp]
last_verified: 2026-08-01
---

# MCP Server

An MCP (Model Context Protocol) server is a standalone process that exposes capabilities to AI agents through a standardized JSON-RPC protocol. It decouples tool implementation from the agent runtime, allowing any conforming client to discover and invoke tools without custom integration.

## How It Works

**Transport layer:**
- **stdio** — server runs as a subprocess; client communicates over stdin/stdout. Zero config, works everywhere, default for local dev.
- **HTTP+SSE / Streamable HTTP** — server listens on a port; supports remote and multi-tenant deployments.

**Primitives exposed by a server:**
- **Tools** — callable functions (e.g. `search_files`, `run_query`). The agent sees a JSON Schema for each tool and can invoke it.
- **Resources** — read-only data endpoints (files, database rows, API responses) the client can pull on demand.
- **Prompts** — reusable prompt templates the server offers to the client.

Clients discover capabilities via `initialize` → `tools/list` handshake, then invoke with `tools/call`.

## Key Implementations

| Server | Purpose |
|--------|---------|
| filesystem | Read/write/search local files |
| browser-mcp | Browser automation (Playwright-backed) |
| memex | Knowledge-base and memory retrieval |
| postgres / sqlite | Database query and schema introspection |
| github | Issue/PR/repo operations via GitHub API |
| fetch | HTTP requests with content extraction |

Anthropic maintains reference servers; the ecosystem has hundreds of community implementations.

## Security Considerations

- Servers run with the permissions of their host process — a misconfigured server can expose filesystem or network access.
- No built-in auth on stdio transport; HTTP servers need their own auth layer.
- Tool descriptions are model-visible — prompt injection via tool output is a real attack surface.
- Process isolation helps: a crashing or malicious server doesn't corrupt the agent's memory.
- Principle of least privilege: expose only the tools needed for the task.

## Relevance to Our Setup

MCP servers are how coding agents (Claude Code, Cursor, Windsurf) gain extended capabilities without forking the agent itself. Our wiki tracks which servers matter for agent workflows and where native tools remain preferable.

See also: [[mcp-vs-native-tools]], [[tool-calling]], [[agent-skill-ecosystem]], [[coding-agent-ecosystem]]
