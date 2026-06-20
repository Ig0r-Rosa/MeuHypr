#!/usr/bin/env bash
# Gera bookmarks do Nautilus/GTK apontando para as pastas XDG do usuário local.

set -euo pipefail

TARGET_USER="${1:?Informe o usuário alvo}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
BOOKMARKS_FILE="$TARGET_HOME/.config/gtk-3.0/bookmarks"

sudo -u "$TARGET_USER" xdg-user-dirs-update 2>/dev/null || true
sudo -u "$TARGET_USER" mkdir -p "$(dirname "$BOOKMARKS_FILE")"

sudo -u "$TARGET_USER" bash -lc 'python3 - <<'"'"'PY'"'"' > "$HOME/.config/gtk-3.0/bookmarks"
from pathlib import Path
import subprocess

BOOKMARK_DIRS = ("DOCUMENTS", "MUSIC", "PICTURES", "VIDEOS", "DOWNLOAD")

def xdg_dir(name: str) -> Path:
    path = Path(subprocess.check_output(["xdg-user-dir", name], text=True).strip())
    path.mkdir(parents=True, exist_ok=True)
    return path

for key in BOOKMARK_DIRS:
    print(xdg_dir(key).as_uri())
PY'

chown "$TARGET_USER:$TARGET_USER" "$BOOKMARKS_FILE"
