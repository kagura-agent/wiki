# SmallCode — Coding Agent for Small Local LLMs

- **repo**: Doorman11991/smallcode
- **stars**: 1479 (05-27, was 848 on 05-21 — +74% in 6 days, breakout growth)
- **lang**: JavaScript (Node.js)
- **license**: MIT
- **status**: active | deep-read | ✓2026-05-21 (updated)

## What It Is

Terminal-native coding agent designed for small local models (7B-20B) on consumer hardware. While [[opencode]] and Claude Code assume frontier models with 128k+ context, SmallCode compensates for small model limitations through architecture.

Key innovations:
1. **Budget-managed context** — per-trace token and USD ceilings, auto-compaction
2. **Forgiving JSON parser** — repairs malformed tool call output from weak models
3. **TODO-file decomposition** — breaks tasks into steps via persistent TODO file
4. **Search-and-replace patch editing** — never rewrites full files (cheaper than full-file writes)
5. **Model escalation** — auto-escalate from local → cloud when local fails
6. **Governor** — Bayesian tool scoring that learns which tools work for which model
7. **Auto-validation** — compile/lint after every write, never delivers broken code

## Architecture — Cognition Layer (MarrowScript)

Uses a custom "MarrowScript" compiler that generates TypeScript from `.marrow` declarations. The cognition layer has 5 phases:

```
prompts → routing → budget → traces → validation + repair
```

### Deterministic Model Router
- Routes by task complexity (0-1 score) to tiered models:
  - trivial (≤0.3) → TinyClassifier
  - simple (≤0.6) → SmallCoder  
  - complex (>0.6) → MediumCoder
- **Escalation chain**: tier exhausted → try next tier → fallback to cloud
- Key: no dynamic dispatch, same input always selects same tier

### Repair Prompts (Core Innovation for Small Models)
- `on_invalid: retry_with_repair_prompt` — when model output fails validation
- Repair calls are **single-shot, smaller, more constrained** than original
- Pattern-specific guidance: detects common failure patterns (unterminated template literals, missing modules, undeclared types) and appends targeted fix instructions
- **This is the key insight**: small models fail predictably. The repair system learns the failure vocabulary.

### Budget Tracker
- Per-trace token/USD ceilings with pessimistic cost floors by model class
- Supports `charge()`, `refund()` (for rolled-back calls), `assertCanSpend()`
- Observable: metrics exported for monitoring

### Validation Modes
- `schema_only` — type/shape check against declared return type
- `ast_compiles` — runs tsc over output as if it were source
- `custom:<ext>` — user extension point
- All feed issues into repair prompt system

## Benchmarks (Self-Reported)

Claims 87% single-file task success with Gemma 4 E4B (~4B active params) vs ~75% for OpenCode with Qwen2.5-Coder-14B (3-4x larger model). Multi-file: 46% (60%+ with BoneScript scaffolding).

**Caveat**: benchmarks are self-reported, competitors are "estimated" not measured. Take with grain of salt.

## Issue Analysis (Critiques)

