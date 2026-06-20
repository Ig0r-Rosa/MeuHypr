#!/usr/bin/env bash
# Abre o calendário (gnome-calendar) a partir da waybar.

if command -v gnome-calendar >/dev/null 2>&1; then
  hyprctl dispatch exec gnome-calendar
  exit 0
fi

notify-send -u low "Calendário" "Instale gnome-calendar para usar este botão." 2>/dev/null || true
