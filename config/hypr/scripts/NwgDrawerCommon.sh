#!/usr/bin/env bash
# Parâmetros compartilhados do nwg-drawer (grid de apps com ícones e nomes).

nwg_drawer_build_args() {
  local scripts_dir="$1"
  printf '%s\n' \
    -wm hyprland \
    -term kitty \
    -fm nautilus \
    -lang pt \
    -i Flat-Remix-Blue-Dark \
    -c 7 \
    -is 72 \
    -spacing 28 \
    -ovl \
    -pblock "$scripts_dir/LockScreen.sh" \
    -pbexit "hyprctl dispatch exit 0" \
    -pbsleep "systemctl suspend" \
    -pbreboot "systemctl reboot" \
    -pbpoweroff "systemctl poweroff"
}
