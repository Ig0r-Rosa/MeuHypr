#!/usr/bin/env bash
# Garante ícone da Steam nos menus (Rofi/wofi) após workaround de ícones.

set -euo pipefail

ICONS_DIR="${HOME}/.local/share/icons"
STEAM_ICON_SRC=""

find_steam_icon_source() {
  local candidate
  for candidate in \
    /usr/share/icons/hicolor/256x256/apps/steam.png \
    /usr/share/icons/hicolor/128x128/apps/steam.png \
    "${HOME}/.steam/debian-installation/deb-installer/steam-launcher/icons/256/steam.png"; do
    if [[ -f "$candidate" ]]; then
      STEAM_ICON_SRC="$candidate"
      return 0
    fi
  done
  return 1
}

install_hicolor_steam_icons() {
  local size src
  mkdir -p "$ICONS_DIR/hicolor"
  for size in 16 24 32 48 64 128 256; do
    src="/usr/share/icons/hicolor/${size}x${size}/apps/steam.png"
    [[ -f "$src" ]] || src="$STEAM_ICON_SRC"
    install -D -m 644 "$src" "$ICONS_DIR/hicolor/${size}x${size}/apps/steam.png"
  done
  if command -v gtk-update-icon-cache >/dev/null; then
    gtk-update-icon-cache -f -t "$ICONS_DIR/hicolor" 2>/dev/null || true
  fi
}

resolve_steam_desktop_icon() {
  if [[ -f "$ICONS_DIR/hicolor/256x256/apps/steam.png" ]]; then
    echo "$ICONS_DIR/hicolor/256x256/apps/steam.png"
  elif [[ -n "$STEAM_ICON_SRC" ]]; then
    echo "$STEAM_ICON_SRC"
  else
    echo "steam"
  fi
}

find_steam_icon_source || exit 0
install_hicolor_steam_icons
resolve_steam_desktop_icon
