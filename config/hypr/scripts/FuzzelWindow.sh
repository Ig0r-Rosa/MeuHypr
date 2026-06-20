#!/usr/bin/env bash
# Alternador de janelas via Rofi (Super+J).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

rofi_show_window "Janelas"
