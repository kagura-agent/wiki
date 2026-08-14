# Noisegate — Differential Privacy Gateway for Untrusted AI Agents

> "Give an AI agent query access to sensitive data, with a mathematical guarantee that no individual's record can leak — even if the agent is adversarial." — yashmahajan10

- **Repo**: [yashmahajan10/llm-differential-privacy-gateway](https://github.com/yashmahajan10/llm-differential-privacy-gateway)
- **Stars**: 19 (2026-08-01)
- **Language**: Python (DuckDB + FastAPI + MCP SDK)
- **License**: Apache-2.0
- **Created**: 2026-06-30
- **Activity**: 30 commits, 33 PRs merged, solo dev, actively refining (last push 07-31)
- **Status**: scout | ✓2026-08-01

## Core Idea

The LLM/agent is **explicitly untrusted**. All privacy enforcement lives below the model in deterministic, testable code. The agent is treated as arbitrary untrusted input — same posture as any user input crossing a trust boundary, applied to an AI agent for the first time with mathematical guarantees.

## Architecture (3-layer trust model)

```
  NL question (untrusted) → LLM compiler (untrusted) → candidate AST
         → Validation layer (TRUSTED — trust boundary HERE)
         → Privacy engine (TRUSTED: sensitivity + clamp + Laplace noise + budget)
         → Noisy answer + confidence interval + remaining budget
```

### Key Components

1. **Constrained AST** (not SQL): Only COUNT/SUM/AVG/histogram. Makes sensitivity statically computable — this is WHY the grammar is restricted. Arbitrary SQL has unbounded sensitivity (JOIN/subquery).
2. **Validation layer**: Column allowlist, per-column operation allowlist, aggregates-only, declared range required for SUM/AVG, group-cardinality cap, filter-narrowing guard (rejects queries resolving to <k individuals).
3. **Laplace mechanism**: Hand-rolled, cross-validated against OpenDP to 1e-9 precision. Scale = Δf/ε. Confidence interval on every answer.
4. **Budget accountant**: Hybrid zCDP composition (308 queries vs 100 naive). Atomic charge-or-refuse. Budget refusal is a normal result (not an error — prevents retry attacks).

### MCP Integration

Runs as stdio MCP server for Claude Desktop. Identity baked in at build time (can't be spoofed by agent). Tool schemas generated from dataset policy — steers agent toward valid queries but enforcement is below.

## Novel Patterns

### 1. Attack Gallery as CI Proof

Ships 3 classic attacks that **succeed** with DP off and **fail** with DP on:
- **Differencing**: Two aggregate queries that differ by one person → exact recovery
- **Membership inference**: Determine if a specific individual is in the dataset
- **Singling out by re-identification**: Sweeney (2002) — ZIP+birthdate+sex uniquely identifies 87% of Americans

These are pinned in CI — the defense cannot quietly rot. "Working attacks, not claims."

### 2. "LLM as Untrusted Input" Posture

The design doesn't try to make the LLM behave correctly. It assumes the LLM is fully adversarial and proves that this changes nothing about the guarantee. A compromised compiler can degrade UX (nonsensical queries) but cannot cause a privacy violation.

### 3. Budget as Finite Resource

Privacy budget (ε) is consumed per-query and cannot be refreshed. When exhausted, the system refuses (doesn't add more noise). This is information-theoretic — "continuing to answer is what leaks."

### 4. Confidence Intervals on Every Answer

Every answer comes with a calibrated confidence interval: "the true value is within ±X with 95% probability." Honesty by default.

## Relevance to Our Direction

| Theme | Connection |
|-------|-----------|
| [[agent-security]] | New angle — mathematical privacy vs access control. Complementary to [[clawpatrol]] (which does tool-level gating) |
| Trust boundaries | "LLM as untrusted input" is the correct mental model for any agent architecture. Most frameworks assume their own LLM is trusted. |
| [[openclaw]] | Could inform how OpenClaw plugins handle sensitive user data — not just "can the agent access it" but "how much can the agent learn from it" |
| Attack-as-test pattern | "Ship the exploits that would break your claim, pin them in CI" — applicable to any security property |

## Counter-intuitive Findings

1. **Restricted grammar enables privacy, not limits it.** The constrained AST isn't a compromise — it's what makes the math possible. Without bounded sensitivity, no finite noise works.
2. **Budget refusal is a feature, not an error.** The agent being told "no more questions" IS the privacy guarantee in action. Retry is the attack.
3. **19 stars ≠ low quality.** This is a rigorous, well-documented system. Low stars because it's niche (DP + MCP intersection) and just hit HN (07-31).

## Limitations / Open Questions

- Solo dev, 0 community (no issues, no external contributors)
- Only supports single-table analytics (no JOINs by design, but this limits use cases)
- Identity is per-stdio-session; no robust multi-tenant identity without a separate auth layer
- Filter guard is structural heuristic, not DP — a sufficiently clever filter could still target small groups (mitigated by budget, not eliminated)
- No streaming / incremental answers — full budget charge per query

## Predictions

- If the author posts on HN properly, could reach 200+ stars (the README quality alone warrants it)
- The "attack gallery as CI" pattern will be adopted by other security-focused agent projects within 6 months
- Solo dev + no community = fragility risk; watch for stagnation after initial burst

## Deep-read update — 2026-08-05

- **The test suite proves the negative at the real boundary.** `test_validation.py` sends adversarial ASTs directly to `Validator`, deliberately bypassing MCP schema guidance and any LLM compiler. That makes the important claim falsifiable: generated tool schemas are ergonomics, whereas policy enforcement is the deterministic authority.
- **Its composition upgrade preserves migration safety as a data invariant.** `HybridZCDPComposition` persists named pure-ε and ρ ledgers; when upgrading an old pure-ε record, it reconstructs ρ as `spent_epsilon² / 2`, the conservative worst case. An unrecognised accounting tag hard-fails instead of silently reinterpreting privacy state.
- **The attack gallery is more rigorous than a happy-path demo.** The differencing test asserts exact secret recovery with DP disabled, then uses a test-only seeded randomness seam to measure DP-on error; a separate test asserts production uses `SecretsSource`. This avoids the common mistake of making a security demonstration reproducible by weakening the deployed path.
- **Current critique surface is absent, not positive evidence.** GitHub issue listing returned `[]` on 2026-08-05. Its filter-narrowing guard explicitly documents itself as a structural heuristic layered above DP, so it should not be mistaken for a k-anonymity guarantee.

**Ecosystem position:** [[noisegate]] is a stronger instance of [[deterministic-envelope-for-small-agents]] than a conventional MCP gateway: it treats every model-produced query as hostile input, while [[clawpatrol]] controls whether a tool call may happen at all. Together they separate *authority* from *information leakage*.

## Scout gate update — 2026-08-06

- A HN result surfaced this repository again (9 points), but the deep-read entry gate caught that it was already documented yesterday (116 lines, deep-read update 2026-08-05). The apparent "new" candidate came from the repository name differing from the wiki slug (`llm-differential-privacy-gateway` vs `noisegate`); no duplicate deep read was performed.
- [Verified 2026-08-06] GitHub reports 24⭐, last push 2026-08-04; no open or closed issues. This is only a small attention signal after the HN mention, not evidence of community adoption or a new architectural direction.
- **Scout-level ecosystem signal:** a project with a strong deterministic security boundary can be rediscovered by generic repository search while remaining below the contribution/critique threshold. Retain [[noisegate]] as a watch item; do not treat star count or HN visibility as validation of its differential-privacy claims.

## Deep-read update — 2026-08-06

- **The strongest evidence is CI wiring, not the headline test count.** The named `Privacy-guarantee tests` job fetches the census data and requires OpenDP; absent dependencies that would otherwise skip are turned into failures. It runs sensitivity/clamping, mechanism, budget, validator, engine, differencing, membership, and OpenDP cross-check tests before the full suite. This makes its test claims materially more falsifiable than a local green run with optional fixtures missing.
- **The budget namespace is deliberately encoded, not a documentation mismatch.** `SQLiteBudgetStore` persists `(identity, epoch)`, while `AnalyticsService._scoped_epoch()` folds `dataset_id` into the epoch (`epoch@dataset_id`) before creating the accountant. That preserves separate per-dataset ledgers without a schema migration; `dataset_id=None` retains the legacy bare epoch.
- **The real deployment boundary remains local trust, not merely query safety.** Stdio fixes identity at server construction, but the HTTP demo accepts a spoofable `X-Identity`; the README explicitly limits both surfaces to local/single-tenant use. The test suite establishes behavior *within* that threat model, not authenticated multi-tenant protection.
- **The code confirms an important pattern for [[openclaw]] and [[clawpatrol]]:** schemas steer the untrusted client but are not relied on for authorization. `Validator` receives constructed ASTs directly, while the MCP transport converts validation failures to tool errors and represents exhausted budget as a normal refusal—preventing a retry loop from looking like a transient failure.
- **Project health [verified 2026-08-06]:** 24⭐, pushed 2026-08-02, and GitHub returns no issues. There is still no independent critique or community validation; keep it as a high-quality reference implementation rather than evidence that the approach has been adopted.

Links: [[agent-security]], [[clawpatrol]], [[openclaw]], [[agent-trust-hierarchy]], [[deterministic-envelope-for-small-agents]]

## Followup — 2026-08-14 (warm)

- **QUIET, docs-only phase.** Last code commit 07-30; 08-01 merge (#34) and 07-31 commits are README restructure/rename (`noisegate-dp` distribution) and composition-baseline docs. v1.0.0 shipped 07-23; nothing since.
- **Stars 24→25 (+4%)** — plateau below the 5% growth threshold; no issue/PR activity, no external contributors. The two known open gaps (spoofable HTTP `X-Identity`, single-tenant only) remain unaddressed.
- **Signal for the portfolio:** the architecture is stable and complete enough to ship v1.0.0, but the absence of any community/critique surface across 3 checks (08-05, 08-06, 08-14) means it stays a reference implementation, not an adoption signal. No new insight this round — the 08-06 reading still holds.
- **Downgraded scout→warm; next revisit 08-28.** Drop candidate if 30d+ no code commits and still no external signal.
