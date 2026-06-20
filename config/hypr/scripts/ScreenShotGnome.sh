#!/usr/bin/env bash
# Screenshot com interface GNOME (gnome-screenshot no Wayland/Hyprland).

case "${1:---interactive}" in
  --interactive|--area)
    exec gnome-screenshot -i -c
    ;;
  --now|--fullscreen)
    exec gnome-screenshot -c
    ;;
  --window|--active)
    exec gnome-screenshot -w -c
    ;;
  --in5)
    exec gnome-screenshot -d 5 -c
    ;;
  --in10)
    exec gnome-screenshot -d 10 -c
    ;;
  *)
    echo "Uso: $0 [--interactive|--now|--window|--in5|--in10]"
    exit 1
    ;;
esac
