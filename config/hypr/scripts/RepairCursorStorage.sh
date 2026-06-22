#!/usr/bin/env bash
# Repara Cursor: state.vscdb (SQLite) e Local Storage (LevelDB).

set -euo pipefail

target_user="${1:-${SUDO_USER:-$USER}}"
target_home="$(getent passwd "$target_user" | cut -d: -f6)"
cursor_config="$target_home/.config/Cursor"
cursor_user="$cursor_config/User"
stamp="$(date +%Y%m%dT%H%M%S)"
backup="$cursor_config/corrupt-backup-$stamp"
repair_mode="${2:---all}"

log() { printf '[repair-cursor] %s\n' "$*"; }

[[ -d "$cursor_user" ]] || {
  log "Cursor não encontrado para $target_user"
  exit 1
}

stop_cursor() {
  log "Encerrando Cursor de $target_user..."
  pkill -u "$target_user" -f '[C]ursor' 2>/dev/null || true
  pkill -u "$target_user" -f 'cursor-agent' 2>/dev/null || true
  pkill -u "$target_user" -f '/\.local/share/cursor-agent/' 2>/dev/null || true
  sleep 2
  pkill -9 -u "$target_user" -f '[C]ursor' 2>/dev/null || true
  pkill -9 -u "$target_user" -f 'cursor-agent' 2>/dev/null || true
}

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

# LevelDB sem .ldb costuma gerar erro de Local Storage no Chromium/Electron.
local_storage_healthy() {
  local leveldb="$cursor_config/Local Storage/leveldb"
  [[ -d "$leveldb" ]] || return 1
  find "$leveldb" -maxdepth 1 -name '*.ldb' -print -quit | grep -q .
}

reset_leveldb_dir() {
  local label="$1"
  local leveldb="$2"
  local dest="$3"

  [[ -d "$leveldb" ]] || return 0
  mkdir -p "$dest"
  mv "$leveldb" "$dest/$label-leveldb-$stamp"
  mkdir -p "$leveldb"
  chmod 700 "$leveldb"
}

repair_sqlite_state() {
  log "Recriando state.vscdb ..."
  move_db_files "$cursor_user/globalStorage" "$backup/globalStorage"

  while IFS= read -r ws_dir; do
    ws_name="$(basename "$ws_dir")"
    move_db_files "$ws_dir" "$backup/workspaceStorage/$ws_name"
  done < <(find "$cursor_user/workspaceStorage" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
}

repair_local_storage() {
  if local_storage_healthy; then
    log "Local Storage íntegro — nada a fazer."
    return 0
  fi

  log "Local Storage corrompido — recriando LevelDB ..."
  reset_leveldb_dir "local" "$cursor_config/Local Storage/leveldb" "$backup"
  reset_leveldb_dir "session" "$cursor_config/Session Storage/leveldb" "$backup"
}

should_repair_sqlite() {
  [[ "$repair_mode" == "--all" || "$repair_mode" == "--sqlite" ]]
}

should_repair_local_storage() {
  [[ "$repair_mode" == "--all" || "$repair_mode" == "--local-storage" ]]
}

stop_cursor
mkdir -p "$backup/globalStorage" "$backup/workspaceStorage"

if should_repair_sqlite; then
  repair_sqlite_state
fi

if should_repair_local_storage; then
  repair_local_storage
fi

find "$cursor_user/globalStorage" -maxdepth 1 -type d -name 'corrupt-backup-*' -exec rm -rf {} + 2>/dev/null || true
find "$cursor_user" -maxdepth 1 -type d -name 'sqlite-reset-*' -exec rm -rf {} + 2>/dev/null || true

chmod 700 "$cursor_config/Local Storage" "$cursor_config/Session Storage" 2>/dev/null || true
chown -R "$target_user:$target_user" "$backup" "$cursor_config" 2>/dev/null || true
log "Concluído. Abra o Cursor como $target_user."
