#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# Kitty Themes Source https://github.com/dexpota/kitty-themes #

# Define directories and variables
kitty_themes_DiR="$HOME/.config/kitty/kitty-themes" # Kitty Themes Directory
kitty_config="$HOME/.config/kitty/kitty.conf"
iDIR="$HOME/.config/swaync/images"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"
rofi_theme="$HOME/.config/rofi/config-kitty-themes.rasi"

# --- Helper Functions ---
notify_user() {
  notify-send -u low -i "$1" "$2" "$3"
}

# Function to apply the selected kitty theme
apply_kitty_theme_to_config() {
  local theme_name_to_apply="$1"
  if [ -z "$theme_name_to_apply" ]; then
    echo "Error: No theme name provided to apply_kitty_theme_to_config." >&2
    return 1
  fi

  local theme_file_path_to_apply="$kitty_themes_DiR/$theme_name_to_apply.conf"
  if [ ! -f "$theme_file_path_to_apply" ]; then
    notify_user "$iDIR/error.png" "Error" "Theme file not found: $theme_name_to_apply.conf"
    return 1
  fi

  local temp_kitty_config_file
  temp_kitty_config_file=$(mktemp)
  cp "$kitty_config" "$temp_kitty_config_file"

  if grep -q -E '^[#[:space:]]*include\s+\./kitty-themes/.*\.conf' "$temp_kitty_config_file"; then
    sed -i -E "s|^([#[:space:]]*include\s+\./kitty-themes/).*\.conf|include ./kitty-themes/$theme_name_to_apply.conf|g" "$temp_kitty_config_file"
  else
    if [ -s "$temp_kitty_config_file" ] && [ "$(tail -c1 "$temp_kitty_config_file")" != "" ]; then
      echo >>"$temp_kitty_config_file"
    fi
    echo "include ./kitty-themes/$theme_name_to_apply.conf" >>"$temp_kitty_config_file"
  fi

  cp "$temp_kitty_config_file" "$kitty_config"
  rm "$temp_kitty_config_file"

  for pid_kitty in $(pidof kitty); do
    if [ -n "$pid_kitty" ]; then
      kill -SIGUSR1 "$pid_kitty"
    fi
  done
  return 0
}

# --- Main Script Execution ---

if [ ! -d "$kitty_themes_DiR" ]; then
  notify_user "$iDIR/error.png" "E-R-R-O-R" "Kitty Themes directory not found: $kitty_themes_DiR"
  exit 1
fi

if [ ! -f "$rofi_theme" ]; then
  notify_user "$iDIR/error.png" "Rofi" "Tema não encontrado: $rofi_theme"
  exit 1
fi

original_kitty_config_content_backup=$(cat "$kitty_config")

mapfile -t available_theme_names < <(find "$kitty_themes_DiR" -maxdepth 1 -name "*.conf" -type f -printf "%f\n" | sed 's/\.conf$//' | sort)

if [ ${#available_theme_names[@]} -eq 0 ]; then
  notify_user "$iDIR/error.png" "No Kitty Themes" "No .conf files found in $kitty_themes_DiR."
  exit 1
fi

current_selection_index=0
current_active_theme_name=$(awk -F'include ./kitty-themes/|\\.conf' '/^[[:space:]]*include \.\/kitty-themes\/.*\.conf/{print $2; exit}' "$kitty_config")

if [ -n "$current_active_theme_name" ]; then
  for i in "${!available_theme_names[@]}"; do
    if [[ "${available_theme_names[$i]}" == "$current_active_theme_name" ]]; then
      current_selection_index=$i
      break
    fi
  done
fi

while true; do
  theme_to_preview_now="${available_theme_names[$current_selection_index]}"

  if ! apply_kitty_theme_to_config "$theme_to_preview_now"; then
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    notify_user "$iDIR/error.png" "Preview Error" "Failed to apply $theme_to_preview_now. Reverted."
    exit 1
  fi

  theme_input_list=$(printf '%s\n' "${available_theme_names[@]}")
  prompt="Kitty: ${theme_to_preview_now} (Enter=prévia, Ctrl+S=aplicar)"

  rofi_require "$rofi_theme"
  rofi_prepare

  chosen_name=$(
    echo "$theme_input_list" | "$rofi_bin" -dmenu -i \
      -config "$rofi_theme" -p "$prompt" -selected-row "$current_selection_index"
  )
  rofi_exit_code=$?

  if [ $rofi_exit_code -eq 0 ]; then
    if [[ -n "$chosen_name" ]]; then
      for i in "${!available_theme_names[@]}"; do
        if [[ "${available_theme_names[$i]}" == "$chosen_name" ]]; then
          current_selection_index=$i
          break
        fi
      done
    fi
  elif [ $rofi_exit_code -eq 1 ]; then
    notify_user "$iDIR/note.png" "Kitty Theme" "Seleção cancelada. Tema original restaurado."
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  elif [ $rofi_exit_code -eq 10 ]; then
    notify_user "$iDIR/ja.png" "Kitty Theme Applied" "$theme_to_preview_now"
    break
  else
    notify_user "$iDIR/error.png" "Rofi Error" "Saída inesperada ($rofi_exit_code). Revertendo."
    echo "$original_kitty_config_content_backup" >"$kitty_config"
    for pid_kitty in $(pidof kitty); do if [ -n "$pid_kitty" ]; then kill -SIGUSR1 "$pid_kitty"; fi; done
    break
  fi
done

exit 0
