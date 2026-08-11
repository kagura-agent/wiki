---
title: "KADATH — Evolutionary Runtime for Full Agent Genomes"
repo: i3T4AN/KADATH
stars: 172
forks: 1
license: Apache-2.0
created: 2026-08-08
last_push: 2026-08-09
status: deep-read
last_verified: 2026-08-11
tags: [evolutionary-agents, multi-agent, reproducibility, benchmarking, sandboxing, memory]
---

# KADATH — Kernel for Agentic Darwinian Adaptation, Tooling, and Heredity

## What it is

KADATH treats an agent as an evolvable **full genome**—system prompt, Python framework, tools, dependency declarations, and supporting files—rather than as a prompt variant. A kernel runs a population through reproducible epochs: a model-generated Architect defines a benchmark, organisms execute in isolated containers, a separate Grader extracts evidenced facts, deterministic kernel code applies the locked rubric, then selection preserves elites and mutates/reproduces the remainder.

At the 2026-08-11 inspection point it was a two-day-old Apache-2.0 repository with **172 stars, 1 fork, 0 issues**, and no commits beyond launch/README proof presentation. That makes its engineering claims source-inspected but its operational and community durability unverified.

## Source evidence

- Read `tests/test_lifecycle.py` before implementation; it exercises benchmark-contract repair, frozen evidence, mutation registration, selection rollback, worker/tool limits, locked-runtime tampering, broker identity, and continuation/export.
- `python3 -m unittest tests.test_lifecycle` passed **53 tests in 28.936s** when proxy variables were unset. A first run with ambient proxies returned HTTP 503 for localhost mock endpoints; that was an environment interception, not evidence of a KADATH defect.
- The public issue list was empty at inspection. The repository's ten-epoch `18 → 91` fitness graphic is a project-supplied demonstration, not independently reproduced evidence.

## Architecture and enforceable boundaries

1. **The kernel is outside heredity.** `Kernel` owns objective hashes, tool manifest, runtime configuration, lifecycle state, selection, Git lineage, evidence freezing, and score application. Organisms receive a read-only genome mount during an epoch; mutations are proposed only after grading and applied by kernel code to a fresh worktree. This is a strong application of [[mechanism-vs-evolution]]: evolve approaches inside a fixed authority boundary, not the evaluator or its policy.
2. **The benchmark is model-authored but formula-owned.** The Architect may create a rubric, but the contract validator repairs malformed output and only preconfigured tools/connectors can be selected. The Grader must cite frozen evidence; it does not set fitness. This separation makes KADATH closer to [[multi-agent-quality-gate]] than an unconstrained self-improvement loop.
3. **Evidence is a first-class phase boundary.** After execution, attempts are copied without symlink traversal, stream-hashed into a manifest, then sealed read-only. Grading works on that frozen copy. This limits post-hoc score gaming and permits a grader outage to resume without rerunning agents.
4. **Heredity preserves provenance, not just text.** Genomes are content-addressed from tree, effective prompt, and runtime signature; duplicate children are rejected. Memory records retain producer/epoch provenance, are linked into descendants rather than recursively copied, and their retrieval score includes source cohort performance and bounded peer ratings.
5. **Workers are kernel-issued capabilities.** Parents cannot start containers directly. The broker imposes per-parent worker limits, subsets of approved tools, worker-specific tokens, deadlines, read-only genome mounts, and lower container limits. It also tags model calls with run/epoch/agent/worker/genome metadata and retains redacted traces.

## The important tradeoff

KADATH spends substantial tokens and infrastructure to search a population. Its anti-gaming design protects **within-run** comparability, but does not establish that a locked LLM-authored benchmark tracks the user’s real-world goal. A population can reliably optimize a proxy. The project acknowledges this indirectly by requiring the Architect to disclose limitations and use a measurable proxy when direct verification is unavailable; a real deployment still needs independently designed benchmark suites and holdout objectives.

The surprising part is not “agents mutate themselves”—that is familiar—but the project makes the **mutation surface wider** than most systems while making the **governance surface narrower**. A child may alter dependencies and framework source, yet cannot mutate the criterion, scheduler, lineage, score, or isolation policy. This is the practical middle ground between prompt-only optimization and an agent that administers its own experiment.

## Position in the ecosystem

- Compared with [[tokencode-parallel-agent-runtime]], KADATH uses evolutionary selection across whole frameworks rather than TokenCode’s competitive `/race` selection among isolated candidate diffs. Both preserve an outside judge/human or kernel boundary; KADATH pays more cost for multi-epoch learning.
- Compared with [[cindy]], KADATH optimizes a temporary population toward one measurable objective; Cindy coordinates durable user-facing worker sessions. They are complementary, not alternatives.
- It is a runtime counterpart to the principles in [[self-evolving-agent-landscape]]: durable state, evaluators, and boundaries matter more than a self-modifying prompt alone.

## Relevance to us

Do not import the population-evolution loop into [[FlowForge]]: ordinary operational tasks lack stable, cheap, independently measurable fitness functions, so selection would optimize workflow artifacts rather than outcomes. The transferable pattern is narrower:

> For any self-modifying workflow, freeze inputs/evidence before evaluation, keep evaluator and transition authority outside the modified artifact, and bind every result to the exact configuration that produced it.

FlowForge already has explicit node transitions; KADATH is evidence that adding “adaptive” behavior should not weaken that boundary. If future workflow adaptation is explored, start with a single bounded candidate change and a held-out regression gate—not population breeding.

## Follow-up

- Revisit **2026-08-25** for a substantive post-launch code change, issue/PR discussion, external reproduction, or published benchmark details.
- [[KADATH]]
