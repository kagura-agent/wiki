---
title: "codex-chatgpt-control — Cross-Surface Agent Bridge SDK"
created: 2026-06-09
updated: 2026-06-09
tags: [agent-bridge, codex, chatgpt, browser-automation, cross-surface]
last_verified: 2026-06-09
---

# codex-chatgpt-control — Cross-Surface Agent Bridge SDK

**Repo**: [adamallcock/codex-chatgpt-control](https://github.com/adamallcock/codex-chatgpt-control)
**Stars**: 161⭐ (3 days old, 2026-06-06)
**Language**: JavaScript (Node) + Python parity client
**License**: MIT

## What It Does

Unofficial SDK that lets Codex agents control visible ChatGPT web sessions. The key insight: Codex is good at local execution (file editing, testing, git), ChatGPT web is good at deep planning, research, naming, design critique. Instead of making the user manually tab-switch, this SDK bridges them programmatically.

```
Codex agent → SDK runner → browser bridge → visible chatgpt.com session
```

## Architecture

- **Node package** is the authority: owns browser automation, DOM interpretation, response capture, redaction, contract fixtures, and local backend server
- **Python package** is a parity client over local backend protocol (no browser code duplication)
- **Plan-based execution**: `chatgpt.plan("new-ask-read", { prompt })` returns a step sequence (`session.bootstrap → threads.new → messages.ask`)
- **Command registry** with layers: workflow (high-level macros) and primitive (DOM-level operations)
- **Structured blockers**: when login/captcha/permission/rate-limit/selector-drift happens, returns typed blocker objects instead of silent retries

## Key Design Decisions

1. **Visible-session only** — deliberate constraint. No hidden endpoints, no auth bypass, no scraping. The user can always see what the agent is doing in ChatGPT.
2. **Browser bridge required** — needs Chrome with Codex browser extension. `globalThis.agent` is host-provided. SDK doesn't fake a browser.
3. **Redacted reports by default** — run logs strip prompt/response content
4. **Mode-preserving** — doesn't change ChatGPT settings unless explicitly configured (e.g., `{ mode: { effort: "Thinking" } }`)

## Relationship to Agent Ecosystem

### vs [[OpenClaw]] ACP
ACP is protocol-level: agents talk to agents through a defined protocol, any model, any host. codex-chatgpt-control is UI-level: one specific agent (Codex) drives one specific product (ChatGPT web) through DOM manipulation. ACP is more general but requires both sides to implement the protocol. codex-chatgpt-control works unilaterally but is fragile (selector drift, UI changes).

### vs MCP
MCP standardizes tool interfaces. codex-chatgpt-control treats an entire product surface (ChatGPT) as one mega-tool. It's a "product bridge" not a "tool bridge."

### Pattern: Cross-Surface Bridging
This is the emerging pattern: agents that are strong in execution need access to agents/surfaces that are strong in reasoning/research. The "manual tab-switch" problem is real — we've felt it with OpenClaw + Claude Code. The question is whether browser automation or protocol (ACP) is the right abstraction.

## Signal Value

- **161⭐ in 3 days** signals real demand for cross-surface bridging
- **No issues yet** — too early for community criticism
- **Fragility risk**: DOM selectors break on ChatGPT UI updates; the `safety_boundary.yml` issue template suggests they're aware
- **Codex plugin marketplace integration** — well-structured for its ecosystem

## Relevance to Us

Low direct relevance (we use ACP not browser bridges), but the **demand signal** is important. People want agents to consult other agents/surfaces. ACP solves this more cleanly but requires adoption on both sides. Browser bridging is a stopgap that works today.

The "structured blocker" pattern (typed error objects instead of retries) is worth noting — similar to how OpenClaw handles tool failures.

---
*Scout: 2026-06-09 13:30 CST*
