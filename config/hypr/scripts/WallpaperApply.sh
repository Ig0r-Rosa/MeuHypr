#!/usr/bin/env bash
# Aplica wallpaper (imagem ou GIF animado) em um monitor via swww.

SCRIPTSDIR="$HOME/.config/hypr/scripts"
LOCK_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-change.lock"

apply_wallpaper_image() {
  local monitor="$1"
  local image_path="$2"
  local fps="${SWWW_FPS:-60}"
  local type="${SWWW_TYPE:-any}"
  local duration="${SWWW_DURATION:-2}"
  local bezier="${SWWW_BEZIER:-.43,1.19,1,.4}"
  local resize="${SWWW_RESIZE:-crop}"

  [[ -n "$monitor" && -f "$image_path" ]] || return 1

  exec 9>"$LOCK_FILE"
  flock -w 60 9 || {
    notify-send -u low "Wallpaper" "Não foi possível aplicar agora"
    return 1
  }

  if ! pgrep -x swww-daemon >/dev/null; then
    swww-daemon &
    sleep 0.3
  fi

  swww img -o "$monitor" "$image_path" \
    --resize "$resize" \
    --transition-fps "$fps" \
    --transition-type "$type" \
    --transition-duration "$duration" \
    --transition-bezier "$bezier"

  if [[ "$duration" != "0" ]]; then
    sleep "$duration"
    sleep 0.25
  fi

  "$SCRIPTSDIR/WallpaperPersist.sh" save "$monitor" "$image_path"
  "$SCRIPTSDIR/WallustSwww.sh" "$image_path"
  SKIP_WALLUST=1 "$SCRIPTSDIR/RefreshNoWaybar.sh"
  "$SCRIPTSDIR/WallpaperPersist.sh" repair
}

case "${1:-}" in
  apply) apply_wallpaper_image "$2" "$3" ;;
  *)
    echo "Uso: $0 apply <monitor> <caminho>"
    exit 1
    ;;
esac
