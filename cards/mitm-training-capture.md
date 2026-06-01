---
title: MITM Proxy as Training Data Capture
tags: [architecture-pattern, agent-training, security, dual-use-infrastructure]
created: 2026-06-01
last_verified: 2026-06-01
---

# MITM Proxy as Training Data Capture

**Pattern:** A security-enforcement proxy that already terminates TLS and inspects traffic can cheaply add verbatim recording for training-data purposes.

## Key Insight

Security proxies already have:
- Decrypted plaintext (TLS terminated)
- Credential isolation (key swap boundary)
- Semantic understanding (endpoint routing, policy evaluation)
- Position between untrusted code and trusted services

Adding training-data capture requires only a **tee** on the already-decrypted stream. The security property (credential isolation) directly serves the training data property (no real keys in corpus).

## Design Principles (from [[ironcurtain]])

1. **Byte fidelity**: Never JSON round-trip streaming deltas. Raw string concatenation preserves exact wire content.
2. **Poison over partial**: If any exchange in a session can't be fully captured, poison the whole session. Downstream discards it. No partial records.
3. **Allowlist endpoints**: Only capture completion endpoints (`/v1/messages`). Housekeeping traffic (telemetry, registry) is noise. Allowlist fails safe.
4. **Pre-key-swap capture**: Record agent-facing headers (with sentinel key), never real provider key.

## Flywheel

```
Run agents → Capture trajectories → Fine-tune models → Run better agents
```

Combined with domain-specific workflows (e.g., vuln-discovery), generates specialized training data at scale without human annotation.

## Applicability

Any system with a reverse-proxy/gateway between agents and LLM providers could implement this:
- [[openclaw]] gateway (provider routing already present)
- Any API proxy (LiteLLM, AI Gateway, etc.)

The key enabler is **positional privilege** — you must be in the data path, not just observing from outside.

## Related

- [[ironcurtain]] — First implementation of this pattern
- [[agent-trust-hierarchy]] — Security positioning that enables capture
