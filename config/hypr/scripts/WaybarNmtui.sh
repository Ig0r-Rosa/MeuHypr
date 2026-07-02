#!/usr/bin/env bash
# nmtui — rede TUI; foca janela existente ou abre em área vazia.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$script_dir/SwayncFocusOrLaunchTui.sh" nmtui nmtui
