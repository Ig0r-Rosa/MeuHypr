#!/usr/bin/env bash
# Super+S — busca na web via Rofi (navegador padrão).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
rofi_theme="$HOME/.config/rofi/config-search.rasi"

if ! command -v jq >/dev/null 2>&1; then
  notify-send -u low "Busca web" "Instale jq para codificar a URL."
  exit 1
fi

[[ -f "$config_file" ]] || {
  notify-send -u critical "Busca web" "Arquivo de configuração não encontrado."
  exit 1
}

config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
eval "$config_content"

[[ -n "$Search_Engine" ]] || {
  notify-send -u critical "Busca web" "Search_Engine não definido em 01-UserDefaults.conf"
  exit 1
}

rofi_require "$rofi_theme"
rofi_prepare

query=$("$rofi_bin" -dmenu -config "$rofi_theme")

[[ -n "$query" ]] || exit 0

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)

if [[ "$Search_Engine" == *"{}"* ]]; then
  search_url="${Search_Engine//\{\}/${encoded_query}}"
else
  search_url="${Search_Engine}${encoded_query}"
fi

xdg-open "$search_url" >/dev/null 2>&1 &
