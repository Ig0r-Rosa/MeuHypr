#!/usr/bin/env bash
# Abre gerenciador de arquivos: Nautilus (GUI) ou yazi (TUI) como fallback silencioso.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

if [[ -f "$config_file" ]]; then
  config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')
  eval "$config_content"
fi

term="${term:-kitty}"

open_yazi() {
  command -v yazi >/dev/null 2>&1 || return 1
  export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
  command -v yazi >/dev/null 2>&1 || return 1
  pkill -x fuzzel 2>/dev/null || true
  hyprctl dispatch exec "$term --title yazi yazi"
}

open_nautilus() {
  command -v nautilus >/dev/null 2>&1 || return 1
  nautilus --new-window &
}

case "${1:-}" in
  --tui)
    open_yazi
    ;;
  *)
    open_nautilus || open_yazi
    ;;
esac
