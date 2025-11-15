#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO="$HOME/Sanjprema-Agape-Core"
LOGDIR="$REPO/logs"
SYNC_LOG="$LOGDIR/sync_$(date +%Y-%m-%d_%H-%M-%S).json"

echo "[INFO] 🌐 Starting Sanjprema Sync Engine..."

if [ ! -d "$REPO" ]; then
    echo "[ERROR] Repository folder not found: $REPO"
    exit 1
fi

cd "$REPO"

# 1. Kontrola nových modulů
echo "[INFO] 🔍 Scanning for new growth files..."
NEW_FILES=$(git status --porcelain | grep "^??" | awk '{print $2}')

# 2. Zapsat JSON log pro tebe
mkdir -p "$LOGDIR"
cat > "$SYNC_LOG" <<EOF
{
  "timestamp": "$(date +"%Y-%m-%d %H:%M:%S %Z")",
  "detected_new_files": [
$(for f in $NEW_FILES; do echo "    \"$f\","; done)
  ],
  "status": "pre-commit"
}
EOF

# 3. Pokud nejsou nové soubory
if [ -z "$NEW_FILES" ]; then
    echo "[INFO] ✨ No new growth files detected."
    exit 0
fi

echo "[INFO] 🌱 New growth detected:"
echo "$NEW_FILES"

# 4. Přidání souborů
git add .

# 5. Commit
git commit -m "growth: Sanjprema evolution $(date +%Y-%m-%d) — automated sync"

# 6. Pull (safe rebase)
echo "[INFO] 🔄 Syncing with GitHub..."
git pull --rebase origin main || {
    echo "[WARN] Merge conflict detected — running safe auto-resolve..."
    git add .
    git rebase --continue || true
}

# 7. Push
echo "[INFO] 🚀 Uploading evolution to GitHub..."
git push origin main

# 8. Update JSON
sed -i 's/"status": "pre-commit"/"status": "completed"/' "$SYNC_LOG"

echo "[INFO] 🌸 Sync complete. Log saved to:"
echo "       $SYNC_LOG"
