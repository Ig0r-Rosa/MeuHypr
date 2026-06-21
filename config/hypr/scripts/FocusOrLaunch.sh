#!/usr/bin/env bash
# Super+E / Super+B: foca janela aberta ou abre o app se não existir.

mode="${1:-}"

find_client() {
  hyprctl clients -j | jq -r --arg m "$mode" '
    .[] | select(
      if $m == "browser" then
        any(.tags[]?; test("^browser"))
        or (.class | test("(?i)(firefox|chrome|chromium|brave|edge|zen|thorium|cachy)"))
      elif $m == "files" then
        (.class == "org.gnome.Nautilus" or .class == "nautilus")
        or any(.tags[]?; test("^file-manager"))
      else
        false
      end
    ) | .address' | head -n1
}

focus_client() {
  local addr="$1"
  [[ -n "$addr" ]] || return 1
  hyprctl dispatch focuswindow "address:${addr}" 2>/dev/null
}

launch_app() {
  case "$mode" in
    browser) xdg-open "https://" ;;
    files)   nautilus ;;
  esac
}

[[ "$mode" == "browser" || "$mode" == "files" ]] || exit 1

addr="$(find_client)"
if [[ -n "$addr" ]]; then
  focus_client "$addr"
else
  launch_app &
fi
