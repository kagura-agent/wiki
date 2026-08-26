---
title: "cMCP — Confidential MCP Runtime"
type: deep-read
status: tracking
created: 2026-08-05
updated: 2026-08-05
stars: 15
url: https://github.com/agentrust-io/cmcp
license: MIT
language: Python
last_verified: 2026-08-26
---

# cMCP — Confidential MCP Runtime

> An MCP gateway that puts catalog/policy enforcement and its TRACE receipt inside a TEE. It is not merely an approval layer: it tries to give a downstream verifier cryptographic evidence of which policy governed a session.

## What it solves

[[tool-execution-policy-enforcement]] can stop a tool call, but its decision record is normally produced by the same machine/operator that controls the agent. cMCP inserts a proxy between an agent and upstream MCP servers, evaluates each request against a versioned Cedar policy and approved tool catalog, and produces a signed TRACE claim containing policy/catalog hashes plus an append-only audit-chain root and tip.

Its threat model explicitly treats the agent as untrusted: policy must constrain the agent's chosen tool and payload rather than infer benign intent. This makes it a hardware-attested extension of the governance approach in [[makerchecker]], rather than a replacement for ordinary sandboxing or native approvals.

## Architecture

```text
Agent MCP client → cMCP gateway → Cedar policy + catalog → upstream MCP server
                         │
                         ├─ per-session hash-chained audit entries
                         └─ TRACE claim: policy/catalog hashes + signing-key binding + attestation evidence
```

- **Catalog before forwarding:** the gateway exposes only approved tool definitions; an unknown tool is denied before reaching the upstream server.
- **Policy as data:** Cedar evaluates allow/deny/redact from tool, session, and data-class context. `enforcing` blocks, `advisory` records and forwards, and `silent` is a baselining mode.
- **Evidence separation:** the claim signs a session summary and audit-chain commitment. An offline verifier can recompute the chain and check the policy hash without trusting the runtime operator.
- **TEE provider abstraction:** TPM/vTPM, AMD SEV-SNP, and Intel TDX have different evidence formats; the project centralizes verification where possible in `agent-manifest` instead of maintaining three divergent TPM verifiers.

The conformance tests expose the useful boundary: a catalog miss produces a denial at the JSON-RPC gateway; audit tests assert canonical JSON SHA-256 chaining, monotonic timestamps, and that an anchored chain detects substitution. This is stronger than a dashboard audit log, but only as strong as the signing-key/attestation binding.

## The important tradeoff: detection is not enforcement

The README describes policy measurement and a TEE-bound signing key as if they establish an unbroken control plane. The issue tracker is more precise: measuring a gateway and checking an attestation claim **detects** a modified runtime after the fact; it does not stop a modified runtime from signing a claim. The planned decisive step is sealing the TRACE signing key to the gateway measurement, so altered code cannot unseal it and cannot issue a receipt.

That exposes a real bootstrapping problem: current attestation certifies a nonce derived from the signing key, while sealing wants the measurement established before the key can be used. The project has documented this ordering conflict rather than hand-waving it away. Until it is resolved and hardware-validated, the strongest claim should remain tamper-evident evidence, not tamper-proof policy enforcement.

## Criticism-led findings

The tracker is unusually valuable because it documents failed assumptions with reproductions:

1. **Dependency/API fragility:** the Cedar evaluator imports an upstream `CedarBackend` removed by the successor policy-language release. A permissive version constraint can silently choose a generation that breaks the enforcement path. The proposed immediate mitigation is an explicit pin; the strategic choice is migrate to ACS v5 or own the small Cedar integration surface.
2. **Telemetry can be present but inert:** OpenTelemetry tests validated an exporter in isolation, but a real collector received zero spans because no session attached the sink and no SDK tracer provider was configured. A contributor supplied a live-collector reproduction and recording-path tests. This is a clean reminder that passing unit tests of a component do not prove its production wiring.
3. **Hardware claims need hardware runs:** TPM PCR parsing used `lstrip("0x")`, which removes any leading `0`/`x` characters rather than the prefix; leading-zero PCRs were dropped or shifted. Unit test coverage existed around much of the path, but real-hardware validation also exposed certificate-chain and `TPM2_NV_Certify` uncertainties.
4. **Cloud TEE provenance is provider- and host-specific:** an Azure vTPM hierarchy lacks AIA links, so a pinned root alone cannot build the chain. The solution needs a validated vendored intermediate, not a generic claim that Azure TPM attestation works.

## Ecosystem position

cMCP sits between [[makerchecker]]'s in-process governance and [[clawpatrol]]'s tool-traffic firewall: it adds a **verifiable evidence plane** to gateway enforcement. Its core differentiator is not Cedar itself—Cedar is replaceable—but binding an approved catalog, policy hash, decision transcript, and hardware identity into a receipt an auditor can verify offline.

The cost is substantial operational complexity: policy-language compatibility, certificate-chain supply, TEE-specific evidence, key lifecycle, and real-hardware test environments. That complexity is justified for regulated or cross-organization agent workflows, not for a personal local-agent approval loop.

## Relevance to us

- [[tool-execution-policy-enforcement]] identifies a gap between interactive approval and silent programmatic denial. cMCP reinforces that enforcement needs a distinct policy point, but its TEE stack is disproportionate for our local runtime.
- The portable idea is **receipt-quality audit design**: hash the approved tool contract and policy version with every significant decision, then make verification independent from the executor that produced it.
- The stronger lesson is procedural: label assurance tiers by demonstrated evidence. "Code exists", "unit-tested", "live integration verified", and "hardware-attested" are different claims; no tier should inherit credibility from the next one.

## Status at verification (2026-08-05)

15⭐, 9 forks, 15 open issues; pushed 2026-08-04. Developer Preview launched June 23. The repository is active and its issues contain high-quality adversarial review, but the project remains early and its most consequential assurance property—measurement-bound TRACE-key sealing—is open.

## Links

[[tool-execution-policy-enforcement]] · [[makerchecker]] · [[clawpatrol]] · [[agent-harness-landscape]] · [[agent-security]]

## 08-19 Followup — TDX 硬件 attestation 路径推进

- 15→20⭐ / 11 forks，default-branch 活跃到 08-18
- **#527（08-18）**：TDX MRTD/REPORTDATA 按 ABI 正确位置读取 — 上轮"measurement-bound signing-key sealing + real-hardware validation"开放边界在实打实推进
- **#523**：catalog 检测 upstream tool-definition drift，scanner 不再 fail-open（又一个 fail-closed 实践）
- **#519**：verifiable catalog approval provenance；**#513**：initialize 时协商 handshake-era revision
- 小星但工程密度高，继续 warm track

## 08-26 Followup

- 20→22⭐（+10%），活跃到 08-25：TPM chained signature metadata 保留（#557）、tool args 每字符串长度上限（#562/#570）、azure-cvm-sev-snp provider 修复（#564）
- TDX 硬件验证证据仍未落地（#527 MRTD/REPORTDATA ABI-correct read 待真机验证）— 小星高工程密度持续，revisit 09-02
