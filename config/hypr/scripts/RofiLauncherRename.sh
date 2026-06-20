#!/usr/bin/env bash
# Campo de renomear — janela estilo Super+S, acima do launcher (pidfile próprio).

ROFI_BIN="/usr/local/bin/rofi"
THEME="$HOME/.config/rofi/config-launcher-rename.rasi"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/rofi-rename.pid"
CURRENT="${1:-}"

[[ -x "$ROFI_BIN" && -f "$THEME" ]] || exit 1

"$ROFI_BIN" \
  -dmenu \
  -config "$THEME" \
  -pid "$PIDFILE" \
  -filter "$CURRENT"
