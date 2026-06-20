#!/usr/bin/env bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# RofiBeats - unified, dynamic UI (add, remove, manage, play)

mDIR="$HOME/Music/"
iDIR="$HOME/.config/swaync/icons"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
# shellcheck source=/dev/null
source "$SCRIPTSDIR/RofiCommon.sh"
rofi_theme="$HOME/.config/rofi/config-rofi-Beats.rasi"
music_list="$HOME/.config/rofi/online_music.list"

mkdir -p "$(dirname "$music_list")"
[[ -f "$music_list" ]] || touch "$music_list"

# Send notification
notification() {
  notify-send -u normal -i "$iDIR/music.png" "$@"
}

# Check if mpv is currently playing
music_playing() { pgrep -x "mpv" >/dev/null; }

# Stop all mpv processes except mpvpaper
stop_music() {
  mpv_pids=$(pgrep -x mpv)
  if [ -n "$mpv_pids" ]; then
    mpvpaper_pid=$(ps aux | grep -- 'unique-wallpaper-process' | grep -v 'grep' | awk '{print $2}')
    for pid in $mpv_pids; do
      if ! echo "$mpvpaper_pid" | grep -q "$pid"; then
        kill -9 $pid || true
      fi
    done
    notification "Music stopped"
  fi
}

# Populate local music file list
populate_local_music() {
  local_music=()
  filenames=()
  while IFS= read -r file; do
    local_music+=("$file")
    filenames+=("$(basename "$file")")
  done < <(find -L "$mDIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" -o -iname "*.mp4" \))
}

# Play selected local music file
play_local_music() {
  populate_local_music
  choice=$(printf "%s\n" "${filenames[@]}" | rofi_menu_pick "Música local" "$rofi_theme")
  [[ -z "$choice" ]] && exit 1
  for ((i = 0; i < "${#filenames[@]}"; ++i)); do
    if [ "${filenames[$i]}" = "$choice" ]; then
      music_playing && stop_music
      notification "Now Playing:" "$choice"
      mpv --no-video --playlist-start="$i" --loop-playlist "${local_music[@]}"
      break
    fi
  done
}

# Shuffle and play all local music
shuffle_local_music() {
  music_playing && stop_music
  notification "Shuffle Play local music"
  mpv --no-video --shuffle --loop-playlist "$mDIR"
}

# Play selected online music
play_online_music() {
  if [ ! -s "$music_list" ]; then
    notify-send -u low -i "$iDIR/music.png" "No online music found" "Add some with Manage Music"
    exit 0
  fi
  choice=$(awk -F'|' '{print $1}' "$music_list" | sort | rofi_menu_pick "Rádio online" "$rofi_theme")
  [[ -z "$choice" ]] && exit 1
  link=$(awk -F'|' -v name="$choice" '$1 == name {print $2; exit}' "$music_list")
  [[ -z "$link" ]] && {
    notify-send -u low -i "$iDIR/music.png" "URL not found for" "$choice"
    exit 1
  }
  music_playing && stop_music
  notification "Now Playing:" "$choice"
  mpv --no-video --shuffle "$link"
}

# Manage online music list (add, remove, view)
manage_music() {
  sub_choice=$(printf "Add Music\nRemove Music\nView List" | rofi_menu_pick "Gerenciar músicas" "$rofi_theme")

  case "$sub_choice" in
  "Add Music")
    name=$(rofi_prompt_only "Nome da música")
    [[ -z "$name" ]] && return
    url=$(rofi_prompt_only "URL da música")
    [[ -z "$url" ]] && return
    echo "$name|$url" >>"$music_list"
    notification "Added" "$name"
    ;;
  "Remove Music")
    entry=$(awk -F'|' '{print $1}' "$music_list" | rofi_menu_pick "Remover música" "$rofi_theme")
    [[ -z "$entry" ]] && return
    grep -vF "$entry" "$music_list" >"$music_list.tmp" && mv "$music_list.tmp" "$music_list"
    notification "Removed" "$entry"
    ;;
  "View List")
    # Show only titles, not URLs
    awk -F'|' '{print $1}' "$music_list" | rofi_menu_pick "Lista online" "$rofi_theme" >/dev/null
    ;;
  esac
}

# Main menu
user_choice=$(printf "%s\n" \
  "Play from Online Stations" \
  "Play from Music directory" \
  "Shuffle Play from Music directory" \
  "Stop RofiBeats" \
  "Manage Music List" |
  rofi_menu_pick "RofiBeats" "$rofi_theme")

case "$user_choice" in
"Play from Online Stations") play_online_music ;;
"Play from Music directory") play_local_music ;;
"Shuffle Play from Music directory") shuffle_local_music ;;
"Stop RofiBeats") music_playing && stop_music ;;
"Manage Music List") manage_music ;;
esac
