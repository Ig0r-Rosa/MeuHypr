#!/usr/bin/env bash
# Launcher da Steam estável no Hyprland (evita loop do steamwebhelper).

STEAM_BIN="${STEAM_BIN:-/usr/games/steam}"
CACHE_DIR="${HOME}/.steam/debian-installation/config/htmlcache"
STEAM_GTK2_RC="${HOME}/.config/hypr/assets/steam-gtk2.rc"
RAISE_SCRIPT="${HOME}/.config/hypr/scripts/SteamRaiseWindow.sh"
SEED_SCRIPT="${HOME}/.config/hypr/scripts/SteamSeedWindowGeometry.sh"
ICONS_WORKAROUND="${HOME}/.config/hypr/scripts/SteamIconsWorkaround.sh"

log() { printf '[steam-launch] %s\n' "$*"; }

stop_steam() {
  pkill -x steam 2>/dev/null || true
  pkill -f 'steamwebhelper' 2>/dev/null || true
  sleep 1
}

clear_cef_cache() {
  [[ -d "$CACHE_DIR" ]] || return 0
  log "Limpando cache CEF da Steam ..."
  rm -rf "${CACHE_DIR:?}"
}

seed_window_geometry() {
  [[ -x "$SEED_SCRIPT" ]] || return 0
  "$SEED_SCRIPT"
}

# Workaround Hyprland: tema default/ em ~/.local/share/icons quebra o steamwebhelper.
apply_icons_workaround() {
  [[ -x "$ICONS_WORKAROUND" ]] || return 0
  "$ICONS_WORKAROUND"
}

# Ambiente isolado: temas GTK globais quebram o CEF antigo da Steam.
prepare_steam_env() {
  export GDK_BACKEND=x11
  export QT_QPA_PLATFORM=xcb
  export SDL_VIDEODRIVER=x11
  export STEAM_FORCE_MINIMIZE_ON_FOCUS_LOSS=0
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
  export DISPLAY="${DISPLAY:-:1}"
  export GTK2_RC_FILES="$STEAM_GTK2_RC"
  unset GTK_THEME GTK_CSD GTK_IM_MODULE QT_IM_MODULE XMODIFIERS MOZ_ENABLE_WAYLAND
}

start_window_helper() {
  [[ -x "$RAISE_SCRIPT" ]] || return 0
  nohup "$RAISE_SCRIPT" >/dev/null 2>&1 &
}

case "${1:-}" in
  --repair)
    stop_steam
    apply_icons_workaround
    clear_cef_cache
    shift
    ;;
  --clear-cache)
    stop_steam
    clear_cef_cache
    seed_window_geometry
    exit 0
    ;;
esac

prepare_steam_env
start_window_helper

# -cef-disable-gpu: workaround Hyprland/NVIDIA para o steamwebhelper não reiniciar em loop.
exec "$STEAM_BIN" -no-cef-sandbox -cef-disable-gpu "$@"
