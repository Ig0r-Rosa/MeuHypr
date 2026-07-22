#!/usr/bin/env bash
# Super+E / Super+B: foca janela aberta ou abre o app se não existir.
# Super+Shift+B: mesmo fluxo para janela anônima do navegador padrão.

mode="${1:-}"

# Título típico de modo privado (vários idiomas / motores).
PRIVATE_TITLE_RE='(?i)(privat|incognito|inprivate|an[oô]nim|inc[oó]gnit)'

# Classe de fallback se a janela ainda não tiver tag browser.
BROWSER_CLASS_RE='(?i)(firefox|librewolf|waterfox|floorp|chrome|chromium|brave|msedge|microsoft-edge|opera|vivaldi|zen|thorium|cachy|epiphany|gnome-web|falkon|midori|qutebrowser|tor|mullvad|seamonkey|ungoogled)'

# Endereço da primeira janela que casa com o modo pedido.
find_client() {
  hyprctl clients -j | jq -r --arg m "$mode" --arg tre "$PRIVATE_TITLE_RE" --arg cre "$BROWSER_CLASS_RE" '
    .[] | select(
      if $m == "browser" then
        any(.tags[]?; test("^browser"))
        or (.class | test($cre))
        or (.initialClass | test($cre))
      elif $m == "browser-private" then
        (
          any(.tags[]?; test("^browser"))
          or (.class | test($cre))
          or (.initialClass | test($cre))
        )
        and (
          (.title | test($tre))
          or (.initialTitle | test($tre))
        )
      elif $m == "files" then
        (.class == "org.gnome.Nautilus" or .class == "nautilus")
        or any(.tags[]?; test("^file-manager"))
        or ((.class | test("(?i)kitty")) and (.title | test("(?i)yazi")))
      else
        false
      end
    ) | .address' | head -n1
}

# Traz a janela existente para frente.
focus_client() {
  local addr="$1"
  [[ -n "$addr" ]] || return 1
  hyprctl dispatch focuswindow "address:${addr}" 2>/dev/null
}

# Desktop file do navegador padrão (ex.: firefox-esr.desktop).
default_browser_desktop() {
  local desktop
  desktop=$(xdg-settings get default-web-browser 2>/dev/null || true)
  [[ -z "$desktop" ]] && desktop=$(xdg-mime query default x-scheme-handler/https 2>/dev/null || true)
  printf '%s' "$desktop"
}

# Binário a partir do .desktop (Exec= sem argumentos %u/%f).
browser_bin_from_desktop() {
  local desktop="$1" path="" line bin
  [[ -n "$desktop" ]] || return 1

  for dir in \
    "${XDG_DATA_HOME:-$HOME/.local/share}/applications" \
    /usr/local/share/applications \
    /usr/share/applications; do
    [[ -f "$dir/$desktop" ]] && path="$dir/$desktop" && break
  done
  [[ -n "$path" ]] || return 1

  line=$(grep -m1 '^Exec=' "$path" | sed 's/^Exec=//')
  bin=$(printf '%s' "$line" | awk '{print $1}')
  command -v "$bin" >/dev/null 2>&1 && printf '%s' "$bin"
}

# Flag de modo anônimo conforme a família do navegador.
private_flag_for() {
  local name
  name=$(basename "$1" | tr '[:upper:]' '[:lower:]')
  case "$name" in
    *chrome*|*chromium*|*brave*|*edge*|*opera*|*vivaldi*|*thorium*|*cachy*|*ungoogled*)
      printf '%s' '--incognito'
      ;;
    *)
      # Firefox, Zen, LibreWolf, Epiphany, Tor, etc.
      printf '%s' '--private-window'
      ;;
  esac
}

# Abre o navegador padrão em modo anônimo/privado.
launch_private_browser() {
  local bin desktop flag
  desktop=$(default_browser_desktop)
  bin=$(browser_bin_from_desktop "$desktop") || true

  if [[ -z "$bin" ]]; then
    for cand in \
      firefox-esr firefox google-chrome-stable google-chrome \
      chromium brave-browser brave microsoft-edge opera vivaldi zen-browser; do
      command -v "$cand" >/dev/null 2>&1 && bin="$cand" && break
    done
  fi
  [[ -n "$bin" ]] || return 1

  flag=$(private_flag_for "$bin")
  "$bin" "$flag"
}

# Abre o app do modo atual (sem janela já aberta).
launch_app() {
  local scripts_dir="$HOME/.config/hypr/scripts"

  case "$mode" in
    browser)          xdg-open "https://" ;;
    browser-private)  launch_private_browser ;;
    files)            "$scripts_dir/FileManagerOpen.sh" ;;
  esac
}

[[ "$mode" == "browser" || "$mode" == "browser-private" || "$mode" == "files" ]] || exit 1

addr="$(find_client)"
if [[ -n "$addr" ]]; then
  focus_client "$addr"
else
  launch_app &
fi
