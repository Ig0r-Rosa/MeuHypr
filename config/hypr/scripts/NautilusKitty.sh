#!/usr/bin/env bash
# Nautilus: aplica configurações do repositório (kitty, extensão, preferências).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$scripts_dir/setup-nautilus.sh" "${USER:-$(id -un)}"
