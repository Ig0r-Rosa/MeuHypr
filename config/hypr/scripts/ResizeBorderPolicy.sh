#!/usr/bin/env bash
# Sem cursor de resize na borda em janelas tileadas; mantém em flutuantes.

SCRIPT_NAME="$(basename "$0")"

apply_policy() {
  local floating
  floating="$(hyprctl activewindow -j | jq -r '.floating // false')"
  if [[ "$floating" == "true" ]]; then
    hyprctl keyword general:resize_on_border true
    hyprctl keyword general:hover_icon_on_border true
  else
    hyprctl keyword general:resize_on_border false
    hyprctl keyword general:hover_icon_on_border false
  fi
}

listen_focus() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  [[ -S "$socket" ]] || exit 1
  apply_policy
  socat -u "UNIX-CONNECT:${socket}" - | while read -r line; do
    case "$line" in
      activewindowv2*|changefloatingmode*)
        apply_policy
        ;;
    esac
  done
}

case "${1:-}" in
  --listener) listen_focus ;;
  *)
    apply_policy
    pgrep -f "${SCRIPT_NAME} --listener" >/dev/null && exit 0
    nohup "$0" --listener >>"${XDG_CACHE_HOME:-$HOME/.cache}/resize-border.log" 2>&1 &
    ;;
esac
