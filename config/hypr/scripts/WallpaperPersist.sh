#!/usr/bin/env bash
# Salva e restaura wallpaper por monitor.

STATE_FILE="$HOME/.config/hypr/wallpaper_effects/monitors.json"
USER_FALLBACK="$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
SYSTEM_FALLBACK="/usr/share/backgrounds/meuhypr-matrix.jpg"
USER_WALLPAPER="$HOME/Pictures/wallpapers/matrix-default.jpg"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/swww"

resolve_fallback_wallpaper() {
  local candidate
  for candidate in "$USER_FALLBACK" "$USER_WALLPAPER" "$SYSTEM_FALLBACK"; do
    [[ -s "$candidate" ]] && [[ -f "$candidate" ]] && { echo "$candidate"; return 0; }
  done
  return 1
}

save_for_monitor() {
  local monitor="$1"
  local path="$2"

  [[ -n "$monitor" && -f "$path" ]] || return 1
  mkdir -p "$(dirname "$STATE_FILE")"
  [[ -f "$STATE_FILE" ]] || echo '{}' >"$STATE_FILE"

  local tmp
  tmp=$(mktemp)
  jq --arg m "$monitor" --arg p "$path" '.[$m] = $p' "$STATE_FILE" >"$tmp"
  mv "$tmp" "$STATE_FILE"
}

monitor_exists() {
  hyprctl monitors -j 2>/dev/null | jq -e --arg m "$1" '.[] | select(.name == $m)' >/dev/null
}

apply_to_monitor() {
  local monitor="$1"
  local path="$2"

  [[ -f "$path" ]] || return 1
  monitor_exists "$monitor" || return 1
  swww img -o "$monitor" "$path" --transition-duration 0
}

ensure_swww_daemon() {
  pgrep -x swww-daemon >/dev/null && return 0
  swww-daemon &
  for _ in {1..20}; do
    pgrep -x swww-daemon >/dev/null && swww query >/dev/null 2>&1 && return 0
    sleep 0.1
  done
  return 1
}

import_from_swww_cache() {
  local monitor path cache_file

  [[ -d "$CACHE_DIR" ]] || return 1
  for cache_file in "$CACHE_DIR"/*; do
    [[ -f "$cache_file" ]] || continue
    monitor=$(basename "$cache_file")
    path=$(read_swww_cache_path "$cache_file")
    [[ -n "$path" && -f "$path" ]] && save_for_monitor "$monitor" "$path"
  done
}

# Lê caminho da imagem no cache binário do swww.
read_swww_cache_path() {
  local cache_file="$1"
  [[ -f "$cache_file" ]] || return 1
  strings "$cache_file" | awk '/^\// { print; exit }'
}

# Reaplica wallpaper em monitores que ficaram pretos ou sem imagem.
repair_black_monitors() {
  local monitor path display

  ensure_swww_daemon || return 1

  if ! swww query >/dev/null 2>&1; then
    restore_all
    return
  fi

  [[ -f "$STATE_FILE" ]] || return 0

  while IFS=$'\t' read -r monitor path; do
    [[ -f "$path" ]] || continue
    monitor_exists "$monitor" || continue

    display=$(swww query 2>/dev/null | awk -v mon="$monitor" '
      $0 ~ "^: " mon ":" {
        if ($0 ~ /color: 000000/ || $0 !~ /image:/) { print "broken"; exit }
        print "ok"; exit
      }')

    [[ "$display" == "broken" ]] && apply_to_monitor "$monitor" "$path"
  done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$STATE_FILE")
}

restore_all() {
  local monitor path restored=0 failed=0

  ensure_swww_daemon || return 1

  if [[ ! -f "$STATE_FILE" ]] || ! jq -e 'length > 0' "$STATE_FILE" >/dev/null 2>&1; then
    import_from_swww_cache
  fi

  if [[ -f "$STATE_FILE" ]]; then
    while IFS=$'\t' read -r monitor path; do
      if apply_to_monitor "$monitor" "$path"; then
        restored=$((restored + 1))
      else
        failed=$((failed + 1))
      fi
    done < <(jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$STATE_FILE")
  fi

  # Nunca aplicar fallback global se já há configuração por monitor
  if [[ "$restored" -gt 0 ]]; then
    return 0
  fi

  local fallback
  fallback=$(resolve_fallback_wallpaper) || return 0
  swww img "$fallback" --transition-duration 0
}

case "${1:-}" in
  save) save_for_monitor "$2" "$3" ;;
  restore) restore_all ;;
  repair) repair_black_monitors ;;
  repaint) repair_black_monitors ;;
  *)
    echo "Uso: $0 save <monitor> <caminho> | restore | repair | repaint"
    exit 1
    ;;
esac
