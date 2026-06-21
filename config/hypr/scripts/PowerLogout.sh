#!/usr/bin/env bash
# Logout: encerra Hyprland e reinicia SDDM (greeter na tty2).

session="${XDG_SESSION_ID:-self}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
logout_helper="/usr/local/bin/meuhypr-logout-sddm"

# shellcheck source=/dev/null
source "$scripts_dir/PowerActionGuard.sh"

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

schedule_sddm_restart() {
  [[ -x "$logout_helper" ]] || return 1
  sudo -n "$logout_helper" 2>/dev/null || sudo "$logout_helper" 2>/dev/null
}

fallback_logout() {
  hyprctl dispatch exit 0 2>/dev/null || true
  loginctl terminate-session "$session" 2>/dev/null || true
  sleep 1
  chvt "$(sddm_vt)" 2>/dev/null || true
}

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

if schedule_sddm_restart; then
  hyprctl dispatch exit 0 2>/dev/null \
    || loginctl terminate-session "$session" 2>/dev/null \
    || true
  exit 0
fi

fallback_logout
