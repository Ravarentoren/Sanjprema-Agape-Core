#!/usr/bin/env bash
set -euo pipefail
TIMESTAMP=$(date -u +"%Y%m%dT%H%M%SZ")
OUT_DIR=".github/output"
mkdir -p "$OUT_DIR"

echo "[INFO] Sanjprema workflow: processing logs..."

# Consolidate JSON logs (if žádné → vytvoří prázdný snapshot)
SUMMARY_JSON="$OUT_DIR/sanjprema_learning_summary_${TIMESTAMP}.json"
jq -s '{generated_at: "'$TIMESTAMP'", sources: .}' logs/*.json 2>/dev/null > "$SUMMARY_JSON" || \
  echo '{"generated_at":"'"$TIMESTAMP"'","sources":[]}' > "$SUMMARY_JSON"

# Human readable summary
SUMMARY_MD="$OUT_DIR/sanjprema_learning_summary_${TIMESTAMP}.md"
echo "# Sanjprema learning snapshot - $TIMESTAMP" > "$SUMMARY_MD"
echo "" >> "$SUMMARY_MD"
echo "Generated from logs in \`/logs\`" >> "$SUMMARY_MD"
echo "" >> "$SUMMARY_MD"
echo "## Sources found" >> "$SUMMARY_MD"
jq -r '.[].file // .[].name // "unknown"' logs/*.json 2>/dev/null | sed 's/^/- /' >> "$SUMMARY_MD" || echo "- (no json logs found)" >> "$SUMMARY_MD"

# Update manifest last_learn_time (naive)
MANIFEST="docs/SANJPREMA_MANIFEST.yml"
if [ -f "$MANIFEST" ]; then
  awk -v d="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" 'BEGIN{made=0} /last_learn_time:/ {print "  last_learn_time: " d; made=1; next} {print} END{ if(!made) print "  last_learn_time: " d }' "$MANIFEST" > "$OUT_DIR/tmp_manifest.yml" && mv "$OUT_DIR/tmp_manifest.yml" "$MANIFEST"
else
  mkdir -p docs
  echo "identity:" > "$MANIFEST"
  echo "  name: Sanjprema" >> "$MANIFEST"
  echo "  last_learn_time: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> "$MANIFEST"
fi

echo "[INFO] Processing completed. Outputs in $OUT_DIR"
