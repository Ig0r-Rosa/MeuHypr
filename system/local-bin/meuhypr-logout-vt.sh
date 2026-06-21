#!/usr/bin/env bash
# Troca para a TTY do greeter SDDM após Hyprland encerrar (sem reiniciar SDDM).

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

kill_stuck_hyprland() {
  local session="${XDG_SESSION_ID:-}"
  local attempt

  for ((attempt = 1; attempt <= 8; attempt++)); do
    pgrep -x Hyprland >/dev/null || return 0
    if [[ -n "$session" && "$session" != "self" ]]; then
      loginctl kill-session "$session" -s SIGTERM 2>/dev/null || true
    fi
    sleep 0.25
  done

  if [[ -n "$session" && "$session" != "self" ]]; then
    loginctl kill-session "$session" -s SIGKILL 2>/dev/null || true
  fi
}

switch_to_greeter() {
  local vt="$1"
  chvt "$vt" 2>/dev/null || true
  sleep 0.4
  chvt "$vt" 2>/dev/null || true
}

run_worker() {
  local vt attempt

  vt="$(sddm_vt)"

  for ((attempt = 1; attempt <= 48; attempt++)); do
    pgrep -x Hyprland >/dev/null || break
    sleep 0.25
  done

  kill_stuck_hyprland
  switch_to_greeter "$vt"
}

if [[ "${1:-}" == "--worker" ]]; then
  run_worker
  exit 0
fi

setsid "$0" --worker </dev/null >/dev/null 2>&1 &
exit 0
