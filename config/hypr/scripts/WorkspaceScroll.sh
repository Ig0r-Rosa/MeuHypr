#!/usr/bin/env bash
# Super + scroll e Super + . / , : navega áreas do monitor em ciclo.
# Na última, volta para a primeira. Não cria áreas novas — criar é do Super + =.

# Intervalo mínimo entre trocas (ms). O Hyprland mantém scroll_event_delay=0
# para não rolar apps com Super; o suavização fica aqui.
SCROLL_COOLDOWN_MS=300
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/meuhypr-workspace-scroll"

direction="${1:-+1}"

now_ms() {
  date +%s%3N
}

scroll_throttled() {
  local now last elapsed
  mkdir -p "$STATE_DIR"
  now="$(now_ms)"
  [[ -f "$STATE_DIR/last" ]] || { echo "$now" > "$STATE_DIR/last"; return 1; }

  last="$(<"$STATE_DIR/last")"
  elapsed=$((now - last))
  (( elapsed < SCROLL_COOLDOWN_MS )) && return 0

  echo "$now" > "$STATE_DIR/last"
  return 1
}

get_monitor_workspaces() {
  local monitor="$1"
  hyprctl workspaces -j | jq --arg mon "$monitor" '
    [.[] | select(.monitor == $mon and (.name | startswith("special:") | not)) | .id]
    | sort'
}

go_to_first_workspace() {
  local monitor first_id
  monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
  first_id=$(get_monitor_workspaces "$monitor" | jq 'min')
  hyprctl dispatch workspace "$first_id"
}

# Próxima área do monitor; na última, cicla para a primeira (não cria nova).
scroll_next() {
  local monitor current_id max_id
  monitor=$(hyprctl activeworkspace -j | jq -r '.monitor')
  current_id=$(hyprctl activeworkspace -j | jq '.id')
  max_id=$(get_monitor_workspaces "$monitor" | jq 'max')

  if [[ "$current_id" -eq "$max_id" ]]; then
    go_to_first_workspace
  else
    hyprctl dispatch workspace m+1
  fi
}

scroll_prev() {
  hyprctl dispatch workspace m-1
}

scroll_throttled && exit 0

case "$direction" in
  next|+1|down) scroll_next ;;
  prev|-1|up) scroll_prev ;;
  *) echo "Uso: $0 [next|prev]" ; exit 1 ;;
esac
