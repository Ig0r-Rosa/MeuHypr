#!/usr/bin/env bash
# Launcher de aplicativos via Fuzzel (Super+D) — estilo Spotlight.

# Apps Snap precisam de /snap/bin no PATH e do diretório desktop do snapd.
export PATH="${PATH:+$PATH:}/snap/bin"

snap_desktop="/var/lib/snapd/desktop"
case ":${XDG_DATA_DIRS:-}:" in
  *:"$snap_desktop":*) ;;
  *)
    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:${snap_desktop}"
    ;;
esac

pkill fuzzel 2>/dev/null || true
exec fuzzel --config "$HOME/.config/fuzzel/fuzzel.ini" "$@"
