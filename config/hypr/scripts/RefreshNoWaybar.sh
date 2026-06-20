#!/usr/bin/env bash
# Atualiza swaync e extras — sem repetir wallust (evita corrida com troca de wallpaper).

SCRIPTSDIR=$HOME/.config/hypr/scripts
UserScripts=$HOME/.config/hypr/UserScripts

file_exists() {
  [[ -e "$1" ]]
}

for proc in fuzzel; do
  pidof "$proc" >/dev/null && pkill "$proc"
done

# Wallust só quando o caller não rodou (ex.: wallpaper automático).
if [[ "${SKIP_WALLUST:-}" != "1" ]]; then
  "${SCRIPTSDIR}/WallustSwww.sh"
fi

swaync-client --reload-config 2>/dev/null || true

if file_exists "${UserScripts}/RainbowBorders.sh"; then
  ${UserScripts}/RainbowBorders.sh &
fi

exit 0
