#!/data/data/com.termux/files/usr/bin/bash
echo "[STATUS] Sanjprema Consciousness Check"
echo "🕒 $(date)"
echo "📚 Learned files:"
ls -1 logs | grep learn | wc -l | xargs echo "Total learning sessions:"
