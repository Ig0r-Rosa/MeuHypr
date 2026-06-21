#!/usr/bin/env bash
# Troca para a TTY do greeter SDDM após encerrar a sessão (sem reiniciar SDDM).

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

resolve_session_id() {
  local session="$1"
  if [[ "$session" =~ ^[0-9]+$ ]]; then
    echo "$session"
    return
  fi
  loginctl show-session "$session" -p Id --value 2>/dev/null \
    || loginctl list-sessions --no-legend 2>/dev/null \
      | awk -v u="${SUDO_USER:-${LOGOUT_USER:-}}" '$3==u {print $1; exit}'
}

active_vt() {
  sed 's/[^0-9]//g' /sys/class/tty/tty0/active 2>/dev/null
}

end_user_session() {
  local session="$1"

  [[ -n "$session" ]] || return 0
  loginctl terminate-session "$session" 2>/dev/null || true
  sleep 0.5
  loginctl kill-session "$session" -s SIGTERM 2>/dev/null || true
  sleep 0.5
  loginctl kill-session "$session" -s SIGKILL 2>/dev/null || true
  pkill -KILL -x Hyprland 2>/dev/null || true
}

wait_hyprland_exit() {
  local attempt

  for ((attempt = 1; attempt <= 40; attempt++)); do
    pgrep -x Hyprland >/dev/null || return 0
    sleep 0.25
  done
}

switch_to_greeter() {
  local vt="$1"
  local attempt active

  for ((attempt = 1; attempt <= 12; attempt++)); do
    chvt "$vt" 2>/dev/null || true
    sleep 0.25
    active="$(active_vt)"
    [[ "$active" == "$vt" ]] && return 0
  done

  return 1
}

run_worker() {
  local session vt

  session="$(resolve_session_id "$1")"
  vt="${2:-$(sddm_vt)}"

  sleep 0.3
  end_user_session "$session"
  wait_hyprland_exit
  end_user_session "$session"
  switch_to_greeter "$vt"
}

if [[ "${1:-}" == "--worker" ]]; then
  run_worker "${2:-}" "${3:-}"
  exit 0
fi

setsid "$0" --worker "$1" "$2" </dev/null >/dev/null 2>&1 &
exit 0
