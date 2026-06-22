#!/usr/bin/env bash
# Instala dependências e aplica as configurações do MeuHypr no sistema local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/config"
SYSTEM_SRC="$SCRIPT_DIR/system"
ASSETS_SRC="$SCRIPT_DIR/assets"
SDDM_THEME_SRC="$SCRIPT_DIR/sddm/themes/noc-sddm"

# Wallpaper padrão (SDDM + fallback Hyprland) — altere só aqui para trocar o fundo do sistema
DEFAULT_WALLPAPER_FILE="matrix-default.jpg"
DEFAULT_WALLPAPER_SRC="$ASSETS_SRC/wallpapers/$DEFAULT_WALLPAPER_FILE"
DEFAULT_WALLPAPER_SYSTEM="/usr/share/backgrounds/meuhypr-matrix.jpg"
SDDM_WALLPAPER_FILE="matrix.jpg"
SDDM_WALLPAPER_PATH="/usr/share/sddm/themes/noc-sddm/backgrounds/$SDDM_WALLPAPER_FILE"
SDDM_THEME_CONF="/usr/share/sddm/themes/noc-sddm/theme.conf"
USER_WALLPAPER_NAME="$DEFAULT_WALLPAPER_FILE"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

log() { printf '\n[%s] %s\n' "MeuHypr" "$*"; }
need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Execute com sudo para instalar pacotes e configurar o SDDM." >&2
    exit 1
  fi
}

install_apt_packages() {
  log "Instalando pacotes APT (Debian trixie)..."
  apt-get update
  apt-get install -y \
    build-essential git curl wget pkg-config cmake meson ninja-build \
    libwayland-dev libxkbcommon-dev libinput-dev libpixman-1-dev \
    libpango1.0-dev libdrm-dev libgbm-dev libegl-dev libgles2-mesa-dev \
    libseat-dev libsystemd-dev libudev-dev libdisplay-info-dev libliftoff-dev \
    libhwdata-dev libtomlplusplus-dev libre2-dev \
    libwebp-dev libjpeg-dev libpng-dev libgif-dev librsvg2-dev \
    libdbus-1-dev libpipewire-0.3-dev libspa-0.2-dev libxcb1-dev \
    libxcb-ewmh-dev libxcb-icccm4-dev libxcb-util-dev libstartup-notification0-dev \
    libxdg-basedir-dev libcheck-dev libjson-c-dev libinih-dev \
    waybar sddm kitty nautilus \
    sway-notification-center wlogout fuzzel \
    grim slurp wl-clipboard cliphist jq \
    playerctl pamixer pavucontrol brightnessctl \
    network-manager network-manager-gnome nmtui \
    polkit-kde-agent-1 \
    pipewire pipewire-audio wireplumber \
    xdg-desktop-portal xdg-desktop-portal-gtk \
    qt5ct qt6ct qt-style-kvantum \
    nwg-displays nwg-look \
    python3 python3-pip python3-nautilus zsh fastfetch btop cava \
    fonts-noto fonts-noto-color-emoji fonts-firacode \
    libnotify-bin imagemagick \
    gnome-themes-extra adwaita-icon-theme
}

install_cargo_tools() {
  log "Instalando ferramentas Rust (wallust, bluetui)..."
  local cargo_home="$TARGET_HOME/.cargo"
  local cargo_bin="$cargo_home/bin"

  sudo -u "$TARGET_USER" bash -lc "
    command -v cargo >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source \"$cargo_home/env\"
    cargo install wallust bluetui
  "

  if [[ -d "$cargo_bin" ]]; then
    grep -qxF 'export PATH="$HOME/.cargo/bin:$PATH"' "$TARGET_HOME/.profile" 2>/dev/null || \
      echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> "$TARGET_HOME/.profile"
  fi
}

install_starship() {
  log "Instalando Starship prompt..."
  if ! command -v starship >/dev/null; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi
}

build_from_cmake() {
  local repo_url="$1"
  local repo_name="$2"
  git clone "$repo_url" "$repo_name"
  cd "$repo_name"
  cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
  cmake --build build --config Release -j"$(nproc)"
  cmake --install build
  cd ..
}

install_hypr_stack() {
  log "Compilando Hyprland e utilitários (não disponíveis no APT)..."
  local build_dir="/tmp/meuhypr-hypr-build"
  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  cd "$build_dir"

  git clone --recursive https://github.com/hyprwm/Hyprland.git
  cd Hyprland
  make all
  make install
  cd ..

  build_from_cmake https://github.com/hyprwm/hyprsunset.git hyprsunset

  if ! command -v swww >/dev/null; then
    log "Compilando swww..."
    git clone https://github.com/LGFae/swww.git
    cd swww
    cargo build --release
    install -Dm755 target/release/swww /usr/local/bin/swww
    install -Dm755 target/release/swww-daemon /usr/local/bin/swww-daemon 2>/dev/null || true
    cd ..
  fi

  if ! command -v hyprland-portal >/dev/null; then
    log "Compilando xdg-desktop-portal-hyprland..."
    build_from_cmake https://github.com/hyprwm/xdg-desktop-portal-hyprland.git xdg-desktop-portal-hyprland
  fi
}

