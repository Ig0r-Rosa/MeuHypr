#!/usr/bin/env bash
# Compila kew v4.0+ em ~/.local/bin (Debian APT traz 3.2.x com áudio inferior).

set -euo pipefail

TARGET_USER="${1:?Informe o usuário alvo}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
KEW_VERSION="${KEW_VERSION:-v4.0.0}"
BUILD_DIR="/tmp/meuhypr-kew-build-$$"
BIN_DIR="$TARGET_HOME/.local/bin"

mkdir -p "$BIN_DIR"

cleanup() {
  rm -rf "$BUILD_DIR"
}
trap cleanup EXIT

sudo -u "$TARGET_USER" bash -lc "
  set -euo pipefail
  git clone --depth 1 --branch '$KEW_VERSION' https://github.com/ravachol/kew.git '$BUILD_DIR'
  cd '$BUILD_DIR'
  make -j\"\$(nproc)\"
  install -Dm755 kew '$BIN_DIR/kew'
"

chown -R "$TARGET_USER:$TARGET_USER" "$BIN_DIR"