1. **Context overflow persists** — user reports "tool calling quickly exceeds 256k context with 9B model" (#10). The budget management isn't fully solving the core problem yet.
2. **Native dependency hell** — better-sqlite3 build failures on Node 26/macOS. Fixed by making it optional (v0.4.13).
3. **Community formed** — upgraded from 🔴 SOLO (0/6) to 🟢 THRIVING (5/6) by v0.7.0. External PRs merging.
4. **No unit tests** — still only stress tests in bench/, but v0.7.0 E2E verified against 5 multi-file projects (Python/TS/Rust/Go/C#).

## Comparison with Our Tools

| Aspect | SmallCode | Kagura/OpenClaw |
|--------|----------|-----------------|
| Target | Small local LLMs | Frontier (Claude) |
| Budget mgmt | Per-trace token/USD ceiling | None explicit |
| Repair system | Pattern-matched retry prompts | Not applicable (frontier doesn't need) |
| Tool scoring | Bayesian governor | Not applicable |
| Editing | Search-and-replace only | Claude Code handles |

### Relevance to Us
- **Low** — we use frontier models, most SmallCode innovations compensate for weak model capabilities
- **Budget tracker pattern** is well-engineered and could be useful if we ever add cost tracking to subagent spawns
- **Repair prompt with pattern-specific guidance** is a generalizable idea — could apply to our own tool output validation

## Ecosystem Position

- Competes with: [[opencode]], Pi Agent, Claude Code (different tier)
- Related concepts: [[context-budget-constraint]], [[forge-guardrails]] (same "make bad models good" thesis)
- Niche: local-first, privacy-conscious developers who won't use cloud APIs

## v0.7.0 Security Audit (2026-05-21)

Massive 86-bug audit covering security, context overflow, tool schema, and general fixes. +1539/-442 lines across 29 files.

### New: Centralized Security Module (`src/security/sanitize.js`)
287-line pure-function module providing:
- **Secret redaction** — 12 regex patterns covering OpenAI/Anthropic/GitHub/AWS/GCP/JWT/Slack/Discord tokens + env-style assignments + private key blocks. `ALWAYS_REDACT_KEYS` set for object property scanning.
- **Path containment** — `safeResolvePath()` with NUL-byte rejection, sensitive path blocklist (~/.ssh, ~/.gnupg, .env, .password-store, .docker/config.json, .kube/config), optional containment to project root.
- **Shell escaping** — `escapeShellArg()` cross-platform (POSIX single-quote / CMD double-quote). `buildCommand()` separates trusted prefixes from user args.
- **ANSI stripping** — comprehensive CSI/OSC/DCS/C1 removal. Used to prevent escape code injection into model context.
- **Line demuxer** — shared Readable stream listener to avoid EventEmitter accumulation in stdio MCP servers.

**Design principle**: "Stay under 300 lines so audit is feasible" — security code that's too large to audit defeats its purpose.

### SSRF Guard (origin-based)
- Default: only loopback + RFC1918 allowed
- **Always blocked** (even with `LLM_ALLOW_PUBLIC_ENDPOINTS=1`): link-local (169.254/16), CGNAT (100.64/10), cloud metadata (169.254.169.254, fd00:ec2::254, metadata.google.internal)
- Compares **origin** (scheme+host+port), not string prefix — prevents `api.evil.com.attacker.com` bypass
- Env override: `LLM_ENDPOINT_ALLOWLIST` for specific endpoints, `LLM_ALLOW_PUBLIC_ENDPOINTS=1` for production

### Context Overflow Fixes (20 bugs)
The context overflow problem (noted in #10) addressed through multiple mechanisms:
- Mid-turn eviction: `let` instead of `const` for eviction targets, respects tool_call_id pairing
- File injection capped at **15% of context window** in improvement loop
- Image base64 only from latest user message (was: every call — huge token waste)
- References capped at 8000 chars, git stat at 40 lines
- Compaction triggers at **80% budget**, compression target capped at 1500 tokens
- **2-stage routing**: sends only selector, not selector + all tools (significant savings for small contexts)
- Tool_call arguments truncated in old messages during eviction

**Key insight**: context overflow in small models isn't one bug — it's death by a thousand cuts. The fix is a systematic audit of every injection point, not a single compaction algorithm.

### Community Health Transformation
- **Was**: 🔴 SOLO (0/6) on 05-21 initial assessment
- **Now**: 🟢 THRIVING (5/6) — 4 unique merged PR authors, 11 issue authors/30d, 6 external PRs
- Contributors: Zireael (CI + branch fix), trufae (--endpoint flag)
- ACP integration requested (#20) — someone wants to connect SmallCode to [[acp]] via Zed editor

### RTK Integration (v0.6.14)
"Rust Token Killer" — auto-rewrites bash commands for 60-90% token savings. An optimization layer between the model's shell commands and execution, compressing verbose tool output before feeding back to context.

### What We Can Learn
1. **Centralized sanitize module pattern** — having one <300-line file that all persistence/export paths use is better than scattering redaction logic. Our workspace also handles secrets ([[pass-sops-credential-management]]) but lacks systematic tool output redaction.
2. **Context injection auditing** — SmallCode's approach of capping every injection point (15% file, 8000 char refs, 40-line git stat) is systematic. Our subagents don't have equivalent caps.
3. **SSRF guard with origin comparison** — the insight about comparing URL origins not string prefixes is a common pitfall. Worth checking if our web_fetch/browser tools have similar protections.
4. **"86-bug audit" framing** — counting and categorizing bugs in a security audit makes progress visible and scope clear. Good practice for our own audits.

## v1.0→v1.2 Breakout (2026-05-26 followup)

1,426⭐ (was 848 on 05-21, **+68% in 5 days**). Crossed v1.0 milestone.

### v1.0.0 — Production Baseline
Five reliability fixes from [mebassett fork](https://github.com/mebassett/smallcode):
- **Executor argument validation** — malformed tool calls no longer crash agent process
- **Poisoned history fix** — when all tool calls fail, bad messages spliced out to prevent death-spiral (model seeing own malformed output → producing more)
- **5xx retry** — llama-server transient failures handled
- **Max output tokens 4096→8192** — reasoning models emit 2k-6k `<think>` tokens before tool calls
- **Tool result truncation 4000→8000 chars** — real files fit in one `read_file`

Key: the fork-to-upstream pipeline worked. Community contributor surfaced real production issues.

### v1.1.0 — Contract / Definition of Done ⭐
**Most interesting feature.** MarrowScript-declared contract system:
- Per-project assertion list the agent commits to up-front
- Model **physically cannot** deliver "I'm done" while any assertion is `pending` or `failed`
- State persists to `.smallcode/contracts/<id>/state.json` with rendered markdown + `log.jsonl` audit trail
- `done_guard` policy: hard-fail, not behavioral
- Inspired by jukefr/itsy (downstream Rust port)

**Why this matters for us**: this is a structural constraint (cf. [[structural-backpressure]]) rather than a behavioral prompt. The agent doesn't "try to remember" to check completion — completion is gated.

**✅ Applied 2026-05-26**: Added "Definition of Done" structural completion gate to [[team-lead]] SKILL.md. Every task assignment now requires a `Done Contract` with checkable assertions (file scope, test exit codes, PR link). Agent must report each as ✅/❌ — ❌ means fix or escalate, not "done with caveats." Anti-patterns updated.

### Idempotent-Write Dedup
- Dedup module for read-only tool calls (sliding window, hash-based)
- Handles "small model spiral" — e.g., `memory_remember(same key)` called 36 times in one turn
- PURE_TOOLS whitelist (read_file, search, etc.) + separate idempotent-tools set (mutating but effect-idempotent within a turn)
- Configuration: `SMALLCODE_DEDUP=false`, `SMALLCODE_DEDUP_WINDOW=5`

### SSRF Hardening (External PR #39 by aaronjmars)
- IPv4-mapped IPv6 bypass closed (`::ffff:169.254.169.254`)
- Browser redirect bypass closed
- Both under "incomplete coverage of every representation the OS routes to the same destination"

### Community Explosion
- External PRs: security (aaronjmars), Willow skill pack (rudi193-cmd), path resolution (dmdeemer), mebassett fork fixes
- Issues: Chinese users (ollama), OpenWebUI users, TUI/UX feedback
- From 🔴 SOLO to 🟢 THRIVING 6/6 in ~2 weeks

### Relevance Update
- **Contract/DoD** pattern: HIGH relevance. Our subagent completion detection is behavioral ("agent says done"). SmallCode's is structural.
- **Dedup**: LOW for frontier models (don't spiral as much), but relevant for ACP sessions where tool calls can loop
- **Fork-to-upstream pipeline**: validation that community fork → upstream merge works as growth mechanism

---

## Broader Scout Findings (2026-05-21)

### Identity Layer Explosion
The agent identity/soul space is exploding. Beyond [[claude-soul]] (76⭐) and [[engram]] (47⭐, up from 34⭐ yesterday), 10+ zero-star repos launched this week all building identity/memory/soul layers. The category is becoming crowded — our DNA system has differentiation through production usage + self-governance.

### Structural Backpressure (Shen-Backpressure)
- HN frontpage (104pts): "Formal Verification Gates for AI Coding Loops"
- Thesis: type checkers, proof checkers, and linters as **structural constraints** beat **behavioral instructions** (prompts). Instead of telling the model "remember to check auth", arrange code so auth violations fail to compile.
- 35⭐, Go, by pyrex41. 2 months old.
- **Relevant insight**: we already do this informally (lint/test gates in workloop). The formalization of "structural backpressure" as a design principle for AI coding loops is worth naming.

### agents-best-practices (902⭐, 6 days)
No code (lang: null), pushed only on creation day. Likely just a SKILL.md/prompt collection riding the "agent skills" wave. 900+ stars for a static doc = the space is oversaturated with template repos.

### Qwen3.7-Max: The Agent Frontier
599pts on HN. Major model release positioned as agent-optimized. Couldn't extract blog content (JS-rendered).

### DCP (Device Context Protocol)
25⭐, 3 days old. Bridge LLM agents to physical devices. Sub-50-byte frames, <16KB MCU footprint. Complementary to MCP. Early but interesting direction — agents controlling hardware.

## Contract/DoD Evaluation for OpenClaw (2026-05-26)

Evaluated whether SmallCode's Contract/Definition-of-Done hard-gate pattern applies to our subagent completion detection.

**SmallCode approach**: Per-project assertion list declared up-front in `.marrow` files. Model physically cannot claim "done" while any assertion is `pending` or `failed`. State persists to `.smallcode/contracts/<id>/state.json` with full audit trail. This is [[structural-backpressure]], not behavioral prompt compliance.

**Assessment for OpenClaw**:
- Our `sessions_spawn` + `sessions_yield` already provides **structural completion** — subagent runs to completion and pushes result back through the runtime
- The gap is **quality**: subagent can "complete" without actually verifying its work (tests pass, lint clean, PR validates)
- Contract/DoD would help for complex multi-step tasks where we spawn [[Claude Code]] but want to ensure pre-defined assertions pass before accepting "done"
- Implementation path: pre-completion hook in ACP/subagent runtime checking declared assertion list

**Verdict**: NOT NOW. Our runtime handles structural completion; the quality gap is real but not yet a recurring enough problem to justify the infrastructure. When subagent quality becomes a pattern (3+ incidents of "completed but broken"), revisit.

**v1.2.1 status (05-26)**: 1,426⭐, pushed 05-24. 🟢 THRIVING (6/6). Community explosion continues.

## Plugin System (v1.2.2, PR#28+29, 2026-05-27)

1,495⭐. Major architecture addition: full plugin system shipped in 2 stacked PRs.

### Architecture

**PluginLoader** (~270 LOC, `src/plugins/loader.js`):
- Two plugin scopes: project (`.smallcode/plugins/`) + user (`~/.config/smallcode/plugins/`)
- Each plugin = directory with `plugin.json` manifest + JS handler files
- Single-file plugins also supported (JSON-only for prompt injection)
- Load order: project-level first, then user-level (project can override global)

**Extension points (6):**
1. **Tools** — custom tool definitions with handler functions, injected into model's tool list
2. **Commands** — `/slash` commands (e.g., `/provider` for runtime provider switching)
3. **Prompts** — system prompt injection (scoped: always/backend/coding/debugging)
4. **Hooks** — 7 lifecycle events: `pre_tool`, `post_tool`, `session_start`, `session_end`, `pre_request`, `post_request`, `on_error`. Filter by tool name.
5. **Providers** — `ProviderRegistry` singleton. Plugins register `IModelProvider` instances with capability declarations (tools/streaming/vision/tokenCounting). Runtime resolution: plugin → built-in → OpenAI-compat fallback.
6. **MCP Servers** — declare stdio MCP servers in manifest, lifecycle managed by plugin system

**Permission model** (declared but not yet enforced):
```json
{ "read": true, "write": true, "execute": false, "network": true }
```
TODO comment indicates enforcement not wired into tool execution pipeline yet.

### Provider Wizard (PR#29)
- Interactive `/provider` command for runtime provider switching
- Per-tier endpoint routing (PR#51): route requests to different endpoints by model tier
- Auth-header isolation: OpenAI keys not sent to DeepSeek when both configured

### Comparison with [[openclaw-plugin-nudge]]

| Aspect | SmallCode Plugins | OpenClaw Plugins |
|--------|------------------|------------------|
| Scope | Project + User | Per-gateway |
| Format | Directory + plugin.json | npm package + manifest |
| Safety | Declared permissions (unenforced) | Sandboxed hooks + approval model |
| Extension | Tools, commands, prompts, hooks, providers, MCP | Hooks, tools, channels, MCP |
| Model awareness | Prompt injection scoping | System event injection |

**Key insight**: SmallCode's plugin system is simpler (no sandboxing, synchronous require() loading, no approval model) — appropriate for a local-first tool where the user trusts their own plugins. The ProviderRegistry pattern (register at load, resolve by name at runtime, declare capabilities) is clean and minimal.

**Relevance to us**: LOW for direct adoption (different trust model), but validates the "manifest + handler files" pattern as sufficient for a plugin system. The prompt injection scoping (always/backend/coding/debugging) is more granular than our system event approach.

### Elephant Agent Parallel: Seatbelt Sandbox Hardening

Elephant Agent (PR#52) took the opposite approach to plugin safety — hardening the execution sandbox rather than the plugin load path:
- `SeatbeltPolicyBuilder`: composable macOS sandbox policy generation
- `.git/hooks` write-protect (prevents [[sandbox-escape-via-git-hooks]])
- Credential deny-read (~/.ssh, ~/.aws, ~/.gnupg, ~/.kube, ~/.docker)
- mach-lookup restricted to 4 essential services (was unlimited)
- IPC narrowed from all System V to POSIX semaphores only

This is complementary to SmallCode's approach: SmallCode trusts plugins but limits what the *model* can do; Elephant trusts the model but limits what the *sandbox* exposes. Different threat models, both valid.
