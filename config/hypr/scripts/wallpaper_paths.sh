#!/usr/bin/env bash
# Caminhos padrão de wallpaper — respeita XDG (Imagens vs Pictures).

wallpaper_pictures_dir() {
  xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures"
}

wallpaper_library_dir() {
  printf '%s/wallpapers\n' "$(wallpaper_pictures_dir)"
}

default_wallpaper_file() {
  printf '%s/wallpapers/matrix-default.jpg\n' "$(wallpaper_pictures_dir)"
}
