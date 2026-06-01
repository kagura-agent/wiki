# Mirage — Unified Virtual Filesystem for AI Agents

- **Repo**: [strukto-ai/mirage](https://github.com/strukto-ai/mirage)
- **Stars**: 2,158 (2026-05-14; was 2,068 on 05-13, +4.3%)
- **Language**: Python + TypeScript (dual SDK)
- **License**: Apache 2.0
- **Company**: Strukto.AI

## What It Does

Mounts heterogeneous services (S3, GitHub, Slack, Discord, Gmail, Redis, MongoDB, SSH) as a single VFS tree. Agents interact using familiar Unix commands (`cat`, `grep`, `ls`, `cp`, `find`, `jq`) across all mounts. No new vocabulary needed — any LLM that knows bash can use it.

```
/s3/      → S3Resource
/github/  → GitHubResource
/slack/   → SlackResource
/data/    → RAMResource (ephemeral)
```

## Architecture Insights

- **MountRegistry** resolves paths to resources, **Workspace** dispatches ops
- **CommandSpec** system: each resource type can override commands per filetype (e.g., `cat` on `.parquet` renders JSON, not raw bytes)
- **Shell parse layer**: implements pipes, redirects, job control within the VFS — agents compose commands like real bash
- **Full bash interpreter** (v0.0.2-alpha): parameter expansion (`${X:-default}`, `${X#prefix}`, `${X//from/to}`, `${X:offset:length}`, etc.), arrays, `set -e`/`pipefail`, `readonly`, `VAR=val cmd` prefix scoping. 73 new tests per binding (Python + TS parity). 5,451 Python tests, 2,516 TS tests total.
- **Session + History**: tracks execution per agent per session, supports snapshot/restore
- **FUSE mount**: optional real FUSE layer so native CLI tools can access the VFS too
- **Cache layer**: file-level caching (RAM or Redis) with consistency policies (LAZY/STRICT)
- **Observer**: records agent interactions into a dedicated resource for observability

## Why It Matters

1. **Universal interface hypothesis**: instead of N tools/MCPs, give agents ONE abstraction they already know (filesystem + bash). Radical simplification of agent tooling surface.
2. **Composability through pipes**: `grep alert /slack/general/*.json | wc -l` — cross-service queries composed like shell pipelines. This is the [[thin-harness-fat-skills]] philosophy applied to data access.
3. **Snapshot portability**: clone/version agent environments. Relevant to [[agent-session-resume]] patterns.

## Tradeoffs

- **Impedance mismatch risk**: not everything maps cleanly to files (real-time streams, paginated APIs, write semantics)
- **Command surface explosion**: each resource needs custom command overrides per filetype — N resources × M filetypes × K commands
- **Startup cost**: created 05-06, v0.0.2-alpha as of 05-08. Maturing fast — 11 PRs merged in 3 days. Active development.
- **Filesystem metaphor ceiling**: works great for read-heavy agents, but interactive/write-heavy workflows (send message, create issue) feel shoehorned into file ops

## Relationship to Our Direction

- **Not a competitor**: Mirage is infra, OpenClaw is a runtime. Could be complementary.
- **Pattern worth watching**: the "one abstraction to rule them all" bet is bold. If it works, it validates that agents don't need MCP — they need good metaphors. [[mcp-vs-native-tools]]
- **Contrast with MCP**: MCP = give agents typed functions. Mirage = give agents a filesystem. Both reduce N-SDK complexity, but MCP preserves API semantics while Mirage forces filesystem semantics.

## Verdict

**Track** — 1,460⭐ in 4 days, fastest growth in portfolio. Now facing serious architectural scrutiny (5 critical issues filed by @eouzoe, a Rust/Nix/Firecracker infrastructure person). Growth is real but the gap between VFS promise and multi-agent reality is becoming visible. Key question: can they address isolation and cache correctness without breaking the simplicity that drives adoption? Revisit 05-14.

## Updates

- **05-09 PM**: 1,460⭐. **Critical architectural scrutiny**: @eouzoe (Rust/Nix/Firecracker background) filed 5 well-researched issues in one batch:
  1. **#15 Snapshot fidelity**: snapshot/load only captures RAM + config, not remote state. No version IDs/ETags tracked. "Portability" is overstated.
  2. **#16 Session isolation**: concurrent agents share all filesystem state. No COW, no branch-scoped views, no conflict detection. Fan-out patterns (ToT, Reflexion) need per-session delta layers.
  3. **#17 Credential blast radius**: all mount credentials colocated in one daemon. `MountMode.READ` is software-level, not a capability boundary. One prompt-injected agent can pivot to every mounted resource.
  4. **#18 Cache invalidation**: read-through cache with no write-through invalidation. Read-after-write returns stale cached bytes. Verified in code: `FileCacheMixin` has no `invalidate_on_write` hook. This is a correctness bug.
  5. **#19 Shell coverage gaps**: undocumented unsupported constructs (process substitution, here-docs, arithmetic expansion, brace expansion, job control). LLMs will reach for these and get silent failures.
  - **0 maintainer responses** after ~24h. Watch how they handle this — will determine project maturity trajectory.
  - **Lesson for us**: filesystem metaphor for agents is powerful but "works on the happy path" ≠ production-ready. Multi-agent isolation is the hard problem that separates toys from infrastructure. [[agent-isolation]] [[capability-scoping]]
- **05-09 PM update**: 1,487⭐ (+1.8%). PR#10 "agents prompt isolation" merged — **misleading title**: actually dependency isolation between agent backends (pydantic_ai, openai_agents, langchain), not session isolation. Extracted shared `MIRAGE_SYSTEM_PROMPT` into `prompts.py`, added tests ensuring each backend can import without cross-dependencies (e.g., pydantic_ai works even if deepagents not installed). 6 test cases including module-blocking fixtures. v0.0.2-alpha version bump. New bug: #14 (grep mount path breaks file reads). Critical arch issues #15-#19 still open with **0 maintainer response** after ~48h. Growth decelerating (2%/day vs 12%/day earlier). New issue from community (@SaguaroDev) = real users hitting real bugs now.
- **05-10**: 1,686⭐ (+13%, reaccelerating). **Maintainer responding to critiques.** PR#22 fixes issues #17/#18/#19 (credential isolation, session isolation, cache invalidation — the @eouzoe issues). PR#23 adds `Session.fork()` for proper session propagation (allowedMounts inherit to child sessions). Both Python and TypeScript ports updated. This is a significant maturity signal — the project is taking architectural criticism seriously rather than ignoring it. Growth re-acceleration may be tied to demonstrating responsiveness.
- **05-10 PM**: 1,695⭐. **Deep read of PR#22+#23 capability enforcement implementation:**
  - **ContextVar/AsyncLocalStorage pattern**: Session capabilities propagate implicitly through async boundaries via Python `contextvars.ContextVar` and TS `AsyncLocalStorage`. Enforcement at 3 chokepoints (dispatch, handle_command, ops._call), all calling shared `assert_mount_allowed()`. Elegant — no need to thread session tokens through every function call. [[agent-isolation]]
  - **Infrastructure prefix auto-grant**: `/dev`, `/_default` (cache), `/.sessions` (observer) always allowed, preventing UX frustration when `wc -c` fails because cache mount wasn't explicitly allowed.
  - **Test-as-contract**: 255 lines of capability tests covering every shell composition vector: pipes, command substitution, subshells, `&&`/`||` chains, redirects, cross-mount cp, concurrent sessions (`asyncio.gather`), background jobs. Most thorough capability enforcement test suite in agent ecosystem.
  - **Session.fork()**: Deep-copies all state (env, arrays, readonly_vars, shell_options, allowedMounts). Future Session fields auto-propagate. Eliminates manual `new Session({...fewFields...})` footgun that caused the original vulnerability shape.
  - **Cache write-through**: `invalidateAfterWriteByPath()` drops file cache AND parent directory index. Closes stale-readdir gap.
  - **Maturity signal**: 0 responses → comprehensive fixes in ~48h. 1420 pytest cases pass. Both Python+TS ports updated. Community growing (PR#21 Notion support from external contributor).
  - **Relevance**: OpenClaw has process-level isolation (layer 4 vs mirage's layer 2), but the test design patterns for capability enforcement are excellent reference. The ContextVar pattern could be useful for in-process capability propagation.
- **05-14**: 2,158⭐ (+4.3%). **Snapshot drift detection shipped** (PR#32, closes #15 — the @eouzoe fidelity issue). Major feature:
  - Per-path fingerprints (ETag + Revision) recorded at snapshot time
  - `ContentDriftError` raised under STRICT drift policy when remote content changes between snapshot and load
  - Resources opt-in via `SUPPORTS_SNAPSHOT` capability (S3, R2 currently). Live-only resources (Gmail, Slack) surface warnings
  - `pin_revision(path, rev)` lets backends (S3) serve exact recorded version. OFF policy skips pins entirely
  - Parallel drift checking via `asyncio.gather` — N-path latency drops from N*RTT to ~1*RTT
  - Refactored recording: single `Recorder` ContextVar (frozen, per-task), `OpRecord` carries `mount_prefix` explicitly
  - `Workspace.snapshot` and `Workspace.copy` now async (await stat() on touched paths)
  - Integration tests against real S3 buckets (auto-skip when env missing)
  - PR#41 follow-up: `Revision` on `OpRecord`, `Mount.revisions` for cleaner pin API
  - **Significance**: This was the #1 architectural gap (@eouzoe's most pointed critique). Snapshot now means something — deterministic replay of agent state across time. All 5 @eouzoe issues (#15-#19) now addressed. Project has proven it can absorb hard criticism and ship fixes.
- **05-20**: 2,446⭐ (+13.4% in 6 days). Community: 🟢 THRIVING (6/6), 163 forks, 21 issue authors, 14 external PRs/30d. Four major changes:
  1. **Three-mode daemon auth** (PR#63, +2509/-25): local (auto-mint file token at 0o600), token (operator PAT), JWT (RS256/ES256 with Clerk-compatible claims). Hard rules: `alg:none` rejected, `exp` mandatory, algorithm pinned to config (defeats alg-confusion), signature verified before any claim read. `/v1/health` bypasses auth. ASGI middleware with `hmac.compare_digest` for constant-time comparison. Python `StrEnum` for `AuthMode`, TS const-object pattern. 35 new auth tests + CI smoke for all 3 modes. [[agent-isolation]]
  2. **DNS rebinding fix** (PR#58): custom `HostHeaderMiddleware` replacing Starlette's `TrustedHostMiddleware` — adds rejection logging. Loopback-only default allowlist. CWE-346/350. Detected by Aeon + semgrep. Both Python (ASGI) and TS (Fastify onRequest hook) ports. [[capability-scoping]]
  3. **Generic command consolidation** (PR#68, +15,751/-9,836): extracted 57 generic modules from ram/disk/redis backends via dependency injection (VFS callables: read_bytes, read_stream, write_bytes, stat, readdir, mkdir). Backend wrappers reduced to thin shims. Net -7,772 lines. 240-case cross-backend integration harness comparing ram/disk/redis output against committed truth.txt fixture. Bug fixes: disk/md5 format, disk/sort multi-path, disk/awk BEGIN/END, disk/unzip directory preservation, rg auto-recurse, diff GNU normal format. [[thin-harness-fat-skills]]
  4. **S3 key_prefix** (PR#60): multi-tenant bucket subpath scoping. Agent-facing paths remain prefix-free. Normalization at config construction. Extracted key-prefix helpers into `utils/key_prefix` for reuse by R2/GCS/Dropbox backends.
  - **Architecture insight**: the dependency-injection pattern for generic commands is elegant — instead of 3 copies of `cat` (ram/disk/redis) with subtly different bugs, one generic implementation accepts callable interfaces. The cross-backend truth.txt harness ensures parity. This is the [[thin-harness-fat-skills]] principle applied to VFS internals.
  - **Security posture leap**: from "daemon ignores auth" to three-mode auth + Host validation in one sprint. The design doc approach (docs/plans/2026-05-17-server-auth-design.md) shows planning-before-coding maturity.
- **06-01**: 2,833⭐ (+8.2%, was 2,618). Pushed today. 192 forks (+13 in 5d). Key activity:
  - **OneDrive/SharePoint backend** (PR#139): versioned, snapshot-capable. External contributor @zechengz building new backends — community-driven expansion of the VFS surface.
  - **Databricks volume safety** (PR#142): prevent mv/cp onto same path from deleting the file. Classic filesystem edge case that VFS must handle correctly. External contributor @sonhmai.
  - **Growth trend**: consistent 7-8% weekly, up from infra burst in mid-May. Community contributions diversifying beyond core team — 3 distinct external contributors in latest PRs. 🟢 THRIVING.
  - **Ecosystem position**: solidified as the leading "filesystem metaphor for agents" project. No real competitors in this specific niche. The question isn't IF agents need unified data access, but WHICH abstraction wins (VFS vs MCP vs direct API). Mirage betting on VFS and growing.

## Ecosystem Observation (06-01)

Scout round shows content/skill projects dominating new repos (XHS card skills 2.1K⭐, illustration skills 1.5K⭐, edu skills 212⭐). Infrastructure layer settling — no new breakout infra projects. The "skill as content template" pattern (generate cards/images/docs) is where stars are flowing, not "skill as capability" (tools/integrations). This validates our focus on execution quality over content generation.

**Portfolio health**: 5 active tracks remaining (mirage, oh-story-claudecode, agentops, kiwifs, reversa) + 3 deferred (quarqlabs/agent-oss, mercury-agent-skills, ironcurtain). Dropped 3 this round (poco-claw, eval-view, letta-evals). Portfolio is consolidating — tracking fewer, higher-signal projects.
