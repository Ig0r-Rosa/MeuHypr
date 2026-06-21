#!/usr/bin/env bash
# Reinicia SDDM após logout — roda como root, fora da sessão Wayland.

run_worker() {
  local attempt

  for ((attempt = 1; attempt <= 48; attempt++)); do
    pgrep -x Hyprland >/dev/null || break
    sleep 0.25
  done

  systemctl restart sddm
}

if [[ "${1:-}" == "--worker" ]]; then
  run_worker
  exit 0
fi

setsid "$0" --worker </dev/null >/dev/null 2>&1 &
exit 0
