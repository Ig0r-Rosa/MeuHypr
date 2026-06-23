#!/usr/bin/env bash
# kew — usa ~/Músicas (XDG) e sincroniza o path no kewrc antes de abrir.

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kewrc="$HOME/.config/kew/kewrc"
music_dir="$(xdg-user-dir MUSIC 2>/dev/null || echo "$HOME/Músicas")"

[[ -d "$music_dir" ]] || {
  notify-send -u low kew "Pasta de músicas não encontrada: $music_dir"
  exit 1
}

sync_kew_music_path() {
  local target="${music_dir%/}/"
  local current=""

  [[ -f "$kewrc" ]] && current="$(grep -E '^path=' "$kewrc" | cut -d= -f2- || true)"
  [[ "${current%/}/" == "$target" ]] && return 0

  command -v kew >/dev/null 2>&1 || return 1
  kew path "$target" >/dev/null 2>&1
}

sync_kew_music_path

# Buffer maior no PipeWire/Pulse — reduz engasgos no áudio.
export PULSE_LATENCY_MSEC=60

kew_bin="$HOME/.local/bin/kew"
[[ -x "$kew_bin" ]] || kew_bin="$(command -v kew)"

exec "$script_dir/SwayncFocusOrLaunchTui.sh" kew "${kew_bin##*/}"
