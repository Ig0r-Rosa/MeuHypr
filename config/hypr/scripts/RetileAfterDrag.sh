#!/usr/bin/env bash
# Reintegra janelas ao layout após soltar Super+arrastar em outra área de trabalho.

# Popups e janelas que devem permanecer flutuantes.
is_permanent_float() {
  local addr="$1"
  hyprctl clients -j | jq -e --arg a "$addr" '
    .[] | select(.address == $a) |
    (.tags | index("floatlock") != null)
    or (.pinned == true)
    or (.class | test("^(swaync|rofi|yad|hyprland-donate-screen|pavucontrol|org[.]pulseaudio[.]pavucontrol|nm-applet|org[.]gnome[.]Calculator|qalculate-gtk|zoom|onedriver)$"; "i"))
    or (.title | test("^(Picture-in-Picture|Authentication Required|Add Folder to Workspace|Save As|Keybindings|ROG Control|SDDM Background|File Operation Progress)$"; "i"))
  ' >/dev/null
}

# Coloca uma janela flutuante de volta no tiling dwindle.
retile_address() {
  local addr="$1"
  [[ -z "$addr" || "$addr" == "null" || "$addr" == "0x0" ]] && return 0
  is_permanent_float "$addr" && return 0
  hyprctl clients -j | jq -e --arg a "$addr" \
    '.[] | select(.address == $a and .floating == true)' >/dev/null || return 0
  hyprctl dispatch settiled "address:${addr}" 2>/dev/null || true
}

# Reorganiza janelas flutuantes tileáveis de um workspace.
retile_workspace() {
  local ws_id="$1"
  local addr
  while read -r addr; do
    retile_address "$addr"
  done < <(
    hyprctl clients -j | jq -r --argjson ws "$ws_id" '
      .[] | select(.workspace.id == $ws and .floating == true) | .address'
  )
}

case "${1:-}" in
  --workspace)
    retile_workspace "${2:-}"
    ;;
  *)
    retile_workspace "$(hyprctl activeworkspace -j | jq '.id')"
    ;;
esac
