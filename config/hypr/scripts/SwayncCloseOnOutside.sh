#!/usr/bin/env bash
# Fecha o painel ao trocar workspace ou foco de monitor.

panel_open() {
  hyprctl layers 2>/dev/null | rg -q 'swaync-control-center'
}

close_panel() {
  panel_open || return 0
  swaync-client -cp -sw 2>/dev/null || true
}

listen_outside() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  [[ -S "$socket" ]] || exit 1

  socat -U "UNIX-CONNECT:${socket}" - | while read -r line; do
    case "$line" in
      workspace\>\>*|focusedmonv2\>\>*)
        close_panel
        ;;
    esac
  done
}

case "${1:-}" in
  --listener) listen_outside ;;
  *)
    pkill -f "SwayncCloseOnOutside.sh --listener" 2>/dev/null || true
    nohup "$0" --listener >/dev/null 2>&1 &
    ;;
esac
