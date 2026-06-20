#!/usr/bin/env bash
# Corrige wallpaper preto só quando o swww realmente quebrou (sem repintar à toa).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
persist="$script_dir/WallpaperPersist.sh"

# setsid: sobrevive ao processo do swaync encerrar após clique no botão.
setsid bash -c "sleep ${1:-0.5}; \"$persist\" repair" </dev/null >/dev/null 2>&1 &
