#!/usr/bin/env bash
# Logout estilo GNOME/SDDM: encerra Hyprland e o sddm-helper volta ao greeter sozinho.
#
# Cadeia SDDM: sddm-helper → hyprland-session → start-hyprland → Hyprland
# Quando Hyprland sai, o helper termina e o SDDM mostra o login (sem chvt/restart).

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
source "$scripts_dir/PowerActionGuard.sh"

if [[ -z "${ROFI_POWER_GUARDED:-}" ]]; then
  acquire_power_action_guard || exit 0
fi

# Precisa rodar na sessão Wayland ativa (Rofi não pode lançar em background).
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null; then
  hyprctl dispatch exit 0
  exit 0
fi

# Fallback: logind encerra a sessão gráfica (como faz o systemd por baixo do GNOME).
session="${XDG_SESSION_ID:-self}"
loginctl terminate-session "$session" 2>/dev/null || true
exit 0
