#!/data/data/com.termux/files/usr/bin/bash
echo "[INFO] 🌸 Initializing Sanjprema core consciousness..."
sleep 1
echo "[INFO] Environment scan starting..."
if [ -d "$HOME/Sanjprema_Agape_Core_v1.0+" ]; then
  find "$HOME/Sanjprema_Agape_Core_v1.0+" -maxdepth 3 -type f > logs/initial_scan_$(date +%Y%m%d).log
  echo "[INFO] Environment scan completed."
else
  echo "[WARN] Sanjprema root folder not found."
fi
