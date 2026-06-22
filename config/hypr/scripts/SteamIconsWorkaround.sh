#!/usr/bin/env bash
# Desativa tema default/ do nwg-look que quebra steamwebhelper no Hyprland.
# Restaura ícones de apps se existir backup legado (icons.steam-bak).

set -euo pipefail

ICONS_DIR="${HOME}/.local/share/icons"
ICONS_BAK="${HOME}/.local/share/icons.steam-bak"
ICONS_MARKER="${HOME}/.config/hypr/.steam-icons-workaround"
DEFAULT_BAK="${ICONS_DIR}/default.steam-disabled"
RESTORE_SCRIPT="${HOME}/.config/hypr/scripts/RestoreUserAppIcons.sh"

log() { printf '[steam-icons] %s\n' "$*"; }

disable_default_icon_theme() {
  local default_theme="${ICONS_DIR}/default/index.theme"
  [[ -f "$default_theme" && ! -d "$DEFAULT_BAK" ]] || return 0
  log "Desativando ~/.local/share/icons/default (nwg-look quebra a Steam)"
  mv "${ICONS_DIR}/default" "$DEFAULT_BAK"
  touch "$ICONS_MARKER"
}

restore_icons_from_legacy_backup() {
  [[ -f "$ICONS_MARKER" && ! -d "$ICONS_DIR" && -d "$ICONS_BAK" ]] || return 0
  [[ -x "$RESTORE_SCRIPT" ]] || return 0
  log "Restaurando ícones de apps do backup legado ..."
  "$RESTORE_SCRIPT"
}

disable_default_icon_theme
restore_icons_from_legacy_backup
