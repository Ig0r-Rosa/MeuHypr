#!/usr/bin/env bash
# Aplica gtk.css canônico do MeuHypr (cantos retos + sem botões na titlebar).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_home="$(dirname "$(dirname "$scripts_dir")")"
assets_dir="$config_home/hypr/assets"

apply_one() {
  local version="$1"
  local src="$assets_dir/gtk-$version.css"
  local dst="$config_home/gtk-$version/gtk.css"

  [[ -f "$src" ]] || return 1
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
}

for version in 3.0 4.0; do
  apply_one "$version" || true
done
