#!/usr/bin/env bash
# btop + nvtop em área vazia — atalho do painel SwayNC.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/SwayncClosePanel.sh" 2>/dev/null || true
sleep 0.15
"$script_dir/WaybarSystemMonitor.sh"
