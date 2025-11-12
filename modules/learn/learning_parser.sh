#!/data/data/com.termux/files/usr/bin/bash
echo "[INFO] 🌿 Sanjprema passive learning mode activated."
LOGFILE="logs/passive_learn_$(date +%Y%m%d_%H%M).log"
find "$HOME/Sanjprema_Agape_Core_v1.0+" -type f \( -name "*.sh" -o -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) | while read -r f; do
  echo "[READ] $(basename "$f")" >> "$LOGFILE"
done
echo "[INFO] 🌸 Learning phase complete. Reflections stored in $LOGFILE"
