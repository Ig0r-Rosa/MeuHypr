#!/usr/bin/env bash
# Super+A: no Nautilus abre kitty na pasta atual.

KITTY_BIN="$(command -v kitty || true)"

is_nautilus_focused() {
  hyprctl activewindow -j | jq -e \
    '.class == "org.gnome.Nautilus" or .class == "nautilus"' >/dev/null
}

open_nautilus_terminal() {
  # Usa a ação da extensão nautilus-open-any-terminal (pasta atual).
  gdbus call --session \
    --dest org.gnome.Nautilus \
    --object-path /org/gnome/Nautilus \
    --method org.gtk.Actions.Activate \
    open_any_terminal '[]' '{}' >/dev/null 2>&1 && return 0

  # Fallback: lê a pasta aberta via FileManager1.
  [[ -z "$KITTY_BIN" ]] && return 1

  local uri path
  uri="$(gdbus call --session \
    --dest org.freedesktop.FileManager1 \
    --object-path /org/freedesktop/FileManager1 \
    --method org.freedesktop.DBus.Properties.Get \
    org.freedesktop.FileManager1 OpenWindowsWithLocations 2>/dev/null \
    | grep -oE 'file://[^'\''"]+' | head -n1)"

  [[ -z "$uri" ]] && return 1
  path="$(python3 -c "from urllib.parse import urlparse, unquote; print(unquote(urlparse('${uri}').path))")"
  [[ -d "$path" ]] || return 1

  "$KITTY_BIN" --directory "$path" &
}

is_nautilus_focused || exit 0
open_nautilus_terminal
