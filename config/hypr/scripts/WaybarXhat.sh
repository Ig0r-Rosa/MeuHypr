#!/usr/bin/env bash
# Botão da Waybar (💬): abre o Xhat no terminal padrão (foca se já estiver aberto).

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_file="$HOME/.config/hypr/UserConfigs/01-UserDefaults.conf"

# Carrega $term de 01-UserDefaults.conf (padrão: kitty).
if [[ -f "$config_file" ]]; then
  # shellcheck disable=SC1090
  eval "$(sed 's/\$//g; s/ = /=/' "$config_file")"
fi

term="${term:-kitty}"
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Avisa se o Xhat ainda não foi instalado neste usuário.
require_xhat() {
  command -v Xhat >/dev/null 2>&1 && return 0
  notify-send -u low "Xhat" "Não instalado. Rode o install do MeuHypr."
  return 1
}

# Foca a janela do Xhat se já existir (título/classe).
focus_existing() {
  local addr
  addr="$(hyprctl clients -j 2>/dev/null | jq -r '
    .[] | select(
      (.title | test("(?i)^xhat"))
      or (.initialTitle | test("(?i)^xhat"))
    ) | .address' | head -n1)"
  [[ -n "$addr" ]] || return 1
  hyprctl dispatch focuswindow "address:${addr}"
}

# Abre o Xhat em uma nova janela do terminal.
launch_xhat() {
  pkill -x fuzzel 2>/dev/null || true
  hyprctl dispatch exec "$term --title Xhat Xhat"
}

main() {
  require_xhat || exit 1
  focus_existing || launch_xhat
}

main "$@"
