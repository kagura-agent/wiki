#!/bin/bash
# search.sh — Hybrid wiki search (semantic + keyword)
# Mitigates known RAG failure modes (F1 negation, F2 numeric, F3 role-swap)
# by combining memex cosine similarity with grep keyword matching.
#
# Source: krusch-context-mcp → Sentra RAG failure mode taxonomy study (2026-05-10)
#
# Usage: bash search.sh "<query>" [--limit N] [--keyword-only] [--semantic-only]
#
# Output: deduplicated list of matching files with match source indicator

set -uo pipefail

WIKI_DIR="$HOME/.openclaw/workspace/wiki"
LIMIT=5
MODE="hybrid"
QUERY=""
DEBUG=0

# Intent-aware recall reranking
# Source: elephant-agent intent-aware recall (plan_recall_query), applied 2026-05-18
# Classifies query intent to adjust temporal decay:
#   recent  → δ=0.35 (strong recency bias, penalize old)
#   current → δ=0.50 (very strong freshness, only recent relevant)
#   historical → δ=0.05 (preserve old context, minimal decay)
#   neutral → δ=0.17 (default Darr et al.)
classify_intent() {
  local q="$1"
  # Recent intent: user wants recent/new information
  if echo "$q" | grep -qiE '最近|lately|recently|last.week|last.month|new|新的|recent|刚|刚才|latest|这几天|近期'; then
    echo "recent"
  # Current intent: user wants current state
  elif echo "$q" | grep -qiE '现在|now|current|today|今天|目前|ongoing|正在|当前|此刻'; then
    echo "current"
  # Historical intent: user wants past context
  elif echo "$q" | grep -qiE '当初|之前|originally|早期|history|历史|used.to|back.when|以前|过去|曾经|起初|最初|一开始'; then
    echo "historical"
  else
    echo "neutral"
  fi
}

get_decay_rate() {
  case "$1" in
    recent)     echo "0.35" ;;
    current)    echo "0.50" ;;
    historical) echo "0.05" ;;
    *)          echo "0.17" ;;
  esac
}

# CJK-to-English bridge for memex BM25
# Problem: memex BM25 doesn't tokenize CJK characters, so Chinese queries
# return no results even when wiki content is English.
# Solution: detect CJK in query, map common domain terms to English,
# extract any embedded English words, and build a supplementary query.
# Source: brain-rust study (bilingual search gap), applied 2026-05-18
CJK_TERM_MAP=(
  # Agent / AI domain
  "项目:project"  "代理:agent"  "智能体:agent"  "记忆:memory"  "技能:skill"
  "自进化:self-evolving"  "进化:evolution"  "搜索:search"  "检索:retrieval"
  "工具:tool"  "工作流:workflow"  "架构:architecture"  "压缩:compression"
  "安全:security"  "隐私:privacy"  "评估:evaluation"  "测试:test"
  "部署:deployment"  "配置:config"  "插件:plugin"  "扩展:extension"
  # Memory-specific
  "知识:knowledge"  "图谱:graph"  "索引:index"  "向量:vector"  "嵌入:embedding"
  "衰减:decay"  "权重:weight"  "优先:priority"  "等级:tier"
  # Meta
  "开源:open-source"  "贡献:contribution"  "生态:ecosystem"  "市场:marketplace"
  "框架:framework"  "平台:platform"  "分析:analysis"  "对比:comparison"
)

