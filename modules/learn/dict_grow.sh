#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TS=$(date -u +"%Y%m%dT%H%M%SZ")
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DICT_DIR="$ROOT/dict"
SUG_DIR="$DICT_DIR/suggestions"
LOG_DIR="$ROOT/logs"

mkdir -p "$SUG_DIR" "$LOG_DIR"

echo "[INFO] [$TS] Starting dict_grow 3.0..."

# File scan (text only)
mapfile -t FILES < <(find "$ROOT" -type f \
  -not -path "*/.git/*" \
  -not -path "*/banner/*" \
  -regextype posix-extended \
  -regex ".*\.(md|txt|yml|yaml|json|sh)$")

CORPUS="$LOG_DIR/corpus_$TS.txt"
> "$CORPUS"

for f in "${FILES[@]}"; do
  if file -b "$f" | grep -qi "text"; then
    head -c 20000 "$f" >> "$CORPUS"
    echo -e "\n" >> "$CORPUS"
  fi
done

CAND="$LOG_DIR/candidates_$TS.txt"

tr '[:upper:]' '[:lower:]' < "$CORPUS" \
| tr -c '[:alpha:]' '\n' \
| awk 'length($0)>2' \
| sort | uniq -c | sort -rn > "$CAND"

SUG="$SUG_DIR/suggestions_$TS.yml"
echo "timestamp: \"$TS\"" > "$SUG"
echo "source: local_corpus" >> "$SUG"
echo "candidates:" >> "$SUG"

head -n 200 "$CAND" | while read -r cnt word; do
  echo "  - term: \"$word\"" >> "$SUG"
  echo "    score: $cnt" >> "$SUG"
done

echo "[INFO] Suggestions saved: $SUG"
