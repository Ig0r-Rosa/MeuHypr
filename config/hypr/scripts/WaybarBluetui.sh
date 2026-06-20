#!/usr/bin/env bash
# Abre o bluetui no terminal padrão ($term de 01-UserDefaults.conf).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"

# Fecha o painel antes de abrir o terminal — evita corrida no compositor.
"$HOME/.config/hypr/scripts/SwayncClosePanel.sh"
sleep 0.15

hyprctl dispatch exec "$term --title bluetui bluetui"
"$script_dir/SwayncRepaintWallpaper.sh"
