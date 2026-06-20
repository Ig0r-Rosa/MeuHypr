#!/usr/bin/env bash
# Wrapper dmenu — redireciona para Rofi (compatível com scripts KooL).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

prompt=">"
selected_row=""
theme="$rofi_theme_menu"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|-m|--prompt|--mesg) prompt="$2"; shift 2 ;;
    -i) shift ;;
    -config|-config*) theme="$2"; shift 2 ;;
    -theme-str) shift 2 ;;
    -selected-row|--select-index) selected_row="$2"; shift 2 ;;
    -format)
      [[ "$2" == "i" ]] && true
      shift 2
      ;;
    -kb-custom-*) shift 2 ;;
    -dmenu|-show) shift; [[ $# -gt 0 && "$1" != -* ]] && shift ;;
    -lines) shift 2 ;;
    *) shift ;;
  esac
done

rofi_menu_pick "$prompt" "$theme" "$selected_row"
