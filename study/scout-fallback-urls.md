# Scout Fallback URLs

When `web_search` is unavailable, use `web_fetch` on these URLs directly.

## Hacker News
- Front page: `https://news.ycombinator.com`
- HN API top stories: `https://hacker-news.firebaseio.com/v0/topstories.json`
- HN search (Algolia): `https://hn.algolia.com/api/v1/search?query=ai+agent&tags=story&numericFilters=created_at_i>UNIX_TIMESTAMP`

## GitHub (non-API fallback)
- Trending daily: `https://github.com/trending?since=daily&spoken_language_code=en`
- Trending weekly: `https://github.com/trending?since=weekly`

## Blogs & Aggregators
- Simon Willison (LLM/agent): `https://simonwillison.net/`
- The Batch (Andrew Ng): `https://www.deeplearning.ai/the-batch/`
- Latent Space podcast: `https://www.latent.space/`

## Usage

**Preferred: use the dedicated tool** (created 2026-06-15):
```bash
bash tools/hn-scan.sh                        # default: "ai agent", 7d, min 5pts
bash tools/hn-scan.sh --query "mcp" --days 3  # custom query + window
bash tools/hn-scan.sh --min-points 50         # only popular stories
```

Manual fallback (if tool unavailable):
```bash
WEEK_AGO=$(date -d '7 days ago' +%s)
curl -sS "https://hn.algolia.com/api/v1/search?query=ai+agent&tags=story&numericFilters=created_at_i%3E${WEEK_AGO},points%3E5&hitsPerPage=15" | jq '.hits[] | "\(.points)pts | \(.title)"'
```

> ⚠️ Use `%3E` not `>` in URL — bare `>` causes 400 Bad Request.

Created 2026-05-12 after noting web_search unavailability 3 consecutive sessions.
Updated 2026-06-15: `tools/hn-scan.sh` created, integrated into study.yaml scout/quick_scout.
