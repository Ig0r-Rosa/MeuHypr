#!/usr/bin/env bash
# Instala e ativa o tema Plymouth "monoarch" personalizado do MeuHypr
# (splash de boot entre o GRUB e o SDDM: só a bolinha girando, sem logo).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="monoarch"
THEME_SRC="$SCRIPT_DIR/../plymouth/themes/$THEME_NAME"
THEME_DST="/usr/share/plymouth/themes/$THEME_NAME"
GRUB_DEFAULT_FILE="/etc/default/grub"

log() { printf '[setup-plymouth] %s\n' "$*"; }

# Só faz sentido se o Plymouth estiver instalado.
plymouth_available() {
  command -v plymouth-set-default-theme >/dev/null 2>&1
}

# Espelha o tema versionado para o diretório do sistema.
install_theme_files() {
  install -d "$THEME_DST"
  rsync -a --delete "$THEME_SRC/" "$THEME_DST/"
  chown -R root:root "$THEME_DST"
  chmod -R a+rX "$THEME_DST"
}

# Garante o parâmetro "splash" no kernel (necessário p/ o splash gráfico).
ensure_splash_cmdline() {
  [[ -f "$GRUB_DEFAULT_FILE" ]] || return 0
  grep -q 'GRUB_CMDLINE_LINUX_DEFAULT=.*splash' "$GRUB_DEFAULT_FILE" && return 0
  sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*\)"/\1 splash"/' "$GRUB_DEFAULT_FILE"
  command -v update-grub >/dev/null 2>&1 && update-grub >/dev/null 2>&1 || true
}

# Define o tema padrão e reconstrói o initramfs (-R) para valer no próximo boot.
apply_theme() {
  plymouth-set-default-theme -R "$THEME_NAME" >/dev/null 2>&1 \
    || { plymouth-set-default-theme "$THEME_NAME"; update-initramfs -u; }
}

main() {
  if ! plymouth_available; then
    log "Plymouth não instalado — pulando (instale o pacote 'plymouth')."
    return 0
  fi
  log "Instalando tema Plymouth '$THEME_NAME'..."
  install_theme_files
  ensure_splash_cmdline
  apply_theme
  log "Tema Plymouth aplicado (efetivo no próximo boot)."
}

main "$@"
