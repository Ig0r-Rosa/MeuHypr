#!/usr/bin/env bash
# Aplica preferências do Nautilus, terminal kitty e extensão open-any-terminal.

set -euo pipefail

TARGET_USER="${1:-${SUDO_USER:-$USER}}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CONFIG="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { printf '[setup-nautilus] %s\n' "$*"; }

run_as_user() {
  sudo -u "$TARGET_USER" bash -lc "$1"
}

apply_xdg_terminals_list() {
  local dest="$TARGET_HOME/.config/xdg-terminals.list"
  local src=""

  for candidate in \
    "$REPO_CONFIG/xdg-terminals.list" \
    "$SCRIPT_DIR/xdg-terminals.list"; do
    [[ -f "$candidate" ]] || continue
    src="$candidate"
    break
  done

  mkdir -p "$(dirname "$dest")"
  if [[ -n "$src" && "$src" != "$dest" ]]; then
    cp -a "$src" "$dest"
  elif [[ ! -f "$dest" ]]; then
    printf '%s\n' 'kitty.desktop' >"$dest"
  fi

  chown "$TARGET_USER:$TARGET_USER" "$dest"
}

apply_nautilus_preferences() {
  run_as_user 'gsettings set org.gnome.nautilus.preferences default-folder-viewer icon-view'
  run_as_user 'gsettings set org.gnome.nautilus.preferences click-policy double'
  run_as_user 'gsettings set org.gnome.nautilus.preferences default-sort-order name'
  run_as_user 'gsettings set org.gnome.nautilus.preferences show-hidden-files false'
  run_as_user 'gsettings set org.gnome.nautilus.preferences recursive-search local-only'
  run_as_user 'gsettings set org.gnome.nautilus.preferences search-filter-time-type last_modified'
  run_as_user 'gsettings set org.gnome.nautilus.list-view default-visible-columns "[\"name\", \"size\", \"date_modified\"]"'
  run_as_user 'gsettings set org.gnome.nautilus.list-view use-tree-view false'
  run_as_user 'gsettings set org.gnome.nautilus.icon-view default-zoom-level medium'
  run_as_user 'gsettings set org.gnome.nautilus.compression default-compression-format zip'
}

apply_open_any_terminal() {
  local kitty_bin

  kitty_bin="$(run_as_user 'command -v kitty' 2>/dev/null || true)"
  [[ -n "$kitty_bin" ]] || return 0

  run_as_user 'gsettings list-schemas' | grep -q 'com.github.stunkymonkey.nautilus-open-any-terminal' || return 0

  run_as_user "gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal custom"
  run_as_user "gsettings set com.github.stunkymonkey.nautilus-open-any-terminal custom-local-command '${kitty_bin} --directory %s'"
  run_as_user 'gsettings set com.github.stunkymonkey.nautilus-open-any-terminal use-generic-terminal-name true'
}

main() {
  log "Configurando Nautilus para $TARGET_USER ..."
  apply_xdg_terminals_list
  apply_nautilus_preferences
  apply_open_any_terminal
  log "Concluído."
}

main "$@"
