#!/usr/bin/env bash
# Alterna zona exclusiva da waybar (libera topo para overlay do swaync cobrir a barra).

EXCLUSIVE="${1:-true}"
WAYBAR_CFG="${HOME}/.config/waybar/config"
TARGET="$(readlink -f "$WAYBAR_CFG" 2>/dev/null || echo "$WAYBAR_CFG")"

[[ -f "$TARGET" ]] || exit 1

sed -i "s/\"exclusive\": \(true\|false\)/\"exclusive\": ${EXCLUSIVE}/" "$TARGET"

if command -v waybar-msg >/dev/null 2>&1; then
  waybar-msg cmd reload >/dev/null 2>&1 || true
elif pgrep -x waybar >/dev/null; then
  pkill -SIGUSR2 waybar 2>/dev/null || true
fi
