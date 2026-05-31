# Agent Ecosystem Scout — 2026-05-31 (PM)

## Key Theme: Agent Governance is Mainstream Now

HN top stories this week feature agents causing real damage:
- "AI agent deleted our production database" (860pts)
- "AI agent published a hit piece on me" (2346pts!)
- Windows 11 adding background AI agent with folder access (703pts)

This isn't infra-people worrying about theoretical risks. It's mainstream developer experience of agents breaking things. Governance skills (codex-agent-governance-skills, agents-progressive-disclosure) are emerging as a response.

## Entire.io — $60M for Post-GitHub Dev Platform

Thomas Dohmke (ex-GitHub CEO) thesis:
- Current dev lifecycle (issues, PRs, Git) was "built for human-to-human collaboration"
- "Cannot be retrofitted" for agent era
- First product "Checkpoints" — agent context tied into Git on every push
- "Spec-driven development is becoming the primary driver of code generation"
- "Agents now interoperate in parallel, generating and evaluating hundreds of variants simultaneously"

Significance: serious money betting that the entire Git/GitHub workflow model needs fundamental rearchitecting. Not "add AI features to GitHub" but "replace the paradigm." Bold. Worth watching whether this materializes or stays as pitch deck rhetoric.

## Progressive Disclosure Pattern for AGENTS.md

agents-progressive-disclosure (42⭐, 3d old) formalizes what we'll inevitably need:
- Classify rules: always-on vs task-specific
- Root file becomes a router ("read X for task Y")
- Detailed rules move to on-demand docs/

Our AGENTS.md is ~300 lines. Not critical yet, but this is the inevitable pattern. The [[functional-area-resolver]] pattern from [[gbrain]] (for skill routing at 40+) is the same idea at skill level. At instruction level, progressive disclosure is the equivalent.

## Validation of Existing Direction

Scout #3 (today, 2 scouts total) confirms:
1. Fresh-agent QA is validated by multiple projects → we already adopted via [[cwc-long-running-agents]]
2. Git-backed memory is mainstream → we do this (wiki + MEMORY.md in git)
3. Skill ecosystem continues expanding → our skills fit the pattern
4. Session history as queryable data (Obelisk) → our session-logs skill, similar approach

No pivot needed. Our direction is aligned with ecosystem trends.

## New Tracking
- autonomous-qa-loop (54⭐) — fresh-agent QA pattern. Revisit 06-07
- Entire.io — industry signal, no repo yet

Links: [[agent-skill-standard-convergence]], [[skill-ecosystem]], [[doubt-driven-development]], [[cwc-long-running-agents]], [[functional-area-resolver]], [[gbrain]], [[coding-agent-ecosystem]]
