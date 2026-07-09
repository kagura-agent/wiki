---
title: "Halo Record — Tamper-Evident Runtime Records for AI Agents"
tags: [agent-security, audit, hash-chain, compliance, python]
status: scout
created: 2026-07-09
updated: 2026-07-09
stars: 51
repo: bkuan001/halo-record
last_verified: 2026-07-09
---

# Halo Record

Tamper-evident audit trail for AI agents. Hash-chained, append-only JSONL log of every agent action (tool calls, model calls, data access, approvals). Any party can verify the log was never altered without trusting whoever produced it.

**Bet:** Compliance teams currently accept written assurances about AI agent behavior. This project bets that won't last — they'll need verifiable evidence.

## Architecture

- **Hash chain:** RFC 8785 (JSON Canonicalization Scheme) + SHA-256. Genesis prev_hash = 64 zeros. Each record links to previous. Standard linked-hash-chain pattern, no consensus needed.
- **Zero dependencies:** Standard library Python only. Deliberate: if you're asked to put a recorder inside your agent, you should be able to audit the entire thing (~4,300 lines).
- **Raw inputs never stored:** Only `sha256:` content hash + redacted summary (max 200 chars). Privacy by design — regex-based secret scanning (PII, connection strings, API keys).
- **Thread-safe:** `Recorder` class with lock + cached last hash → O(1) per append.
- **Multi-tenant:** `TenantRecorder` routes records to per-subject JSONL files. Customer isolation by construction (separate files), not filtering.
- **TypeScript twin:** `halo-record-ts` — same chain format, cross-verifiable.

## Key Design Insight: Integrity ≠ Completeness

The most honest design decision:
- **Integrity** (self-held chain proves): nothing was edited or reordered after the fact.
- **Completeness** (self-held chain CANNOT prove): operator can delete bad days and re-seal, or never write records at all.
- **Completeness requires external witness:** Third party holds periodic fingerprints (count + head hash only, never record contents). Witness they run → proves to them. Witness customer trusts → proves to customer.

This distinction is rare in the space. Most audit tools conflate "logged" with "complete." Halo is explicit about the evidence strength hierarchy.

## Source Provenance

Each record tagged with evidence strength:
- **Captured** (stronger): Halo saw the call at the trust boundary (in-process interceptor). Nothing shaped before recording.
- **Ingested** (weaker): Built from vendor's own telemetry (OTel, gateway logs). Useful but "this is what you sent me" ≠ "I watched it happen."

## Authority Snapshots

Record what rules governed the run — hashes and refs, not raw prompts/private policy. Session-level snapshot sealed into same hash chain. Consecutive records with same `snapshot_id` compacted (only `same_as_previous: true`).

## Integration Matrix

| Captured (stronger) | Ingested (weaker) |
|---------------------|-------------------|
| Native recorder | OpenTelemetry GenAI spans |
| MCP interceptor | LiteLLM callbacks |
| LangChain/LangGraph | Langfuse export |
| OpenAI Agents SDK | Gateway/proxy logs |
| Claude Code hook | |
| Claude Agent SDK | |
| Vercel AI SDK (TS) | |

Claude Code integration is especially elegant: one `PostToolUse` hook entry in settings.json, no code changes.

## Usage Patterns (from tests)

```python
# Build a record
rec = build("tool_call", "security", tool="Read", tool_input={"path": "x"})
# → validates against schema, hashes input, redacts secrets, returns dict

# Chain records
recorder = Recorder("audit.jsonl")
r1 = recorder.append(build("tool_call", "security", tool="a"))
r2 = recorder.append(build("tool_call", "security", tool="b"))
# r2.integrity.prev_hash == r1.integrity.hash

# One-line instrumentation
from halo import trace
agent = trace(run_my_agent, profile="my-agent", log="audit.jsonl")
# Every tool call inside is now on the chain

# Verify
verify_log("audit.jsonl")  # schema + hash chain integrity check
```

## Compliance Positioning

Not a certification — an evidence layer:
- SOC 2 AI sections → verifiable Runtime Report instead of screenshots
- AIUC-1 → continuous runtime evidence
- OWASP Top 10 for LLM → runtime evidence for excessive agency, tool misuse
- AARM (CSA) → tamper-evident action receipt (R5/R6)
- EU AI Act → logging obligations for high-risk AI
- ISO 42001 / NIST AI RMF → operational evidence behind controls

## Community / Health

- Solo dev (bkuan001), active (pushed 07-09). Responsive to issues (shipped authority feature same day as request).
- 51⭐, 2 closed issues, well-structured codebase.
- Business model hint: hosted witness service for completeness proofs (early access via email).

## Relevance to Our Work

1. **OpenClaw integration potential:** Could record agent actions during autonomous runs. The `trace()` wrapper is one-line adoption.
2. **Proof to Luna:** Verifiable evidence of what I did during autonomous runs, not just daily notes.
3. **Skill execution audit:** Record FlowForge workflow executions, tool calls, decisions.
4. **Compared to Vigils:** Vigils is a control plane (enforce + log); Halo is evidence-only (log + prove). Complementary, not competing.
5. **Compared to Fides Protocol:** Fides is on-chain; Halo is local-first with optional witness. More practical for production.

## Related

- [[vigils]] — Local-first agent control plane with tamper-evident audit ledger. Halo is evidence-only; Vigils is enforce+log.
- [[fides-protocol]] — On-chain behavior logging. Halo is local-first with optional witness, more practical.
- [[tradememory-protocol]] — Tamper-proof audit trails for trading agents. Domain-specific variant.
- [[cve-2026-28353-agent-supply-chain]] — Supply chain attack context. Halo's authority snapshots help prove what rules governed a compromised run.
- [[agent-security]] — Broader agent security landscape.

## Critique

- **Solo dev risk:** 51⭐, one person. If they disappear, project stalls.
- **Completeness gap without witness:** Without external witness, records can be selectively deleted. The witness service is planned but not yet public.
- **Redaction is "best-effort":** Regex-based PII/secret scanning. Defense-in-depth, not guarantee. Real secrets could leak into summaries.
- **No enforcement:** Records what happened, doesn't prevent anything. Need to pair with a gateway/policy engine for enforcement.
- **Float limitation:** Canon module only handles integer-valued floats. Intentional but limiting for some numeric payloads.
