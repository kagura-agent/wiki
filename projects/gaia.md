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
- PR #1210: fix(tests): update stale electron test assertions after #606 (#1204) — pending
- **PR #2500: fix(tests): make unit suite hermetic by blocking real network connections (Closes #2499) — PENDING**

## 2026-07-26 Session Notes

### PR #2500 — fix(tests): make unit suite hermetic (fixes #2499)
- **Issue**: Unit test suite passes/fails depending on host state (Lemonade server running)
- **Root cause**: `_ensure_lemonade_installed()` probe hits real localhost:13305
- **Fix**: Autouse `_block_network` socket guard in conftest + LemonadeClient mock on 3 tests
- **Key discovery**: Socket guard affects many more tests than just the 3 mentioned in the issue
  - 8 test modules need `allow_network` marker (start real uvicorn/sidecar/aiohttp servers)
  - All use real `requests.get/post` or `httpx` to local servers for integration-style validation
- **CI notes**: macOS smoke uses `--maxfail=1` — failures show one at a time
- **Lint**: `python util/lint.py --fix` (black + isort), line length ~88 chars
- **Gotcha**: `from gaia.installer...` must come BEFORE `from gaia.llm...` (isort alphabetical)

### Maintainer Style (updated)
- Issue #2499 extremely well-written (detailed root cause + code pointers)
- Explicit "good candidate for a PR" invitation — welcoming to external contributions
- No human review yet — check back in 2-3 days

### CI Architecture
- macOS smoke: fast (3m), `--maxfail=1`
- py3.10/11/12: parallel full suite
- Code Quality: black + isort + pylint + mypy (pre-existing errors in discovery.py)
- Email Agent Tests: separate workflow
- Integration: Windows + Linux CLI tests (uvicorn+sidecar)

## 2026-05-23 Session Notes

### PR #1210 — fix(tests): update stale electron test assertions (fixes #1204)
- **Issue**: Test Electron Framework CI job permanently red since #606
- **Root cause**: PR #606 renamed `.empty-chat*` → `.empty-task*` CSS classes and grew MemoryDashboard.tsx to 159KB without updating electron tests
- **Fix**: Updated 4 assertions (.empty-chat→.empty-task) + added allowlist for known-large dashboard files (200KB cap)
- **CI**: label ✅ pr-review ✅ (electron test workflow didn't fire due to path filter — only tests changed)
- **Pattern**: Pure test fix, no production code. Manual edit was much faster than acpx for 4-line changes
- **Observation**: gaia repo uses path-filtered CI — changes to test files only may not trigger the test workflow itself. Maintainer will need to verify on a PR that touches a filtered path
- **Note**: gogetajob keeps getting OOM-killed during scan/sync. Need to investigate memory usage

## Notes
- `PinnedIPAdapter` in `src/gaia/web/client.py` — DNS-rebind protection via IP pinning
- Test env needs `openai` pip package (import chain via `gaia.__init__` → `lemonade_client`)
- Run tests with `PYTHONPATH=src:$PYTHONPATH python3 -m pytest tests/unit/` if not using venv
- Full venv install is heavy (many deps), minimal approach works for focused tests
- urllib3 2.0.7 — supports `assert_hostname` on connection pool for TLS hostname override
