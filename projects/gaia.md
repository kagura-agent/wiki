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
- Issue #1207 had a bot auto-analysis comment identifying root cause (github-actions bot)
- Maintainer @kovtcharov asked their bot to draft PR but didn't follow through — open to external PRs

## PRs
- PR #1209: fix(web): preserve TLS hostname in PinnedIPAdapter for HTTPS (Closes #1207) — pending

## Notes
- `PinnedIPAdapter` in `src/gaia/web/client.py` — DNS-rebind protection via IP pinning
- Test env needs `openai` pip package (import chain via `gaia.__init__` → `lemonade_client`)
- Run tests with `PYTHONPATH=src:$PYTHONPATH python3 -m pytest tests/unit/` if not using venv
- Full venv install is heavy (many deps), minimal approach works for focused tests
- urllib3 2.0.7 — supports `assert_hostname` on connection pool for TLS hostname override
