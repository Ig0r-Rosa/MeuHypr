#!/usr/bin/env bash
# Desliga o sistema — uma única vez por ação no menu.

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  # shellcheck source=/dev/null
  source "$scripts_dir/PowerActionGuard.sh"
  acquire_power_action_guard || exit 0
fi

exec systemctl poweroff
