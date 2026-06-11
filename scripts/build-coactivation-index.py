#!/usr/bin/env python3
"""
Build co-activation index from wiki/.recall-log
Output format: slug<TAB>co-slug1:count,co-slug2:count,...
Only includes pairs with count >= 3 (noise filter).
Slugs normalized: strip projects/ and cards/ prefixes, skip dated entries.

Used by search.sh to boost docs frequently returned alongside current matches.
"""
import sys
from collections import Counter, defaultdict
from itertools import combinations

log_path = sys.argv[1] if len(sys.argv) > 1 else "/home/kagura/.openclaw/workspace/wiki/.recall-log"
output_path = sys.argv[2] if len(sys.argv) > 2 else "/home/kagura/.openclaw/workspace/wiki/.coactivation-index"
min_count = 3

def normalize_slug(s):
    """Normalize to bare slug (no prefix, no extension)."""
    s = s.strip()
    if not s:
        return None
    # Skip dated scan/scout entries (not actual docs)
    if s.startswith('20') and len(s) > 15 and ('-' in s[:5]):
        return None
    # Strip directory prefixes
    for prefix in ('projects/', 'cards/'):
        if s.startswith(prefix):
            s = s[len(prefix):]
    # Strip .md extension if present
    if s.endswith('.md'):
        s = s[:-3]
    return s if s else None

pair_counts = Counter()

with open(log_path) as f:
    for line in f:
        parts = line.strip().split('|')
        if len(parts) < 4:
            continue
        slugs_raw = parts[3].split(',')
        slugs = set()
        for raw in slugs_raw:
            n = normalize_slug(raw)
            if n:
                slugs.add(n)
        
        if len(slugs) < 2:
            continue
        
        for a, b in combinations(sorted(slugs), 2):
            if a != b:
                pair_counts[(a, b)] += 1

# Build adjacency: for each slug, list of (co-slug, count) with count >= min_count
adjacency = defaultdict(list)
for (a, b), count in pair_counts.items():
    if count >= min_count:
        adjacency[a].append((b, count))
        adjacency[b].append((a, count))

# Write output
with open(output_path, 'w') as out:
    out.write(f"# Co-activation index — auto-generated from .recall-log\n")
    out.write(f"# Format: slug<TAB>co-slug1:count,co-slug2:count,...\n")
    out.write(f"# Min co-occurrence: {min_count}\n")
    for slug in sorted(adjacency):
        pairs = sorted(adjacency[slug], key=lambda x: -x[1])[:10]  # top 10 per slug
        pairs_str = ','.join(f"{s}:{c}" for s, c in pairs)
        out.write(f"{slug}\t{pairs_str}\n")

total_pairs = sum(1 for c in pair_counts.values() if c >= min_count)
total_slugs = len(adjacency)
print(f"Built co-activation index: {total_slugs} slugs, {total_pairs} pairs (count >= {min_count})")
print(f"Written to: {output_path}")
