#!/usr/bin/env bash
# Fecha o painel swaync e executa a ação do módulo da waybar.

scripts_dir="${HOME}/.config/hypr/scripts"
CLOSE="${scripts_dir}/SwayncClosePanel.sh"

case "$1" in
  workspace)
    "$CLOSE"
    exec hyprctl dispatch workspace "name:${2:?}"
    ;;
  workspace-rel)
    "$CLOSE"
    exec hyprctl dispatch workspace "${2:?}"
    ;;
  terminal) "$CLOSE"; exec "${scripts_dir}/WaybarTerminal.sh" ;;
  launcher) "$CLOSE"; exec "${scripts_dir}/RofiLauncher.sh" ;;
  calendar) "$CLOSE"; exec "${scripts_dir}/WaybarCmatrix.sh" ;;
  files)    "$CLOSE"; exec "${scripts_dir}/WaybarYazi.sh" ;;
  add-ws)   "$CLOSE"; exec "${scripts_dir}/WaybarAddWorkspace.sh" ;;
  *)
    "$CLOSE"
    [[ $# -gt 0 ]] && exec "$@"
    ;;
esac
