---
title: Cloudflare OS — per-workspace capability boundary for agent-built applications
created: 2026-08-10
tags: [agent-workspace, capability-security, sandboxing, cloudflare-workers, collaboration]
last_verified: 2026-08-10
source: https://github.com/cloudflare/cloudflare-os
---

# Cloudflare OS — per-workspace capability boundary for agent-built applications

**Repository:** [cloudflare/cloudflare-os](https://github.com/cloudflare/cloudflare-os), Apache-2.0; inspected 2026-08-10 at **7,152 stars, 706 forks, 47 open issues**, with a push at `2026-08-10T03:23:35Z`. The project labels its August 2026 v2 release early access; its local `pnpm run-local` path is explicitly not production deployment.

## What it is

Cloudflare OS is a self-hostable AI productivity environment built around three units:

- a workspace-specific agent chat with company context;
- **Gadgets**: private, editable application instances created from reusable Blueprints;
- **Gatekeepers**: service-specific capability boundaries between agents/Gadgets and external accounts or resources.

Its core architectural move is that a user does not invoke a shared SaaS application: each Gadget is a separate per-user application instance. A workspace is a Durable Object; a Gadget server is a Dynamic Worker Facet; client/server communication is Cap'n Web RPC. The server has no general Internet access and receives only explicitly introduced Workers bindings. The client runs in a sandboxed iframe constrained to its RPC session.

## Security mechanics verified in code

The compelling part is not merely an approval dialog, but how authority follows the data boundary.

1. **No ambient connector access.** Agents and Gadgets start with access to nothing. A user must introduce a particular repository, document, or account resource; Gatekeepers then expose only the selected service/resource rather than a globally configured MCP surface.
2. **Ownership blocks unsafe sharing.** `packages/mcp-shared/src/sharing-policy.ts` refuses observers for an MCP-bound Gadget. The comment gives the decisive reason: authenticating to the same upstream service cannot establish that a viewer may read data fetched with the Gadget owner's credentials. The supported alternative is a Blueprint, so each person connects their own account.
3. **Approval-gated writes are durable and non-replaying.** `ActionStore` persists a pending action before external I/O. On a new Durable Object activation, an interrupted `applying` action becomes a non-retryable failure with an explicit “may or may not have taken effect” message. It also caps pending actions at 50 and retained completed actions at 100. This is an actual outcome-unknown boundary, not a promise that failed writes are harmless.
4. **Deferred approval uses simulated responses.** A Gatekeeper can let the agent continue after staging a side-effecting action, returning a local simulated result until the user later approves or rejects the queued batch. This removes synchronous approval deadlock, but means downstream agent reasoning is necessarily conditional on an action that has not happened yet.

## Transferable insight

For a shared agent workspace, the most useful pattern is:

> A collaboration permission must not implicitly convey the right to data fetched under someone else’s external credential.

Cloudflare OS enforces that by choosing copy/derive semantics (Blueprint + one’s own connection) over sharing a live, credential-bearing Gadget. This is stronger than merely hiding credentials from the UI: the object itself cannot be opened by a non-owner when it carries MCP-derived data.

The companion pattern is an explicit **outcome-unknown** state for interrupted external operations. A reliable harness should preserve that state and require target-side verification; automatically retrying turns a transport failure into duplicate side effects. This is a concrete control-plane mechanism rather than a general evolution policy, the distinction captured by [[mechanism-vs-evolution]].

## Fit and limits

- The private-instance + Blueprint model is directly relevant to a private companion/mirror-world: personal artifacts can be safely customized without silently becoming a shared, credential-bearing application. For [[OpenClaw]], the transferable unit is a resource-specific authority boundary around integrations—not a replacement for its channel/session runtime. [[FlowForge]] remains the appropriate layer for explicit workflow transitions; Cloudflare OS demonstrates how a lower layer can make connector-side effects and ownership constraints durable.
- Cloudflare Workers, Durable Objects, Dynamic Workers, and Facets are load-bearing runtime assumptions. `workerd` self-host deployment documentation is marked “coming soon,” so cloud independence is an architectural possibility rather than a verified operational path.
- Gatekeepers centralize the difficult data-authority decision per service, but each connector remains a security-critical implementation. The review inspected the shared policy/action-store mechanics and README architecture, not every Gatekeeper’s OAuth scopes or resource parser.
- The repository asks contributors to avoid non-trivial outside PRs while it is early access. This is not a contribution target now.

## Decision

**Track no further for now; do not adopt.** The two patterns worth retaining are (1) deny sharing of credential-derived live state unless resource-level authorization can be proved, and (2) model interrupted side effects as outcome-unknown, never as safely retryable. A concrete future trigger would be building a shared workspace that combines collaboration with external-account data; then evaluate a small, runtime-agnostic capability/ownership design rather than importing the Workers stack.
