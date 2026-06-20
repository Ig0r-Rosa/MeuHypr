#!/usr/bin/env bash
# Wrapper de sessão Wayland para o SDDM iniciar o Hyprland com variáveis corretas.

export XDG_CURRENT_DESKTOP=Hyprland
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=Hyprland

HYPR_BIN="${HYPR_BIN:-/usr/local/bin/Hyprland}"
if [[ ! -x "$HYPR_BIN" ]]; then
  HYPR_BIN="$(command -v Hyprland || command -v hyprland || true)"
fi

if [[ -z "$HYPR_BIN" ]]; then
  echo "Hyprland não encontrado. Instale o compositor antes de iniciar a sessão." >&2
  exit 1
fi

exec "$HYPR_BIN" "$@"
