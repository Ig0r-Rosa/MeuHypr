#!/usr/bin/env bash
# Atualiza waybar, fuzzel e swaync sem derrubar a barra.

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

file_exists() {
  [[ -e "$1" ]]
}

# Recarrega a waybar in-place (sem pkill — evita sumir da tela).
reload_waybar() {
  if ! pgrep -x waybar >/dev/null; then
    "$SCRIPTSDIR/WaybarStart.sh" --quick
    return
  fi

  if command -v waybar-msg >/dev/null 2>&1; then
    waybar-msg cmd reload >/dev/null 2>&1 && return
  fi

  pkill -SIGUSR2 waybar 2>/dev/null || true
  sleep 0.15

  if ! pgrep -x waybar >/dev/null; then
    "$SCRIPTSDIR/WaybarStart.sh" --quick
  fi
}

for proc in fuzzel swaync ags; do
  pidof "$proc" >/dev/null && pkill "$proc"
done

sleep 0.15
reload_waybar
sleep 0.2
swaync >/dev/null 2>&1 &
swaync-client --reload-config 2>/dev/null || true
swaync-client --reload-css 2>/dev/null || true

sleep 0.5
if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
