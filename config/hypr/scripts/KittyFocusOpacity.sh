#!/usr/bin/env bash
# Ajusta a opacidade do fundo do kitty conforme foco (texto permanece opaco).

SCRIPT_NAME="$(basename "$0")"
FOCUSED_OPACITY=0.7
UNFOCUSED_OPACITY=0.55
PREV_ADDR=""

is_kitty_address() {
  local addr="$1"
  [[ -z "$addr" || "$addr" == "0x0" ]] && return 1
  hyprctl clients -j | jq -e --arg a "$addr" \
    '.[] | select(.address == $a and (.class == "kitty" or .class == "kitty-dropterm"))' >/dev/null
}

kitty_pid_for_address() {
  local addr="$1"
  hyprctl clients -j | jq -r --arg a "$addr" \
    '.[] | select(.address == $a) | .pid' | head -n1
}

set_kitty_opacity() {
  local pid="$1"
  local opacity="$2"
  [[ -z "$pid" || "$pid" == "0" || "$pid" == "null" ]] && return 0
  kitty @ --to "pid:${pid}" set-background-opacity "$opacity" 2>/dev/null || true
}

apply_opacity_for_address() {
  local addr="$1"
  local opacity="$2"
  is_kitty_address "$addr" || return 0
  set_kitty_opacity "$(kitty_pid_for_address "$addr")" "$opacity"
}

sync_all_kitty_windows() {
  local active_addr
  active_addr="$(hyprctl activewindow -j | jq -r '.address // empty')"

  while read -r addr pid; do
    [[ -z "$addr" || -z "$pid" ]] && continue
    if [[ "$addr" == "$active_addr" ]]; then
      set_kitty_opacity "$pid" "$FOCUSED_OPACITY"
    else
      set_kitty_opacity "$pid" "$UNFOCUSED_OPACITY"
    fi
  done < <(
    hyprctl clients -j | jq -r \
      '.[] | select(.class == "kitty" or .class == "kitty-dropterm") | "\(.address) \(.pid)"'
  )
}

handle_active_window() {
  local new_addr="$1"
  [[ -n "$PREV_ADDR" && "$PREV_ADDR" != "$new_addr" ]] && \
    apply_opacity_for_address "$PREV_ADDR" "$UNFOCUSED_OPACITY"
  apply_opacity_for_address "$new_addr" "$FOCUSED_OPACITY"
  PREV_ADDR="$new_addr"
}

subscribe() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  [[ -S "$socket" ]] || { echo "Socket Hyprland não encontrado: $socket" >&2; exit 1; }

  sync_all_kitty_windows

  socat -u "UNIX-CONNECT:${socket}" - | while read -r line; do
    case "$line" in
      activewindowv2\>\>*) handle_active_window "${line#activewindowv2>>}" ;;
      activewindow\>\>*) sync_all_kitty_windows ;;
    esac
  done
}

if [[ "${1:-}" == "--listener" ]]; then
  subscribe
  exit 0
fi

if pgrep -f "${SCRIPT_NAME} --listener" >/dev/null; then
  exit 0
fi

nohup "$0" --listener >/dev/null 2>&1 &
