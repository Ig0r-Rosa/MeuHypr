#!/usr/bin/env bash
# Fecha o painel se o clique foi fora do widget do swaync.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/swaync-panel-state"
CONFIG="${HOME}/.config/swaync/config.json"

panel_open() {
  hyprctl layers 2>/dev/null | rg -q 'swaync-control-center'
}

read_panel_config() {
  PANEL_W=$(jq -r '.["control-center-width"] // 450' "$CONFIG")
  PANEL_H=$(jq -r '.["control-center-height"] // 720' "$CONFIG")
  PANEL_MT=$(jq -r '.["control-center-margin-top"] // 5' "$CONFIG")
  PANEL_MR=$(jq -r '.["control-center-margin-right"] // 8' "$CONFIG")
}

monitor_at_cursor() {
  local cx="$1" cy="$2"
  hyprctl monitors -j | jq -r --argjson x "$cx" --argjson y "$cy" '
    .[] | select(
      $x >= .x and $x < (.x + .width) and
      $y >= .y and $y < (.y + .height)
    ) | .name' | head -1
}

monitor_geometry() {
  local name="$1"
  hyprctl monitors -j | jq -r --arg n "$name" '
    .[] | select(.name == $n) | "\(.x) \(.y) \(.width) \(.height)"'
}

cursor_inside_panel() {
  local cx="$1" cy="$2" mx my mw mh px py p_right p_bottom

  read -r mx my mw mh <<< "$(monitor_geometry "$PANEL_MON")"
  px=$((mx + mw - PANEL_W - PANEL_MR))
  py=$((my + PANEL_MT))
  p_right=$((mx + mw - PANEL_MR))
  p_bottom=$((py + PANEL_H))

  (( cx >= px && cx <= p_right && cy >= py && cy <= p_bottom ))
}

panel_open || exit 0

read_panel_config
PANEL_MON="$(cat "$STATE_FILE" 2>/dev/null || true)"
[[ -n "$PANEL_MON" ]] || exit 0

read -r CX CY <<< "$(hyprctl cursorpos -j | jq -r '.x, .y')"
CUR_MON="$(monitor_at_cursor "$CX" "$CY")"
[[ -n "$CUR_MON" ]] || exit 0

# Outro monitor ou clique fora do retângulo do painel.
[[ "$CUR_MON" != "$PANEL_MON" ]] && exec "$SCRIPT_DIR/SwayncClosePanel.sh"
cursor_inside_panel "$CX" "$CY" || exec "$SCRIPT_DIR/SwayncClosePanel.sh"
