#!/usr/bin/env bash
# Garante Super+J = alternador de janelas (Rofi) após o carregamento da sessão.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
switcher="$scripts_dir/FuzzelWindow.sh"

hyprctl keyword unbind SUPER,J 2>/dev/null || true
hyprctl keyword bindd SUPER,J,alternador de janelas,exec,"$switcher"
