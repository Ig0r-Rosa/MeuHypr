#!/usr/bin/env bash
# Instala o tema GRUB "clean" do MeuHypr (só o fundo + lista de boot) e o ativa.
# Remove as mensagens de ajuda do GRUB (EN/PT) e o título do topo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$SCRIPT_DIR/../grub/themes/clean"
THEME_DST="/boot/grub/themes/clean"
GRUB_DEFAULT_FILE="/etc/default/grub"
GRUB_THEME_PATH="$THEME_DST/theme.txt"
ASSETS_WALLPAPERS="$SCRIPT_DIR/../../assets/wallpapers"

# Fundo do GRUB: vazio = mantém o background.jpg versionado (imagem do repo).
# Se definido (caminho ou nome em assets/wallpapers), passa a ser esse.
GRUB_BG_OVERRIDE="${MEUHYPR_GRUB_BG:-}"

log() { printf '[setup-grub] %s\n' "$*"; }

# Só faz sentido em sistemas com GRUB configurável.
grub_available() {
  [[ -f "$GRUB_DEFAULT_FILE" ]] && command -v update-grub >/dev/null 2>&1
}

# Espelha o tema (theme.txt, fonte .pf2, PNGs e background) para o /boot,
# removendo arquivos obsoletos. Ignora o gerador de assets (só dev).
install_theme_files() {
  install -d "$THEME_DST"
  rsync -a --delete \
    --exclude 'generate-assets.py' \
    "$THEME_SRC/" "$THEME_DST/"
}

# Verifica se dá para gerar os assets (precisa de python3 + Pillow).
can_generate_assets() {
  command -v python3 >/dev/null 2>&1 \
    && python3 -c 'import PIL' >/dev/null 2>&1
}

# Imprime "LARGURA ALTURA" da resolução do GRUB (fallback 1920x1080).
grub_screen_size() {
  local mode
  mode=$(grep -oE 'GRUB_GFXMODE="?[0-9]+x[0-9]+' "$GRUB_DEFAULT_FILE" 2>/dev/null \
         | grep -oE '[0-9]+x[0-9]+' | head -1)
  [[ -n "$mode" ]] || mode="1920x1080"
  echo "${mode%x*} ${mode#*x}"
}

# Resolve o fundo escolhido: aceita caminho absoluto ou nome em assets/wallpapers.
# Retorna 1 se não houver override válido (aí mantém o do repo).
resolve_grub_bg() {
  local bg="$GRUB_BG_OVERRIDE"
  [[ -n "$bg" ]] || return 1
  [[ -f "$bg" ]] || bg="$ASSETS_WALLPAPERS/$bg"
  [[ -f "$bg" ]] && { echo "$bg"; return 0; }
  return 1
}

# Aplica um fundo específico só quando MEUHYPR_GRUB_BG é definido e válido.
# Redimensiona para a resolução do GRUB; sem Pillow, copia como está.
install_custom_background() {
  local src w h
  if ! src="$(resolve_grub_bg)"; then
    [[ -n "$GRUB_BG_OVERRIDE" ]] \
      && log "Fundo '$GRUB_BG_OVERRIDE' não encontrado — usando o do repo."
    return 0
  fi
  read -r w h <<<"$(grub_screen_size)"
  log "Aplicando fundo do GRUB: $src (${w}x${h})"
  if can_generate_assets; then
    resize_background "$src" "$THEME_DST/background.jpg" "$w" "$h"
  else
    cp -f "$src" "$THEME_DST/background.jpg"
  fi
}

# Redimensiona a imagem para o tamanho da tela do GRUB (JPEG).
resize_background() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import sys
from PIL import Image
src, dst, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
Image.open(src).convert("RGB").resize((w, h), Image.LANCZOS).save(dst, "JPEG", quality=90)
PY
}

# Regenera painel + theme.txt no /boot para o Nº REAL de entradas do menu
# e a resolução do GRUB (o gerador lê /boot/grub/grub.cfg e /etc/default/grub).
# Sem python3/Pillow, mantém os assets versionados (padrão: 2 itens).
regenerate_theme_for_entries() {
  if ! can_generate_assets; then
    log "python3/Pillow ausente — mantendo tema padrão (2 itens)."
    return 0
  fi
  log "Ajustando painel do GRUB ao nº de entradas do menu..."
  cp "$THEME_SRC/generate-assets.py" "$THEME_DST/generate-assets.py"
  python3 "$THEME_DST/generate-assets.py" || true
  rm -f "$THEME_DST/generate-assets.py"
}

# Trunca títulos longos do menu com reticências (o GRUB não faz isso sozinho).
truncate_menu_titles() {
  command -v python3 >/dev/null 2>&1 || {
    log "python3 ausente — títulos não truncados."
    return 0
  }
  log "Truncando títulos longos do menu (reticências)..."
  python3 "$SCRIPT_DIR/grub_truncate_titles.py" || true
}

# Faz backup do /etc/default/grub (uma vez por execução).
backup_grub_default() {
  cp -a "$GRUB_DEFAULT_FILE" "${GRUB_DEFAULT_FILE}.bak-$(date +%Y%m%d-%H%M%S)"
}

# Garante GRUB_THEME apontando para o tema (adiciona ou corrige, sem duplicar).
enable_grub_theme() {
  if grep -q '^GRUB_THEME=' "$GRUB_DEFAULT_FILE"; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$GRUB_THEME_PATH\"|" "$GRUB_DEFAULT_FILE"
  else
    printf 'GRUB_THEME="%s"\n' "$GRUB_THEME_PATH" >>"$GRUB_DEFAULT_FILE"
  fi
}

main() {
  [[ "${EUID:-0}" -eq 0 ]] || { echo "Execute com sudo." >&2; exit 1; }

  if ! grub_available; then
    log "GRUB não encontrado — etapa ignorada."
    exit 0
  fi

  log "Instalando tema GRUB 'clean' em $THEME_DST ..."
  install_theme_files
  install_custom_background
  backup_grub_default
  enable_grub_theme
  log "Regenerando /boot/grub/grub.cfg ..."
  update-grub >/dev/null
  truncate_menu_titles
  regenerate_theme_for_entries
  log "Concluído. Efeito no próximo boot."
}

main "$@"
