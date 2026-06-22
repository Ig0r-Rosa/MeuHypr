#!/usr/bin/env bash
# Restaura wallpapers por monitor após o Hyprland e o swww estarem prontos.

SCRIPTSDIR="$HOME/.config/hypr/scripts"
STATE_FILE="$HOME/.config/hypr/wallpaper_effects/monitors.json"
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-restore.log"

log() {
  echo "$(date '+%F %T') $1" >>"$LOG_FILE"
}

wait_for_swww() {
  local i
  for i in $(seq 1 30); do
    pgrep -x swww-daemon >/dev/null && swww query >/dev/null 2>&1 && return 0
    sleep 0.3
  done
  return 1
}

wait_for_monitors() {
  local i count target
  target=$(jq 'length' "$STATE_FILE" 2>/dev/null || echo 1)
  [[ "$target" -lt 1 ]] && target=1

  for i in $(seq 1 50); do
    count=$(hyprctl monitors -j 2>/dev/null | jq 'length')
    [[ "${count:-0}" -ge "$target" ]] && return 0
    sleep 0.3
  done
  return 1
}

start_swww() {
  pgrep -x swww-daemon >/dev/null || swww-daemon &
  wait_for_swww
}

restore_wallpapers() {
  "$SCRIPTSDIR/WallpaperPersist.sh" restore
  if [[ -f "$STATE_FILE" ]] && jq -e 'length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    "$SCRIPTSDIR/WallpaperPersist.sh" verify && return 0
    log "verificação falhou — executando repair"
    "$SCRIPTSDIR/WallpaperPersist.sh" repair
  fi
}

main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  log "início"

  start_swww || log "swww indisponível"
  wait_for_monitors || log "monitores incompletos — restaurando mesmo assim"
  sleep 0.8
  restore_wallpapers
  log "concluído"
}

main
