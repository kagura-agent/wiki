---
created: 2026-06-05
tags: [pattern, performance, architecture]
last_verified: 2026-06-05
---
# Gateway Cold Start Optimization

Pattern from [[nanobot]] PR #3918: reducing gateway startup time by ~90% (4.6s → 480ms) and memory by ~82% (211MB → 39MB) through systematic lazy loading.

## Three Strategies

### 1. Channel Lazy Load (biggest win: 3170ms → 35ms, -156MB RSS)

- `discover_channel_names()` does cheap `pkgutil` scan for channel module names
- `discover_enabled(enabled_names)` only imports modules matching the enabled set
- Skips ~16 unused channel modules and their heavy SDK deps (telegram, discord, slack, aiohttp, requests)
- These skipped modules **never enter the process** for the entire gateway lifetime

**Key insight**: pkgutil scan to discover names is O(n) filesystem reads with no imports. Filter to enabled set, then import only those. Same pattern would work for OpenClaw's skill/channel loading.

### 2. Lazy OpenAI Client (638ms → 8ms, -15MB RSS)

- Defer `AsyncOpenAI()` and `httpx.AsyncClient` construction from `__init__` to `_ensure_client()`
- `_ensure_client()` is async with `asyncio.Lock` double-checked locking
- `openai` and `httpx` imports moved from module-level into `_ensure_client()`
- For idle/low-traffic gateways, this memory is never allocated

### 3. PEP 562 `__getattr__` for Module Exports

- `nanobot/__init__.py`: `Nanobot`/`RunResult` exported lazily
- Minor savings but clean pattern for avoiding import chains

## Results

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| Total startup | 4550ms | 476ms | -89.5% |
| Total RSS | 211MB | 39MB | -82% |
| Modules loaded | 11,243 | 595 | -95% |

## Broader Pattern: Import-Time Cost Awareness

The root cause was **import-time side effects**: constructing clients, loading SDKs, building registries — all in module-level or `__init__` code. The fix is systematic: audit what happens at import time, defer everything that isn't needed for startup.

**95% module reduction** means the original codebase was loading ~10,000 modules it didn't need at startup. This is common in Python projects with many optional integrations.

## Relevance to OpenClaw

OpenClaw (Node.js) has similar patterns:
- [[skill-lazy-loading-poc]] — already explored for skills
- Channel plugins loaded at startup regardless of enabled state
- Provider clients constructed eagerly

The nanobot benchmark methodology (clean subprocess, psutil RSS, sys.modules count) is worth adopting for OpenClaw startup audits.

Links: [[nanobot]], [[skill-lazy-loading-poc]], [[warm-start-agents]]
