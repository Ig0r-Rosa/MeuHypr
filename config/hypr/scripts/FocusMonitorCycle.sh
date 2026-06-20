#!/usr/bin/env bash
# Alterna foco entre monitores e centraliza o cursor (Super+Shift+Tab).

monitor_count() {
  hyprctl monitors -j | jq 'length'
}

move_cursor_to_focused_monitor() {
  local pos
  pos="$(hyprctl monitors -j | jq -r '
    .[] | select(.focused) |
    "\((.x + (.width / 2) | floor)) \((.y + (.height / 2) | floor))"
  ')"
  [[ -n "$pos" ]] || return 0
  hyprctl dispatch movecursor $pos
}

[[ "$(monitor_count)" -le 1 ]] && exit 0

hyprctl dispatch focusmonitor +1
move_cursor_to_focused_monitor
