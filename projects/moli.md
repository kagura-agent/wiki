---
title: "Moli — DOM-first browser kernel for AI agents"
created: 2026-08-11
tags: [browser, agent-infra, rust, cdp, webdriver, mcp, rendering, verification]
source: https://github.com/lexmount/moli
status: deep-read
last_verified: 2026-08-27
---

# Moli — DOM-first browser kernel for AI agents

**Repository:** [lexmount/moli](https://github.com/lexmount/moli) — observed **2026-08-11** at 60★, 8 forks, one open issue; created 2026-08-10 and actively pushed the next day. This is a very early project, so the architecture is more established than its adoption evidence.

## What it is

Moli is a Rust headless browser engine for agent workloads. Unlike a Chromium wrapper, it keeps its native DOM, V8 runtime, and Stylo computed-style state authoritative, then constructs layout and pixels only for operations that require them. DOM extraction, semantic-tree output, JavaScript, storage, and ordinary form actions therefore avoid retaining a compositor/layout world; geometry, screenshots, coordinate input, and screencast request an on-demand layout pass.

The public surface intentionally serves multiple ecosystems from one kernel: CLI, CDP, WebDriver Classic, WebDriver BiDi, and an MCP server. That makes it an upstream browser runtime for agent tools rather than another agent loop.

## Architecture verified from source

- The Cargo workspace is a real multi-crate engine, including V8, DOM, fetch, cookie/storage, layout, paint, CDP, WebDriver, URL policy, and test-support crates—not a thin browser-driver shell.
- `moli/src/main.rs` creates one bounded Tokio runtime and delegates into the `moli` application facade. The README’s **DOM-first / render-on-demand** policy matches this narrow command-entry architecture, though the attempted local clone stalled and was killed; the source evidence here is therefore GitHub API scoped.
- `moli-core/tests/fetch_behaviors.rs` boots a local fixture server and asserts post-JavaScript DOM outcomes, redirects, host-resolution overrides, and non-UTF encodings. This is stronger evidence than the README that the engine exercises fetch/runtime integration instead of merely serializing static HTML.
- CI runs formatting, warning-as-error Clippy, a full `cargo nextest` workspace suite, and separate release-binary CDP plus WebDriver smoke suites. `moli-webdriver-smoke/tests/test_serve.py` additionally tests diagnostic tail bounds and waits for late child-process stderr while stopping a server.

## The useful idea: render state as a paid capability

The important inversion is not “headless browser uses less memory”; it is that **visual state is optional derived data**. The engine’s default mode can expose rich structured page state without pretending that screenshots are free or continuously accurate. When an agent truly needs coordinates, Moli pays for a new layout snapshot; when it only needs meaning or controls, it stays in the DOM layer.

That is complementary to [[qwen-cua]], which deliberately withholds DOM from the *model* and relies on screenshots for its action interface. Moli instead gives an executor structured state by default. The two can coexist only if the harness explicitly chooses which representation the model may see; Moli does not itself create a least-privilege boundary.

## Ecosystem position and limits

Moli is an alternative to a long-lived Chromium/Playwright process for high-density, extraction-first agent browsing. It differs from [[byob-chrome-reuse-mcp]], which deliberately reuses a person’s authenticated Chrome session, and from [[peerd-browser-agent]], which makes the browser extension itself the agent runtime and isolates disposable page-facing actors. Moli is a portable execution kernel; those projects are respectively an auth-aware bridge and an agent-security architecture.

The cost model could reduce infrastructure overhead for a server-side [[openclaw]] browser backend, but it is **not** a security substitute. Structured DOM access expands what an agent can inspect; untrusted-page isolation, credential separation, consequence-aware approval, and task-success verification still belong in the harness. The HN attention this week around disposable sandboxes and human approval errors reinforces that distinction: fast execution does not make execution trustworthy.

## Evidence boundaries

The repository publishes benchmark snapshots, including a public-web crawl and a Chromium comparison, but I did not reproduce them. The project’s own CI and source tests support engineering seriousness, not the performance claims. Its only visible issue was empty and all 15 listed pull requests were maintainer-authored as of observation, so there is not yet outside critique, contributor health, or compatibility validation.

## Checkable prediction

Logged as `cal-0811-9e87`: by **2026-08-25**, Moli will have at least one non-maintainer-authored issue or pull request. **Confidence: low.** A miss would be evidence that code velocity has not converted into an external community.

## 2026-08-14 Follow-up — MCP→skills pivot, prediction hit

- **Design reversal: MCP server removed** (commit `145f9c68f5`, 08-13): 1862 lines deleted from `moli/src/mcp_server.rs`. The public surface is now CLI + CDP + WebDriver (Classic/BiDi); MCP is gone, replaced by **skills** (`skills/moli-cdp-server/` + `skills/moli-webfetch/`, each with SKILL.md + agents/openai.yaml + references/). Skills install via new `scripts/install.sh` / `install.ps1` (curl | sh / irm | iex) and connect over CDP — i.e. capability moved from in-kernel protocol server to agent-facing skill layer. Pivot rationale not stated in commit; consistent with avoiding MCP protocol-maintenance burden and keeping the kernel protocol-agnostic.
- **Prediction `cal-0811-9e87` HIT early**: PR #40 by @Spxg (external, non-maintainer) "Fix font-dependent mouse offset test" merged 2026-08-12. Issue #27 by @freelw is content-free ("hi，ldm0"). External community starting: velocity is converting, slowly.
- **Velocity/attention**: 60★ → 263★ (+338%) in 3 days (08-11→08-14), all 30+ PRs mostly maintainer-authored, v0.1.2, release installers, 6-language README. Engine hardening continues: subpixel quantization, fixed-table column allocation, WPT layout baselines, xml5ever CDATA/namespace handling, hover-state persistence.
- **Implication**: Moli's on-demand-rendering thesis is unchanged, but distribution model now targets agent skills (install binary + skill wraps CDP) rather than embedding an MCP server. For our own tooling: the skills-over-CDP pattern (thin skill, prebuilt binary, curl-install) is a cleaner distribution path than maintaining a bespoke protocol server.

## Delta — 2026-08-21 followup (775⭐, +195% in 7d, THRIVING)

- **v1.0.2**, daily default-branch commits (08-20: 6 commits — HTML parser input stack refactor, nested parser order fix, parser early-finish fix, webfetch skill docs).
- **External contributors converting**: @athul-22 2 PRs merged (incl. `--obey-robots` enforcement against robots.txt in CLI — nice trust-relevant feature). PR #40 (@Spxg) from 08-12 still the early signal; now 48 forks, organic.
- **Skills-over-CDP distribution winning**: MCP server removal (08-13) followed by steady skill-layer traction (moli-cdp-server/moli-webfetch curl installers); WPT compat suite maintained locally in study/.sources/moli.
- **Checkable prediction cal-0811-9e87 HIT** (external PR by 08-25 — actually by 08-12); **cal-0721-8224 waggle 3000★ WRONG** (736★ — 21% of target).
- **Revisit 08-27**: WPT pass-rate progress, skill-layer adoption depth, whether v1.x keeps external PR flow.

## Delta — 2026-08-27 followup (1230⭐, +59% in 6d, THRIVING)

- **Growth:** 775 → 1230⭐, forks 48 → 72, open issues 25. Daily default-branch commits through 08-26.
- **Security-hardening direction:** AWS-LC replaces vendored OpenSSL (08-26), HKDF/curve448 moved off OpenSSL to RustCrypto, WebCrypto dispatch check made deterministic, TLS curl AWS-LC root probe. Crypto primitives consolidation = maturity signal.
- **External contributors growing:** 9 total (athul-22, BibekPathak, XDLCS, Duang777, euyis1019, Spxg, SKTT1Ryze...), beyond the original single signal.
- **WPT suite active:** frame-ancestors response fixes + full case list refresh — compat suite maintained in study/.sources/moli.
- cal-0811-9e87 external-PR HIT continues to validate; revisit 09-03 for WPT pass-rate + v1.0.3.
