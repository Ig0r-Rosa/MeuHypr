#!/usr/bin/env bash
# Logout root: encerra sessão Hyprland e reinicia SDDM (greeter limpo na tty2).

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

end_user_session() {
  local session="$1"

  [[ -n "$session" ]] || return 0
  loginctl terminate-session "$session" 2>/dev/null || true
  sleep 0.4
  loginctl kill-session "$session" -s SIGTERM 2>/dev/null || true
  sleep 0.4
  loginctl kill-session "$session" -s SIGKILL 2>/dev/null || true
  pkill -KILL -x Hyprland 2>/dev/null || true
}

wait_hyprland_exit() {
  local attempt

  for ((attempt = 1; attempt <= 24; attempt++)); do
    pgrep -x Hyprland >/dev/null || return 0
    sleep 0.25
  done
}

restart_sddm_greeter() {
  systemctl is-active --quiet sddm 2>/dev/null || return 1
  systemctl restart sddm
}

run_worker() {
  local session

  session="$(resolve_session_id "$1")"

  sleep 0.3
  end_user_session "$session"
  wait_hyprland_exit
  end_user_session "$session"
  restart_sddm_greeter
}

if [[ "${1:-}" == "--worker" ]]; then
  run_worker "${2:-}"
  exit 0
fi

setsid "$0" --worker "$1" </dev/null >/dev/null 2>&1 &
exit 0
