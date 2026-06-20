#!/usr/bin/env bash
# Fecha o painel swaync antes de executar ação de um módulo da waybar.

"$HOME/.config/hypr/scripts/SwayncClosePanel.sh"
[[ $# -gt 0 ]] && exec "$@"
