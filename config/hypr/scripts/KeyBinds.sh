#!/usr/bin/env bash
# Super+H — atalhos do Hyprland (consulta; Enter não executa comandos).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

pkill yad 2>/dev/null || true

keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
user_keybinds_conf="$HOME/.config/hypr/UserConfigs/UserKeybinds.conf"
laptop_conf="$HOME/.config/hypr/UserConfigs/Laptops.conf"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='Atalhos do Hyprland'

files=("$keybinds_conf" "$user_keybinds_conf")
[[ -f "$laptop_conf" ]] && files+=("$laptop_conf")

display_keybinds=$("$scripts_dir/keybinds_parser.py" "${files[@]}")

if [[ -f "/tmp/hypr_keybind_suggestions_file" ]]; then
  suggestions_file=$(cat "/tmp/hypr_keybind_suggestions_file")
  rm "/tmp/hypr_keybind_suggestions_file"
  if [[ -n "$suggestions_file" && -f "$suggestions_file" ]]; then
    count=$(wc -l < "$suggestions_file")
    msg="$msg | Overrides missing unbind: $count"
  fi
fi

rofi_require "$rofi_theme"
rofi_prepare

printf '%s\n' "$display_keybinds" | "$rofi_bin" \
  -dmenu \
  -i \
  -config "$rofi_theme" \
  -p "$msg" \
  >/dev/null
