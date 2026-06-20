#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# For applying Pre-configured Monitor Profiles

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

iDIR="$HOME/.config/swaync/images"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
monitor_dir="$HOME/.config/hypr/Monitor_Profiles"
target="$HOME/.config/hypr/monitors.conf"
rofi_theme="$HOME/.config/rofi/config-Monitors.rasi"
msg='Perfil de monitor (sobrescreve monitors.conf)'

ignore_files=(
  "README"
)

mon_profiles_list=$(find -L "$monitor_dir" -maxdepth 1 -type f | sed 's/.*\///' | sed 's/\.conf$//' | sort -V)

for ignored_file in "${ignore_files[@]}"; do
  mon_profiles_list=$(echo "$mon_profiles_list" | grep -v -E "^$ignored_file$")
done

chosen_file=$(echo "$mon_profiles_list" | rofi_menu_pick "$msg" "$rofi_theme")

if [[ -n "$chosen_file" ]]; then
  full_path="$monitor_dir/$chosen_file.conf"
  cp "$full_path" "$target"
  notify-send -u low -i "$iDIR/ja.png" "$chosen_file" "Monitor Profile Loaded"
fi

sleep 1
${SCRIPTSDIR}/RefreshNoWaybar.sh &
