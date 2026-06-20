#!/usr/bin/env bash
# Fecha o painel swaync e executa a ação do módulo da waybar.

CLOSE="/home/igor/.config/hypr/scripts/SwayncClosePanel.sh"

case "$1" in
  workspace)
    "$CLOSE"
    exec hyprctl dispatch workspace "name:${2:?}"
    ;;
  workspace-rel)
    "$CLOSE"
    exec hyprctl dispatch workspace "${2:?}"
    ;;
  terminal) "$CLOSE"; exec /home/igor/.config/hypr/scripts/WaybarTerminal.sh ;;
  launcher) "$CLOSE"; exec /home/igor/.config/hypr/scripts/RofiLauncher.sh ;;
  calendar) "$CLOSE"; exec /home/igor/.config/hypr/scripts/WaybarCalendar.sh ;;
  files)    "$CLOSE"; exec nautilus --new-window ;;
  add-ws)   "$CLOSE"; exec /home/igor/.config/hypr/scripts/WaybarAddWorkspace.sh ;;
  *)
    "$CLOSE"
    [[ $# -gt 0 ]] && exec "$@"
    ;;
esac
