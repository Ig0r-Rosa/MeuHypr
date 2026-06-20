#!/usr/bin/env bash
# Duplo toque no Super em menos de 1s alterna fullscreen da janela ativa.

STAMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/super-double-fullscreen.ts"
WINDOW_MS=1000

now_ms() {
  date +%s%3N
}

NOW=$(now_ms)

if [[ -f "$STAMP_FILE" ]]; then
  LAST=$(<"$STAMP_FILE")
  DELTA=$((NOW - LAST))
  if (( DELTA < WINDOW_MS )); then
    rm -f "$STAMP_FILE"
    hyprctl dispatch fullscreen
    exit 0
  fi
fi

echo "$NOW" > "$STAMP_FILE"
