#!/usr/bin/env bash
# Restaura ícones de apps do backup, sem o tema default/ (que quebra a Steam no Hyprland).

set -euo pipefail

ICONS_DIR="${HOME}/.local/share/icons"
ICONS_BAK="${HOME}/.local/share/icons.steam-bak"

log() { printf '[restore-icons] %s\n' "$*"; }

[[ -d "$ICONS_BAK" ]] || { log "Backup não encontrado: $ICONS_BAK"; exit 1; }

mkdir -p "$ICONS_DIR"

# hicolor com ícones de apps — sem tema default/ (nwg-look).
if [[ -d "$ICONS_BAK/hicolor" ]]; then
  rsync -a --exclude='steam_tray_mono.png' \
    "$ICONS_BAK/hicolor/" "$ICONS_DIR/hicolor/"
fi

# Ícone da Steam para menus (foi omitido no rsync legado).
if [[ -x "${HOME}/.config/hypr/scripts/SteamMenuIcon.sh" ]]; then
  "${HOME}/.config/hypr/scripts/SteamMenuIcon.sh" >/dev/null || true
fi

# Godot existia só na raiz do backup; instala no padrão freedesktop.
if [[ -f "$ICONS_BAK/godot.png" ]]; then
  for size in 16 32 48 64 128 256; do
    install -D -m 644 "$ICONS_BAK/godot.png" \
      "$ICONS_DIR/hicolor/${size}x${size}/apps/godot.png"
  done
fi

# NÃO restaurar default/index.theme (nwg-look) — causa loop do steamwebhelper.

if command -v gtk-update-icon-cache >/dev/null; then
  gtk-update-icon-cache -f -t "$ICONS_DIR/hicolor" 2>/dev/null || true
fi

if command -v update-desktop-database >/dev/null; then
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
fi

log "Ícones restaurados em $ICONS_DIR (sem tema default/)"
