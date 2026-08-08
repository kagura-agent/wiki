# MCP Slim Guard — recoverable MCP result delivery

**Repo**: [lennney/mcp-slim-guard](https://github.com/lennney/mcp-slim-guard)
**Stars**: 22 (2026-08-06)
**License**: MIT | **Language**: TypeScript / Node.js ≥20
**Depth**: 🔬 deep-dive | **Last Updated**: 2026-08-06

## What

A local stdio MCP proxy that reduces **tool-catalog** context and oversized eligible **tool-result** context, without changing the authorized upstream invocation. It exposes either a generic `find_tool` → `call_tool` → `read_result` surface or host-native authorized tool names, then conservatively projects only plain text / uniform JSON / logs.

The key contract is: resolve one authorized catalog entry, forward its arguments unchanged, call it at most once, snapshot the exact result before lossy delivery, and use `read_result` to replay the snapshot without calling upstream again.

## Architecture and invariants

1. **Authorization first.** Tool allow/deny filtering occurs before discovery, schemas, or invocation; ambiguous identifiers are rejected rather than guessed.
2. **Two independent reductions.** `src/compressor.ts` defers full schemas behind wrapper tools, while `ResultCapsuleStore` handles only oversized eligible results. This separates catalog pressure from payload pressure.
3. **Fail-open delivery.** Errors in classification, projection, storage, observer, or audit return the original upstream result rather than risk data loss. Authorization/policy rejection instead fails closed.
4. **Immutable bounded recovery.** A capsule has a runtime-generation-scoped reference, a five-minute TTL, max 64 stored results, and 16 MiB total storage. `read_result` returns bounded chunks and never invokes upstream.
5. **Narrow eligibility.** Results with errors, mixed content, metadata, `structuredContent`, output schemas, source-like content, or uncertainty pass through unchanged. Tests exercise exact reconstruction, eviction rollback when delivery observation fails, and security findings that do not leak raw credentials into capsule metadata.

## What is genuinely different

[[taco-context-compression]] and our `compress-output.sh` shrink terminal output by preserving salient text. Slim Guard puts a stronger **reversibility boundary** around MCP delivery: an agent sees a projection but can retrieve the exact original result later, and the proxy proves that this recovery does not repeat the upstream side effect.

The useful general pattern is not "compress more" but **lossy first delivery + lossless, bounded replay + fail-open fallback**. It is complementary to [[skill-context-compression]]: skill compilation reduces what enters an agent; Slim Guard reduces MCP protocol surfaces after an authorized call.

## Evidence and limits

- The repository's frozen synthetic fixture reports 76.18% fewer normal-path tokens (71,388 → 17,007) for 24/24 deterministic tasks, with exactly one upstream call each. It explicitly does **not** measure model answer quality, provider caching, or billing.
- Its 99.71% figure is a deliberately extreme 100-tool / 8,000-row synthetic stress case, not a typical workload estimate.
- There were no GitHub issues at the 2026-08-06 inspection, so no independent user criticism or real compatibility failure signal was available.
- Local verification was blocked before execution: `npm ci` emitted only a deprecated `glob@10.5.0` warning and was SIGKILLed by the environment; no dependencies were installed, so build/tests/benchmark were not run. The claims above are code-and-repository evidence, not locally reproduced results.

## Relation to our direction

OpenClaw already benefits from [[taco-context-compression]]-style terminal filtering, but an MCP delivery proxy would only be worthwhile when a host loads many schemas or frequently returns large plain-text/log/regular-JSON results. It would not solve conversation-history bloat, arbitrary file reads, or durable cross-session retrieval. More importantly, installing it rewrites host MCP configuration, so it must remain an opt-in reversible trial, never a transparent global optimization.

## Anti-intuitive finding

The strongest safety choice is that an optimization failure returns *more* context (the exact original result), while an authorization failure returns *less* (a rejection). Treating these opposite failure modes identically would either hide authorized data or accidentally expose capabilities.

## Follow-up

Track only after independent compatibility reports or a non-synthetic evaluation appears; the project is alpha and current issue activity is zero.
