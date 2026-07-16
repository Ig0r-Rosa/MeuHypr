#!/usr/bin/env bash
# Emite para a Waybar o número da área de trabalho ativa e reemite a cada
# evento relevante do Hyprland (troca, criação ou remoção de área).

# Imprime o id da área de trabalho ativa no monitor em foco.
emit_active_id() {
  hyprctl activeworkspace -j | jq -r '.id'
}

# Caminho do socket de eventos do Hyprland (socket2).
event_socket() {
  echo "${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
}

# Reemite o id sempre que o Hyprland sinalizar mudança de área.
listen_events() {
  local socket
  socket="$(event_socket)"
  [[ -S "$socket" ]] || return 1

  socat -u "UNIX-CONNECT:${socket}" - 2>/dev/null | while read -r line; do
    case "$line" in
      workspace\>* | focusedmon\>* | createworkspace\>* | destroyworkspace\>*)
        emit_active_id
        ;;
    esac
  done
}

emit_active_id

# Mantém a escuta ativa mesmo se o socket cair (ex.: reload do Hyprland).
while true; do
  listen_events
  sleep 1
done