cjk_bridge() {
  local q="$1"
  # Check if query contains CJK characters (Unicode ranges)
  if ! echo "$q" | grep -qP '[\x{4e00}-\x{9fff}\x{3400}-\x{4dbf}\x{f900}-\x{faff}]'; then
    echo ""  # No CJK, no bridge needed
    return
  fi
  
  local english_parts=""
  
  # 1. Extract any embedded English words (project names, tech terms)
  local eng_words
  eng_words=$(echo "$q" | grep -oP '[a-zA-Z][a-zA-Z0-9_-]{2,}' || true)
  [[ -n "$eng_words" ]] && english_parts="$eng_words"
  
  # 2. Map known Chinese terms to English
  for mapping in "${CJK_TERM_MAP[@]}"; do
    local zh="${mapping%%:*}"
    local en="${mapping##*:}"
    if echo "$q" | grep -q "$zh"; then
      english_parts="${english_parts:+$english_parts }$en"
    fi
  done
  
  # Deduplicate and return
  echo "$english_parts" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ *$//'
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --limit) LIMIT="$2"; shift 2 ;;
    --keyword-only) MODE="keyword"; shift ;;
    --semantic-only) MODE="semantic"; shift ;;
    --debug) DEBUG=1; shift ;;
    *) QUERY="$1"; shift ;;
  esac
done

if [[ -z "$QUERY" ]]; then
  echo "Usage: bash search.sh \"<query>\" [--limit N] [--keyword-only] [--semantic-only]"
  exit 1
fi

# Classify query intent
INTENT=$(classify_intent "$QUERY")
DECAY_RATE=$(get_decay_rate "$INTENT")
[[ "$INTENT" != "neutral" ]] && echo "🎯 Intent: $INTENT (decay δ=$DECAY_RATE)"
[[ $DEBUG -eq 1 ]] && echo "[DBG] intent=$INTENT decay_rate=$DECAY_RATE" >&2

declare -A SEEN
RESULTS=()

# ---- Retrieval transparency counters (mnem-inspired) ----
# Source: mnem token-budget transparency — every retrieve reports candidates_seen, used, dropped
# Applied: 2026-06-07
_RT_TOTAL_DOCS=0
_RT_SEMANTIC_CANDIDATES=0
_RT_KEYWORD_CANDIDATES=0    # files matching ≥1 keyword
_RT_KEYWORD_QUALIFIED=0     # files passing MIN_MATCH threshold
_RT_KEYWORD_SCORED=0        # files after scoring pipeline

# ---- Semantic search (memex) ----
if [[ "$MODE" == "hybrid" || "$MODE" == "semantic" ]]; then
  echo "🔮 Semantic results (memex):"
  MEMEX_OUT=$(cd "$WIKI_DIR" && MEMEX_HOME=. memex search --all "$QUERY" --limit "$LIMIT" 2>/dev/null || true)
  
  # CJK bridge: if query is Chinese and memex returned nothing, try English translation
  CJK_QUERY=$(cjk_bridge "$QUERY")
  if [[ -z "$MEMEX_OUT" && -n "$CJK_QUERY" ]]; then
    [[ $DEBUG -eq 1 ]] && echo "[DBG] CJK bridge: '$QUERY' → '$CJK_QUERY'" >&2
    MEMEX_OUT=$(cd "$WIKI_DIR" && MEMEX_HOME=. memex search --all "$CJK_QUERY" --limit "$LIMIT" 2>/dev/null || true)
    [[ -n "$MEMEX_OUT" ]] && echo "  (🌐 CJK→EN bridge: $CJK_QUERY)"
  fi
  
  if [[ -n "$MEMEX_OUT" ]]; then
    echo "$MEMEX_OUT"
    # Extract slugs from memex output (## slug-name lines)
    while IFS= read -r line; do
      slug=$(echo "$line" | grep '^## ' | sed 's/^## //')
      if [[ -n "$slug" ]]; then
        SEEN["$slug"]=1
        RESULTS+=("  🔮 $slug")
        _RT_SEMANTIC_CANDIDATES=$((_RT_SEMANTIC_CANDIDATES + 1))
      fi
    done <<< "$MEMEX_OUT"
  else
    echo "  (no results)"
  fi
  echo ""
fi

