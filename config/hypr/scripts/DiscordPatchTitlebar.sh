#!/usr/bin/env bash
# Remove botões da barra do Discord (Electron frameless) via CSS no core.asar.
# O Discord snap desenha min/max/fechar na interface web, não no GTK.

PATCH_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/discord-titlebar-patch"
VENV_DIR="$PATCH_DIR/venv"
PATCHED_ASAR="$PATCH_DIR/core.asar"
META_FILE="$PATCH_DIR/.snap-revision"

CSS_RULE='[class*=winButton]{display:none!important}[class*=titleBar]{display:none!important}:root{--custom-app-top-bar-height:0px}'
PATCH_OLD='mainWindow.webContents.on("did-finish-load",()=>{loadingDragCssPromises.push(mainWindow.webContents.insertCSS("body { -webkit-app-region: drag; }").catch(()=>null))})'
PATCH_NEW='mainWindow.webContents.on("did-finish-load",()=>{loadingDragCssPromises.push(mainWindow.webContents.insertCSS("body { -webkit-app-region: drag; }").catch(()=>null)),loadingDragCssPromises.push(mainWindow.webContents.insertCSS("'"$CSS_RULE"'").catch(()=>null))})'

log_msg() {
  echo "$(date '+%F %T') discord-patch: $1" >>"${XDG_CACHE_HOME:-$HOME/.cache}/discord-patch.log"
}

get_snap_core() {
  readlink -f /snap/discord/current/usr/share/discord/resources/standalone_modules/discord_desktop_core/core.asar
}

get_snap_revision() {
  basename "$(readlink -f /snap/discord/current)"
}

ensure_python_env() {
  [[ -x "$VENV_DIR/bin/python3" ]] && "$VENV_DIR/bin/python3" -c "from asar.asar import create_archive" 2>/dev/null && return 0
  mkdir -p "$PATCH_DIR"
  python3 -m venv "$VENV_DIR"
  "$VENV_DIR/bin/pip" install -q asar asarpy
}

build_patched_asar() {
  local source_asar="$1"
  ensure_python_env
  mkdir -p "$PATCH_DIR/work"

  "$VENV_DIR/bin/python3" - "$source_asar" "$PATCHED_ASAR" "$PATCH_OLD" "$PATCH_NEW" <<'PY'
import shutil
import sys
from pathlib import Path
from asar.asar import create_archive, extract_archive

source, output, old, new = sys.argv[1:5]
work = Path(output).parent / "work"
extracted = work / "extracted"
if work.exists():
    shutil.rmtree(work)
extracted.mkdir(parents=True)

extract_archive(Path(source), extracted)
bundle = extracted / "bundle.js"
text = bundle.read_text(encoding="utf-8")
if old not in text:
    if "[class*=winButton]" in text:
        shutil.copy2(Path(source), Path(output))
        sys.exit(0)
    raise SystemExit("Discord mudou o core.asar; patch precisa ser atualizado.")
bundle.write_text(text.replace(old, new, 1), encoding="utf-8")
create_archive(extracted, Path(output))
shutil.rmtree(work)
PY
}

needs_rebuild() {
  local revision source_asar
  revision="$(get_snap_revision)"
  source_asar="$(get_snap_core)"

  [[ -f "$PATCHED_ASAR" ]] || return 0
  [[ -f "$META_FILE" ]] || return 0
  [[ "$(cat "$META_FILE")" == "$revision:$(stat -c %Y "$source_asar")" ]] || return 0
  return 1
}

# Monta sem pedir senha — se falhar, Discord abre normalmente sem o patch.
apply_bind_mount() {
  local target="$1"

  if mountpoint -q "$target" 2>/dev/null; then
    local current
    current="$(findmnt -n -o SOURCE --target "$target" 2>/dev/null || true)"
    [[ "$current" == *"discord-titlebar-patch/core.asar" ]] && return 0
    sudo -n umount -l "$target" 2>/dev/null || true
  fi

  if sudo -n mount --bind "$PATCHED_ASAR" "$target" 2>/dev/null; then
    return 0
  fi

  log_msg "mount ignorado (sudo interativo ou sem permissão)"
  return 0
}

apply_patch() {
  command -v discord >/dev/null 2>&1 || return 0
  [[ -f "$(get_snap_core)" ]] || return 0

  local source_asar revision target
  source_asar="$(get_snap_core)"
  revision="$(get_snap_revision)"
  target="$source_asar"

  if needs_rebuild; then
    build_patched_asar "$source_asar" || {
      log_msg "falha ao gerar core.asar patchado"
      return 0
    }
    echo "$revision:$(stat -c %Y "$source_asar")" >"$META_FILE"
  fi

  apply_bind_mount "$target"
}

case "${1:-apply}" in
  apply) apply_patch ;;
  rebuild)
    target="$(get_snap_core)"
    if mountpoint -q "$target" 2>/dev/null; then
      sudo -n umount -l "$target" 2>/dev/null || true
    fi
    rm -f "$PATCHED_ASAR" "$META_FILE"
    apply_patch
    ;;
  *) echo "Uso: $0 [apply|rebuild]" ;;
esac
