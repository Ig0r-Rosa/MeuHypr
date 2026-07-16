#!/usr/bin/env bash
# instalar_tema_grub.sh — instala o tema GRUB "clean" do MeuHypr usando o
# wallpaper que você escolher, mantendo AUTOMATICAMENTE as entradas de boot
# desta máquina (Linux, Windows, Ubuntu, Windows 10/11... o que houver).
#
# Uso:
#   sudo ./instalar_tema_grub.sh                     # usa a imagem padrão do repo
#   sudo ./instalar_tema_grub.sh wallpaper_grub.png  # usa a imagem que você passar
#   sudo ./instalar_tema_grub.sh espaco_1.jpg        # nome dentro de assets/wallpapers/
#
# Como as entradas são preservadas:
#   O menu de boot vem do grub.cfg (gerado por update-grub a partir do que
#   está instalado NA MÁQUINA). Este script apenas aplica o visual; o
#   gerador conta quantas entradas existem e dimensiona o painel para elas.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="$SCRIPT_DIR/system/grub/themes/clean"
GEN_ASSETS="$THEME_SRC/generate-assets.py"
TRUNCATE="$SCRIPT_DIR/system/scripts/grub_truncate_titles.py"
THEME_DST="/boot/grub/themes/clean"
GRUB_DEFAULT_FILE="/etc/default/grub"
GRUB_THEME_PATH="$THEME_DST/theme.txt"
ASSETS_WALLPAPERS="$SCRIPT_DIR/assets/wallpapers"
# Fundo padrão (sem argumento): a imagem versionada do próprio tema.
DEFAULT_BG="$THEME_SRC/background.jpg"

log() { printf '\n[tema-grub] %s\n' "$*"; }
die() { printf '\n[tema-grub] ERRO: %s\n' "$*" >&2; exit 1; }

# --- Validações -------------------------------------------------------------

require_root() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || die "Rode com sudo. Ex.: sudo $0 wallpaper.png"
}

# Define $WALLPAPER: usa o argumento (caminho absoluto ou nome em
# assets/wallpapers) ou, sem argumento, a imagem padrão do repo.
resolve_wallpaper() {
  WALLPAPER="${1:-}"
  if [[ -z "$WALLPAPER" ]]; then
    WALLPAPER="$DEFAULT_BG"
    log "Sem wallpaper informado — usando o padrão do repo: $(basename "$WALLPAPER")"
  elif [[ ! -f "$WALLPAPER" && -f "$ASSETS_WALLPAPERS/$WALLPAPER" ]]; then
    WALLPAPER="$ASSETS_WALLPAPERS/$WALLPAPER"
  fi
  [[ -f "$WALLPAPER" ]] || die "Wallpaper não encontrado: $WALLPAPER"
}

# Confere as dependências necessárias.
require_deps() {
  command -v update-grub >/dev/null 2>&1 || die "update-grub não encontrado (GRUB não instalado?)."
  command -v python3 >/dev/null 2>&1 || die "python3 é necessário."
  python3 -c 'import PIL' 2>/dev/null || die "Pillow ausente. Instale: apt install python3-pil"
  [[ -f "$GEN_ASSETS" ]] || die "Gerador não encontrado: $GEN_ASSETS"
}

# --- Detecção ---------------------------------------------------------------

# Imprime "LARGURA ALTURA" da resolução do GRUB (fallback 1920x1080).
screen_size() {
  local mode
  mode=$(grep -oE 'GRUB_GFXMODE="?[0-9]+x[0-9]+' "$GRUB_DEFAULT_FILE" 2>/dev/null \
         | grep -oE '[0-9]+x[0-9]+' | head -1)
  [[ -n "$mode" ]] || mode="1920x1080"
  echo "${mode%x*} ${mode#*x}"
}

# Mostra as entradas detectadas (feedback para o usuário).
# Extrai o título entre aspas (simples ou duplas) de cada menuentry.
show_detected_entries() {
  log "Entradas de boot detectadas nesta máquina:"
  grep -E '^[[:space:]]*menuentry ' /boot/grub/grub.cfg 2>/dev/null \
    | sed -E "s/^[[:space:]]*menuentry[[:space:]]+['\"]([^'\"]*)['\"].*/  • \1/" || true
}

# --- Passos de instalação ---------------------------------------------------

# Copia os assets versionados do tema para o /boot (fonte, PNGs, theme base).
install_theme_files() {
  install -d "$THEME_DST"
  rsync -a --delete --exclude 'generate-assets.py' "$THEME_SRC/" "$THEME_DST/"
}

# Converte o wallpaper escolhido em background.jpg no tamanho da tela.
install_background() {
  local w h
  read -r w h <<<"$(screen_size)"
  log "Preparando wallpaper (${w}x${h})..."
  python3 - "$WALLPAPER" "$THEME_DST/background.jpg" "$w" "$h" <<'PY'
import sys
from PIL import Image
src, dst, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
Image.open(src).convert("RGB").resize((w, h), Image.LANCZOS).save(
    dst, "JPEG", quality=90
)
PY
}

# Faz backup e aponta GRUB_THEME para o tema (sem duplicar).
enable_theme() {
  cp -a "$GRUB_DEFAULT_FILE" "${GRUB_DEFAULT_FILE}.bak-$(date +%Y%m%d-%H%M%S)"
  if grep -q '^GRUB_THEME=' "$GRUB_DEFAULT_FILE"; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$GRUB_THEME_PATH\"|" "$GRUB_DEFAULT_FILE"
  else
    printf 'GRUB_THEME="%s"\n' "$GRUB_THEME_PATH" >>"$GRUB_DEFAULT_FILE"
  fi
}

# Gera painel + theme.txt para o Nº REAL de entradas e a resolução da máquina.
generate_theme() {
  log "Gerando painel para as entradas desta máquina..."
  cp "$GEN_ASSETS" "$THEME_DST/generate-assets.py"
  python3 "$THEME_DST/generate-assets.py"
  rm -f "$THEME_DST/generate-assets.py"
}

# Trunca títulos longos com reticências (se o helper existir).
truncate_titles() {
  [[ -f "$TRUNCATE" ]] || return 0
  log "Truncando títulos longos (reticências)..."
  python3 "$TRUNCATE" || true
}

main() {
  require_root
  resolve_wallpaper "${1:-}"
  require_deps

  install_theme_files
  install_background
  enable_theme

  log "Atualizando grub.cfg (mantém as entradas desta máquina)..."
  update-grub >/dev/null

  show_detected_entries
  generate_theme
  truncate_titles

  log "Tema instalado com sucesso! Reinicie para ver o resultado."
}

main "$@"
