#!/usr/bin/env bash
# Para serviços Flatpak quando nenhum app estiver aberto (libera RAM).
# Os serviços sobem de novo automaticamente ao abrir um Flatpak (D-Bus).

SCRIPT_NAME="$(basename "$0")"
INTERVAL_SEC="${FLATPAK_IDLE_INTERVAL:-60}"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/flatpak-idle.log"

log_msg() {
  echo "$(date '+%F %T') $1" >>"$LOG"
}

flatpak_apps_running() {
  flatpak ps 2>/dev/null | grep -q .
}

stop_flatpak_services() {
  systemctl --user stop flatpak-portal.service flatpak-session-helper.service 2>/dev/null || true
}

ensure_idle_cleanup() {
  flatpak_apps_running && return 0
  stop_flatpak_services
  log_msg "serviços parados — nenhum app flatpak ativo"
}

listen_idle() {
  ensure_idle_cleanup
  while sleep "$INTERVAL_SEC"; do
    ensure_idle_cleanup
  done
}

case "${1:-}" in
  --listener)
    listen_idle
    ;;
  *)
    ensure_idle_cleanup
    pgrep -f "${SCRIPT_NAME} --listener" >/dev/null && exit 0
    nohup "$0" --listener >>"$LOG" 2>&1 &
    ;;
esac
