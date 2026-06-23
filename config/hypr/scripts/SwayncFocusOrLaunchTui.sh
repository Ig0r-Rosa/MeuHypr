#!/usr/bin/env bash
# Fecha o SwayNC e foca TUI pelo título ou abre em área de trabalho vazia.

set -euo pipefail

TITLE="${1:?Informe o título da janela}"
CMD="${2:-$1}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"
bin="${CMD%% *}"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:${PATH:-}"

close_swaync_panel() {
  "$script_dir/SwayncClosePanel.sh" 2>/dev/null || true
  sleep 0.15
}

find_client_by_title() {
  hyprctl clients -j | jq -r --arg t "$TITLE" '
    .[] | select((.title | test($t; "i"))) | .address' | head -n1
}

launch_on_empty_workspace() {
  if ! command -v "$bin" >/dev/null 2>&1; then
    notify-send -u low "$TITLE" "Instale '$bin' para usar este botão."
    return 1
  fi
  "$script_dir/WorkspaceCreateEmpty.sh"
  bin_path="$(command -v "$bin")"
  hyprctl dispatch exec "$term --title $TITLE $bin_path${CMD#"$bin"}"
  "$script_dir/SwayncRepaintWallpaper.sh" 2>/dev/null || true
}

close_swaync_panel
addr="$(find_client_by_title)"
if [[ -n "$addr" ]]; then
  hyprctl dispatch focuswindow "address:${addr}"
  exit 0
fi

launch_on_empty_workspace