install_rofi_wayland() {
  log "Instalando Rofi com suporte Wayland (fork lbonn/rofi)..."
  if command -v rofi >/dev/null && [[ "$(command -v rofi)" == /usr/local/bin/rofi ]]; then
    return 0
  fi

  local build_dir="/tmp/meuhypr-rofi-build"
  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  cd "$build_dir"

  git clone https://github.com/lbonn/rofi.git
  cd rofi
  mkdir build && cd build
  cmake .. -DENABLE_WAYLAND=1
  make -j"$(nproc)"
  make install
}

deploy_user_configs() {
  local pictures_dir
  pictures_dir=$(sudo -u "$TARGET_USER" xdg-user-dir PICTURES 2>/dev/null || echo "$TARGET_HOME/Pictures")

  log "Copiando configurações para $TARGET_HOME/.config ..."
  sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.config" "$pictures_dir/wallpapers"

  rsync -a --delete \
    --exclude='.wallpaper_current' \
    --exclude='.wallpaper_modified' \
    --exclude='monitors.json' \
    "$CONFIG_SRC/hypr/" "$TARGET_HOME/.config/hypr/"

  rsync -a "$CONFIG_SRC/waybar/" "$TARGET_HOME/.config/waybar/"
  for item in swaync swhkd kitty wallust fuzzel xdg-desktop-portal fastfetch wlogout qt5ct qt6ct Kvantum; do
    rsync -a "$CONFIG_SRC/$item/" "$TARGET_HOME/.config/$item/"
  done
  # launcher.py é symlink gerado no pós-deploy — não copiar cópia estática
  rsync -a --exclude='scripts/launcher.py' "$CONFIG_SRC/rofi/" "$TARGET_HOME/.config/rofi/"

  rsync -a --exclude='bookmarks' "$CONFIG_SRC/gtk-3.0/" "$TARGET_HOME/.config/gtk-3.0/"
  rsync -a "$CONFIG_SRC/gtk-4.0/" "$TARGET_HOME/.config/gtk-4.0/"
  mkdir -p "$TARGET_HOME/.config/hypr/assets"
  cp -a "$CONFIG_SRC/gtk-3.0/gtk.css" "$TARGET_HOME/.config/hypr/assets/gtk-3.0.css"
  cp -a "$CONFIG_SRC/gtk-4.0/gtk.css" "$TARGET_HOME/.config/hypr/assets/gtk-4.0.css"
  cp -a "$CONFIG_SRC/starship.toml" "$TARGET_HOME/.config/"
  cp -a "$CONFIG_SRC/mimeapps.list" "$TARGET_HOME/.config/"
  cp -a "$CONFIG_SRC/xdg-terminals.list" "$TARGET_HOME/.config/"

  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$pictures_dir" 2>/dev/null || \
    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$TARGET_HOME/Pictures"

  # Ajusta caminhos absolutos do usuário original (só /home/igor/ — evita corromper /home/igor_retta)
  if [[ "$TARGET_HOME" != "/home/igor" ]]; then
    grep -rl '/home/igor/' "$TARGET_HOME/.config" 2>/dev/null | while read -r f; do
      sed -i "s|/home/igor/|$TARGET_HOME/|g" "$f"
    done
  fi

  setup_gtk_bookmarks
  setup_nautilus
  setup_display_preferences
  setup_default_wallpaper_user
  setup_steam_launcher
  repair_cursor_storage_if_needed
  finalize_config_permissions

  if [[ ! -f "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json" ]]; then
    cp -a "$CONFIG_SRC/hypr/wallpaper_effects/monitors.json.example" \
      "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json"
  fi
}

install_nautilus_extension() {
  log "Instalando extensão nautilus-open-any-terminal para $TARGET_USER..."
  local schemas_dir="$TARGET_HOME/.local/share/glib-2.0/schemas"

  sudo -u "$TARGET_USER" bash -lc "
    pip3 install --user nautilus-open-any-terminal 2>/dev/null \
      || pip3 install --user --break-system-packages nautilus-open-any-terminal
  "

  if [[ -d "$schemas_dir" ]]; then
    sudo -u "$TARGET_USER" glib-compile-schemas "$schemas_dir"
  fi
}

