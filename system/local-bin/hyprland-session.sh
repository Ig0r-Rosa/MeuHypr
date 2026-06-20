#!/usr/bin/env bash
# Wrapper de sessão para o SDDM: define variáveis Wayland e delega ao start-hyprland
# oficial (watchdog do Hyprland 0.53+). Não substituir o binário start-hyprland.

export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

START_HYPR_BIN="${START_HYPR_BIN:-/usr/local/bin/start-hyprland}"

if [[ ! -x "$START_HYPR_BIN" ]] || file -b "$START_HYPR_BIN" | grep -qi 'shell script'; then
  echo "start-hyprland oficial não encontrado. Execute install.sh completo antes de iniciar a sessão." >&2
  exit 1
fi

exec "$START_HYPR_BIN" "$@"
