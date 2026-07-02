#!/usr/bin/env bash
# Abre/fecha o painel swaync (duplo Super, waybar, etc.).

MODE="${1:-toggle}"

service_ready() {
  busctl --user list 2>/dev/null | grep -q '^org\.erikreider\.swaync\.cc '
}

ensure_daemon() {
  service_ready && return 0
  pgrep -x swaync >/dev/null && return 0
  swaync >/dev/null 2>&1 &
}

wait_ready() {
  local attempt
  for attempt in $(seq 1 50); do
    service_ready && return 0
    sleep 0.1
  done
  return 1
}

toggle_panel() {
  swaync-client -t -sw
}

run_action() {
  case "$MODE" in
    toggle) toggle_panel ;;
    dnd)    swaync-client -d -sw ;;
    *)
      echo "Uso: $0 [toggle|dnd]" >&2
      exit 1
      ;;
  esac
}

ensure_daemon
wait_ready || exit 1
run_action
