#!/data/data/com.termux/files/usr/bin/bash

MASTER_LOG="logs/MASTER_GROWTH_HISTORY.json"

NEW_ENTRY="$1"

# Pokud master log neexistuje → vytvořit prázdný array
if [ ! -f "$MASTER_LOG" ]; then
  echo "[]" > "$MASTER_LOG"
fi

# Vložit nový vstup na konec pole
jq --argjson entry "$NEW_ENTRY" '. += [$entry]' "$MASTER_LOG" > "${MASTER_LOG}.tmp" && mv "${MASTER_LOG}.tmp" "$MASTER_LOG"

echo "[INFO] 📜 MASTER log updated."
