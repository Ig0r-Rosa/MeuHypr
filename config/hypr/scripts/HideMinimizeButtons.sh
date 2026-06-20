#!/usr/bin/env bash
# Remove botões da barra de título (min/max/fechar) e bloqueia minimizar no Hyprland.

LAYOUT=":"
PID_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/block-minimize.pid"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/block-minimize.log"

apply_gtk_layout() {
  gsettings set org.gnome.desktop.wm.preferences button-layout "$LAYOUT" 2>/dev/null || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true

  for gtk_dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    mkdir -p "$gtk_dir"
    local ini="$gtk_dir/settings.ini"
    if [[ -f "$ini" ]]; then
      if grep -q '^gtk-decoration-layout=' "$ini"; then
        sed -i "s/^gtk-decoration-layout=.*/gtk-decoration-layout=${LAYOUT}/" "$ini"
      else
        sed -i "/^\[Settings\]/a gtk-decoration-layout=${LAYOUT}" "$ini"
      fi
      if grep -q '^gtk-application-prefer-dark-theme=' "$ini"; then
        sed -i 's/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/' "$ini"
      else
        sed -i "/^\[Settings\]/a gtk-application-prefer-dark-theme=1" "$ini"
      fi
    else
      printf '[Settings]\ngtk-decoration-layout=%s\ngtk-application-prefer-dark-theme=1\n' "$LAYOUT" >"$ini"
    fi
  done
}

install_gtk_css() {
  local css='/* Sem botões na barra de título (GTK/libadwaita) */
.titlebutton,
.titlebutton.minimize,
.titlebutton.maximize,
.titlebutton.close,
button.minimize,
button.maximize,
button.close,
windowcontrols button,
headerbar windowcontrols button {
  opacity: 0;
  min-width: 0;
  min-height: 0;
  padding: 0;
  margin: 0;
  border: none;
  -gtk-icon-source: none;
}'

  for gtk_dir in "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"; do
    mkdir -p "$gtk_dir"
    printf '%s\n' "$css" >"$gtk_dir/gtk.css"
  done
}

patch_brave_prefs() {
  local prefs="$HOME/.config/BraveSoftware/Brave-Browser/Default/Preferences"
  [[ -f "$prefs" ]] || return 0
  pgrep -x brave >/dev/null && return 0

  python3 - "$prefs" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
browser = data.setdefault("browser", {})
browser["custom_chrome_frame"] = False
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, separators=(",", ":"))
PY
}

stop_old_handlers() {
  pkill -f 'MinimizeHandler.sh' 2>/dev/null || true
  pkill -f 'HideMinimizeButtons.sh listen' 2>/dev/null || true
  rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/hypr-minimized.json" \
        "${XDG_CACHE_HOME:-$HOME/.cache}/minimize-handler.pid" \
        "$PID_FILE" 2>/dev/null || true
}

wait_for_socket() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  for _ in $(seq 1 40); do
    [[ -S "$socket" ]] && return 0
    sleep 0.25
  done
  return 1
}

block_minimize_event() {
  local addr="$1"
  [[ -n "$addr" ]] || return
  hyprctl dispatch focuswindow "address:${addr}" 2>/dev/null || true
}

listen_events() {
  wait_for_socket || exit 1
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

  socat -u "UNIX-CONNECT:${socket}" - | while read -r line; do
    [[ "$line" == minimized* ]] || continue
    line="${line#minimized>>}"
    addr="${line%%,*}"
    state="${line##*,}"
    [[ "$state" == "1" ]] || continue
    echo "$(date '+%F %T') bloqueado minimize $addr" >>"$LOG"
    block_minimize_event "$addr"
  done
}

start_listener() {
  if [[ -f "$PID_FILE" ]]; then
    local old_pid
    old_pid=$(cat "$PID_FILE")
    kill -0 "$old_pid" 2>/dev/null && return 0
  fi

  mkdir -p "$(dirname "$LOG")"
  wait_for_socket || return 1
  setsid nohup "$0" listen >>"$LOG" 2>&1 < /dev/null &
  echo $! >"$PID_FILE"
}

case "${1:-apply}" in
  listen) listen_events ;;
  apply)
    stop_old_handlers
    apply_gtk_layout
    install_gtk_css
    patch_brave_prefs
    "$HOME/.config/hypr/scripts/DiscordPatchTitlebar.sh" apply || true
    start_listener
    ;;
  *) echo "Uso: $0 [apply|listen]" ;;
esac
