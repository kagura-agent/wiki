---
title: Computer Anthology — continuously evolving terminal-agent benchmark (public evidence limited)
created: 2026-08-06
updated: 2026-08-06
tags: [agent-evaluation, benchmark, terminal-agents, evidence-quality]
last_verified: 2026-08-06
source: https://vetto.ai/companies/computer-anthology-terminal-tasks.html
---

# Computer Anthology

**Observed 2026-08-06:** Vetto announced *Computer Anthology* as “a continuously evolving benchmark family for AI agents,” framed around terminal tasks. The public landing page was not extractable into readable project documentation, and GitHub repository/code search found no public `vetto-ai/computer-anthology` repository. Consequently, there is no public source tree, test suite, task specification, score data, or issue tracker to inspect. This is a **watch item, not a validated deep read**.

## Public claims and the interesting design direction

The available HN discussion describes an attempt to make benchmark generation and maintenance a continuing system rather than a frozen dataset. Commenters specifically attribute three methodological ideas to the project:

- comparing harnesses as well as models (one commenter claims harness choice can move results by roughly a model-generation gap at lower cost);
- testing task difficulty under semantic perturbation, rather than assuming a single wording measures a stable capability; and
- running a selection-bias analysis against the benchmark’s own tasks.

If independently documented, that combination would address a real benchmark failure mode: static task sets become prompt- and harness-specific, then get mistaken for a general agent capability measure. The methodological claim is more useful than any unverified score: test whether conclusions survive changes to task wording and execution harness.

## Relation to our direction

[[realreplicabench|RealReplicaBench]] provides public stateful tasks, verifier code, a pinned environment, and a reproducible execution path. [[longhorizon-harness|LongHorizon-Harness]] makes durable state contingent on auditor-approved outcomes. Computer Anthology’s announced contribution, if it materializes, would sit one layer above both: a **benchmark-maintenance process** that detects when tasks cease to discriminate between agents or become biased toward a particular wrapper.

For [[openclaw|OpenClaw]] and [[flowforge|FlowForge]], the transferable hypothesis is modest: an evaluation should record the exact harness version, prompt assembly, tool/runtime configuration, and a semantically perturbed task variant where practical. Otherwise a workflow result is evidence about one orchestration recipe, not necessarily the underlying capability.

## Evidence limits and counter-signals

1. This assessment has no code or tests: the declared GitHub target does not resolve, and repository search returned no matching public repository.
2. The landing page returned only a title through the text extractor, so its content cannot substantiate architecture, task counts, licensing, or reported results.
3. The HN thread had 27 points and ten visible comments when checked. Its substantive observations are useful leads, but they are not independent experimental validation; most comments were praise rather than criticism or reproduction.
4. The project is therefore unsuitable as a current benchmark dependency or as evidence for a performance claim.

## Follow-up

- Revisit **2026-08-20**: look for a public paper, task release, repository, executable harness, raw results, and external reproductions/critique.
- Upgrade only if the benchmark exposes enough artifacts to test its anti-bias and harness-comparison claims. Until then, retain the principle rather than adopting the product.
