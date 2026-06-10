# Agent Ecosystem Scout — 2026-06-10

- **depth**: scout
- **status**: current
- **tags**: ecosystem, trending, weekly

## GitHub Trending (Weekly, 2026-06-10)

The agent skill ecosystem continues its explosive growth. Key observations:

### Mega-projects dominating

| Project | Stars | Weekly gain | Category |
|---------|-------|-------------|----------|
| ECC (affaan-m) | 212K | +9,025 | Agent harness optimization |
| hermes-agent (NousResearch) | 189K | +11,915 | Self-improving agent |
| taste-skill (Leonxlnx) | 39.7K | +7,787 | Quality control skill |
| last30days-skill (mvanhorn) | 37.8K | +9,307 | Research aggregation skill |
| impeccable (pbakaus) | 36.9K | +3,334 | Design language for agents |
| open-notebook (lfnovo) | 28.6K | +4,245 | NotebookLM alternative |
| Agent-Reach (Panniantong) | 25.7K | +4,361 | Multi-platform web reading |
| supermemory | 26.4K | +1,982 | Memory engine API |
| headroom (chopratejas) | 20.8K | +15,060 | Context compression |
| compound-engineering-plugin | 20.8K | +1,442 | Multi-agent engineering |

### Key insights

#### 1. ECC v2.0 — The "agent config as code" category winner
- 261 skills, 64 agents, 84 legacy command shims
- Cross-harness: Codex, Claude Code, Cursor, OpenCode, Gemini, Zed, GitHub Copilot
- Rust control-plane prototype (ecc2/) — signals intent to move beyond shell scripts
- **Has integrated Hermes operator story** — convergence signal with NousResearch
- Orchestrator family (orch-*), worktree-lifecycle service for parallelization
- MIT + Pro tier (GitHub App) business model
- **Key architectural concept**: "control-pane substrate" with session adapters + MCP inventory

#### 2. hermes-agent 189K⭐ — Massive growth since last check (78K → 189K)
- **`hermes claw migrate`** — explicit OpenClaw migration path. Competitive signal.
- Now supports: Telegram, Discord, Slack, WhatsApp, Signal, Email, CLI
- 6 terminal backends: local, Docker, SSH, Singularity, Modal, Daytona (serverless persistence)
- **Closed learning loop**: skill creation from experience → skill self-improvement during use → nudges to persist knowledge → FTS5 session search
- [[Honcho]] dialectic user modeling
- Compatible with agentskills.io open standard
- Key new Chinese provider support: Xiaomi MiMo, z.ai/GLM, Kimi/Moonshot, MiniMax

#### 3. Headroom 20.8K⭐ — From 16.1K (06-07) → 20.8K (06-10), +4.7K in 3 days
- Now trending #1 weekly (15,060 stars this week!)
- Added `headroom learn` — mines failed sessions, writes corrections to CLAUDE.md/AGENTS.md
- Cross-agent memory store with auto-dedup
- OpenClaw listed as compatible ("installs as ContextEngine plugin")
- Our [[compress-output.sh]] does 71-84%, Headroom claims 47-92% on real workloads
- **Actionable**: evaluate `headroom wrap` for OpenClaw integration

#### 4. New category: "Agent taste/quality" skills
- taste-skill (39.7K⭐) — "stops AI from generating boring, generic slop"
- impeccable (36.9K⭐) — "design language that makes your AI harness better at design"
- These are essentially prompt engineering packaged as skills — interesting that they get massive stars

#### 5. Meta-skill emergence
- revfactory/harness (6.7K⭐) — "meta-skill that designs domain-specific agent teams"
- pm-skills (phuryn) — "100+ agentic skills for product management"
- The ecosystem is layering: individual skills → skill packs → meta-skills that generate skills

### Tracked project updates

| Project | Previous | Current | Δ | Status |
|---------|----------|---------|---|--------|
| re_gent (regent-vcs) | 584⭐ (05-23) | 680⭐ (06-10) | +16.4% | 🟢 Active, pushed 06-08 |
| Beads (gastownhall) | 24,020⭐ (05-23) | 24,444⭐ (06-10) | +1.8% | 🟢 Active, pushed today |

- **re_gent**: Steady growth from 584 → 680 (+16.4%). Still active (pushed 2 days ago). 29 open issues. Multi-agent VCS continues expanding. Keep tracking. Revisit 06-24.
- **Beads**: 24,020 → 24,444 (+1.8%). Active daily (pushed today). Mature/steady phase. Keep tracking. Revisit 06-24.

## Ecosystem trend: Consolidation around 3 poles

1. **NousResearch/hermes-agent** — The self-improving agent platform (189K⭐)
2. **ECC** — The cross-harness config/skill system (212K⭐)  
3. **OpenClaw/ClawX** — The infrastructure gateway (our home)

The convergence between ECC and hermes-agent (ECC 2.0 adds Hermes operator story) is a significant consolidation signal. The "migrate from OpenClaw" feature in hermes-agent is a competitive move worth monitoring.

## Relevance to us

- Headroom's `headroom wrap` for OpenClaw is worth evaluating as a ContextEngine plugin
- hermes-agent's learning loop (skill creation from experience → self-improvement) validates our beliefs-candidates → DNA pipeline approach
- ECC's 261-skill catalog at scale confirms the need for our functional-area-resolver pattern (from [[gbrain]]) once we hit 40+ skills
- The "meta-skill" layer (harness, pm-skills) is a trend we could participate in — a skill that generates skills from workflow patterns
