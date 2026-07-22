#!/usr/bin/env bash
# Fecha todas as janelas privadas/anônimas de qualquer navegador.
# Detecta pelo tag Hyprland "browser" (ou classe conhecida) + título privado.

# Título típico de modo privado (vários idiomas / motores).
PRIVATE_TITLE_RE='(?i)(privat|incognito|inprivate|an[oô]nim|inc[oó]gnit)'

# Classe de fallback se a janela ainda não tiver tag browser.
BROWSER_CLASS_RE='(?i)(firefox|librewolf|waterfox|floorp|chrome|chromium|brave|msedge|microsoft-edge|opera|vivaldi|zen|thorium|cachy|epiphany|gnome-web|falkon|midori|qutebrowser|tor|mullvad|seamonkey|ungoogled)'

# Lista endereços de janelas privadas.
list_private_addrs() {
  hyprctl clients -j | jq -r --arg tre "$PRIVATE_TITLE_RE" --arg cre "$BROWSER_CLASS_RE" '
    .[]
    | select(
        (
          any(.tags[]?; test("^browser"))
          or (.class | test($cre))
          or (.initialClass | test($cre))
        )
        and (
          (.title | test($tre))
          or (.initialTitle | test($tre))
        )
      )
    | .address
  '
}

# Fecha uma janela pelo endereço Hyprland.
close_addr() {
  local addr="$1"
  [[ -n "$addr" ]] || return 1
  hyprctl dispatch closewindow "address:${addr}" >/dev/null 2>&1
}

main() {
  local addr closed=0
  while IFS= read -r addr; do
    [[ -z "$addr" ]] && continue
    close_addr "$addr" && closed=$((closed + 1))
  done < <(list_private_addrs)

  [[ "$closed" -gt 0 ]]
}

main
