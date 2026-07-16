#!/usr/bin/env bash
# Launcher Super+D — grid normal; Super+Shift+D — apps ocultos.
# Ctrl+R renomeia; Ctrl+O oculta/restaura.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$scripts_dir/RofiCommon.sh"

launcher_theme="$HOME/.config/rofi/config-launcher.rasi"
hidden_theme="$HOME/.config/rofi/config-launcher-hidden.rasi"
rename_theme="$HOME/.config/rofi/config-launcher-rename.rasi"
apps_py="$scripts_dir/RofiLauncherApps.py"
action_file="${XDG_RUNTIME_DIR:-/tmp}/rofi-launcher.action"
launcher_pid="${XDG_RUNTIME_DIR:-/tmp}/rofi-launcher.pid"

export PATH="${PATH:+$PATH:}/snap/bin:/usr/local/bin"

snap_desktop="/var/lib/snapd/desktop"
case ":${XDG_DATA_DIRS:-}:" in
  *:"$snap_desktop":*) ;;
  *)
    export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:${snap_desktop}"
    ;;
esac

hidden_mode=0
if [[ "${1:-}" == "--hidden" ]]; then
  hidden_mode=1
  shift
fi

rofi_require "$launcher_theme"
rofi_require "$hidden_theme"
rofi_require "$rename_theme"
rofi_prepare

run_rename_dialog() {
  local app_id current new_name

  app_id=$(python3 -c "import json; print(json.load(open('$action_file')).get('app_id',''))")
  current=$(python3 -c "import json; print(json.load(open('$action_file')).get('current',''))")
  rm -f "$action_file"

  [[ -n "$app_id" && -n "$current" ]] || return 0

  new_name=$("$rofi_bin" \
    -dmenu \
    -config "$rename_theme" \
    -filter "$current")

  [[ -n "$new_name" ]] || return 0
  python3 "$apps_py" apply-rename "$app_id" "$new_name"
}

while true; do
  rm -f "$action_file"

  if [[ "$hidden_mode" -eq 1 ]]; then
    export ROFI_LAUNCHER_MODE=hidden
  else
    export ROFI_LAUNCHER_MODE=normal
  fi

  # Ícones são materializados sob demanda pelo modo do Rofi (icon_field →
  # materialize_icon usa o cache). Não pré-aquecemos aqui para abrir mais rápido.
  theme="$launcher_theme"
  if [[ "$hidden_mode" -eq 1 ]]; then
    theme="$hidden_theme"
  fi

  # Slot 0 = spacer interno; índice 1 = primeiro app visível.
  "$rofi_bin" \
    -show launcher \
    -config "$theme" \
    -pid "$launcher_pid" \
    -selected-row 1 \
    "$@"

  [[ -f "$action_file" ]] || break

  action=$(python3 -c "import json; print(json.load(open('$action_file')).get('action',''))")

  case "$action" in
    rename)
      run_rename_dialog
      ;;
    *)
      break
      ;;
  esac
done
