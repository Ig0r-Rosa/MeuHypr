#!/usr/bin/env bash
# Remove a área de trabalho atual, fechando as janelas dela.

notify_user() {
  command -v notify-send >/dev/null && notify-send -u low "Workspace" "$1"
}

is_special_workspace() {
  [[ "$1" == special:* ]]
}

count_workspaces_on_monitor() {
  local monitor="$1"
  hyprctl workspaces -j | jq --arg mon "$monitor" '
    [.[] | select(.monitor == $mon and (.name | startswith("special:") | not))] | length'
}

close_all_windows() {
  local ws_id="$1" address
  while true; do
    address=$(hyprctl clients -j | jq -r --argjson ws "$ws_id" '
      .[] | select(.workspace.id == $ws) | .address' | head -1)
    [[ -z "$address" || "$address" == "null" ]] && break
    hyprctl dispatch closewindow "address:${address}"
  done
}

main() {
  local ws_id ws_name monitor count
  ws_id=$(hyprctl activeworkspace -j | jq '.id')
  ws_name=$(hyprctl activeworkspace -j | jq -r '.name')
  monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')

  if is_special_workspace "$ws_name"; then
    notify_user "Não é possível remover workspace especial"
    exit 1
  fi

  count=$(count_workspaces_on_monitor "$monitor")
  if [[ "$count" -le 1 ]]; then
    notify_user "Última área de trabalho deste monitor"
    exit 1
  fi

  close_all_windows "$ws_id"
  hyprctl dispatch workspace m-1
}

main
