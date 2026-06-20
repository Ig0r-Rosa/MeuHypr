#!/usr/bin/env bash
# Clipboard via cliphist + Rofi.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

rofi_theme="$HOME/.config/rofi/config-clipboard.rasi"
msg='Enter = colar | Ctrl+Del = apagar | Alt+Del = limpar'

while true; do
  rofi_require "$rofi_theme"
  rofi_prepare

  result=$(
    cliphist list | "$rofi_bin" -dmenu -i -config "$rofi_theme" -p "$msg"
  )
  exit_code=$?

  case "$exit_code" in
    1) exit 0 ;;
    10) [[ -n "$result" ]] && cliphist delete <<<"$result" ;;
    11) cliphist wipe ;;
    0)
      case "$result" in
        "") continue ;;
        *)
          cliphist decode <<<"$result" | wl-copy
          exit 0
          ;;
      esac
      ;;
  esac
done
