---
title: "Docker Sandboxes — microVM boundary for coding agents"
created: 2026-08-11
updated: 2026-08-11
tags: [agent-infrastructure, sandbox, microvm, credential-isolation]
last_verified: 2026-08-11
---

# Docker Sandboxes — microVM boundary for coding agents

**Product**: Docker Sandboxes (`sbx`) | **Implementation**: closed source; public documentation only | **Signal**: HN 624 points / 349 comments (2026-08-11 scan).

## Evidence boundary

This review used Docker's versioned public documentation in `docker/docs` (`content/manuals/ai/sandboxes/security/{_index,credentials,isolation,defaults}.md`, fetched 2026-08-11) and the HN discussion. The marketing page and Docker blog endpoint reset the connection, and no implementation or test suite is public; claims about enforcement therefore remain vendor-documented, not independently reproduced.

## Design

Each agent runs with sudo in a separate Linux microVM with a private Docker Engine. Docker documents five controls:

1. **Hypervisor boundary** — separate kernel; host processes/files are inaccessible except explicit mounts.
2. **Network boundary** — HTTP(S) goes through a host proxy with deny-by-default domain policy; raw TCP/UDP/ICMP, private IP ranges, host localhost, and cross-sandbox networking are blocked.
3. **Private Docker Engine** — agent `docker` commands target an in-VM engine rather than the host daemon.
4. **Workspace modes** — default direct mount is read/write and intentionally leaves the working tree exposed; `--clone` mounts the repository read-only and has the agent work in a private clone, which must be fetched explicitly.
5. **Credential proxy** — host-side proxy overwrites outbound auth headers; the sandbox sees a sentinel such as `proxy-managed`, not the API key. Third-party v2 kits require a domain-scoped credential binding, but OAuth passthrough can explicitly weaken this guarantee.

## The important tradeoff

The microVM protects the *host*, not automatically the work product or every connected integration. Direct-mount mode lets an agent change build scripts, Git hooks, CI/IDE/agent settings, and any workspace file immediately. Clone mode still exposes all files under the Git root for reading, including ignored `.env` files. A shared agent-skills store is read/write across participating sandboxes by default; local stdio MCP servers run on the host and stay outside the VM boundary.

So Docker Sandboxes has a stronger compute boundary than a normal container, but its practical safety depends on choosing clone mode, minimizing mounts/skills, reviewing policy allowlists, and treating local MCP as a privileged host integration.

## External critique / product risks

HN discussion identified useful pressure tests rather than proving defects: login/closed-source dependence, restrictive volume/worktree ergonomics, uncertain Linux visibility, and a central question of whether agent execution can be *enforced* rather than merely offered. One Docker employee stated that sessions use a platform-native-hypervisor microVM (not a container) and linked the architecture post; this is vendor attribution, not independent verification. The most substantive community concern aligns with the docs: sandboxing does not prevent dangerous changes through an explicitly writable workspace or a privileged MCP server.

## Relation to existing knowledge

This is a managed, host-local counterpart to [[superserve]] and [[sandboxes-tastyeffect]]. Superserve's Firecracker + secret proxy pursues a similar credential boundary; tastyeffect's Docker/runc approach targets lower-complexity self-hosting. Docker's distinct contribution is packaging microVM isolation, policy, credential injection, clone workflow, and agent kits into a developer-facing local product.

## Relevance to us

**Adopt the principle, not the product yet.** Our concrete safety checklist for harnessed coding work should distinguish: (a) execution isolation, (b) writable workspace exposure, (c) credential injection, and (d) host-side bridges such as MCP. The immediate transferable rule is: a sandbox boundary is only meaningful if the workspace and host integrations have separately constrained authority. No Docker Sandbox adoption is proposed: it is closed source, untested locally, and its documented trust boundary does not remove the need for our approval and review controls.
