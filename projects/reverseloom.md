---
title: reverseloom
repo: KuiChi-x/reverseloom
category: Browser Agents
status: tracking
stars: 23
first_seen: 2026-07-19
last_verified: 2026-07-19
---

# reverseloom — Browser Agent + JS Reverse Engineering → Browser-Free Crawlers

**Repo:** [KuiChi-x/reverseloom](https://github.com/KuiChi-x/reverseloom)
**Stars:** 23 (2026-07-19, 3 days old)
**Language:** Python + Node.js (sandbox)
**License:** Apache 2.0
**Built on:** [[graphloom]] (same author's agent framework)

## What It Does

Automates the full web scraping reverse-engineering pipeline:
1. **Get in** — browser automation with anti-detection (pairs with kc-browser for C++ kernel-level fingerprinting)
2. **Reverse** — CDP breakpoints + JS debugger to trace how signed/encrypted params are generated
3. **Ship** — generates standalone browser-free Python crawlers that run cold-start

The key insight: existing browser agents can *interact* with pages but can't *reverse-engineer* the protocols, so crawlers remain browser-dependent. reverseloom closes that loop.

## Architecture Insights

### Observer Overwrite-Injection ([[observer-pattern]])

The most transferable pattern. Browser state (DOM digest, screenshot, network, debugger state) is captured fresh each turn and injected as `observer_message_parts` with **overwrite semantics** — never stored in `past_steps`. This solves the context-window explosion that plagues other browser agents where screenshots pile up in history.

```
observer_message_parts → injected per turn (overwrite)
past_steps → only reasoning/actions (never browser state)
```

This is relevant beyond browser agents — any agent working with large, changing external state (terminal output, file diffs, database views) could benefit from this pattern. Compare with [[byob-chrome-reuse-mcp]] which uses a different approach (MCP tool returns).

### CDP Debugger as First-Class Agent Tools

Not just page automation — full JS debugging as agent capabilities:
- `set_line_breakpoint` / `break_on_request` — set breakpoints on code or network patterns
- `evaluate_in_call_frame` — inspect variables at breakpoint
- `step_execution` — single-step through code
- `get_script_source` / `search_in_js_codes` — source analysis

This makes the agent capable of reverse-engineering obfuscated JS — tracing how a `bm-telemetry` header is generated, reproducing the algorithm in a sandbox.

### Node Sandbox with Anti-Detection Armor

jsdom environment with multi-phase armor to make the sandbox indistinguishable from a real browser:
1. **markNative** — wraps functions to pass `toString()` checks (returns `[native code]`)
2. **Timer wrapping** — Chrome-compatible numeric IDs instead of Node.js Timeout objects, with randomized starting ID
3. **prepareStackTrace** — installed for clean error stacks, then **deleted** before target code runs (V8-specific detection vector)
4. **jsdom internal property hiding** — hides `_globalObject` etc. from `in` operator
5. **Deep Proxy monitoring + Phantom Chain** — records all API calls for replay analysis

Anti-counter-intuitive finding: `Error.prepareStackTrace` is a V8/Node-only API. Real Chrome doesn't expose it. So the sandbox installs it for clean error formatting, uses it, then deletes it before the target script can probe for it.

### CdpHandler per-Page Isolation

One `CdpHandler` per browser page, not per session. Multi-tab sessions are naturally isolated — switching tabs picks a different handler. Each handler owns: cdp_session, network_logs, script_registry, OOPIF iframe caches, debugger pause state. Clean separation.

## Three-Project Family

| Project | Layer | Purpose |
|---------|-------|---------|
| kc-browser | Get in | C++ Chromium kernel-level anti-detect fingerprint |
| **reverseloom** | Reverse | CDP + sandbox → browser-free crawler |
| graphloom | Drive | Agent framework: observer, compaction, skills |

## Tradeoffs & Risks

- **jsdom fidelity gap**: WebGL, Canvas 2D, WebRTC, complex CSS — all missing or partial in jsdom. Heavy sites will hit sandbox limitations
- **Arms race**: anti-detection armor needs constant updates as fingerprinting evolves
- **Solo dev, 3 days old, 0 issues**: extremely early. High risk for abandonment
- **Legal gray area**: reverse-engineering anti-bot systems is legally complex (ToS violations, CFAA in US)

## Relation to Our Direction

- **Observer overwrite-injection** is directly applicable — worth considering for any agent that works with large, changing external state. Our [[browser-automation]] skill could benefit from this pattern instead of accumulating screenshots
- **CDP debugging tools** — interesting capability expansion direction but not our current focus
- **Sandbox anti-detection** — fascinating engineering, too domain-specific for us

## Prediction

Solo dev + niche use case + legal concerns → likely stays small (<200⭐) unless kc-browser gains traction as the more broadly useful sibling project.
