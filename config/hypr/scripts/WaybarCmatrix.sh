#!/usr/bin/env bash
# Abre o cmatrix em área de trabalho vazia ($term de 01-UserDefaults.conf).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"

if ! command -v cmatrix >/dev/null 2>&1; then
  notify-send -u low "cmatrix" "Instale o pacote cmatrix para usar este botão."
  exit 1
fi

pkill -x fuzzel 2>/dev/null || true

"$script_dir/WorkspaceCreateEmpty.sh"

hyprctl dispatch exec "$term --title cmatrix sh -c 'cmatrix'"

"$script_dir/RetileAfterDrag.sh"
