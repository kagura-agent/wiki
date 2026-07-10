# Kastor — Declarative Agent Spec (Terraform for Agents)

> 50⭐ | Go | Apache-2.0 | Created 2026-07-02 | by weirdGuy (solo dev)
> Links: [[agent-harness-landscape]], [[agent-infrastructure-trend]], [[pocketdev]], [[agent-skill-standard-convergence]]

## What It Is

HCL-based declarative source-of-truth layer for AI agents. Define agents, tools, prompts, models, and targets in typed spec files. Two execution paths:

1. **`kastor build`** — compile spec to runnable framework code (currently LangGraph)
2. **`kastor plan/apply`** — reconcile hosted agents with Terraform-style state management

**Not a runtime.** Sits above frameworks (LangGraph) and platforms (OpenAI Assistants). The thesis: agent contracts should be reviewable, versionable, and diffable.

## Architecture

```
.agent + .tool + .prompt + kastor.hcl
         │
    kastor validate (type checking, reference resolution, prompt-var satisfaction)
         │
    ┌────┴────┐
    ▼         ▼
kastor build   kastor plan/apply
(codegen)      (platform reconciliation)
```

### Key Design Decisions

1. **Typed file types**: `.agent` (model, IO contract, deps), `.tool` (interface + source), `.prompt` (template + required vars), `.kastor` (project config)
2. **Block references by address, not path**: `model.fast`, `tool.web_search`, `agent.forecast.output.summary`
3. **Dependency graph from references**: referencing `agent.X.output.Y` creates an implicit edge
4. **Three-way diff**: spec vs state vs remote — catches drift (out-of-band platform changes)
5. **Provider interface**: Read/Create/Update/Delete/Diff — identical to Terraform provider pattern
6. **MCP URI pinning**: tools reference `mcp://server/tool`, transport config is deployment-time (via `mcp_servers.json`)
7. **Codegen determinism**: generated output reproducible from spec, enforced by tests
8. **Strict parsing**: unknown attributes are hard errors (loosening later is painless, tightening breaks users)

### Provider Contract (Go interface)

```go
type Provider interface {
    Read(ctx, id) (remote Object, found bool, err error)
    Create(ctx, desired *Resource) (id string, err error)
    Update(ctx, id string, desired *Resource) error
    Delete(ctx, id string) error
    Diff(desired *Resource, remote Object) ([]AttrDiff, error)
}
```

All data is JSON value trees (`map[string]any`). Provider-neutral, serializable, plugin-boundary-ready.

### Plan Output

```
+ agent.forecast (not in state)
+ agent.geocoder (not in state)
~ agent.weather (changed: model.id "gpt-4o-mini" → "gpt-4o")
- agent.old_one (in state, not in spec)
```

Attribute-level diffs with dotted paths (`"model.id"`, `"tools[0].source.uri"`).

## Tradeoffs & Limitations

- **Solo dev, 8 days old** — high execution velocity but fragile bus factor
- **Only LangGraph codegen** — no CrewAI, no Autogen, no native targets yet
- **Only in-memory platform provider** — OpenAI Assistants provider planned but not shipped
- **No runtime/eval** — explicitly non-goal in v0
- **No compound types** — tool params limited to string/number/bool in v0
- **Generated code doesn't wire multi-agent data flow** — dependency graph validates but doesn't execute upstream agents

## What's Novel

1. **"Agent IaC" as distinct category**: Not just config management. Full plan/apply/state lifecycle with drift detection.
2. **Spec-first, codegen-second**: The HCL spec is the contract; generated LangGraph code is a build artifact, not source.
3. **Prompt-variable type safety**: Compile-time check that every `{{var}}` in a prompt is satisfiable from the agent's IO contract.
4. **MCP as universal tool bus**: Clean separation of tool identity (spec-time) from tool transport (deploy-time).

## Relevance to Us

| Aspect | Connection |
|--------|-----------|
| Declarative agent config | OpenClaw agents.yaml is similar in spirit — Kastor goes further with typed IO contracts |
| Plan/apply for agents | Could apply to managing multi-agent OpenClaw setups at scale |
| Tool spec format | MCP URI pinning pattern could inform skill interface definitions |
| Drift detection | Three-way diff idea applicable to skill/config drift in long-running agents |
| Codegen determinism | FlowForge workflow definitions share the "spec generates execution" philosophy |

## Status Assessment

- **Category**: 🆕 Novel (declarative agent infrastructure-as-code)
- **Signal**: Medium — HN 33pts/17 comments, growing from 0→50⭐ in 8 days
- **Risk**: Solo dev, no external contributors, all issues self-filed
- **Verdict**: Track at warm interval. Architecture is clean and thesis is compelling, but too early to invest heavily.

## Predictions

- Will reach 200+ ⭐ within 30 days if dev maintains pace (high confidence — HN exposure + clear value prop)
- First external contributor within 14 days (medium confidence — Apache-2.0 + Go is accessible)
- Will need to ship a real platform provider (OpenAI/Anthropic) to sustain growth past 500⭐ (high confidence)

---
*Deep read: 2026-07-10 | Revisit: 2026-07-24*
