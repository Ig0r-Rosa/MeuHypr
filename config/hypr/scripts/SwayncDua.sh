#!/usr/bin/env bash
# dua — modo interativo (TUI); sem "interactive" o binário só lista e fecha o terminal.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$script_dir/SwayncFocusOrLaunchTui.sh" dua "dua interactive $HOME"
