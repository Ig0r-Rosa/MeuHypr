#!/usr/bin/env bash
# Launcher da Steam estável no Hyprland + NVIDIA (evita loop do steamwebhelper).

STEAM_BIN="${STEAM_BIN:-/usr/games/steam}"
CACHE_DIR="${HOME}/.steam/debian-installation/config/htmlcache"

log() { printf '[steam-launch] %s\n' "$*"; }

stop_steam() {
  pkill -x steam 2>/dev/null || true
  pkill -f 'steamwebhelper' 2>/dev/null || true
  sleep 1
}

clear_cef_cache() {
  [[ -d "$CACHE_DIR" ]] || return 0
  log "Limpando cache CEF da Steam ..."
  rm -rf "${CACHE_DIR:?}"/*
}

# XWayland + NVIDIA costuma ser mais estável que CEF nativo Wayland aqui.
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export SDL_VIDEODRIVER=x11
export STEAM_FORCE_MINIMIZE_ON_FOCUS_LOSS=0

case "${1:-}" in
  --repair)
    stop_steam
    clear_cef_cache
    shift
    ;;
  --clear-cache)
    stop_steam
    clear_cef_cache
    exit 0
    ;;
esac

exec "$STEAM_BIN" -no-cef-sandbox -silent "$@"
