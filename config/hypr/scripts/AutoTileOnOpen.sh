#!/usr/bin/env bash
# Coloca janelas novas no tiling (Flatpak, Blueman, Qt) exceto popups/utilitários.

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/auto-tile.log"
OPEN_ADDR=""
OPEN_CLASS=""
OPEN_TITLE=""

log_msg() {
  echo "$(date '+%F %T') $*" >>"$LOG"
}

normalize_addr() {
  local addr="$1"
  [[ "$addr" == 0x* ]] && printf '%s\n' "$addr" && return 0
  [[ "$addr" =~ ^[0-9a-fA-F]+$ ]] && printf '0x%s\n' "$addr" && return 0
  printf '%s\n' "$addr"
}

# Hyprland: openwindow>>ADDRESS,WORKSPACE,CLASS,TITLE
parse_open_event() {
  local line="$1" data class title addr

  [[ "$line" == openwindow* ]] || return 1
  data="${line#openwindow>>}"
  IFS=',' read -r addr _ class title <<<"$data"

  OPEN_ADDR="$(normalize_addr "$addr")"
  OPEN_CLASS="$class"
  OPEN_TITLE="$title"
}

# Classes que sempre permanecem flutuantes (utilitários, seletores, HUDs).
is_always_floating_class() {
  local class="$1"
  [[ "$class" =~ ^(swaync|rofi|yad|hyprland-donate-screen|hyprland-share-picker|pavucontrol|org\.pulseaudio\.pavucontrol|nm-applet|org\.gnome\.Calculator|qalculate-gtk|zoom|onedriver|qt5ct|qt6ct|[Ss]team|steamwebhelper)$ ]]
}

# Títulos que sempre permanecem flutuantes (diálogos e splashes conhecidos).
is_always_floating_title() {
  local title="$1"
  [[ "$title" =~ ^(Picture-in-Picture|Authentication Required|Add Folder to Workspace|Save As|Keybindings|ROG Control|SDDM Background|File Operation Progress|Open Files|Discord Updater)$ ]]
}

# Classes que devem ir para o tiling mesmo abrindo flutuantes.
is_forced_tiling_class() {
  local class="$1"
  [[ "$class" =~ ^(org\.gnome\.Loupe|eog|blueman-manager|nm-connection-editor)$ ]]
}

# Janela pequena/HUD que abre flutuante mantém o próprio tamanho ("tela solta").
# Barras finas (ex.: aviso do Meet) e splashes/diálogos pequenos não são tileados.
is_freeform_small_window() {
  local width="$1" height="$2"
  (( width <= 0 || height <= 0 )) && return 1
  (( height < 130 )) && return 0
  (( width <= 640 && height <= 560 )) && return 0
  return 1
}

# Decide se a janela deve continuar flutuante (não tileia).
should_keep_floating() {
  local class="$1" title="$2" width="$3" height="$4"

  is_always_floating_class "$class" && return 0
  is_always_floating_title "$title" && return 0
  is_forced_tiling_class "$class" && return 1
  is_freeform_small_window "$width" "$height" && return 0
  return 1
}

client_state() {
  local addr="$1"
  hyprctl clients -j | jq -r --arg a "$addr" \
    '.[] | select(.address == $a) | "\(.floating) \(.size[0]) \(.size[1])"' | head -1
}

try_settiled() {
  local addr="$1"
  hyprctl dispatch settiled "address:${addr}" 2>/dev/null || true
}

try_focus() {
  local addr="$1"
  hyprctl dispatch focuswindow "address:${addr}" 2>/dev/null || true
}

# Qt/GTK demoram para estabilizar o estado floating.
tile_with_retry() {
  local addr="$1" class="$2" title="$3"
  local attempt floating width height

  for attempt in 1 2 3 4 5 6 8 10; do
    sleep 0.12
    read -r floating width height < <(client_state "$addr")
    [[ -z "$floating" ]] && continue
    [[ "$floating" != "true" ]] && return 0
    should_keep_floating "$class" "$title" "${width:-0}" "${height:-0}" && return 0
    try_settiled "$addr"
  done

  try_focus "$addr"
  log_msg "tile $class ($title) addr=$addr"
}

handle_open() {
  local addr class title

  addr="$OPEN_ADDR"
  class="$OPEN_CLASS"
  title="$OPEN_TITLE"
  [[ -z "$addr" ]] && return 0

  tile_with_retry "$addr" "$class" "$title" &
}

listen_opens() {
  local socket="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
  [[ -S "$socket" ]] || exit 1

  socat -u "UNIX-CONNECT:${socket}" - 2>/dev/null | while read -r line; do
    parse_open_event "$line" || continue
    handle_open
  done
}

case "${1:-}" in
  --listener) listen_opens ;;
  *)
    pkill -f "AutoTileOnOpen.sh --listener" 2>/dev/null || true
    nohup "$0" --listener >>"$LOG" 2>&1 &
    ;;
esac
