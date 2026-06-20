#!/usr/bin/env bash
# Abre o arquivo de tema do Fuzzel no editor padrão.

config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
tmp_config_file=$(mktemp)
sed 's/^\$//g; s/ = /=/g' "$config_file" > "$tmp_config_file"
# shellcheck source=/dev/null
source "$tmp_config_file"
rm -f "$tmp_config_file"

fuzzel_ini="$HOME/.config/fuzzel/fuzzel.ini"
exec "$term" -e "$edit" "$fuzzel_ini"
