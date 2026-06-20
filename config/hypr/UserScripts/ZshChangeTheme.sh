#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Oh my ZSH theme

scripts_dir="$HOME/.config/hypr/scripts"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

iDIR="$HOME/.config/swaync/images"
rofi_theme="$HOME/.config/rofi/config-zsh-theme.rasi"

if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
  notify-send -i "$iDIR/note.png" "NOT Supported" "Sorry NixOS does not support this KooL feature"
  exit 1
fi

themes_dir="$HOME/.oh-my-zsh/themes"
file_extension=".zsh-theme"

themes_array=($(find -L "$themes_dir" -type f -name "*$file_extension" -exec basename {} \; | sed -e "s/$file_extension//"))
themes_array=("Random" "${themes_array[@]}")

menu() {
  for theme in "${themes_array[@]}"; do
    echo "$theme"
  done
}

main() {
  choice=$(menu | rofi_menu_pick "Tema Oh My Zsh" "$rofi_theme")
  [[ -z "$choice" ]] && exit 0

  zsh_path="$HOME/.zshrc"
  var_name="ZSH_THEME"

  if [[ "$choice" == "Random" ]]; then
    random_theme=${themes_array[$((RANDOM % (${#themes_array[@]} - 1) + 1))]}
    theme_to_set="$random_theme"
    notify-send -i "$iDIR/ja.png" "Tema aleatório:" "$random_theme"
  else
    theme_to_set="$choice"
    notify-send -i "$iDIR/ja.png" "Tema selecionado:" "$choice"
  fi

  if [ -f "$zsh_path" ]; then
    sed -i "s/^$var_name=.*/$var_name=\"$theme_to_set\"/" "$zsh_path"
    notify-send -i "$iDIR/ja.png" "OMZ theme" "Reabra o terminal"
  else
    notify-send -i "$iDIR/error.png" "E-R-R-O-R" "~/.zshrc não encontrado"
  fi
}

rofi_prepare
main
