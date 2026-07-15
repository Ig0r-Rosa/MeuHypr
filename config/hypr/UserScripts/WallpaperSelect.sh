#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# Seleção de wallpaper (Super+W) — imagens e GIF animado via swww

PICTURES_DIR="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")"
wallDIR="$PICTURES_DIR/wallpapers"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
# shellcheck source=/dev/null
source "$SCRIPTSDIR/RofiCommon.sh"

iDIR="$HOME/.config/swaync/images"

FPS=60
TYPE="any"
DURATION=2
BEZIER=".43,1.19,1,.4"
RANDOM_LABEL="(random)"

rofi_theme="$HOME/.config/rofi/config-wallpaper.rasi"
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')

if [[ -z "$focused_monitor" ]]; then
  notify-send -i "$iDIR/error.png" "Wallpaper" "Monitor focado não detectado"
  exit 1
fi

if ! command -v bc &>/dev/null; then
  notify-send -i "$iDIR/error.png" "bc missing" "Instale o pacote bc"
  exit 1
fi

scale_factor=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .scale')
monitor_height=$(hyprctl monitors -j | jq -r --arg mon "$focused_monitor" '.[] | select(.name == $mon) | .height')
icon_size=$(echo "scale=1; ($monitor_height * 3) / ($scale_factor * 150)" | bc)
adjusted_icon_size=$(echo "$icon_size" | awk '{if ($1 < 15) $1 = 20; if ($1 > 25) $1 = 25; print $1}')
rofi_override="element-icon{size:${adjusted_icon_size}%;}"

mapfile -d '' PICS < <(find -L "$wallDIR" -type f \( \
  -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o \
  -iname "*.bmp" -o -iname "*.tiff" -o -iname "*.webp" \) -print0)

if [[ ${#PICS[@]} -eq 0 ]]; then
  notify-send -i "$iDIR/error.png" "Wallpaper" "Nenhum arquivo em $wallDIR"
  exit 1
fi

RANDOM_PIC="${PICS[$((RANDOM % ${#PICS[@]}))]}"

menu() {
  IFS=$'\n' sorted_options=($(sort <<<"${PICS[*]}"))
  printf '%s\n' "$RANDOM_LABEL"
  for pic_path in "${sorted_options[@]}"; do
    basename "$pic_path"
  done
}

apply_wallpaper() {
  local image_path="$1"
  SWWW_FPS="$FPS" SWWW_TYPE="$TYPE" SWWW_DURATION="$DURATION" \
    SWWW_BEZIER="$BEZIER" SWWW_RESIZE=crop \
    "$SCRIPTSDIR/WallpaperApply.sh" apply "$focused_monitor" "$image_path"
}

resolve_selected_file() {
  local choice="$1"
  if [[ "$choice" == "$RANDOM_LABEL" ]]; then
    printf '%s\n' "$RANDOM_PIC"
    return 0
  fi
  local base
  base=$(basename "$choice" | sed 's/\(.*\)\.[^.]*$/\1/')
  find -L "$wallDIR" -iname "${base}.*" -print -quit
}

main() {
  local choice selected_file
  choice=$(menu | rofi_menu_pick "" "$rofi_theme")
  choice=$(echo "$choice" | xargs)
  [[ -z "$choice" ]] && exit 0

  selected_file=$(resolve_selected_file "$choice")
  if [[ -z "$selected_file" || ! -f "$selected_file" ]]; then
    notify-send -i "$iDIR/error.png" "Wallpaper" "Arquivo não encontrado"
    exit 1
  fi

  apply_wallpaper "$selected_file"
}

if pidof rofi >/dev/null || pidof fuzzel >/dev/null; then
  rofi_prepare
fi

main
