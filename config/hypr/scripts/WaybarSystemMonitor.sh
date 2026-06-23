#!/usr/bin/env bash
# Nova área vazia com btop e nvtop lado a lado (botão 📊 da Waybar).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"

"$script_dir/WorkspaceCreateEmpty.sh"

hyprctl dispatch exec "$term --title btop sh -c 'btop'"
sleep 0.25
hyprctl dispatch splitr
hyprctl dispatch exec "$term --title nvtop sh -c 'nvtop'"

"$script_dir/RetileAfterDrag.sh"
