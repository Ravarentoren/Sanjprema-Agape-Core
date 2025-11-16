#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TS=$(date -u +"%Y%m%dT%H%M%SZ")
ROOT="$(pwd)"
DICT="$ROOT/dict"
LOG_DIR="$ROOT/logs"

BASE="$DICT/DICT_BASE_FULL.yml"
PROP_DIR="$DICT/proposals"
OUT="$DICT/DICT_MASTER_$TS.yml"
LOG="$LOG_DIR/master_update_$TS.json"

echo "[INFO] Building MASTER DICT 3.0..."
echo "[INFO] Timestamp: $TS"

if [ ! -f "$BASE" ]; then
  echo "[ERROR] Missing dict/DICT_BASE_FULL.yml"
  exit 1
fi

echo "version: \"3.0.0\"" > "$OUT"
echo "generated: \"$TS\"" >> "$OUT"
echo "combined_from:" >> "$OUT"
echo "  - base: $(basename "$BASE")" >> "$OUT"
echo "" >> "$OUT"
echo "# ------------------------------------------------------" >> "$OUT"
echo "# BASE" >> "$OUT"
echo "# ------------------------------------------------------" >> "$OUT"

cat "$BASE" >> "$OUT"
echo "" >> "$OUT"

echo "# ------------------------------------------------------" >> "$OUT"
echo "# PROPOSALS" >> "$OUT"
echo "# ------------------------------------------------------" >> "$OUT"

# dedupe set
declare -A seen_terms

for P in "$PROP_DIR"/*.yml; do
  [ -e "$P" ] || continue
  echo "  - proposal: $(basename "$P")" >> "$OUT"

  while read -r line; do
    if [[ "$line" =~ term:\ \"(.+)\" ]]; then
      term="${BASH_REMATCH[1]}"
      if [[ -z "${seen_terms[$term]+x}" ]]; then
        echo "    - term: \"$term\"" >> "$OUT"
        seen_terms[$term]=1
      fi
    fi
  done < "$P"
done

jq -n --arg ts "$TS" --arg file "$(basename "$OUT")" \
  '{timestamp:$ts, master_dict:$file}' > "$LOG"

echo "[INFO] MASTER DICT created: $OUT"
echo "[INFO] Log saved: $LOG"

