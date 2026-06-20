#!/usr/bin/env bash
# Menu de volume e saída de áudio via Rofi.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

rofi_theme="$HOME/.config/rofi/config-menu.rasi"

set_volume() {
  pamixer -u 2>/dev/null || true
  pamixer --set-volume "$1" --allow-boost
}

set_sink() {
  pamixer --set-default-sink "$1"
}

append_volume_items() {
  local current="$1" step mark
  for step in 0 10 20 30 40 50 60 70 80 90 100; do
    mark="  "
    [[ "$step" -eq "$current" ]] && mark="● "
    echo "vol:${step}|${mark}${step}%"
  done
}

append_sink_items() {
  local default_sink="$1"
  pactl -f json list sinks 2>/dev/null | jq -r --arg d "$default_sink" '
    .[] | "sink:\(.name)|" + (if .name == $d then "● " else "  " end) + .description
  '
}

parse_choice() {
  local payload="$1" type target
  payload="${payload%%|*}"
  type="${payload%%:*}"
  target="${payload#*:}"

  case "$type" in
    vol) set_volume "$target" ;;
    sink) set_sink "$target" ;;
  esac
}

build_menu() {
  local current default_sink
  current=$(pamixer --get-volume 2>/dev/null || echo 0)
  default_sink=$(pactl get-default-sink 2>/dev/null)
  append_volume_items "$current"
  append_sink_items "$default_sink"
}

choice=$(build_menu | rofi_menu_pick "Áudio" "$rofi_theme")
[[ -n "$choice" ]] && parse_choice "$choice"
