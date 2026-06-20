#!/usr/bin/env bash
# Modo jogo: desativa efeitos visuais para melhor desempenho.

notif="$HOME/.config/swaync/images/ja.png"
SCRIPTSDIR="$HOME/.config/hypr/scripts"

is_enabled() {
  [[ "$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')" == "1" ]]
}

enable_gamemode() {
  hyprctl --batch "\
    keyword animations:enabled 0;\
    keyword decoration:shadow:enabled 0;\
    keyword decoration:blur:enabled 0;\
    keyword general:gaps_in 0;\
    keyword general:gaps_out 0;\
    keyword general:border_size 1;\
    keyword decoration:rounding 0"
  hyprctl keyword "windowrule opacity 1 override 1 override 1 override, ^(.*)$"
  swww kill 2>/dev/null || true
  notify-send -e -u low -i "$notif" "Modo jogo" "Ativado"
}

disable_gamemode() {
  hyprctl --batch "\
    keyword animations:enabled 1;\
    keyword decoration:shadow:enabled 1;\
    keyword decoration:blur:enabled 1;\
    keyword general:gaps_in 2;\
    keyword general:gaps_out 8;\
    keyword general:border_size 2;\
    keyword decoration:rounding 0"
  hyprctl reload

  pgrep -x swww-daemon >/dev/null || swww-daemon &
  sleep 0.3
  "${SCRIPTSDIR}/WallpaperPersist.sh" restore

  notify-send -e -u normal -i "$notif" "Modo jogo" "Desativado"
}

if is_enabled; then
  enable_gamemode
else
  disable_gamemode
fi
