#!/usr/bin/env bash
# Ajustes pós-deploy: permissões de execução e integração Rofi/Hyprland.

set -euo pipefail

TARGET_USER="${1:?Informe o usuário alvo}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

log() { printf '[finalize-config] %s\n' "$*"; }

chmod_tree() {
  local pattern="$1"
  local dir="$2"
  [[ -d "$dir" ]] || return 0
  find "$dir" -type f -name "$pattern" -exec chmod +x {} +
}

setup_rofi_launcher_symlink() {
  local rofi_script="$TARGET_HOME/.config/rofi/scripts/launcher.py"
  local apps_py="$TARGET_HOME/.config/hypr/scripts/RofiLauncherApps.py"

  mkdir -p "$(dirname "$rofi_script")"
  rm -f "$rofi_script"
  ln -sfn "$apps_py" "$rofi_script"
}

ensure_rofi_python_scripts() {
  local script
  for script in RofiLauncherApps.py RofiPower.py; do
    [[ -f "$TARGET_HOME/.config/hypr/scripts/$script" ]] || continue
    chmod +x "$TARGET_HOME/.config/hypr/scripts/$script"
  done
}

log "Ajustando permissões em $TARGET_HOME/.config ..."
chmod_tree '*.sh' "$TARGET_HOME/.config/hypr/scripts"
chmod_tree '*.py' "$TARGET_HOME/.config/hypr/scripts"
chmod_tree '*.sh' "$TARGET_HOME/.config/hypr/UserScripts"
[[ -f "$TARGET_HOME/.config/hypr/initial-boot.sh" ]] && chmod +x "$TARGET_HOME/.config/hypr/initial-boot.sh"

log "Configurando symlink Rofi launcher -> RofiLauncherApps.py ..."
setup_rofi_launcher_symlink
ensure_rofi_python_scripts

chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypr" "$TARGET_HOME/.config/rofi"
chown -h "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/rofi/scripts/launcher.py" 2>/dev/null || true

log "Concluído."
