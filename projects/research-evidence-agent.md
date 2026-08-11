---
title: research-evidence-agent — Local Provenance and Claim-Evidence Gate
created: 2026-08-10
tags: [provenance, research-integrity, verification, agent-boundary]
last_verified: 2026-08-11
---

# research-evidence-agent — Local Provenance and Claim-Evidence Gate

- **Repo:** [zxxasdfrty/research-evidence-agent](https://github.com/zxxasdfrty/research-evidence-agent)
- **Revision examined:** `c94b2065a844a0b8aa5fb667685788237ef327d6`
- **Observed:** 20⭐; BSD-3-Clause; Python ≥3.10; alpha (`0.1.0`).
- **Verification:** cloned locally; `python3 -m pytest -q` passed **5 tests**. Its demo, scan, and audit commands completed with a passing three-claim ledger.

## What it does

The package records a local research bundle as a SHA-256 manifest. Rules classify files into four evidence classes—raw experiment, reprocessed data, model output, and synthetic illustration—then a claim ledger checks only whether the cited evidence has a compatible class. An `observation`, for example, errors unless it cites at least one raw-experiment item.

Its optional model layer receives a deliberately smaller view: bundle basename, aggregate counts, total bytes/files, and distinct issue codes. It excludes contents, paths, filenames, and checksums. `test_agent_privacy.py` verifies a filename does not occur in that tool output.

## Architecture: two boundaries, not one

1. **Mechanical provenance boundary.** `scan_bundle()` walks the tree, applies path rules, hashes files ≤50 MiB, and emits machine-readable issues for unclassified, over-limit, and sensitive-looking names. `audit_claim_ledger()` rejects missing/unknown evidence IDs and incompatible evidence for raw observations or reprocessing claims.
2. **LLM disclosure boundary.** The optional agent cannot access the original manifest; it invokes only `aggregate_bundle_audit`. The agent prompt also says not to infer scientific validity from names or reproduce contents.

This division is sound: the model summarizes risks but cannot be the authority deciding evidence classification or claim validity.

## What the tests establish—and do not

The five tests cover basic classification/hashing, sensitive filename flags, the raw-evidence requirement, aggregate-only agent output, and the generated demo ledger. The CI runs Ruff plus pytest on Python 3.10–3.12.

They do **not** establish enforcement against filesystem races/symlinks, adversarial rule ordering, hash collisions, or external-model exfiltration beyond the single aggregate tool. The docs call future richer-model access an explicit opt-in, but that is policy/documentation rather than a capability boundary if future code changes the tool set. The sole issue requests versioned JSON schemas, fixtures, and migration rules; current manifest and ledger schemas are implicit Python/JSON conventions.

## Relationship to our work

This is a narrow complement to [[reproducible-evaluation-envelope]]. An evaluation envelope binds a reported result to its task, configuration, trajectory, artifact, and verifier. This project supplies a smaller **evidence-type gate** inside such an envelope: do not let a model-derived artifact silently substantiate a raw observation.

For our study/workflow records, the transferable rule is:

> Preserve an explicit evidence class and make stronger assertions mechanically require stronger source classes; send only aggregates to an optional reviewer model.

Adoption is **not recommended now**. Our artifacts are primarily operational rather than scientific, and adding path-based evidence categories without a concrete release/reporting workflow would create ceremony rather than assurance. Revisit if we publish benchmark claims or need an externally auditable research bundle.

## Ecosystem signal

The project sits beside a small single-author portfolio (`engineering-run-agent`, `synthetic-gpa-agent`) rather than an emerging shared standard. It is useful chiefly as a compact reference implementation of provenance typing plus an aggregate-only LLM boundary—not as evidence that this approach has broad adoption yet.
