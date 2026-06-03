#!/bin/bash
# retire-candidates.sh — Auto-retire scoring for wiki notes
# Source: Elephant Agent auto-retire pattern + ai-memory retention decay math
# Applied: 2026-05-19, upgraded 2026-06-03 (mathematical exponential decay)
#
# Scores wiki notes using exponential retention decay (ai-memory pattern):
#   retention = e^(-λ * age_days) * recall_boost * recency_boost
#   retire_score = (1 - retention) * 60 + status_penalty + orphan_penalty
#
# Key improvement over v1 (discrete 0/15/30 buckets):
#   - Continuous scoring: 38-day and 60-day notes differentiate properly
#   - Recall reinforcement: each query "bumps" retention logarithmically
#   - Recency of last recall matters (recent query = stronger retention)
#   - Far fewer ties — v1 had 458 candidates all scoring 75-85
#
# Parameters (adapted from ai-memory M8 decay):
#   λ (lambda) = 0.03  — base decay rate per day
#   σ (sigma)  = 0.6   — recall reinforcement strength
#   μ (mu)     = 0.04  — recency weight for last recall
#
# Score range: 0-100. Higher = more likely candidate for retirement.
# Threshold: score >= 60 → suggest review, >= 80 → strong retire candidate
#
# Usage: bash retire-candidates.sh [--threshold N] [--top N] [--json]

WIKI_DIR="$HOME/.openclaw/workspace/wiki"
RECALL_LOG="$WIKI_DIR/.recall-log"
THRESHOLD=60
TOP=20
JSON=0
NOW=$(date +%s)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --threshold) THRESHOLD="$2"; shift 2;;
    --top) TOP="$2"; shift 2;;
    --json) JSON=1; shift;;
    *) shift;;
  esac
done

# Build recall frequency map from log
declare -A RECALL_COUNT
declare -A LAST_RECALL_EPOCH
if [[ -f "$RECALL_LOG" ]]; then
  while IFS='|' read -r timestamp intent query slugs; do
    local_epoch=$(date -d "${timestamp%%T*}" +%s 2>/dev/null || continue)
    while IFS=',' read -r slug; do
      slug=$(echo "$slug" | xargs)  # trim
      [[ -z "$slug" ]] && continue
      RECALL_COUNT["$slug"]=$(( ${RECALL_COUNT["$slug"]:-0} + 1 ))
      # Track latest recall epoch
      if [[ -z "${LAST_RECALL_EPOCH[$slug]}" || "$local_epoch" -gt "${LAST_RECALL_EPOCH[$slug]}" ]]; then
        LAST_RECALL_EPOCH["$slug"]=$local_epoch
      fi
    done <<< "$slugs"
  done < "$RECALL_LOG"
fi

# Build orphan set (notes with no inbound links)
declare -A HAS_INBOUND
while IFS= read -r target; do
  [[ "$target" =~ ^[a-zA-Z0-9_-]+$ ]] || continue
  HAS_INBOUND["$target"]=1
done < <(grep -roh '\[\[[^]]*\]\]' "$WIKI_DIR/projects/" "$WIKI_DIR/cards/" 2>/dev/null | sed 's/\[\[//;s/\]\]//' | sort -u)

# Recall log maturity: if < 7 days of data, reduce recall weight
LOG_DAYS=0
if [[ -f "$RECALL_LOG" ]]; then
  FIRST_LOG_DATE=$(head -1 "$RECALL_LOG" | cut -d'|' -f1 | cut -dT -f1)
  FIRST_EPOCH=$(date -d "$FIRST_LOG_DATE" +%s 2>/dev/null || echo "$NOW")
  LOG_DAYS=$(( (NOW - FIRST_EPOCH) / 86400 + 1 ))
fi
RECALL_IMMATURE=0
if [[ $LOG_DAYS -lt 7 ]]; then
  RECALL_IMMATURE=1
fi

# Score each note
declare -a RESULTS=()

