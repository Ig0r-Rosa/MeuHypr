#!/usr/bin/env bash
# Logout: encerra Hyprland e volta ao greeter SDDM na TTY correta (VT 2).
#
# Sessão Hyprland fica na tty1; greeter SDDM na tty2. Sem chvt root o logout
# deixa a tela preta na tty errada (comum no usuário principal).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logout_helper="/usr/local/bin/meuhypr-logout-vt"
session_ref="${XDG_SESSION_ID:-self}"

# shellcheck source=/dev/null
source "$scripts_dir/PowerActionGuard.sh"

resolve_session_id() {
  local session="$1"
  if [[ "$session" =~ ^[0-9]+$ ]]; then
    echo "$session"
    return
  fi
  loginctl show-session "$session" -p Id --value 2>/dev/null \
    || loginctl list-sessions --no-legend 2>/dev/null \
      | awk -v u="$USER" '$3==u {print $1; exit}'
}

schedule_greeter_switch() {
  local session="$1"
  [[ -x "$logout_helper" ]] || return 1
  sudo -n env LOGOUT_USER="$USER" "$logout_helper" "$session" 2>/dev/null \
    || sudo env LOGOUT_USER="$USER" "$logout_helper" "$session" 2>/dev/null
}

exit_hyprland_session() {
  local session="$1"
  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null; then
    hyprctl dispatch exit 0 2>/dev/null || true
  fi
  loginctl terminate-session "$session" 2>/dev/null || true
}

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

session="$(resolve_session_id "$session_ref")"

if schedule_greeter_switch "$session"; then
  exit_hyprland_session "$session"
  exit 0
fi

exit_hyprland_session "$session"
exit 0
