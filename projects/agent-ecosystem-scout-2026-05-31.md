# Agent Ecosystem Scout — 2026-05-31

## Key Trends

### 1. Skill Ecosystem Explosion
The agent skill ecosystem has crossed a threshold — skills now cover content creation (小红书图文 1.6K⭐), hardware control (墨水屏 91⭐), office automation (WPS CLI 131⭐), music (coding-with-beat 110⭐), and even prompt caching fixes (78⭐). AWS entered with official Well-Architected Skills (141⭐). This validates our bet on skills as the primary agent capability distribution mechanism. See [[agent-skill-standard-convergence]], [[skill-ecosystem]].

### 2. Memory Layer Battlefield
Every project is solving "AI forgets":
- **ai-memory** (430⭐, Rust) — cross-agent handoff, 4-tier model, git-backed. See [[ai-memory]]
- **vibecode-pro-max-kit** (594⭐) — "context rot" harness, 12 agents, 32 skills
- **piia-engram** (156⭐) — "one memory, every AI tool"
- **pmb** (61⭐) — local-first MCP memory, 94.5% recall
- **mempalace-evolve** (68⭐) — self-evolving memory palace
- **quarq-agent-oss** (182⭐) — evidence-gated, benchmark-first. See [[quarq-agent-oss]]

Direction split: **unified cross-agent memory** (ai-memory, piia-engram) vs **single-agent self-evolution** (mempalace, quarq). Our approach (MEMORY.md + wiki + beliefs) is manual-first, which gives control but lacks automation.

### 3. Higher-Order Reasoning Skills
- **ADHD** (601⭐) — tree-of-thought with isolation-based anti-anchoring. See [[adhd-divergent-ideation]]
- **science-superpowers** (135⭐) — computational science methodology skills
- **agent-oss** (182⭐) — "recursive evidence-gated cognitive runtime"

Moving from "agent writes code" to "agent thinks better." Meta-cognitive augmentation becoming a category.

### 4. Chinese Agent Ecosystem Maturing
- carboncode (68⭐, DeepSeek terminal agent)
- build-ai-agent-platform book (57⭐, 30万行拆解)
- overmind/玄霖超脑 (75⭐, 66-module cognitive system)
- hermes-agent-cn-desktop (209⭐, Tauri)
- hermes-edu-skills (208⭐, 中文教育 skill pack)

### 5. MCP Cost Observability
MCPSpend (56⭐) adds billing tracking to MCP calls. Signal: MCP production usage at scale that needs cost attribution. See [[mcp-ecosystem]].

## Star Growth Rates (Monitored Projects)
| Project | Stars | Growth | Period |
|---|---|---|---|
| ADHD | 601 | +128 (+27%) | 2d (05-29→05-31) |
| ai-memory | 430 | +140 (+47%) | 4d (05-27→05-31) |
| guizang-social-card | 1613 | — | new (05-15+) |
| vibecode-pro-max-kit | 594 | — | new (05-15+) |

## Connection to Our Direction
- Memory: our manual approach works but lacks the automation of ai-memory's consolidation pipeline. The [[git-backed-agent-memory]] pattern is validated by multiple projects.
- Skills: our flowforge/gogetajob/agent-memes skills fit the ecosystem trend. Distribution via ClawHub aligns with `npx skills add` pattern.
- Reasoning: ADHD's isolation-based divergence is interesting but not needed for our systematic workflows.

---
*Scout: 2026-05-31 09:17 CST*
