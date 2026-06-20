#!/usr/bin/env bash
# Cria área vazia no monitor em foco (não reutiliza vazia de outro monitor).

get_target_monitor() {
  case "${1:-}" in
    --at-cursor)
      local x y monitor
      x=$(hyprctl cursorpos -j | jq '.x')
      y=$(hyprctl cursorpos -j | jq '.y')
      monitor=$(hyprctl monitors -j | jq -r --argjson x "$x" --argjson y "$y" '
        .[] | select(
          .x <= $x and $x < (.x + (.width * .scale)) and
          .y <= $y and $y < (.y + (.height * .scale))
        ) | .name' | head -1)
      echo "${monitor:-$(hyprctl activeworkspace -j | jq -r '.monitor')}"
      ;;
    *)
      hyprctl activeworkspace -j | jq -r '.monitor'
      ;;
  esac
}

next_free_workspace_id() {
  hyprctl workspaces -j | jq '
    [.[] | select(.name | startswith("special:") | not) | .id]
    | if length == 0 then 1 else max + 1 end'
}

create_empty_workspace_on_monitor() {
  local monitor="$1"
  local workspace_id

  [[ -z "$monitor" || "$monitor" == "null" ]] && return 1

  hyprctl dispatch focusmonitor "name:${monitor}"
  workspace_id="$(next_free_workspace_id)"
  hyprctl dispatch workspace "$workspace_id"
  "$HOME/.config/hypr/scripts/RetileAfterDrag.sh" --workspace "$workspace_id"
}

create_empty_workspace_on_monitor "$(get_target_monitor "${1:-}")"
