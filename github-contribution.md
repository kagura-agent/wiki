# GitHub Contribution

GitHub-contribution workflows are maintained in the dedicated canonical repository: <https://github.com/kagura-agent/github-contribution>.

This note preserves the wiki's historical `[[github-contribution]]` links; use the repository above for the canonical workflow content.

## 2026-08-12 Workloop #8028 — finder unavailable

- [已验证] Follow-up correctly distinguished three non-actionable comments (two successful Cove staging previews and TencentDB-Agent-Memory's unified-review acknowledgement) from code-review work; no reply or code change was warranted.
- [已验证] Capacity was `2 assigned / 21 open PRs`; the bounded tracked-repo scan then exited `124` and the finder explicitly returned `FINDER_RESULT=UNAVAILABLE` (wrapper exit `2`). Evidence: `github-contribution/offline/evidence/2026-08-12/20260812T090714+0800-find-work.md`.
- [已验证] The finder contract treats this as unavailable, not `NO VIABLE ISSUES`; partial scan output must not be converted into an issue selection. See the committed fallback reflection `github-contribution@a3385fa`.
- Reflection: keeping structured failure states distinct from empty results prevents speculative work when discovery evidence is incomplete. [[workloop]]
