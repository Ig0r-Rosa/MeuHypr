#!/usr/bin/env bash
# Launcher de aplicativos via nwg-drawer (grid com ícones e nomes).

scripts_dir="$HOME/.config/hypr/scripts"
drawer_bin="$HOME/.local/bin/nwg-drawer"
common_sh="$scripts_dir/NwgDrawerCommon.sh"

# Apps Snap precisam de /snap/bin no PATH e do diretório desktop do snapd.
export PATH="${PATH:+$PATH:}/snap/bin"
export XDG_DATA_DIRS="$HOME/.local/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

snap_desktop="/var/lib/snapd/desktop"
case ":${XDG_DATA_DIRS:-}:" in
  *:"$snap_desktop":*) ;;
  *)
    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:${snap_desktop}"
    ;;
esac

[[ -x "$drawer_bin" && -f "$common_sh" ]] || exit 1
# shellcheck source=/dev/null
source "$common_sh"

mapfile -t drawer_args < <(nwg_drawer_build_args "$scripts_dir")

# Instância residente: apenas sinaliza para abrir (mais rápido).
if pgrep -x nwg-drawer >/dev/null; then
  exec "$drawer_bin" -open
fi

exec "$drawer_bin" "${drawer_args[@]}"
