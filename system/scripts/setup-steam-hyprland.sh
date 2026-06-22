#!/usr/bin/env bash
# Pós-deploy: Steam no Hyprland (launcher, ícones, permissões).

set -euo pipefail

TARGET_USER="${1:?Informe o usuário alvo}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

log() { printf '[setup-steam] %s\n' "$*"; }

ensure_steam_scripts_executable() {
  local script
  for script in SteamLaunch.sh SteamRaiseWindow.sh SteamSeedWindowGeometry.sh \
    SteamIconsWorkaround.sh RestoreUserAppIcons.sh; do
    [[ -f "$TARGET_HOME/.config/hypr/scripts/$script" ]] || continue
    chmod +x "$TARGET_HOME/.config/hypr/scripts/$script"
  done
  [[ -f "$TARGET_HOME/.config/hypr/assets/steam-gtk2.rc" ]] || \
    log "Aviso: steam-gtk2.rc ausente em hypr/assets/"
}

apply_icons_workaround() {
  sudo -u "$TARGET_USER" bash -lc \
    "'$TARGET_HOME/.config/hypr/scripts/SteamIconsWorkaround.sh'" 2>/dev/null || true
}

create_steam_desktop_entry() {
  local dest="$TARGET_HOME/.local/share/applications/steam.desktop"
  local launch_script="$TARGET_HOME/.config/hypr/scripts/SteamLaunch.sh"

  [[ -x "$launch_script" ]] || return 0
  mkdir -p "$(dirname "$dest")"
  rm -f "$dest" "$TARGET_HOME/.local/share/applications/steam-hyprland.desktop"
  cat >"$dest" <<DESKTOP
[Desktop Entry]
Name=Steam
Comment=Aplicativo para jogar e gerenciar jogos no Steam
Exec=$launch_script %U
Icon=steam
Terminal=false
Type=Application
Categories=Network;FileTransfer;Game;
MimeType=x-scheme-handler/steam;x-scheme-handler/steamlink;
Keywords=Games
PrefersNonDefaultGPU=false
DESKTOP
  chown "$TARGET_USER:$TARGET_USER" "$dest"
}

log "Configurando Steam + Hyprland para $TARGET_USER ..."
ensure_steam_scripts_executable
apply_icons_workaround
create_steam_desktop_entry
log "Steam configurada (launcher: SteamLaunch.sh)"
