#!/usr/bin/env bash
# Para o portal GTK quando idle — libera ~50 MB de RAM.
# Sobe de novo via D-Bus ao abrir diálogo de arquivo (Abrir/Salvar).

SCRIPT_NAME="$(basename "$0")"
INTERVAL_SEC="${PORTAL_GTK_IDLE_INTERVAL:-60}"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/portal-gtk-idle.log"

log_msg() {
  echo "$(date '+%F %T') $1" >>"$LOG"
}

gtk_portal_active() {
  systemctl --user is-active xdg-desktop-portal-gtk.service >/dev/null 2>&1
}

# Evita parar no meio de um seletor de arquivos aberto.
file_dialog_open() {
  hyprctl clients -j 2>/dev/null | jq -e '
    [.[] | select(.title | test(
      "(Open Files|Save As|Abrir|Salvar|Select File|Choose File|File Upload|Authentication Required)";
      "i"
    ))] | length > 0
  ' >/dev/null
}

stop_gtk_portal() {
  systemctl --user stop xdg-desktop-portal-gtk.service 2>/dev/null || true
}

ensure_idle_cleanup() {
  gtk_portal_active || return 0
  file_dialog_open && return 0
  stop_gtk_portal
  log_msg "xdg-desktop-portal-gtk parado — idle"
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
