# Control Flow Over Prompts — HN Essay (2026-05-07)

- **Source**: [bsuh.bearblog.dev](https://bsuh.bearblog.dev/agents-need-control-flow/)
- **HN**: 326 pts, 181 comments (front page 2026-05-07)
- **Author**: Brian Suh

## Core Thesis

Reliable agents tackling complex tasks need **deterministic control flow encoded in software**, not increasingly elaborate prompt chains. If you've resorted to "MANDATORY" or "DO NOT SKIP" in prompts, you've hit the ceiling of prompting.

## Key Arguments

1. **Prompts are non-deterministic**: imagine a programming language where statements are suggestions and functions return "Success" while hallucinating
2. **Software scales through composability**: systems built from libraries, modules, functions — code all the way down. Prompts lack this property.
3. **Deterministic scaffolds needed**: explicit state transitions and validation checkpoints that treat the LLM as a **component**, not the system
4. **Verification is half the battle**: without programmatic verification, you're left with Babysitter (human-in-the-loop), Auditor (end-to-end verification), or Prayer (vibe accept)

## Relationship to Our Work

This directly validates [[FlowForge]]'s approach:
- FlowForge = deterministic DAG workflow with explicit node transitions
- LLM executes each node's task, but the **flow is deterministic**
- Node branching + `flowforge next --branch N` = explicit state transitions
- The `verify-claims.sh` pattern = programmatic verification checkpoint

Also validates our AGENTS.md philosophy: "必须通过 flowforge 走完整个 workflow" — the cron instruction itself is control flow, not a prompt suggestion.

## Connection to [[thin-harness-fat-skills]]

The essay argues the same pattern: thin deterministic harness (control flow) + fat LLM components (skills/tasks). The harness constrains, the LLM creates.

## Ecosystem Signal

326pts + 181 comments on HN means this resonates with practitioners. The agent ecosystem is moving past "just prompt harder" toward structured orchestration. Good timing for FlowForge.


## HN Discussion Source

Merged from hn-agents-control-flow.md — see [[control-flow-over-prompts]]
# HN: Agents Need Control Flow, Not More Prompts (2026-05-07)

- **Source**: [bsuh.bearblog.dev](https://bsuh.bearblog.dev/agents-need-control-flow/) — 306pts on HN
- **Author**: bsuh

## Core Thesis

Reliable agents need deterministic control flow encoded in software, not increasingly elaborate prompt chains. If you've resorted to "MANDATORY" or "DO NOT SKIP" in prompts, you've hit the ceiling of prompting.

## Key Arguments

1. **Prompts as suggestions**: in prompt-land, statements are suggestions and functions can return "Success" while hallucinating
2. **Software composability**: code works because of recursive composability (libraries → modules → functions). Prompt chains lack this property — non-deterministic, weakly specified, hard to verify
3. **LLM as component, not system**: deterministic scaffolds with explicit state transitions treat the LLM as a capability, not the orchestrator
4. **Error detection gap**: without programmatic verification, you get three options — Babysitter (HITL), Auditor (end-to-end check), or Prayer (vibe accept)

## HN Discussion Highlights

- "If you're trying to get reliability and determinism out of the LLM, you've already lost" — top comment, strong agreement
- Counter: "Making unreliable systems give reliable results for bounded tasks is half of engineering" — valid for classification-type tasks, less for open-ended
- sudosteph: "Scripts and hooks are the main levers — a decent script and a cron job will handle certain things much better and cheaper"
- Spectrum view: it's not binary deterministic vs random — intelligence occupies a range, the question is where each task falls

## Relevance to FlowForge

**This is exactly the FlowForge thesis.** FlowForge = deterministic workflow scaffolding (YAML state machine) that treats the LLM as executor of individual nodes, not the orchestrator. The blog post validates our direction from first principles.

Key connection: FlowForge's `flowforge next --branch N` = explicit state transitions. The agent doesn't decide the workflow structure — it executes within it.

**What we do better**: FlowForge allows branch decisions (LLM picks which branch), preserving flexibility within a deterministic skeleton. The blog post presents a binary (code vs prompts) but the real answer is hybrid — which is what we built.

**What we could learn**: the "error detection gap" framing is useful. FlowForge has validation nodes but no programmatic verification hooks (e.g., run tests after code generation). Could add `validate:` fields to workflow nodes.

See also: [[thin-harness-fat-skills]], [[flowforge]]