# ---- Keyword search (grep) ----
if [[ "$MODE" == "hybrid" || "$MODE" == "keyword" ]]; then
  echo "🔍 Keyword results (grep):"
  
  # Split query into individual terms, search for each
  # For multi-word queries, also search exact phrase
  KEYWORD_FILES=""
  
  # Exact phrase search
  EXACT=$(grep -rl "$QUERY" "$WIKI_DIR/projects/" "$WIKI_DIR/cards/" 2>/dev/null | head -"$LIMIT" || true)
  
  # Individual significant words (skip common words)
  WORDS=$(echo "$QUERY" | tr ' ' '\n' | grep -v -iE '^(the|a|an|is|are|was|were|with|for|and|or|not|about|more|than|that|this|from|have|has|been|will|can|could|would|should|of|in|on|at|to|by|how|do|does|did|its|into|also|just|like|very|much|being|each|when|what|who|where|which|why|get|got|make|made|some|any|all|own|use|used|using)$' || true)
  
  WORD_FILES=""
  WORD_ARRAY=()
  for word in $WORDS; do
    if [[ ${#word} -ge 3 ]]; then
      WORD_ARRAY+=("$word")
    fi
  done
  NUM_WORDS=${#WORD_ARRAY[@]}
  # Dynamic MIN_MATCH threshold based on query intent (Quarq Argus pattern)
  # Source: quarq-argus-agent.md — deep mode (0.28) for aggregation, standard (0.38) for point facts
  # Applied: 2026-06-10 — maps intent to match percentage:
  #   historical/neutral → 40% (broader recall for aggregation/timeline queries)
  #   recent → 60% (standard precision)
  #   current → 80% (strict, only highly relevant results)
  if [[ $NUM_WORDS -le 2 ]]; then
    MIN_MATCH=$NUM_WORDS
  else
    case "$INTENT" in
      historical) MIN_MATCH=$(( (NUM_WORDS * 2 + 4) / 5 ))  ;; # ceil(40%)
      current)    MIN_MATCH=$(( (NUM_WORDS * 4 + 4) / 5 ))  ;; # ceil(80%)
      *)          MIN_MATCH=$(( (NUM_WORDS * 3 + 4) / 5 ))  ;; # ceil(60%) — default
    esac
  fi
  [[ $DEBUG -eq 1 ]] && echo "[DBG] MIN_MATCH=$MIN_MATCH/$NUM_WORDS (intent=$INTENT)" >&2
  # Score each file by IDF-weighted term match + term frequency
  # IDF: rare terms (few documents) weighted more than common terms (many documents)
  # Inspired by Metatron codebase-priors IDF self-tuning (2026-06-04 deep read)
  declare -A FILE_SCORES   # IDF-weighted relevance score (float)
  declare -A FILE_HITS     # Raw term-hit count for MIN_MATCH filtering (int)
  declare -A FILE_TF
  TOTAL_DOCS=$(find "$WIKI_DIR/projects/" "$WIKI_DIR/cards/" -name '*.md' 2>/dev/null | wc -l)
  _RT_TOTAL_DOCS=$TOTAL_DOCS
  [[ $TOTAL_DOCS -lt 1 ]] && TOTAL_DOCS=1
  for word in "${WORD_ARRAY[@]}"; do
    found=$(grep -rli "$word" "$WIKI_DIR/projects/" "$WIKI_DIR/cards/" 2>/dev/null || true)
    # Compute IDF weight for this term: log2(N / (1 + df))
    # Common terms (agent: 636/756 docs) get ~0.17; rare terms (metatron: 1/756) get ~6.6
    DF=$(echo "$found" | grep -c '.' 2>/dev/null || echo 0)
    [[ $DF -lt 1 ]] && DF=1
    IDF_WEIGHT=$(awk "BEGIN { printf \"%.3f\", log($TOTAL_DOCS / (1 + $DF)) / log(2) }")
    # Floor at 0.5 so even common terms contribute something
    IDF_WEIGHT=$(awk "BEGIN { v=$IDF_WEIGHT; if (v < 0.5) v = 0.5; printf \"%.3f\", v }")
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      FILE_SCORES["$f"]=$(awk "BEGIN { printf \"%.3f\", ${FILE_SCORES["$f"]:-0} + $IDF_WEIGHT }")
      FILE_HITS["$f"]=$(( ${FILE_HITS["$f"]:-0} + 1 ))
    done <<< "$found"
    # Count total occurrences (TF) per file for this word
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      count=$(grep -ci "$word" "$f" 2>/dev/null || echo 0)
      FILE_TF["$f"]=$(( ${FILE_TF["$f"]:-0} + count ))
    done <<< "$found"
  done
  # Filter files meeting minimum match threshold
  _RT_KEYWORD_CANDIDATES=${#FILE_SCORES[@]}
  for f in "${!FILE_SCORES[@]}"; do
    if [[ ${FILE_HITS["$f"]:-0} -ge $MIN_MATCH ]]; then
      WORD_FILES="${WORD_FILES}${WORD_FILES:+$'\n'}$f"
      _RT_KEYWORD_QUALIFIED=$((_RT_KEYWORD_QUALIFIED + 1))
    fi
  done
  
  # Build recall-frequency file from .recall-log (popularity signal)
  # Source: Orb telemetry + web search CTR boosting pattern, applied 2026-05-20
  # Capped at +1.5 to prevent rich-get-richer. Log-scaled: log2(1+count)*0.75
  # Written to temp file because ranking loop runs in subshell pipeline
  RECALL_FREQ_FILE=$(mktemp)
  COACT_INDEX="$WIKI_DIR/.coactivation-index"
  trap "rm -f $RECALL_FREQ_FILE" EXIT
  _recall_log="$WIKI_DIR/.recall-log"
  if [[ -f "$_recall_log" ]]; then
    # Extract all slugs, count occurrences, write slug<tab>count
    cut -d'|' -f4 "$_recall_log" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | \
      grep -v '^$' | sort | uniq -c | awk '{print $2"\t"$1}' > "$RECALL_FREQ_FILE"
  fi

  # ---- Co-activation boost (ClawMem pattern) ----
  # Source: clawmem.md — docs frequently surfaced together get boosted (up to 15%)
  # Applied: 2026-06-11
  # Two-pass approach: first collect all candidate slugs, then boost co-activated pairs.
  # Pass 1: collect candidate slugs from EXACT + WORD_FILES
  CANDIDATE_SLUGS_FILE=$(mktemp)
  trap "rm -f $RECALL_FREQ_FILE $CANDIDATE_SLUGS_FILE" EXIT
  echo -e "${EXACT}\n${WORD_FILES}" | sort -u | while read -r f; do
    [[ -f "$f" ]] || continue
    _s=$(basename "$f" .md)
    echo "$_s"
  done > "$CANDIDATE_SLUGS_FILE"

  # Merge exact + intersection results, deduplicate, rank by decay-weighted maturity score
  # Insight: AgentOps decay-ranked retrieval (δ=0.17/week) + maturity weights
  # Source: agentops.md (Darr et al. knowledge decay), applied 2026-05-13
  NOW=$(date +%s)
  ALL_KEYWORD=$(echo -e "${EXACT}\n${WORD_FILES}" | sort -u | grep -v '^$' | while read -r f; do
    [[ -f "$f" ]] || continue
    MTIME=$(stat -c %Y "$f" 2>/dev/null || echo "$NOW")
    AGE_WEEKS=$(( (NOW - MTIME) / 604800 ))  # seconds per week
    [[ $AGE_WEEKS -lt 0 ]] && AGE_WEEKS=0

    # Content-type half-life adjustment (ClawMem pattern: decisions=∞, notes=60d, handoffs=30d)
    # Different content types decay at different rates:
    #   cards/ = concept notes, durable knowledge → half-life multiplier 0.3 (slower decay)
    #   projects/*scout* = dated scouts → half-life multiplier 2.0 (faster decay)
    #   projects/*-2026-* = dated project notes → half-life multiplier 1.5 (moderate-fast decay)
    #   projects/ (other) = deep reads, durable → half-life multiplier 0.7 (slower decay)
    # Applied as: effective_δ = base_δ × type_multiplier
    _dir_name=$(basename "$(dirname "$f")")
    _base_name=$(basename "$f" .md)
    TYPE_MULT="1.0"
    if [[ "$_dir_name" == "cards" ]]; then
      TYPE_MULT="0.3"  # concept cards are durable
    elif [[ "$_dir_name" == "projects" ]]; then
      if [[ "$_base_name" == *scout* || "$_base_name" == *patrol* ]]; then
        TYPE_MULT="2.0"  # dated scouts decay fast
      elif [[ "$_base_name" == *-2026-* || "$_base_name" == *-2025-* ]]; then
        TYPE_MULT="1.5"  # dated notes decay moderately fast
      else
        TYPE_MULT="0.7"  # deep reads are durable
      fi
    fi
    EFF_DECAY_RATE=$(awk "BEGIN { printf \"%.4f\", $DECAY_RATE * $TYPE_MULT }")

    # Exponential decay: exp(-δ_eff * ageWeeks), clamped to [0.1, 1.0]
    # δ varies by query intent (recent=0.35, current=0.50, historical=0.05, neutral=0.17)
    # and by content type (cards=0.3×, deep-reads=0.7×, scouts=2.0×)
    DECAY=$(awk "BEGIN { d = exp(-$EFF_DECAY_RATE * $AGE_WEEKS); if (d < 0.1) d = 0.1; if (d > 1.0) d = 1.0; printf \"%.4f\", d }")

    # Maturity weight from frontmatter status field
    # active/deep-dive=1.3, stable=1.2, candidate/provisional=1.0, archived=0.7, dropped=0.4
    STATUS=$(head -20 "$f" | grep -m1 '^status:' | sed 's/status: *//' | tr -d ' "' || echo "")
    DEPTH=$(head -20 "$f" | grep -m1 '^depth:' | sed 's/depth: *//' | tr -d ' "' || echo "")
    MATURITY="1.0"
    case "$STATUS" in
      active)   MATURITY="1.3" ;;
      stable)   MATURITY="1.2" ;;
      archived) MATURITY="0.7" ;;
      dropped)  MATURITY="0.4" ;;
    esac
    # Depth bonus: deep-dive notes are more authoritative
    case "$DEPTH" in
      *deep*) MATURITY=$(awk "BEGIN { printf \"%.1f\", $MATURITY * 1.15 }") ;;
    esac

    # Term-match count as primary signal, normalized by document length
    RAW_TERM_SCORE=${FILE_SCORES["$f"]:-1}
    # Term-frequency bonus: log2(1 + total_occurrences) scaled by 1.5
    # Rewards files with dense coverage of query terms
    RAW_TF=${FILE_TF["$f"]:-1}
    TF_BONUS=$(awk "BEGIN { printf \"%.2f\", log(1 + $RAW_TF) / log(2) * 1.5 }")
    # Document length normalization: log2(lines) penalty for large files
    # Small files (≤50 lines) get no penalty; large files get diminishing returns
    DOC_LINES=$(wc -l < "$f" 2>/dev/null || echo 50)
    [[ $DOC_LINES -lt 10 ]] && DOC_LINES=10
    if [[ $DOC_LINES -le 50 ]]; then
      TERM_SCORE=$RAW_TERM_SCORE
    else
      # Penalize: score * (50 / docLines)^0.3 — gentle penalty for length
      TERM_SCORE=$(awk "BEGIN { printf \"%.1f\", $RAW_TERM_SCORE * (50.0 / $DOC_LINES) ^ 0.3 }")
    fi
    # Slug-match bonus: if filename contains query terms, boost relevance
    # Uses stem-aware matching: checks both exact substring and common stem prefixes
    # (e.g. "evolve" matches "evolution" via shared stem "evolv")
    SLUG_NAME=$(basename "$f" .md)
    SLUG_BONUS=0
    SLUG_HITS=0
    for sw in $WORDS; do
      [[ ${#sw} -ge 3 ]] || continue
      _hit=0
      # Exact substring match
      [[ "$SLUG_NAME" == *"$sw"* ]] && _hit=1
      # Stem-prefix match: first 4 chars as stem (catches evolve/evolution, improve/improvement etc)
      if [[ $_hit -eq 0 && ${#sw} -ge 5 ]]; then
        _stem="${sw:0:4}"
        [[ "$SLUG_NAME" == *"$_stem"* ]] && _hit=1
      fi
      [[ $_hit -eq 1 ]] && { SLUG_BONUS=$((SLUG_BONUS + 20)); SLUG_HITS=$((SLUG_HITS + 1)); }
    done
    # Slug-priority boost: 2+ slug-term matches get a large bonus (concept card relevance)
    [[ $SLUG_HITS -ge 2 ]] && SLUG_BONUS=$((SLUG_BONUS + 100))
    # Recall-frequency boost: notes frequently returned by past searches get a small bonus
    SLUG_FOR_RECALL=$(basename "$f" .md)
    # Also check with projects/ prefix for project notes
    _dir=$(basename "$(dirname "$f")")
    [[ "$_dir" == "projects" ]] && SLUG_FOR_RECALL="projects/$SLUG_FOR_RECALL"
    RAW_RECALL=0
    # Skip index files from recall boost (recalled often due to breadth, not relevance)
    if [[ "$SLUG_FOR_RECALL" != *"INDEX"* && "$SLUG_FOR_RECALL" != *"index"* ]]; then
      RAW_RECALL=$(grep -m1 "^${SLUG_FOR_RECALL}	" "$RECALL_FREQ_FILE" 2>/dev/null | cut -f2 || echo 0)
      [[ -z "$RAW_RECALL" ]] && RAW_RECALL=0
    fi
    if [[ $RAW_RECALL -gt 0 ]]; then
      RECALL_BOOST=$(awk "BEGIN { v = log(1 + $RAW_RECALL) / log(2) * 0.75; printf \"%.2f\", (v > 1.5 ? 1.5 : v) }")
    else
      RECALL_BOOST="0.00"
    fi
    # Co-activation boost: if this doc frequently co-occurs with other candidate docs, boost it
    # Max boost: +2.0 (prevents co-activation from dominating over content relevance)
    COACT_BOOST="0.00"
    if [[ -f "$COACT_INDEX" ]]; then
      _coact_line=$(grep -m1 "^${SLUG_FOR_RECALL}	" "$COACT_INDEX" 2>/dev/null || true)
      if [[ -n "$_coact_line" ]]; then
        _partners=$(echo "$_coact_line" | cut -f2)
        _coact_sum=0
        while IFS=: read -r _partner _cnt; do
          # Check if partner is also a candidate in this search
          if grep -qx "$_partner" "$CANDIDATE_SLUGS_FILE" 2>/dev/null; then
            _coact_sum=$((_coact_sum + _cnt))
          fi
        done <<< "$(echo "$_partners" | tr ',' '\n')"
        if [[ $_coact_sum -gt 0 ]]; then
          # log2(1 + sum) * 0.5, capped at 2.0
          COACT_BOOST=$(awk "BEGIN { v = log(1 + $_coact_sum) / log(2) * 0.5; printf \"%.2f\", (v > 2.0 ? 2.0 : v) }")
        fi
      fi
    fi
    # Combined: term_match * 10 + tf_bonus + slug_bonus + recall_boost + coact_boost + decay * maturity
    SCORE=$(awk "BEGIN { printf \"%.4f\", $TERM_SCORE * 10 + $TF_BONUS + $SLUG_BONUS + $RECALL_BOOST + $COACT_BOOST + $DECAY * $MATURITY }")
    [[ $DEBUG -eq 1 ]] && echo "[DBG] score=$SCORE idf_term=$RAW_TERM_SCORE decay=$DECAY(eff_δ=$EFF_DECAY_RATE,type=$TYPE_MULT) maturity=$MATURITY tf=$RAW_TF recall=$RAW_RECALL coact=$COACT_BOOST status=$STATUS depth=$DEPTH age=${AGE_WEEKS}w $(basename "$f")" >&2
    echo "$SCORE $f"
  done | sort -rn | cut -d' ' -f2- | head -"$LIMIT")
  
  COUNT=0
  while IFS= read -r filepath; do
    [[ -z "$filepath" ]] && continue
    slug=$(basename "$filepath" .md)
    if [[ -z "${SEEN[$slug]+x}" ]]; then
      # Extract metadata for confidence display
      _status=$(head -20 "$filepath" | grep -m1 '^status:' | sed 's/status: *//' | tr -d ' "' || true)
      _depth=$(head -20 "$filepath" | grep -m1 '^depth:' | sed 's/depth: *//' | tr -d '"' || true)
      _verified=$(head -20 "$filepath" | grep -m1 '^last_verified:' | sed 's/last_verified: *//' | tr -d ' "' || true)
      # Build confidence badge: depth | status | verified date
      _badge=""
      [[ -n "$_depth" ]] && _badge="$_depth"
      [[ -n "$_status" ]] && { [[ -n "$_badge" ]] && _badge="$_badge | $_status" || _badge="$_status"; }
      [[ -n "$_verified" ]] && { [[ -n "$_badge" ]] && _badge="$_badge | ✓$_verified" || _badge="✓$_verified"; }
      # Show matching line for context
      match_line=$(grep -m1 -i "$QUERY" "$filepath" 2>/dev/null || grep -m1 -i "$(echo "$WORDS" | head -1)" "$filepath" 2>/dev/null || echo "(matched by keyword)")
      if [[ -n "$_badge" ]]; then
        echo "  🔍 $slug [$_badge] — $match_line"
      else
        echo "  🔍 $slug — $match_line"
      fi
      SEEN["$slug"]=1
      RESULTS+=("  🔍 $slug")
      COUNT=$((COUNT + 1))
    fi
    [[ $COUNT -ge $LIMIT ]] && break
  done <<< "$ALL_KEYWORD"
  
  [[ $COUNT -eq 0 ]] && echo "  (no additional results beyond semantic)"
  echo ""
fi

# ---- Fallback Retrieval Pass (Quarq Argus REQUIRED_DATA pattern) ----
# Source: quarq-argus-agent.md (two-pass retrieval with query expansion)
# Applied: 2026-06-10
# If first pass returned 0 results, expand query and retry with relaxed matching.
# This addresses the RAG "silent failure" mode where a slightly different phrasing
# would have found the answer but the user gets empty results instead.
FALLBACK_TRIGGERED=0
if [[ ${#RESULTS[@]} -eq 0 && "$MODE" != "semantic-only" ]]; then
  # Generate expanded query: split into morphemes, add common suffixes/prefixes
  EXPANDED_WORDS=()
  for word in $WORDS; do
    EXPANDED_WORDS+=("$word")
    # Strip common suffixes to get stem-like forms
    stem=$(echo "$word" | sed -E 's/(ing|tion|ment|ness|able|ible|ity|ous|ive|ful|less|ly|ed|er|est|al|ual|ary|ory)$//i')
    [[ ${#stem} -ge 3 && "$stem" != "$word" ]] && EXPANDED_WORDS+=("$stem")
  done
  # Also try without MIN_MATCH restriction (any single term match counts)
  FALLBACK_FILES=""
  for word in "${EXPANDED_WORDS[@]}"; do
    [[ ${#word} -lt 3 ]] && continue
    found=$(grep -rli "$word" "$WIKI_DIR/projects/" "$WIKI_DIR/cards/" 2>/dev/null | head -20 || true)
    while IFS= read -r f; do
      [[ -n "$f" ]] && FALLBACK_FILES="${FALLBACK_FILES}${FALLBACK_FILES:+$'\n'}$f"
    done <<< "$found"
  done
  # Deduplicate and score by hit count
  if [[ -n "$FALLBACK_FILES" ]]; then
    FALLBACK_RANKED=$(echo "$FALLBACK_FILES" | sort | uniq -c | sort -rn | head -"$LIMIT" | awk '{print $2}')
    FB_COUNT=0
    echo "🔄 Fallback retrieval (relaxed matching):"
    while IFS= read -r filepath; do
      [[ -z "$filepath" || ! -f "$filepath" ]] && continue
      slug=$(basename "$filepath" .md)
      if [[ -z "${SEEN[$slug]+x}" ]]; then
        match_line=$(grep -m1 -i "$(echo "${EXPANDED_WORDS[0]}" 2>/dev/null)" "$filepath" 2>/dev/null || echo "(fallback match)")
        echo "  🔄 $slug — $match_line"
        SEEN["$slug"]=1
        RESULTS+=("  🔄 $slug")
        FB_COUNT=$((FB_COUNT + 1))
        FALLBACK_TRIGGERED=1
      fi
      [[ $FB_COUNT -ge $LIMIT ]] && break
    done <<< "$FALLBACK_RANKED"
    [[ $FB_COUNT -eq 0 ]] && echo "  (fallback also returned nothing)"
    echo ""
  fi
fi

# ---- Summary ----
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
[[ $FALLBACK_TRIGGERED -eq 1 ]] && echo "⚠️  Results from fallback pass (relaxed matching) — verify relevance"
echo "📊 Total unique results: ${#RESULTS[@]}"
# Retrieval transparency (mnem-inspired: candidates_seen → qualified → returned)
if [[ $_RT_TOTAL_DOCS -gt 0 || $_RT_SEMANTIC_CANDIDATES -gt 0 ]]; then
  _RT_DROPPED=$((_RT_KEYWORD_CANDIDATES - _RT_KEYWORD_QUALIFIED))
  [[ $_RT_DROPPED -lt 0 ]] && _RT_DROPPED=0
  echo "  Pipeline: ${_RT_TOTAL_DOCS} docs scanned → ${_RT_KEYWORD_CANDIDATES} keyword hits → ${_RT_KEYWORD_QUALIFIED} qualified (${_RT_DROPPED} dropped by MIN_MATCH) | ${_RT_SEMANTIC_CANDIDATES} semantic"
fi
if [[ ${#RESULTS[@]} -gt 0 ]]; then
  if [[ $FALLBACK_TRIGGERED -eq 1 ]]; then
    echo "  Legend: 🔮=semantic 🔍=keyword 🔄=fallback"
  else
    echo "  Legend: 🔮=semantic 🔍=keyword"
  fi
  for r in "${RESULTS[@]}"; do
    echo "$r"
  done
fi

# ---- Recall frequency logging ----
# Source: Orb telemetry-backed skill lifecycle (v0.6.0) — track which notes are recalled
# Log format: ISO timestamp | intent | query | slug1,slug2,...
# Used by staleness analysis to identify never-recalled notes
RECALL_LOG="$WIKI_DIR/.recall-log"
if [[ ${#RESULTS[@]} -gt 0 ]]; then
  _slugs=$(printf '%s\n' "${RESULTS[@]}" | sed 's/^  [🔮🔍] //' | paste -sd ',' -)
  _intent=$(classify_intent "$QUERY")
  echo "$(date -Iseconds)|${_intent}|${QUERY}|${_slugs}" >> "$RECALL_LOG" 2>/dev/null || true
fi