setup_nautilus() {
  log "Aplicando preferências do Nautilus para $TARGET_USER..."
  bash "$SCRIPT_DIR/config/hypr/scripts/setup-nautilus.sh" "$TARGET_USER"
}

setup_gtk_bookmarks() {
  log "Gerando bookmarks GTK/Nautilus para $TARGET_USER..."
  bash "$SCRIPT_DIR/system/scripts/setup-gtk-bookmarks.sh" "$TARGET_USER"
}

setup_display_preferences() {
  log "Aplicando monitor/Kvantum/fontes GTK para $TARGET_USER..."
  bash "$SCRIPT_DIR/system/scripts/setup-display-preferences.sh" "$TARGET_USER"
}

# Um único atalho Steam no menu — usa SteamLaunch.sh (Hyprland + NVIDIA).
setup_steam_launcher() {
  local dest="$TARGET_HOME/.local/share/applications/steam.desktop"
  local src="$CONFIG_SRC/applications/steam.desktop"

  [[ -f "$src" ]] || return 0
  mkdir -p "$(dirname "$dest")"
  rm -f "$dest" "$TARGET_HOME/.local/share/applications/steam-hyprland.desktop"
  sed "s|__MEUHYPR_HOME__|$TARGET_HOME|g" "$src" >"$dest"
  chown "$TARGET_USER:$TARGET_USER" "$dest"
}

repair_cursor_storage_if_needed() {
  local script="$SCRIPT_DIR/config/hypr/scripts/RepairCursorStorage.sh"
  local leveldb="$TARGET_HOME/.config/Cursor/Local Storage/leveldb"
  local global_db="$TARGET_HOME/.config/Cursor/User/globalStorage/state.vscdb"
  local latest_log

  [[ -d "$TARGET_HOME/.config/Cursor/User" ]] || return 0
  [[ -x "$script" ]] || chmod +x "$script"

  if [[ -d "$leveldb" ]] && ! find "$leveldb" -maxdepth 1 -name '*.ldb' -print -quit | grep -q .; then
    log "Reparando Cursor Local Storage para $TARGET_USER ..."
    bash "$script" "$TARGET_USER" --local-storage
  fi

  latest_log="$(ls -t "$TARGET_HOME/.config/Cursor"/logs/*/main.log 2>/dev/null | head -1 || true)"
  if [[ -f "$global_db" ]] && ! python3 - "$global_db" <<'PY'
import sqlite3, sys
try:
    con = sqlite3.connect(f"file:{sys.argv[1]}?mode=ro", uri=True)
    ok = con.execute("pragma integrity_check").fetchone()[0]
    raise SystemExit(0 if ok == "ok" else 1)
except Exception:
    raise SystemExit(1)
PY
  then
    log "Reparando Cursor SQLite (state.vscdb) para $TARGET_USER ..."
    bash "$script" "$TARGET_USER" --sqlite
    return 0
  fi

  if [[ -n "$latest_log" ]] && grep -q 'SQLITE_CORRUPT' "$latest_log" 2>/dev/null; then
    log "Reparando Cursor após SQLITE_CORRUPT para $TARGET_USER ..."
    bash "$script" "$TARGET_USER" --sqlite
  fi
}

# Instala o wallpaper padrão em /usr/share e no tema SDDM.
setup_default_wallpaper_system() {
  [[ -f "$DEFAULT_WALLPAPER_SRC" ]] || {
    log "Aviso: wallpaper padrão não encontrado em $DEFAULT_WALLPAPER_SRC"
    return 0
  }

  log "Instalando wallpaper padrão do sistema (SDDM + /usr/share/backgrounds)..."
  install -Dm644 "$DEFAULT_WALLPAPER_SRC" "$DEFAULT_WALLPAPER_SYSTEM"
  install -Dm644 "$DEFAULT_WALLPAPER_SRC" "$SDDM_WALLPAPER_PATH"

  if [[ -f "$SDDM_THEME_CONF" ]]; then
    sed -i "s|^background=.*|background=$SDDM_WALLPAPER_PATH|" "$SDDM_THEME_CONF"
  fi
}

# Copia o wallpaper padrão para o usuário e define fallback do Hyprland.
setup_default_wallpaper_user() {
  local pictures_dir user_wp fallback_wp
  pictures_dir=$(sudo -u "$TARGET_USER" xdg-user-dir PICTURES 2>/dev/null || echo "$TARGET_HOME/Pictures")
  user_wp="$pictures_dir/wallpapers/$USER_WALLPAPER_NAME"
  fallback_wp="$TARGET_HOME/.config/hypr/wallpaper_effects/.wallpaper_current"

  mkdir -p "$pictures_dir/wallpapers" "$(dirname "$fallback_wp")"

  if [[ -f "$DEFAULT_WALLPAPER_SRC" ]]; then
    log "Configurando wallpaper padrão para $TARGET_USER ..."
    cp -a "$DEFAULT_WALLPAPER_SRC" "$user_wp"
    if [[ ! -s "$fallback_wp" ]]; then
      cp -a "$DEFAULT_WALLPAPER_SRC" "$fallback_wp"
    fi
    chown "$TARGET_USER:$TARGET_USER" "$user_wp" "$fallback_wp"
    return 0
  fi

  [[ -f "$fallback_wp" ]] || touch "$fallback_wp"
  chown "$TARGET_USER:$TARGET_USER" "$fallback_wp"
}

