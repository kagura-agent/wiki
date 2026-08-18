# Nightcrawler — Offline Mobile Pentest Agent

- **Repo**: [garagehq/nightcrawler](https://github.com/garagehq/nightcrawler)
- **Stars**: 113 (2026-08-04)
- **Language**: Python
- **License**: not declared in repository metadata
- **Created**: 2026-07-30
- **Status**: deep-read | ✓2026-08-04

## Core Idea

Nightcrawler packages an autonomous, local-model-driven network-assessment loop into an Android/Kali NetHunter phone. Its differentiator is deployment shape rather than a new planning algorithm: a low-power local model selects one action at a time, while persistent host memory, predefined playbooks, and a local SQLite store carry the work across a long engagement.

The project is positioned at the intersection of [[agent-security]], local-first agents, and physical/mobile operation. It is not an agent harness for general software work, but it offers a sharp example of how a constrained model can be wrapped in deterministic infrastructure.

## Architecture

```
local LLM → Python agent loop → scope proxy → Kali MCP executor
                    ↕               ↕
           SQLite host/network memory  audit log + rate limit
                    ↕
           web dashboard / operator controls
```

The loop has four phases—reconnaissance, enumeration, exploitation, reporting—and a separate per-host memory model. It compensates for an unreliable 1.2B model with few-shot seeding, parse recovery, duplicate/stuck detection, watchdogs, and direct execution of deterministic playbooks.

### Design Details Worth Keeping

1. **Model weakness is externalized, not ignored.** `tests/test_prompt_compliance.py` runs the live local model against scenario prompts and fails below a configured compliance threshold. The test checks the *extracted command* rather than only the model’s response format, matching the runtime parser.
2. **Two memory scopes prevent false continuity.** Hosts are keyed by MAC address and attached to a network identity derived from the gateway MAC. `AgentLoop._get_hosts()` returns no hosts when it cannot identify the current network, choosing safe emptiness over accidentally acting on memories from a previous network.
3. **Playbooks bypass an unreliable planner.** The project deliberately routes repeatable multi-step procedures around the LLM. This is a useful general pattern: use a model for observation/triage, but encode high-consequence or brittle sequences as deterministic code.
4. **Operational recovery is first-class.** It has separate counters for malformed output, missing commands, repeated commands, and time-based stalls. Those triggers reset context instead of treating every failed iteration as the same failure.

## Safety Analysis

The intended safety boundary is a scope proxy that validates target addresses, excluded hosts/ports, and a blocklist before forwarding a command to the execution layer. The separation—model output cannot directly reach the executor—is directionally sound and resembles [[clawpatrol]]’s policy-before-action posture.

However, the implementation is a **best-effort guard, not a complete security boundary**: `proxy/scope.py` extracts only literal IPv4/CIDR tokens and has narrow port parsing, while `proxy/command_filter.py` is a finite regex blocklist. Shell syntax, hostnames, alternative encodings, tool-specific target forms, or dangerous actions outside those patterns may not be covered. This matters especially because the agent loop’s recognized command set includes credential-testing and exploitation tools. The project should move from extraction/blocklists toward an allowlisted structured command schema plus independent authorization checks at the executor.

## Relevance to Our Direction

| Theme | Transferable lesson |
|---|---|
| [[agent-security]] | Keep enforcement below the LLM, but treat regex filtering as insufficient for high-consequence tools. |
| [[openclaw]] / [[flowforge]] | A workflow can safely use a weaker model when transitions and high-impact actions are deterministic and auditable. |
| Agent memory | Make contextual identity explicit; when identity cannot be established, fail closed instead of reusing stale state. |
| Evaluation | Test the actual model-to-action extraction path with a failable threshold, not just prompt wording. |

## Counter-intuitive Finding

The project’s most valuable general contribution is not “autonomous pentesting.” It is the admission that the small model is frequently wrong, then engineering the system around that fact. The planner has less authority than the state machine, scoped memory, and recovery mechanisms—an inversion that makes local models practical for constrained tasks.

## Limitations / Watch Items

- No repository issues were open or closed at review time, so there is no external critique signal yet.
- New project with a single visible maintainer; its 113-star HN attention has not yet become a community signal.
- The safety claims exceed the guarantees offered by literal-token validation and regex denylisting.
- A mobile/physical deployment creates authorization and accountability risks that software-only agent frameworks generally do not face.

## Prediction

The project will either add stronger structured command authorization or attract security criticism once it gets wider review; its current safety proxy is likely to be the first architectural pressure point.

### Followup — 2026-08-18
- **Stars**: 743 (+557% in 14d, 113→743). Viral growth — but default-branch code silent since 07-28 (only README commits 08-03). 63 forks (organic signal).
- **Community**: 2 external PRs — Dev9269 #2 (fix clean-training-data under sudo) closed unmerged, Srimi1 #3 (one-tap Wi-Fi connect) open since 08-07. Maintainer not merging → growth outpaces maintainer bandwidth.
- **Assessment**: Classic marketing-driven star spike (matches [[pi-from-scratch]] pattern). Safety boundary (regex/token) still the known weak point, now with a much bigger audience.
- **Prediction**: growth cools without code; no code by 08-25 → downgrade cool. Bump revisit 08-25 for PR merge activity + star trajectory.

Links: [[agent-security]], [[clawpatrol]], [[openclaw]], [[flowforge]], [[agent-harness-landscape]]
