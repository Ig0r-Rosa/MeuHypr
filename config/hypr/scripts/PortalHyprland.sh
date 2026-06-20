#!/usr/bin/env bash
# Garante o backend Hyprland do xdg-desktop-portal (sem reiniciar tudo no boot).

hyprland_portal_ready() {
  busctl --user list 2>/dev/null | rg -q 'org[.]freedesktop[.]impl[.]portal[.]desktop[.]hyprland'
}

start_hyprland_portal() {
  [[ -x /usr/lib/xdg-desktop-portal-hyprland ]] || return 1
  /usr/lib/xdg-desktop-portal-hyprland >/dev/null 2>&1 &
}

hyprland_portal_ready && exit 0
start_hyprland_portal
