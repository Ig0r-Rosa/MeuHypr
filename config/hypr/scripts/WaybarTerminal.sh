#!/usr/bin/env bash
# Abre o Kitty na workspace/monitor em foco.

pkill -x fuzzel 2>/dev/null || true
hyprctl dispatch exec kitty
