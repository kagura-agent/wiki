# Phoenix — Hermes Plugin for Routing and Guardrails

> A standalone plugin rather than a fork: it layers routing, safety controls, and recovery behavior over Hermes's official hook surface.

- **Repo**: [xyaz1313/phoenix](https://github.com/xyaz1313/phoenix)
- **Stars**: 104 · **Forks**: 8 (2026-08-04)
- **Language**: Python
- **Created / last push**: 2026-08-02 / 2026-08-03
- **License**: README declares CC BY-NC 4.0; GitHub API returns `NOASSERTION` — distribution terms need verification before reuse.
- **Status**: deep-read | ✓2026-08-04

## Position in the Ecosystem

Phoenix is a user-space policy bundle for [[hermes-agent]], not a general agent runtime. Its `plugin.yaml` declares six official integration points—`pre_tool_call`, `post_api_request`, `api_request_error`, `subagent_stop`, `transform_llm_output`, and `post_approval_response`—and explicitly avoids modifying Hermes core. It is closer to an opinionated, installable operational policy layer than to [[clawpatrol]]'s network firewall: Phoenix classifies the task and returns hook directives; Claw Patrol inspects traffic and can enforce rules independently of agent intent.

This offers a concrete contrast with [[tool-execution-policy-enforcement]]: Hermes exposes programmatic pre-tool blocking/approval through plugins, whereas OpenClaw's normal control plane is principally interactive approval.

## Architecture

```text
latest user message → Metis weighted classifier → l0/l1/l2/l3 tier
                                             ↓
pre_tool_call → circuit-breaker check → scheduled/Loop policy → approval directive
                                             ↓
                    safe local-tool escape hatch / delegate evaluator escape hatch
```

### 1. Cumulative routing, not one-keyword escalation

`router/metis_core.py` maps a latest user message to four tiers. Critical, coding, complexity, length, multiline, and connector signals add up; thresholds are `l2=3`, `l3=7`. The test suite specifically preserves the distinction between one critical phrase (only `l2_deep`) and a critical phrase plus a code signal (`l3_critical`).

**Why it matters:** it rejects the tempting but brittle rule “a sensitive word means maximum restriction.” Routing becomes explainable enough to test, while avoiding obvious false positives.

### 2. Safety policy is a state machine with a recovery path

`guardrails/tool_guard.py` gives the circuit breaker priority. When it is open, it blocks normal tools but permits `todo`, `memory`, and `session_search`, so an agent can inspect state and recover instead of being completely frozen. The comments tie this to a real prior lockout.

For high tiers, the policy differs by execution context:

- interactive task → return `approve`;
- scheduled task → block/skip, rather than leave an approval waiting for an absent human;
- Loop task → require a different-model evaluator before the risky action.

That is a useful refinement of [[tool-execution-policy-enforcement]]: an enforcement decision should be context-aware, not merely allow/deny.

### 3. “The tool that satisfies the gate” needs an explicit escape hatch

A Loop requires a checklist before most tools run, but `delegate_task` must be allowed so it can obtain the required evaluator. It is also exempted from the high-tier evaluator rule itself. The project records a real three-tool deadlock (`todo` / `delegate_task` / `terminal`) that motivated the exception.

**Portable insight:** any policy that says “do X before Y” must test whether the mechanism for doing X is itself caught by Y. Safety gates need a deliberately narrow progress path, not blanket exemptions—see [[policy-gate-progress-path]].

### 4. Trust is scoped; hardlines are not learned away

A tool that has been approved repeatedly can skip future approval, but `is_hardline=True` still requires approval. Scheduled high-tier work ignores learned trust entirely. This keeps behavioral adaptation below an irreversible-security floor.

## Evidence Quality and Limits

- I inspected the hook manifest, classifier, guard implementation, and their tests through the GitHub API. The repository lists 252 test files in its badge but says 257 in README text; this mismatch is unverified and the tests were **not run** because the shallow clone stalled and was killed.
- The repository had no issues returned by `gh issue list --state all` and the API reported zero open issues, so there was no external design critique to assess.
- It is only two days old, has one visible contributor from the API check, and its “production incident” claims are self-reported code comments. Treat its patterns as promising evidence, not a mature framework.

## Relevance to Us

Phoenix validates two existing instincts behind [[flowforge]] and OpenClaw's approval design:

1. **Workflow gates must leave a recovery route.** FlowForge branch checks and approval gates should be tested for self-deadlock, especially when a branch asks an agent to delegate or record state before continuing.
2. **Automation needs an explicit no-human policy.** “Require approval” is invalid for cron-like execution. The safe options are skip-and-audit, pre-authorized narrow actions, or independent verification—not an indefinitely pending approval.

The project does **not** justify copying its keyword-weight model or adaptive approval immediately: those thresholds are declared initial heuristics, and it has no demonstrated community validation. The durable lesson is the policy-state-machine shape and its regression tests for past deadlocks.

Links: [[hermes-agent]], [[tool-execution-policy-enforcement]], [[policy-gate-progress-path]], [[clawpatrol]], [[flowforge]], [[agent-security]]
