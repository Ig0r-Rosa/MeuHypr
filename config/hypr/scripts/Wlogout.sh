#!/usr/bin/env bash
# Menu de energia — Super+Alt+Delete (Rofi script, padrão do launcher).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

theme="$HOME/.config/rofi/config-power.rasi"
power_py="$scripts_dir/RofiPower.py"

rofi_require "$theme"
[[ -f "$power_py" ]] || {
  notify-send -u critical "Energia" "Script RofiPower.py não encontrado." 2>/dev/null
  exit 1
}

rofi_prepare

# shellcheck source=/dev/null
source "$scripts_dir/PowerActionGuard.sh"
reset_power_action_guard

"$rofi_bin" \
  -show power \
  -modi "power:$power_py" \
  -config "$theme"
