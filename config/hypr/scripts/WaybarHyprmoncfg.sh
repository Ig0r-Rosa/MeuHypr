#!/usr/bin/env bash
# Abre o hyprmoncfg no terminal padrão ($term de 01-UserDefaults.conf).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v hyprmoncfg >/dev/null 2>&1; then
  notify-send -u low "hyprmoncfg" "Instale o hyprmoncfg para usar este botão."
  exit 1
fi

pkill -x fuzzel 2>/dev/null || true

"$script_dir/SwayncClosePanel.sh" 2>/dev/null || true
sleep 0.15

hyprctl dispatch exec "$term --title hyprmoncfg hyprmoncfg"
