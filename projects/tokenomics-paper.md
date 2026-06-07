---
title: "Tokenomics: Quantifying Where Tokens Are Used in Agentic SE"
status: noted
depth: 🔬 deep
created: 2026-06-07
updated: 2026-06-07
source: https://arxiv.org/abs/2601.14470
tags: [paper, token-efficiency, multi-agent, coding-agent, cost-analysis]
last_verified: 2026-06-07
---

# Tokenomics Paper (arXiv:2601.14470)

**Authors:** Mohamad Salim et al., Concordia University (DAS Lab)
**Venue:** MSR 2026 (Mining Software Repositories), April 2026, Rio de Janeiro
**Method:** 30 ChatDev tasks × GPT-5 Reasoning model, execution trace analysis

## Core Question

"Where do the tokens go?" in multi-agent software engineering systems.

## Key Findings

### Finding 1: Code Review = 59.4% of All Tokens
- The iterative **Code Review** stage dominates — not code generation
- Code Completion (when triggered, n=6): 26.8%
- Documentation: 20.1%
- Testing (n=12): 10.3%
- **Initial Coding: only 8.6%**
- **Design: only 2.4%**
- → **Refinement > Generation**: the cost is in review/verification, not creation

### Finding 2: Input Tokens = 53.9% of Total ("Communication Tax")
- Input: 53.9%, Output: 24.4%, Reasoning: 21.6%
- ~2:1 ratio of input to output tokens
- Agents repeatedly pass large contexts during collaborative dialogue
- Empirical validation of AGENTTAXO's "communication tax" concept
- → **Context passing, not generation, is the bottleneck**

### Finding 3: Distinct Tokenomic Profiles Per Phase
| Phase | Input | Output | Reasoning | Profile |
|-------|-------|--------|-----------|---------|
| Coding | 6.9% | 58% | 35.1% | Output-heavy (generating code) |
| Code Review | 51.4% | 24.2% | 24.4% | Input-heavy (consuming code to analyze) |
| Documentation | 80.2% | ~10% | ~10% | Extremely input-heavy |

## Our Connections

### Validates TACO
Our [[compress-output]] tool (TACO-inspired regex compression, 71-84% reduction) directly attacks the input token bottleneck. If 53.9% of all tokens are input and most come from context-passing, compressing intermediate outputs has outsized impact.

### Validates Dirac's AST-Native Reads
If Code Review is 59.4% of cost and is input-heavy (51.4% input), then **reducing what gets passed during review** is the highest-leverage optimization. Dirac's approach — file skeleton → drill into function instead of full-file reads — directly attacks this.

### Informs Our Subagent Architecture
ChatDev's waterfall architecture with full-context-passing is inefficient. Our subagent model (isolated sessions, focused prompts) naturally avoids the worst of the "communication tax" by not passing full conversation history between agents.

### Context Curation as Top Priority
This paper provides quantitative backing for what we observed qualitatively: **less context = better reasoning = lower cost**. The 2:1 input-to-output ratio means that any tool/technique that reduces input tokens has double the leverage of one that reduces output tokens.

## Limitations
- Single framework (ChatDev) — conversational waterfall, may differ for SOP-based (MetaGPT) or single-agent (Claude Code) architectures
- 30 tasks, varying complexity
- GPT-5 only — token profiles may differ with other models
- Some phases triggered infrequently (Testing n=12, Code Completion n=6)

## Actionable Insights
1. **Prioritize context compression** over output compression — 2x leverage
2. **Invest in review-phase efficiency** — it's where 59.4% of cost goes
3. **Human-in-the-loop checkpoints before review** can prevent costly iterative loops
4. **Different project types have different cost profiles** — greenfield (coding-heavy) vs refactoring (review-heavy)

## Related
- [[taco-context-compression]] — our implementation addressing the input token bottleneck
- [[dirac]] — AST-native reads, another approach to reducing input tokens
- [[reasonix]] — cache-first loop, 94% cache utilization addresses similar efficiency concerns

## Application Log
- **2026-06-07**: Applied "progressive disclosure" to TOOLS.md — restructured from 213→47 lines, moved details to on-demand files. 29% reduction in auto-loaded project context (~2,200 tokens/turn saved). Directly addresses Finding 2 (input tokens = 53.9% of cost).
