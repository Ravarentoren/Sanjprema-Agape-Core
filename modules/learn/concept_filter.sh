#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TS=$(date -u +"%Y%m%dT%H%M%SZ")
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SUG_DIR="$ROOT/dict/suggestions"
PROP_DIR="$ROOT/dict/proposals"
LOG="$ROOT/logs/concept_filter_$TS.log"

mkdir -p "$PROP_DIR"

echo "[INFO] [$TS] Starting concept_filter 3.0..." | tee "$LOG"

# Nejnovější suggestions
SUG=$(ls -1t "$SUG_DIR"/*.yml | head -n1)

echo "[INFO] Using suggestions: $(basename "$SUG")" | tee -a "$LOG"

# Extrahuj termy z YML, ignoruj čísla a nesmysly
mapfile -t TERMS < <(
  grep -Eo 'term: "[a-z0-9_\\-]+"' "$SUG" \
  | sed 's/term: "//' | sed 's/"$//' \
  | grep -Ev '^[0-9]+$' \
  | sort -u
)

OUT="$PROP_DIR/proposal_$TS.yml"
echo "timestamp: \"$TS\"" > "$OUT"
echo "type: concept_proposal" >> "$OUT"
echo "proposals:" >> "$OUT"

for t in "${TERMS[@]}"; do
  echo "  - term: \"$t\"" >> "$OUT"
done

echo "[INFO] Proposal created: $OUT" | tee -a "$LOG"
