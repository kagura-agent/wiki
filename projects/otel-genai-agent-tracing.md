# OpenTelemetry GenAI agent tracing — evaluation

**Date:** 2026-08-04  
**Status:** evaluated — do not adopt as a runtime project yet

## What the standard now provides

OpenTelemetry moved GenAI conventions into the dedicated `open-telemetry/semantic-conventions-genai` repository. Its agent-span document is explicitly **Development** status, so its schema can still change.

The relevant operation names are:

- `invoke_agent` — an agent invocation; client variant for a remote agent service, internal variant for a locally-run framework agent.
- `invoke_workflow` — a workflow invocation.
- `plan` — planning/task decomposition.
- `execute_tool` — each tool execution.
- `chat`, `generate_content`, and `text_completion` — model calls.

For agent spans, the useful common fields are `gen_ai.operation.name`, `gen_ai.provider.name`, `gen_ai.agent.name`, `gen_ai.agent.id`, `gen_ai.agent.version`, `gen_ai.request.model`, and `error.type`. The spec recommends putting attributes important to sampling decisions on the span at creation time. Instructions and message content are opt-in, which is the appropriate posture for private prompts and tool inputs.

## Assessment

**Do not add OTel instrumentation now.** The conventions are a strong vocabulary but a premature implementation target:

1. The agent-specific schema is still Development, so hard-coding it now creates churn risk.
2. This workspace already has native execution evidence (session/cron trajectories and workflow state). Introducing a parallel telemetry pipeline would add export, sampling, retention, and privacy decisions without a currently identified consumer.
3. If a dashboard, cross-runtime tracing, or external observability backend becomes an actual requirement, the spec gives a ready shape for a minimal adapter.

## Adoption trigger and minimum shape

Revisit only when we need to correlate a single task across gateway turns, subagents/ACP, and external tools—or when an observability consumer is selected.

Then start with a **local/export-disabled proof of value**, excluding prompt/tool payloads by default:

```text
invoke_workflow (workflow id, run id)
  └─ invoke_agent (session/agent id, model/provider)
       ├─ plan
       ├─ chat|generate_content
       └─ execute_tool (tool name, status, duration, low-cardinality error.type)
```

Use `gen_ai.operation.name` rather than inventing custom names; record only identifiers and operational metadata. Make prompt, message, and tool argument capture explicit opt-in. A useful go/no-go gate is whether the trace answers a debugging question that the existing trajectory cannot.

## Sources

- [OpenTelemetry GenAI semantic conventions repository](https://github.com/open-telemetry/semantic-conventions-genai), fetched 2026-08-04. The repository is active and its README defines coverage for LLM, agent, tool, evaluation, and MCP signals.
- [Agent spans specification](https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/gen-ai-agent-spans.md), fetched 2026-08-04. Status: Development; defines agent, workflow, planning, and tool spans plus operation attributes.
