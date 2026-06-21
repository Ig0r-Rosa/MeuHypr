#!/usr/bin/env bash
# Logout: worker root encerra sessão e reinicia SDDM (tela de login na tty2).

session_ref="${XDG_SESSION_ID:-self}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logout_helper="/usr/local/bin/meuhypr-logout"

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

schedule_logout_worker() {
  local session="$1"

  [[ -x "$logout_helper" ]] || return 1
  sudo -n env LOGOUT_USER="$USER" "$logout_helper" "$session" 2>/dev/null \
    || sudo env LOGOUT_USER="$USER" "$logout_helper" "$session" 2>/dev/null
}

fallback_logout() {
  local session="$1"

  hyprctl dispatch exit 0 2>/dev/null || true
  loginctl terminate-session "$session" 2>/dev/null || true
  sleep 1
  sudo -n systemctl restart sddm 2>/dev/null \
    || sudo systemctl restart sddm 2>/dev/null || true
}

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

session="$(resolve_session_id "$session_ref")"

if schedule_logout_worker "$session"; then
  hyprctl dispatch exit 0 2>/dev/null || true
  loginctl terminate-session "$session" 2>/dev/null || true
  exit 0
fi

fallback_logout "$session"
