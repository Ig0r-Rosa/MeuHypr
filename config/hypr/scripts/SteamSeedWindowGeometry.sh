#!/usr/bin/env bash
# Corrige posição salva da janela principal da Steam (htmlcache/leveldb).
# Rodar com a Steam fechada — evita coords inválidas após --clear-cache.

set -euo pipefail

LEVELDB="${HOME}/.steam/debian-installation/config/htmlcache/Default/Local Storage/leveldb"
# Monitor primário HDMI (0,0): centro aproximado da janela.
GOOD_DETAILS='1&x=240&y=97&w=1440&h=918'

log() { printf '[steam-seed] %s\n' "$*"; }

[[ -d "$LEVELDB" ]] || { log "Sem leveldb — nada a corrigir."; exit 0; }

patched=0
while IFS= read -r -d '' file; do
  if grep -q 'Window_SteamDesktop' "$file" 2>/dev/null || grep -q 'PopupSavedDimensions_' "$file" 2>/dev/null; then
    if sed -i \
      -e 's/1&x=[0-9]\+&y=[0-9]\+&w=[0-9]\+&h=[0-9]\+/'"$GOOD_DETAILS"'/g' \
      "$file"; then
      patched=1
      log "Geometria ajustada em: ${file##*/}"
    fi
  fi
done < <(find "$LEVELDB" -maxdepth 1 -type f -print0 2>/dev/null)

[[ "$patched" -eq 1 ]] && log "Posição salva: $GOOD_DETAILS" || log "Nenhum registro de janela encontrado."
