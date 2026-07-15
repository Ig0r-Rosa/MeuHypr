#!/usr/bin/env bash
# Restaura wallpapers por monitor após o Hyprland e o swww estarem prontos.
# 1 tela: aplica já; multi: completa monitores extras depois (sem atrasar a primeira).

SCRIPTSDIR="$HOME/.config/hypr/scripts"
STATE_FILE="$HOME/.config/hypr/wallpaper_effects/monitors.json"
LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-restore.log"
# Tempo máximo para HDMI/externos aparecerem após a 1ª tela (sem bloquear o wallpaper).
EXTRA_MONITOR_GRACE_MS="${WALLPAPER_EXTRA_MONITOR_GRACE_MS:-1200}"

log() {
  echo "$(date '+%F %T') $1" >>"$LOG_FILE"
}

wait_for_swww() {
  local i
  for i in $(seq 1 60); do
    pgrep -x swww-daemon >/dev/null && swww query >/dev/null 2>&1 && return 0
    sleep 0.05
  done
  return 1
}

# Espera pelo menos 1 monitor (caminho rápido no login).
wait_for_first_monitor() {
  local i count
  for i in $(seq 1 60); do
    count=$(hyprctl monitors -j 2>/dev/null | jq 'length')
    [[ "${count:-0}" -ge 1 ]] && return 0
    sleep 0.05
  done
  return 1
}

monitor_count() {
  hyprctl monitors -j 2>/dev/null | jq 'length'
}

state_monitor_count() {
  jq 'length' "$STATE_FILE" 2>/dev/null || echo 0
}

# Aguarda monitores extras só o tempo do grace; não atrasa a 1ª restauração.
wait_for_extra_monitors() {
  local target current elapsed=0 step=50
  target=$(state_monitor_count)
  current=$(monitor_count)
  [[ "${current:-0}" -ge "${target:-0}" ]] && return 0

  while (( elapsed < EXTRA_MONITOR_GRACE_MS )); do
    current=$(monitor_count)
    [[ "${current:-0}" -ge "${target:-0}" ]] && return 0
    sleep 0.05
    elapsed=$((elapsed + step))
  done
  return 0
}

start_swww() {
  pgrep -x swww-daemon >/dev/null || swww-daemon &
  wait_for_swww
}

restore_wallpapers() {
  "$SCRIPTSDIR/WallpaperPersist.sh" restore
}

main() {
  mkdir -p "$(dirname "$LOG_FILE")"
  log "início"

  start_swww || log "swww indisponível"
  wait_for_first_monitor || log "nenhum monitor — restaurando mesmo assim"

  # Instantâneo: aplica wallpapers das telas já conectadas.
  restore_wallpapers
  log "aplicado (monitores atuais)"

  # Multi: completa telas extras em background (não atrasa a 1ª tela).
  (
    wait_for_extra_monitors
    restore_wallpapers
    log "concluído (monitores extras)"
  ) &
}

main
