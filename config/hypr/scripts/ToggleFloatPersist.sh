#!/usr/bin/env bash
# Super+Space: flutua, reduz e centraliza; só volta ao tiling com Super+Space de novo.

SCRIPTSDIR="$HOME/.config/hypr/scripts"
TAG="floatlock"
FLOAT_W_RATIO="${FLOAT_W_RATIO:-72}"
FLOAT_H_RATIO="${FLOAT_H_RATIO:-68}"

active_addr() {
  hyprctl activewindow -j | jq -r '.address // empty'
}

has_floatlock() {
  local addr="$1"
  hyprctl clients -j | jq -e --arg a "$addr" \
    '.[] | select(.address == $a) | .tags | index("'"$TAG"'")' >/dev/null
}

# Reduz janela flutuante para percentual da área útil do monitor.
resize_floated_window() {
  local addr="$1" monitor_id mon_w mon_h top bottom target_w target_h

  monitor_id=$(hyprctl clients -j | jq -r --arg a "$addr" \
    '.[] | select(.address == $a) | .monitor')

  read -r mon_w mon_h top bottom < <(
    hyprctl monitors -j | jq -r --argjson id "$monitor_id" \
      '.[] | select(.id == $id) | "\(.width) \(.height) \(.reserved[1]) \(.reserved[3])"'
  )

  target_w=$(( mon_w * FLOAT_W_RATIO / 100 ))
  target_h=$(( (mon_h - top - bottom) * FLOAT_H_RATIO / 100 ))
  (( target_w < 400 )) && target_w=400
  (( target_h < 300 )) && target_h=300

  hyprctl dispatch resizewindowpixel "exact ${target_w} ${target_h},address:${addr}"
}

float_and_lock() {
  local addr="$1"
  hyprctl clients -j | jq -e --arg a "$addr" \
    '.[] | select(.address == $a and .floating == false)' >/dev/null \
    && hyprctl dispatch togglefloating
  resize_floated_window "$addr"
  hyprctl dispatch centerwindow
  hyprctl dispatch tagwindow +"$TAG"
  "$SCRIPTSDIR/ResizeBorderPolicy.sh"
}

return_to_tiling() {
  local addr="$1"
  hyprctl dispatch tagwindow -- -"$TAG"
  hyprctl dispatch settiled "address:${addr}"
  "$SCRIPTSDIR/ResizeBorderPolicy.sh"
}

main() {
  local addr
  addr="$(active_addr)"
  [[ -z "$addr" || "$addr" == "null" ]] && exit 0

  if has_floatlock "$addr"; then
    return_to_tiling "$addr"
  else
    float_and_lock "$addr"
  fi
}

main "$@"
