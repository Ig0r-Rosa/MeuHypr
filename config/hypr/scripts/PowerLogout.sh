#!/usr/bin/env bash
# Encerra Hyprland e reinicia o SDDM na TTY do greeter (fallback: chvt).

session="${XDG_SESSION_ID:-self}"
mode="${1:-}"
scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$scripts_dir/PowerActionGuard.sh"

TTY_SWITCH_DELAY=1
WATCHDOG_ATTEMPTS=48
WATCHDOG_INTERVAL=0.25

# Descobre a TTY do greeter SDDM (reconsultada a cada tentativa).
sddm_vt() {
  local vt="" pid args

  for pid in $(pgrep -x Xorg 2>/dev/null); do
    args=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
    [[ "$args" == *sddm* ]] || continue
    vt=$(sed -n 's/.* vt\([0-9]\+\).*/\1/p' <<< "$args")
    [[ -n "$vt" ]] && break
  done

  if [[ -z "$vt" ]]; then
    vt=$(awk -F= '
      /^[[:space:]]*MinimumVT=/ {
        gsub(/[^0-9]/, "", $2)
        if ($2 != "") print $2
        exit
      }
    ' /etc/sddm.conf /etc/sddm.conf.d/*.conf 2>/dev/null)
  fi

  echo "${vt:-2}"
}

active_vt() {
  sed 's/[^0-9]//g' /sys/class/tty/tty0/active 2>/dev/null
}

try_chvt() {
  chvt "$1" 2>/dev/null || true
}

on_sddm_tty() {
  [[ "$(active_vt)" == "$1" ]]
}

restart_sddm() {
  systemctl is-active --quiet sddm 2>/dev/null || return 1
  sudo -n systemctl restart sddm 2>/dev/null \
    || sudo systemctl restart sddm 2>/dev/null
}

kill_stuck_session() {
  local attempt="$1"
  local state

  pgrep -x Hyprland >/dev/null || return 0

  if (( attempt >= 12 )); then
    loginctl kill-session "$session" -s SIGTERM 2>/dev/null || true
  fi

  if (( attempt >= 24 )); then
    loginctl kill-session "$session" -s SIGKILL 2>/dev/null || true
  fi

  state=$(loginctl show-session "$session" -p ActiveState --value 2>/dev/null || echo "")
  [[ "$state" != "active" ]]
}

hyprland_stopped() {
  pgrep -x Hyprland >/dev/null && return 1
  return 0
}

finish_logout() {
  restart_sddm && return 0
  try_chvt "$(sddm_vt)"
  on_sddm_tty "$(sddm_vt)"
}

run_logout_watchdog() {
  local attempt stuck=0

  sleep "$TTY_SWITCH_DELAY"

  for ((attempt = 1; attempt <= WATCHDOG_ATTEMPTS; attempt++)); do
    if hyprland_stopped; then
      stuck=1
    elif kill_stuck_session "$attempt"; then
      stuck=1
    fi

    # Hyprland sumiu ou travou — reinicia SDDM (como após reboot).
    if (( stuck || attempt >= 20 )); then
      finish_logout && return 0
    fi

    sleep "$WATCHDOG_INTERVAL"
  done

  finish_logout
}

start_logout_watchdog() {
  setsid env XDG_SESSION_ID="$session" "$0" --watchdog </dev/null >/dev/null 2>&1 &
}

if [[ "$mode" == "--watchdog" || "$mode" == "--switch-tty" || "$mode" == "--fallback" ]]; then
  run_logout_watchdog
  exit $?
fi

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

start_logout_watchdog
hyprctl dispatch exit 0 || true