score_note() {
  local filepath="$1"
  local slug=$(basename "$filepath" .md)
  local dir=$(dirname "$filepath")
  local category=$(basename "$dir")  # projects or cards
  
  # Age in days
  local mtime=$(stat -c %Y "$filepath" 2>/dev/null || echo "$NOW")
  local age_days=$(( (NOW - mtime) / 86400 ))
  
  # Recall count (check both bare slug and category/slug)
  local recall=${RECALL_COUNT["$slug"]:-0}
  local prefixed_recall=${RECALL_COUNT["$category/$slug"]:-0}
  local total_recall=$(( recall + prefixed_recall ))
  
  # Last recall recency (days since most recent recall)
  local last_recall_days=999
  local lr_epoch=${LAST_RECALL_EPOCH["$slug"]:-0}
  local lr_prefixed=${LAST_RECALL_EPOCH["$category/$slug"]:-0}
  if [[ $lr_prefixed -gt $lr_epoch ]]; then lr_epoch=$lr_prefixed; fi
  if [[ $lr_epoch -gt 0 ]]; then
    last_recall_days=$(( (NOW - lr_epoch) / 86400 ))
  fi
  
  # Compute retention using exponential decay (awk for float math)
  # retention = e^(-λ*age) * (1 + σ*ln(1+recalls)) * recency_boost
  # recency_boost = 1 + μ * max(0, 30 - last_recall_days)
  local retention
  retention=$(awk -v age="$age_days" -v recalls="$total_recall" -v lr_days="$last_recall_days" \
    -v immature="$RECALL_IMMATURE" \
    'BEGIN {
      lambda = 0.03; sigma = 0.6; mu = 0.04
      base = exp(-lambda * age)
      recall_boost = 1 + sigma * log(1 + recalls)
      if (immature) recall_boost = 1 + (recall_boost - 1) * 0.5
      recency = 1
      if (recalls > 0 && lr_days < 30) recency = 1 + mu * (30 - lr_days)
      ret = base * recall_boost * recency
      if (ret > 1) ret = 1
      if (ret < 0) ret = 0
      printf "%.4f", ret
    }')
  
  # Status penalty (0-25)
  local status=$(head -20 "$filepath" | grep -m1 "^status:" | sed 's/status: *//' | tr -d '"' | tr -d "'")
  local status_penalty=10  # default (no status)
  case "$status" in
    dropped|stale|archived|dead) status_penalty=25;;
    scout|stub) status_penalty=15;;
    active|tracking) status_penalty=5;;
    deep-dive|reference) status_penalty=0;;
  esac
  
  # Orphan penalty (0-15)
  local orphan_penalty=0
  if [[ -z "${HAS_INBOUND[$slug]}" ]]; then
    orphan_penalty=15
  fi
  
  # Final score: (1 - retention) * 60 + status + orphan
  local total
  total=$(awk -v ret="$retention" -v sp="$status_penalty" -v op="$orphan_penalty" \
    'BEGIN { score = (1 - ret) * 60 + sp + op; printf "%d", score }')
  
  if [[ $total -ge $THRESHOLD ]]; then
    RESULTS+=("$total|$slug|age=${age_days}d|recalls=${total_recall}|ret=${retention}|status=${status:-none}|orphan=$([ $orphan_penalty -gt 0 ] && echo 'yes' || echo 'no')")
  fi
}

# Scan all wiki notes
for f in "$WIKI_DIR"/projects/*.md "$WIKI_DIR"/cards/*.md; do
  [[ -f "$f" ]] || continue
  [[ "$(basename "$f")" == "INDEX.md" ]] && continue
  [[ "$(basename "$f")" == "backlog.md" ]] && continue
  score_note "$f"
done

# Sort by score descending, take top N
SORTED=$(printf '%s\n' "${RESULTS[@]}" | sort -t'|' -k1 -rn | head -"$TOP")

if [[ $JSON -eq 1 ]]; then
  echo "["
  first=1
  while IFS='|' read -r score slug age recalls retention status orphan; do
    [[ -z "$score" ]] && continue
    [[ $first -eq 0 ]] && echo ","
    echo "  {\"score\":$score,\"slug\":\"$slug\",\"$age\",\"$recalls\",\"$retention\",\"$status\",\"$orphan\"}"
    first=0
  done <<< "$SORTED"
  echo "]"
else
  echo "🗑️ Wiki Retire Candidates (threshold ≥ $THRESHOLD)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Stats
  total_notes=$(find "$WIKI_DIR/projects" "$WIKI_DIR/cards" -name "*.md" ! -name "INDEX.md" ! -name "backlog.md" 2>/dev/null | wc -l)
  candidate_count=${#RESULTS[@]}
  recall_entries=$(wc -l < "$RECALL_LOG" 2>/dev/null || echo 0)
  echo "Total notes: $total_notes | Candidates: $candidate_count | Recall log: ${recall_entries} entries, ${LOG_DAYS}d"
  if [[ $RECALL_IMMATURE -eq 1 ]]; then
    echo "⚠️  Recall log immature (<7 days). Recall scores halved."
  fi
  echo ""
  
  if [[ -z "$SORTED" ]]; then
    echo "  No candidates above threshold $THRESHOLD."
  else
    echo "Score | Slug                              | Age    | Recalls | Retention | Status    | Orphan"
    echo "------|-----------------------------------|--------|---------|-----------|-----------|-------"
    while IFS='|' read -r score slug age recalls retention status orphan; do
      [[ -z "$score" ]] && continue
      # Clean up field values
      age_val="${age#age=}"
      rec_val="${recalls#recalls=}"
      ret_val="${retention#ret=}"
      sta_val="${status#status=}"
      orp_val="${orphan#orphan=}"
      printf " %3d  | %-35s | %6s | %7s | %9s | %9s | %s\n" "$score" "$slug" "$age_val" "$rec_val" "$ret_val" "$sta_val" "$orp_val"
    done <<< "$SORTED"
  fi
  
  echo ""
  echo "Legend: score = (1-retention)*60 + status(0-25) + orphan(0-15)"
  echo "  retention = e^(-0.03*age) × recall_boost × recency_boost"
  echo "  ≥80: strong retire candidate | ≥60: review needed"
  echo ""
  echo "Actions: archive (move to wiki/archive/), compress (reduce to stub), or delete"
fi
