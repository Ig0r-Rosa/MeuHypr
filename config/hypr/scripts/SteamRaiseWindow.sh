#!/usr/bin/env bash
# Mantém a janela principal da Steam visível no monitor primário (XWayland).

DISPLAY="${DISPLAY:-:1}"
TARGET_X=240
TARGET_Y=80
TARGET_W=1280
TARGET_H=800
DURATION_SEC=180

find_main_steam_x11_id() {
  local id w h
  while read -r id; do
    [[ -z "$id" ]] && continue
    eval "$(DISPLAY="$DISPLAY" xdotool getwindowgeometry --shell "$id" 2>/dev/null)" || continue
    [[ "${WIDTH:-0}" -ge 800 && "${HEIGHT:-0}" -ge 600 ]] || continue
    echo "$id"
    return 0
  done < <(DISPLAY="$DISPLAY" xdotool search --name '^Steam$' 2>/dev/null)
  return 1
}

place_steam_window() {
  local win="$1"
  DISPLAY="$DISPLAY" xdotool windowmove "$win" "$TARGET_X" "$TARGET_Y" 2>/dev/null || return 1
  DISPLAY="$DISPLAY" xdotool windowsize "$win" "$TARGET_W" "$TARGET_H" 2>/dev/null || true
  DISPLAY="$DISPLAY" xdotool windowactivate "$win" 2>/dev/null || true
  return 0
}

command -v xdotool >/dev/null || exit 0

end=$((SECONDS + DURATION_SEC))
while (( SECONDS < end )); do
  win=$(find_main_steam_x11_id) && place_steam_window "$win"
  sleep 3
done
