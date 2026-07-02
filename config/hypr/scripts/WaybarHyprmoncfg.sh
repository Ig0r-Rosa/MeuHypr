#!/usr/bin/env bash
# hyprmoncfg — layout de monitores; foca janela existente ou abre em área vazia.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:${PATH:-}"

if ! command -v hyprmoncfg >/dev/null 2>&1; then
  notify-send -u low hyprmoncfg "Instale o hyprmoncfg para usar este botão."
  exit 1
fi

pkill -x fuzzel 2>/dev/null || true
exec "$script_dir/SwayncFocusOrLaunchTui.sh" hyprmoncfg hyprmoncfg
