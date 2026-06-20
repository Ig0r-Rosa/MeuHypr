#!/usr/bin/env bash
# Mantém a Waybar visível: reinicia se sumir (sem depender de flock/portal).

LOG="${XDG_CACHE_HOME:-$HOME/.cache}/waybar.log"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

waybar_layers() {
  hyprctl layers -j 2>/dev/null | \
    jq '[.. | objects | select(.namespace? == "waybar")] | length' 2>/dev/null || echo 0
}

start_waybar() {
  echo "$(date '+%F %T') watchdog — iniciando waybar" >>"$LOG"
  nohup waybar >>"$LOG" 2>&1 &
  disown
}

ensure_waybar() {
  local layers procs

  procs=$(pgrep -x -c waybar 2>/dev/null || echo 0)
  procs=$(( procs + 0 ))
  layers=$(waybar_layers)
  layers=$(( layers + 0 ))

  # Processo ok e barra na tela.
  [[ "$procs" -eq 1 && "$layers" -gt 0 ]] && return 0

  # Vários processos: limpa e sobe um só.
  if [[ "$procs" -gt 1 ]]; then
    echo "$(date '+%F %T') watchdog — ${procs} instâncias, limpando" >>"$LOG"
    pkill -x waybar 2>/dev/null || true
    sleep 0.5
    start_waybar
    return 0
  fi

  # Sem processo.
  if [[ "$procs" -eq 0 ]]; then
    start_waybar
    return 0
  fi

  # Processo existe mas sem camada visível — reload antes de matar.
  if [[ "$layers" -eq 0 ]]; then
    echo "$(date '+%F %T') watchdog — processo sem camada, reload" >>"$LOG"
    if command -v waybar-msg >/dev/null 2>&1; then
      waybar-msg cmd reload >/dev/null 2>&1 || true
    else
      pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
    sleep 1
    layers=$(waybar_layers)
    [[ "$layers" -gt 0 ]] && return 0
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    start_waybar
  fi
}

# Primeira checagem imediata.
ensure_waybar

while sleep 15; do
  ensure_waybar
done
