#!/usr/bin/env bash
# Mantém o nwg-drawer residente na memória para abrir o grid mais rápido.

scripts_dir="$HOME/.config/hypr/scripts"
drawer_bin="$HOME/.local/bin/nwg-drawer"
common_sh="$scripts_dir/NwgDrawerCommon.sh"

[[ -x "$drawer_bin" && -f "$common_sh" ]] || exit 0

export XDG_DATA_DIRS="$HOME/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
pkill -x nwg-drawer 2>/dev/null || true
sleep 0.3

# shellcheck source=/dev/null
source "$common_sh"
mapfile -t drawer_args < <(nwg_drawer_build_args "$scripts_dir")

exec "$drawer_bin" -r "${drawer_args[@]}"
