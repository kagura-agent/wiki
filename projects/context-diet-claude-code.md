# Context Diet — Claude Code Prompt-Overhead Skill

> **Repo:** [reedmasonmxfw7441/context-diet-claude-code](https://github.com/reedmasonmxfw7441/context-diet-claude-code) · **35⭐ / 0 forks** (queried 2026-08-07) · GPL-3.0 · created 2026-08-02 · last push 2026-08-06

## What it claims

A Claude Code optimization skill that says it measures system-prompt/tool-definition payloads through a logging proxy, ranks tool sizes, then produces deterministic conservative or aggressive `settings.json` merges with backup and dry-run modes. Its proposed loop is **measure → rank → review unused tools → preview → apply**.

## Evidence and boundary

- [verified] The repository tree at commit reachable on 2026-08-07 contains only `.github/update-log`, `LICENSE`, `README.md`, and `index.html`; no skill implementation, proxy, configuration templates, or test files were present.
- [verified] `gh issue list --state all --limit 20` returned no issues, so there is no community critique or usage evidence to validate its operational claims.
- [verified] The README documents behavior but does not provide executable commands, implementation files, or measured before/after data.
- [verified] `index.html` is an obfuscated base64/XOR JavaScript loader rather than a readable installation artifact. Its decoded behavior was **not executed or assumed** during this review; that opacity alone makes the advertised download path unsuitable for adoption.

## Assessment

This is a useful *problem statement* but not currently an auditable tool. It names a real tension also covered by [[tokdiet]] and [[headroom]]: tool/prompt capacity is finite, so overhead should be measured before pruning. Its critical missing safeguard is an evidence-preserving, reversible measurement path. A system that changes agent configuration needs a baseline capture, explicit allowlist of removed capabilities, dry-run diff, and a task-level regression check—not only a backup.

For [[OpenClaw]] and [[FlowForge]], the actionable insight is narrower: payload minimization should be an observed performance intervention, never a static “diet.” This repository offers no safe implementation to reuse, and its download artifact should not be run pending transparent source and tests.

## Ecosystem position

It sits in the growing “skills as performance configuration” niche, alongside [[agent-skill-standard-convergence]], but currently behaves more like an unverified landing page than procedural infrastructure. The meaningful ecosystem signal is that context-budget tooling is attracting attention; the project itself has insufficient source, tests, forks, or issue discussion to establish credibility.

## Follow-up

- Watch only if the repository adds readable source, a reproducible proxy measurement fixture, test coverage, and a non-obfuscated installer.
- Do not install or execute its published page in the current state.
