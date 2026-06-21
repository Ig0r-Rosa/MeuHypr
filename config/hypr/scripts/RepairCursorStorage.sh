#!/usr/bin/env bash
# Repara Cursor com SQLITE_CORRUPT — recria state.vscdb global e por workspace.

set -euo pipefail

target_user="${1:-${SUDO_USER:-$USER}}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
cursor_user="$target_home/.config/Cursor/User"
stamp="$(date +%Y%m%dT%H%M%S)"
backup="$target_home/.config/Cursor/corrupt-backup-$stamp"

log() { printf '[repair-cursor] %s\n' "$*"; }

[[ -d "$cursor_user" ]] || {
  log "Cursor não encontrado para $target_user"
  exit 1
}

log "Encerrando Cursor de $target_user..."
pkill -u "$target_user" -f '[C]ursor' 2>/dev/null || true
pkill -u "$target_user" -f 'cursor-agent' 2>/dev/null || true
pkill -u "$target_user" -f '/\.local/share/cursor-agent/' 2>/dev/null || true
sleep 2
pkill -9 -u "$target_user" -f '[C]ursor' 2>/dev/null || true
pkill -9 -u "$target_user" -f 'cursor-agent' 2>/dev/null || true

mkdir -p "$backup/globalStorage" "$backup/workspaceStorage"

move_db_files() {
  local dir="$1"
  local dest="$2"
  local name
  [[ -d "$dir" ]] || return 0
  mkdir -p "$dest"
  for name in state.vscdb state.vscdb-shm state.vscdb-wal state.vscdb.backup; do
    [[ -e "$dir/$name" ]] && mv "$dir/$name" "$dest/"
  done
}

log "Backup em $backup"
move_db_files "$cursor_user/globalStorage" "$backup/globalStorage"

while IFS= read -r ws_dir; do
  ws_name="$(basename "$ws_dir")"
  move_db_files "$ws_dir" "$backup/workspaceStorage/$ws_name"
done < <(find "$cursor_user/workspaceStorage" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

# Backups antigos dentro do globalStorage confundem o Cursor.
find "$cursor_user/globalStorage" -maxdepth 1 -type d -name 'corrupt-backup-*' -exec rm -rf {} + 2>/dev/null || true
find "$cursor_user" -maxdepth 1 -type d -name 'sqlite-reset-*' -exec rm -rf {} + 2>/dev/null || true

chown -R "$target_user:$target_user" "$backup" "$cursor_user" 2>/dev/null || true
log "Concluído. Abra o Cursor como $target_user."
