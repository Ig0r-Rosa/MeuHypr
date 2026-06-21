#!/usr/bin/env bash
# Instala dependências e aplica as configurações do MeuHypr no sistema local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$SCRIPT_DIR/config"
SYSTEM_SRC="$SCRIPT_DIR/system"
SDDM_THEME_SRC="$SCRIPT_DIR/sddm/themes/noc-sddm"
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
    python3 python3-pip zsh fastfetch btop cava \
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

  build_from_cmake https://github.com/hyprwm/hypridle.git hypridle
  build_from_cmake https://github.com/hyprwm/hyprsunset.git hyprsunset

  if ! command -v hyprlock >/dev/null; then
    build_from_cmake https://github.com/hyprwm/hyprlock.git hyprlock
  fi

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
  log "Copiando configurações para $TARGET_HOME/.config ..."
  sudo -u "$TARGET_USER" mkdir -p "$TARGET_HOME/.config" "$TARGET_HOME/Pictures/wallpapers"

  rsync -a --delete \
    --exclude='.wallpaper_current' \
    --exclude='.wallpaper_modified' \
    "$CONFIG_SRC/hypr/" "$TARGET_HOME/.config/hypr/"

  rsync -a "$CONFIG_SRC/waybar/" "$TARGET_HOME/.config/waybar/"
  for item in rofi swaync swhkd kitty wallust fuzzel xdg-desktop-portal fastfetch wlogout qt5ct qt6ct; do
    rsync -a "$CONFIG_SRC/$item/" "$TARGET_HOME/.config/$item/"
  done

  rsync -a --exclude='bookmarks' "$CONFIG_SRC/gtk-3.0/" "$TARGET_HOME/.config/gtk-3.0/"
  rsync -a "$CONFIG_SRC/gtk-4.0/" "$TARGET_HOME/.config/gtk-4.0/"
  cp -a "$CONFIG_SRC/starship.toml" "$TARGET_HOME/.config/"
  cp -a "$CONFIG_SRC/mimeapps.list" "$TARGET_HOME/.config/"

  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config" "$TARGET_HOME/Pictures"

  # Ajusta caminhos absolutos do usuário original
  grep -rl "/home/igor" "$TARGET_HOME/.config" 2>/dev/null | while read -r f; do
    sed -i "s|/home/igor|$TARGET_HOME|g" "$f"
  done

  setup_gtk_bookmarks

  # Placeholder de wallpaper (sem incluir imagens no repositório)
  touch "$TARGET_HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
  chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
}

setup_gtk_bookmarks() {
  log "Gerando bookmarks GTK/Nautilus para $TARGET_USER..."
  bash "$SCRIPT_DIR/system/scripts/setup-gtk-bookmarks.sh" "$TARGET_USER"
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

deploy_system_files() {
  log "Configurando sessão Hyprland e wrapper de ambiente..."
  ensure_start_hyprland_binary
  install -Dm755 "$SYSTEM_SRC/local-bin/hyprland-session.sh" /usr/local/bin/hyprland-session
  install -Dm755 "$SYSTEM_SRC/local-bin/meuhypr-logout-sddm.sh" /usr/local/bin/meuhypr-logout-sddm
  install -Dm644 "$SYSTEM_SRC/wayland-sessions/hyprland.desktop" /usr/share/wayland-sessions/hyprland.desktop
  install -Dm644 "$SYSTEM_SRC/wayland-sessions/hyprland.desktop" /usr/local/share/wayland-sessions/hyprland.desktop

  log "Configurando SDDM..."
  install -Dm644 "$SYSTEM_SRC/sddm.conf" /etc/sddm.conf
  install -Dm644 "$SYSTEM_SRC/sddm.conf.d/10-gnome-default.conf" /etc/sddm.conf.d/10-gnome-default.conf
  install -d /usr/share/sddm/themes/noc-sddm
  rsync -a "$SDDM_THEME_SRC/" /usr/share/sddm/themes/noc-sddm/

  log "Permissão de logout (restart SDDM sem senha)..."
  install -Dm440 /dev/stdin /etc/sudoers.d/meuhypr-sddm-logout <<EOF
# Logout Hyprland - helper root reinicia SDDM fora da sessao Wayland.
${TARGET_USER} ALL=(root) NOPASSWD: /usr/local/bin/meuhypr-logout-sddm
EOF
  visudo -cf /etc/sudoers.d/meuhypr-sddm-logout >/dev/null
}

setup_directories_and_permissions() {
  log "Ajustando permissões dos scripts..."
  chmod +x "$TARGET_HOME/.config/hypr"/scripts/*.sh 2>/dev/null || true
  chmod +x "$TARGET_HOME/.config/hypr"/UserScripts/*.sh 2>/dev/null || true
  chmod +x "$TARGET_HOME/.config/hypr"/initial-boot.sh 2>/dev/null || true
  chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypr"
}

post_install_notes() {
  log "Instalação concluída."
  cat <<EOF

Próximos passos manuais:
  1. Coloque seus wallpapers em: $TARGET_HOME/Pictures/wallpapers/
  2. Defina o wallpaper do SDDM em /usr/share/sddm/themes/noc-sddm/theme.conf
     (campo background=). O padrão aponta para /usr/share/backgrounds/wallpaper11.png
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
    setup_directories_and_permissions
    post_install_notes
    exit 0
  fi

  need_root
  install_apt_packages
  install_cargo_tools
  install_starship
  install_hypr_stack
  install_rofi_wayland
  deploy_user_configs
  deploy_system_files
  setup_directories_and_permissions
  post_install_notes
}

main "$@"
