# amd/gaia

AMD's open-source framework for running generative AI locally on AMD hardware.

## Repo Info
- **Language:** Python
- **Stars:** ~3k
- **Activity:** Active (multiple commits/week)
- **Size:** ~74MB
- **Local clone:** `/mnt/data/repos/forks/gaia2`

## Contributing
- PR must reference a GitHub issue
- PR template: Summary, Why, Linked issue, Changes, Test plan (all required)
- Lint: `python util/lint.py --all --fix`
- Tests: `pytest tests/unit/`
- No DCO/CLA/signoff required
- Keep PR scope-clean — one logical thread per PR

## Relationship
- **Status:** new (first PR with disclosure)
- PR #1188: fix(security): write guardrails for unprotected file tools
- PR #1208: fix(security): pause progress spinner during interactive security prompts (#1089)

## Architecture Notes
- Agent base class: `src/gaia/agents/base/agent.py` — has `_execute_tool()` loop with `start_progress()`/`stop_progress()` around tool execution
- Console: `src/gaia/agents/base/console.py` — `ProgressIndicator` runs spinner on background thread
- Security: `src/gaia/security.py` — `PathValidator` handles path access prompts
- All agents create PathValidator before `super().__init__()`, but self.console is available at runtime via lazy lambda binding

## Maintainer Style
- TBD — first PRs still pending review
