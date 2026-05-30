#!/bin/bash
# recall-report.sh — Analyze wiki note recall frequency
# Source: Orb telemetry-backed skill lifecycle (v0.6.0) — applied 2026-05-18
#
# Shows which notes are frequently recalled vs never retrieved.
# Reads .recall-log written by search.sh.
#
# Usage: bash recall-report.sh [--top N] [--cold] [--since YYYY-MM-DD]

WIKI_DIR="$HOME/.openclaw/workspace/wiki"
RECALL_LOG="$WIKI_DIR/.recall-log"
TOP=20
SHOW_COLD=0
SINCE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --top) TOP="$2"; shift 2;;
    --cold) SHOW_COLD=1; shift;;
    --since) SINCE="$2"; shift 2;;
    *) shift;;
  esac
done

if [[ ! -f "$RECALL_LOG" ]]; then
  echo "No recall log yet. Run some searches first."
  exit 0
fi

# Filter by date if --since given
if [[ -n "$SINCE" ]]; then
  LOG_DATA=$(awk -F'|' -v since="$SINCE" '$1 >= since' "$RECALL_LOG")
else
  LOG_DATA=$(cat "$RECALL_LOG")
fi

TOTAL_QUERIES=$(echo "$LOG_DATA" | wc -l)
FIRST_DATE=$(echo "$LOG_DATA" | head -1 | cut -d'|' -f1 | cut -dT -f1)
LAST_DATE=$(echo "$LOG_DATA" | tail -1 | cut -d'|' -f1 | cut -dT -f1)

echo "📊 Wiki Recall Report"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Period: $FIRST_DATE → $LAST_DATE"
echo "Total queries: $TOTAL_QUERIES"
echo ""

# Count slug frequency
echo "🔥 Most recalled (top $TOP):"
echo "$LOG_DATA" | cut -d'|' -f4 | tr ',' '\n' | sed 's/^ *//' | sort | uniq -c | sort -rn | head -"$TOP" | while read count slug; do
  echo "  $count × $slug"
done

echo ""

# Intent distribution
echo "🎯 Query intent distribution:"
echo "$LOG_DATA" | cut -d'|' -f2 | sort | uniq -c | sort -rn | while read count intent; do
  echo "  $count × $intent"
done

# Get all note slugs and recalled slugs for cold analysis
ALL_SLUGS=$(find "$WIKI_DIR/projects" "$WIKI_DIR/cards" -name "*.md" 2>/dev/null | xargs -I{} basename {} .md | sort -u)
TOTAL_NOTES=$(echo "$ALL_SLUGS" | wc -l)
RECALLED=$(echo "$LOG_DATA" | cut -d'|' -f4 | tr ',' '\n' | sed 's/^ *//' | sort -u)
RECALLED_COUNT=$(echo "$RECALLED" | grep -c .)
COLD_SLUGS=$(comm -23 <(echo "$ALL_SLUGS") <(echo "$RECALLED"))
COLD_COUNT=$(echo "$COLD_SLUGS" | grep -c .)
COLD_PCT=$(( COLD_COUNT * 100 / TOTAL_NOTES ))

echo ""
echo "📦 Coverage: $RECALLED_COUNT/$TOTAL_NOTES recalled ($((100 - COLD_PCT))%) | $COLD_COUNT never recalled ($COLD_PCT%)"

# Show cold notes with context if requested
if [[ $SHOW_COLD -eq 1 ]]; then
  echo ""
  echo "❄️ Never recalled — sorted by staleness (oldest first):"
  echo "  Age  | Status     | Slug"
  echo "  -----|------------|------"
  
  # Build cold notes with age and status
  NOW_EPOCH=$(date +%s)
  echo "$COLD_SLUGS" | while read slug; do
    [[ -z "$slug" ]] && continue
    # Find the file
    FILE=$(find "$WIKI_DIR/projects" "$WIKI_DIR/cards" -name "${slug}.md" 2>/dev/null | head -1)
    [[ -z "$FILE" ]] && continue
    
    # Get age in days
    FILE_EPOCH=$(stat -c %Y "$FILE" 2>/dev/null || echo "$NOW_EPOCH")
    AGE_DAYS=$(( (NOW_EPOCH - FILE_EPOCH) / 86400 ))
    
    # Get status from frontmatter
    STATUS=$(grep -m1 '^status:' "$FILE" 2>/dev/null | sed 's/status: *//' | tr -d '"' | head -c 10)
    [[ -z "$STATUS" ]] && STATUS="none"
    
    printf "  %3dd | %-10s | %s\n" "$AGE_DAYS" "$STATUS" "$slug"
  done | sort -t'|' -k1 -rn
  
  echo ""
  echo "  Legend: Age = days since last modified"
  echo "  Tip: Notes >30d old with status=dropped/none are strong retire candidates"
fi
