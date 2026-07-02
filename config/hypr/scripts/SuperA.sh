#!/usr/bin/env bash
# Super+A: abre terminal na pasta atual (Nautilus ou yazi no kitty).

KITTY_BIN="$(command -v kitty || true)"
KITTEN_BIN="$(command -v kitten || true)"

is_nautilus_focused() {
  hyprctl activewindow -j | jq -e \
    '.class == "org.gnome.Nautilus" or .class == "nautilus"' >/dev/null
}

is_yazi_focused() {
  hyprctl activewindow -j | jq -e \
    '.class == "kitty" and (.title | test("^yazi$"; "i"))' >/dev/null
}

find_yazi_pid() {
  local root="$1" pid comm child
  for pid in $(pgrep -P "$root" 2>/dev/null); do
    comm="$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')"
    if [[ "$comm" == "yazi" ]]; then
      echo "$pid"
      return 0
    fi
    child="$(find_yazi_pid "$pid")"
    if [[ -n "$child" ]]; then
      echo "$child"
      return 0
    fi
  done
  return 1
}

yazi_cwd() {
  local kitty_pid yazi_pid
  kitty_pid="$(hyprctl activewindow -j | jq -r '.pid')"
  [[ -z "$kitty_pid" || "$kitty_pid" == "null" ]] && return 1
  yazi_pid="$(find_yazi_pid "$kitty_pid")"
  [[ -z "$yazi_pid" ]] && return 1
  readlink -f "/proc/$yazi_pid/cwd" 2>/dev/null
}

open_nautilus_terminal() {
  gdbus call --session \
    --dest org.gnome.Nautilus \
    --object-path /org/gnome/Nautilus \
    --method org.gtk.Actions.Activate \
    open_any_terminal '[]' '{}' >/dev/null 2>&1 && return 0

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

open_yazi_terminal() {
  local cwd kitty_pid socket
  [[ -z "$KITTEN_BIN" || -z "$KITTY_BIN" ]] && return 1

  cwd="$(yazi_cwd)" || return 1
  [[ -d "$cwd" ]] || return 1

  kitty_pid="$(hyprctl activewindow -j | jq -r '.pid')"
  socket="unix:${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/kitty-meuhypr"

  if kitten @ --to "$socket" launch --match "pid:$kitty_pid" --type=tab --cwd "$cwd" 2>/dev/null; then
    return 0
  fi

  # Fallback: nova janela kitty na pasta (antes do listen_on estar ativo).
  "$KITTY_BIN" --directory "$cwd" &
}

if is_nautilus_focused; then
  open_nautilus_terminal
  exit 0
fi

if is_yazi_focused; then
  open_yazi_terminal || notify-send -u low Super+A "Não foi possível abrir terminal na pasta do yazi."
fi
