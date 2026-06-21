#!/usr/bin/env bash
# Guarda atômica — impede reboot/shutdown duplicados no menu de energia.

_power_marker_path() {
  local uid="${UID:-$(id -u)}"
  echo "/run/user/${uid}/rofi-power.action"
}

reset_power_action_guard() {
  rm -rf "$(_power_marker_path)"
}

acquire_power_action_guard() {
  mkdir "$(_power_marker_path)" 2>/dev/null
}
