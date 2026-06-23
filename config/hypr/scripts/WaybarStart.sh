#!/usr/bin/env bash
# Garante portal pronto e exatamente uma Waybar visível.

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/waybar.log"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-autohide.state"
LOCK="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-start.lock"

log_msg() {
  echo "$(date '+%F %T') $1" >>"$LOG"
}

wait_hyprland() {
  local count
  for _ in $(seq 1 60); do
    hyprctl monitors -j >/dev/null 2>&1 || continue
    count=$(hyprctl monitors -j | jq 'length' 2>/dev/null || echo 0)
    [[ "${count:-0}" -gt 0 ]] && return 0
    sleep 0.25
  done
  return 1
}

portal_service_ready() {
  busctl --user list 2>/dev/null | grep -q 'org.freedesktop.portal.Desktop'
}

hyprland_portal_ready() {
  busctl --user list 2>/dev/null | grep -q 'org.freedesktop.impl.portal.desktop.hyprland'
}

start_hyprland_portal() {
  hyprland_portal_ready && return 0
  [[ -x /usr/lib/xdg-desktop-portal-hyprland ]] || return 1
  /usr/lib/xdg-desktop-portal-hyprland >/dev/null 2>&1 &
  sleep 0.5
}

start_desktop_portal() {
  portal_service_ready && return 0
  systemctl --user start xdg-desktop-portal.service 2>/dev/null && return 0
  [[ -x /usr/libexec/xdg-desktop-portal ]] || return 1
  /usr/libexec/xdg-desktop-portal >/dev/null 2>&1 &
  sleep 0.5
}

ensure_portals() {
  start_hyprland_portal
  for _ in $(seq 1 20); do
    hyprland_portal_ready && break
    sleep 0.25
  done
  start_desktop_portal
  for _ in $(seq 1 20); do
    portal_service_ready && return 0
    sleep 0.25
  done
  return 1
}

waybar_on_screen() {
  hyprctl layers -j 2>/dev/null | \
    jq -e '[.. | objects | select(.namespace? == "waybar")] | length > 0' >/dev/null
}

count_waybar_procs() {
  local count=0
  count=$(pgrep -x -c waybar 2>/dev/null) || count=0
  echo "$(( count + 0 ))"
}

launch_waybar() {
  nohup waybar >>"$LOG" 2>&1 &
  disown
  for _ in $(seq 1 40); do
    waybar_on_screen && return 0
    pgrep -x waybar >/dev/null || return 1
    sleep 0.2
  done
  pgrep -x waybar >/dev/null
}

# Reinicia a waybar (processo pode existir mas estar oculta via SIGUSR1).
force_restart_waybar() {
  pkill -x waybar 2>/dev/null || true
  sleep 0.35
  launch_waybar
}

ensure_single_waybar() {
  local procs
  procs=$(count_waybar_procs)

  if [[ "$procs" -gt 1 ]]; then
    log_msg "detectadas ${procs} instâncias — reiniciando"
    pkill -x waybar 2>/dev/null || true
    sleep 0.4
    launch_waybar
    return $?
  fi

  if pgrep -x waybar >/dev/null; then
    return 0
  fi

  launch_waybar
}

main() {
  local mode="start"
  case "${1:-}" in
    --quick) mode="quick" ;;
  esac

  rm -f "$STATE"
  mkdir -p "$(dirname "$LOG")"

  if [[ "$mode" == "quick" ]]; then
    wait_hyprland || exit 1
    force_restart_waybar && exit 0
    exit 1
  fi

  exec 9>"$LOCK"
  flock -w 10 9 || { log_msg "lock ocupado — quick"; exec "$0" --quick; }

  log_msg "início"
  wait_hyprland || { log_msg "erro: hyprland indisponível"; exit 1; }
  ensure_portals || log_msg "aviso: portal ainda iniciando — continuando"

  if ensure_single_waybar; then
    log_msg "ok"
    exit 0
  fi

  log_msg "falha ao iniciar waybar"
  exit 1
}

main "$@"
