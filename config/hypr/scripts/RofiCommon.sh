#!/usr/bin/env bash
# Utilitários compartilhados pelos scripts que abrem o Rofi.

rofi_bin="/usr/local/bin/rofi"
rofi_dir="$HOME/.config/rofi"
rofi_theme_menu="$rofi_dir/config-menu.rasi"
rofi_theme_menu_long="$rofi_dir/config-menu-long.rasi"
rofi_theme_prompt="$rofi_dir/config-search.rasi"
rofi_theme_window="$rofi_dir/config-window.rasi"

rofi_require() {
  local theme="$1"
  [[ -x "$rofi_bin" && -f "$theme" ]] || {
    notify-send -u critical "Rofi" "Rofi ou tema não encontrado." 2>/dev/null
    exit 1
  }
}

rofi_prepare() {
  pkill -x rofi 2>/dev/null || true
  pkill -x fuzzel 2>/dev/null || true
}

# Lista com filtro; imprime a linha escolhida.
rofi_menu_pick() {
  local prompt="$1"
  local theme="${2:-$rofi_theme_menu}"
  local selected_row="${3:-}"

  rofi_require "$theme"
  rofi_prepare

  local args=(-dmenu -i -config "$theme")
  [[ -n "$prompt" ]] && args+=(-p "$prompt")
  [[ -n "$selected_row" ]] && args+=(-selected-row "$selected_row")

  "$rofi_bin" "${args[@]}"
}

# Campo único (sem lista).
rofi_prompt_only() {
  local prompt="$1"
  local theme="${2:-$rofi_theme_prompt}"

  rofi_require "$theme"
  rofi_prepare
  "$rofi_bin" -dmenu -config "$theme" -p "$prompt"
}

# Alternador nativo de janelas.
rofi_show_window() {
  local prompt="${1:-Janelas}"
  rofi_require "$rofi_theme_window"
  rofi_prepare
  "$rofi_bin" -show window -config "$rofi_theme_window" -p "$prompt"
}
