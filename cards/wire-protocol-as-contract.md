---
title: Wire Protocol As Contract
created: 2026-06-18
tags: [architecture, hexagonal, contract, interface-design]
status: insight
last_verified: 2026-06-20
---

# Wire Protocol as Contract

> When splitting a system from embedded/in-process to client-server, the wire protocol (SQL, HTTP, gRPC) becomes the formal interface contract. Both sides evolve independently as long as the protocol is honored.

## The Pattern

Instead of coupling components through shared libraries, in-process function calls, or language-level interfaces, use the wire protocol itself as the contract boundary. The protocol is already specified, versioned, and toolable — it's the natural seam for splitting systems.

**Key properties**:
- **Protocol-level testing** — if both modes speak the same wire protocol, the same test suite validates both. No mode-specific test branches needed.
- **Independent evolution** — client and server ship on different cadences. The protocol is the only coordination point.
- **Observable by construction** — wire protocols are inspectable, loggable, and proxyable without code changes.

## Examples

- **[[beads]]**: UI-mode (embedded Dolt) and proxied-mode (remote Dolt server) tested identically because both go through the same domain interface backed by SQL wire protocol. The [[single-process-to-proxied-server-migration]] pattern exploits this — verb-by-verb port works precisely because the SQL wire is the contract.
- **[[clawpatrol]]**: MITM proxy mediates agent actions over the existing wire protocol. Agent code is untouched — the proxy just interposes on the protocol boundary.
- **Hexagonal architecture (ports-and-adapters)**: wire-protocol-as-contract is the concrete realization of "ports" — the protocol *is* the port.

## When to Apply

When you see a system splitting from single-process to multi-process (or adding a proxy/mediator layer), ask: "Is there already a wire protocol here?" If yes, make it the contract. If you're inventing a new protocol, that's a smell — find the existing one.

**Anti-patterns**:
- Inventing a custom RPC when the storage engine already speaks SQL
- Wrapping a wire protocol in a language-specific SDK that hides the contract
- Testing embedded and remote paths through different test suites

Links: [[beads]], [[single-process-to-proxied-server-migration]], [[clawpatrol]]
