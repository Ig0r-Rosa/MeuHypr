#!/usr/bin/env bash
# Aplica tema Kvantum, escala de texto GTK e fontes padrão do MeuHypr.

set -euo pipefail

TARGET_USER="${1:?Informe o usuário alvo}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
KVANTUM_THEME="${MEUHYPR_KVANTUM_THEME:-KvAdaptaDark}"
TEXT_SCALE="${MEUHYPR_TEXT_SCALE:-1.25}"
GTK_FONT="${MEUHYPR_GTK_FONT:-C059 Bold 11}"
GTK_MONO_FONT="${MEUHYPR_GTK_MONO_FONT:-Monospace 11}"

log() { printf '[setup-display] %s\n' "$*"; }

run_as_user() {
  sudo -u "$TARGET_USER" bash -lc "$1"
}

apply_kvantum_theme() {
  local kvconfig="$TARGET_HOME/.config/Kvantum/kvantum.kvconfig"
  mkdir -p "$(dirname "$kvconfig")"
  cat >"$kvconfig" <<KVEOF
[General]
theme=$KVANTUM_THEME
KVEOF
  chown "$TARGET_USER:$TARGET_USER" "$kvconfig"
  if command -v kvantummanager >/dev/null; then
    run_as_user "kvantummanager --set '$KVANTUM_THEME' >/dev/null 2>&1 || true"
  fi
}

apply_gtk_text_preferences() {
  run_as_user "
    command -v gsettings >/dev/null || exit 0
    gsettings set org.gnome.desktop.interface text-scaling-factor '$TEXT_SCALE' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name '$GTK_FONT' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface document-font-name '$GTK_FONT' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface monospace-font-name '$GTK_MONO_FONT' 2>/dev/null || true
  "
}

log "Aplicando display/Kvantum/fontes para $TARGET_USER ..."
apply_kvantum_theme
apply_gtk_text_preferences
log "Concluído."
