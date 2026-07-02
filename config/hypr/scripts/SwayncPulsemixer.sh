#!/usr/bin/env bash
# pulsemixer — controlador de áudio TUI (PipeWire/PulseAudio).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$script_dir/SwayncFocusOrLaunchTui.sh" pulsemixer pulsemixer
