#!/usr/bin/env bash
# Logout: worker root encerra sessão e troca para TTY do greeter SDDM.

session_ref="${XDG_SESSION_ID:-self}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logout_helper="/usr/local/bin/meuhypr-logout-vt"

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

sddm_vt() {
  local vt="" pid args

  for pid in $(pgrep -x Xorg 2>/dev/null); do
    args=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    [[ "$args" == *sddm* ]] || continue
    vt=$(sed -n 's/.* vt\([0-9]\+\).*/\1/p' <<< "$args")
    [[ -n "$vt" ]] && break
  done

  echo "${vt:-2}"
}

schedule_logout_worker() {
  local session="$1"
  local vt="$2"

  [[ -x "$logout_helper" ]] || return 1
  sudo -n env LOGOUT_USER="$USER" "$logout_helper" "$session" "$vt" 2>/dev/null \
    || sudo env LOGOUT_USER="$USER" "$logout_helper" "$session" "$vt" 2>/dev/null
}

fallback_logout() {
  local session="$1"
  local vt="$2"

  hyprctl dispatch exit 0 2>/dev/null || true
  loginctl terminate-session "$session" 2>/dev/null || true
  sleep 1
  chvt "$vt" 2>/dev/null || true
}

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

session="$(resolve_session_id "$session_ref")"
vt="$(sddm_vt)"

if schedule_logout_worker "$session" "$vt"; then
  hyprctl dispatch exit 0 2>/dev/null || true
  loginctl terminate-session "$session" 2>/dev/null || true
  exit 0
fi

fallback_logout "$session" "$vt"
