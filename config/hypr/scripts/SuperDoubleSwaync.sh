#!/usr/bin/env bash
# Duplo toque no Super em menos de 1s abre/fecha o painel SwayNC.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/super-double-swaync.ts"
WINDOW_MS=1000

now_ms() {
  date +%s%3N
}

toggle_swaync_panel() {
  "$script_dir/SwayncPanel.sh" toggle
}

NOW=$(now_ms)

if [[ -f "$STAMP_FILE" ]]; then
  LAST=$(<"$STAMP_FILE")
  DELTA=$((NOW - LAST))
  if (( DELTA < WINDOW_MS )); then
    rm -f "$STAMP_FILE"
    toggle_swaync_panel
    exit 0
  fi
fi

echo "$NOW" > "$STAMP_FILE"
