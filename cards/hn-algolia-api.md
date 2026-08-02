---
created: 2026-06-19
last_verified: 2026-08-02
tags: [api, hacker-news, tools]
title: HN Algolia API
---

# HN Algolia API

Use `hn.algolia.com/api/v1/search` directly for Hacker News scouting instead of `web_search`. Preferred over generic [[search-engineering]] approaches for HN-specific data.

## Why
- Structured JSON response (title, points, num_comments, url, objectID)
- No auth required
- Reliable, fast, filterable by date/points/type
- `web_search "site:news.ycombinator.com ..."` returns inconsistent results

## Usage
```
# Search stories by keyword
curl "https://hn.algolia.com/api/v1/search?query=agent+skills&tags=story&numericFilters=points>50"

# Search by date range
curl "https://hn.algolia.com/api/v1/search_by_date?query=openclaw&tags=story"
```

## Fields
- `hits[].title`, `hits[].url`, `hits[].points`, `hits[].num_comments`
- `hits[].objectID` → `https://news.ycombinator.com/item?id=<objectID>`
- `hits[].created_at` (ISO 8601)

Tags: `story`, `comment`, `ask_hn`, `show_hn`
Numeric filters: `points`, `num_comments`, `created_at_i` (unix)

---
*Graduated from [[beliefs-candidates]] 2026-06-19. Pattern: hn-algolia-direct (6 occurrences across [[study-workflow]] sessions).*