ensure_start_hyprland_binary() {
  local bin="/usr/local/bin/start-hyprland"
  if [[ -x "$bin" ]] && ! file -b "$bin" | grep -qi 'shell script'; then
    return 0
  fi

  log "Restaurando binário oficial start-hyprland (watchdog Hyprland 0.53+)..."
  local build_dir="/tmp/meuhypr-start-hyprland-build"
  rm -rf "$build_dir"
  git clone --depth 1 https://github.com/hyprwm/Hyprland.git "$build_dir"
  cmake -S "$build_dir/start" -B "$build_dir/start/build" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
  cmake --build "$build_dir/start/build" -j"$(nproc)"
  cmake --install "$build_dir/start/build"
}

install_logout_helper() {
  log "Instalando helper de logout (chvt para greeter SDDM)..."
  install -Dm755 "$SYSTEM_SRC/local-bin/meuhypr-logout-vt.sh" /usr/local/bin/meuhypr-logout-vt
  rm -f /usr/local/bin/meuhypr-logout /usr/local/bin/meuhypr-logout-sddm
  install -Dm440 /dev/stdin /etc/sudoers.d/meuhypr-sddm-logout <<'EOF'
# Logout Hyprland — troca para TTY do greeter SDDM após encerrar sessão.
%sudo ALL=(root) NOPASSWD: /usr/local/bin/meuhypr-logout-vt
EOF
  visudo -cf /etc/sudoers.d/meuhypr-sddm-logout >/dev/null
}

deploy_system_files() {
  log "Configurando sessão Hyprland e wrapper de ambiente..."
  ensure_start_hyprland_binary
  install -Dm755 "$SYSTEM_SRC/local-bin/hyprland-session.sh" /usr/local/bin/hyprland-session
  install_logout_helper
  install -Dm644 "$SYSTEM_SRC/wayland-sessions/hyprland.desktop" /usr/share/wayland-sessions/hyprland.desktop
  install -Dm644 "$SYSTEM_SRC/wayland-sessions/hyprland.desktop" /usr/local/share/wayland-sessions/hyprland.desktop

  log "Configurando SDDM..."
  install -Dm644 "$SYSTEM_SRC/sddm.conf" /etc/sddm.conf
  install -Dm644 "$SYSTEM_SRC/sddm.conf.d/10-gnome-default.conf" /etc/sddm.conf.d/10-gnome-default.conf
  install -d /usr/share/sddm/themes/noc-sddm
  rsync -a "$SDDM_THEME_SRC/" /usr/share/sddm/themes/noc-sddm/
  chown -R root:root /usr/share/sddm/themes/noc-sddm
  chmod -R a+rX /usr/share/sddm/themes/noc-sddm
  setup_default_wallpaper_system
}

finalize_config_permissions() {
  log "Finalizando permissões e integração Rofi..."
  bash "$SCRIPT_DIR/system/scripts/finalize-config-permissions.sh" "$TARGET_USER"
}

post_install_notes() {
  log "Instalação concluída."
  cat <<EOF

Próximos passos manuais:
  1. Wallpaper padrão: $DEFAULT_WALLPAPER_SYSTEM (SDDM + fallback Hyprland)
  2. Wallpapers extras: $TARGET_HOME/Pictures/wallpapers/
  3. Instale a fonte JetBrainsMono Nerd Font em ~/.local/share/fonts/
  4. Ajuste monitors.conf com: nwg-displays (monitores variam por máquina)
  5. Reinicie e selecione a sessão "Hyprland" no SDDM

Para aplicar só as configs (sem reinstalar pacotes):
  sudo MEUHYPR_CONFIG_ONLY=1 $SCRIPT_DIR/install.sh

EOF
}

main() {
  if [[ "${MEUHYPR_CONFIG_ONLY:-0}" == "1" ]]; then
    need_root
    deploy_user_configs
    deploy_system_files
    post_install_notes
    exit 0
  fi

  need_root
  install_apt_packages
  install_cargo_tools
  install_starship
  install_hypr_stack
  install_rofi_wayland
  install_nautilus_extension
  deploy_user_configs
  deploy_system_files
  post_install_notes
}

main "$@"
