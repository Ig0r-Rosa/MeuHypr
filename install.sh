#!/usr/bin/env bash
# Instala dependências e aplica as configurações do MeuHypr no sistema local.
#
# Filosofia de instalação:
#   - Automático: sessão Hyprland, TUIs (yazi, btop, nvtop, kew v4, glow, dua-cli,
#     oxker, bluetui, pulsemixer, nmtui…), oh-my-zsh, firefox-esr,
#     Nautilus (gerenciador de arquivos padrão),
#     Rofi (Super+D/S/H) e deps.
#   - Manual: Steam, Discord, pavucontrol, nwg-displays, etc.
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

# Fundo do GRUB. Vazio = usa a imagem versionada do tema (padrão do repo).
# Para escolher outra: nome em assets/wallpapers/ (ex.: "espaco_1.jpg") ou caminho absoluto.
# Também dá para sobrescrever na hora: MEUHYPR_GRUB_BG=... sudo ./install.sh
GRUB_WALLPAPER="${MEUHYPR_GRUB_BG:-}"
TARGET_USER="${MEUHYPR_TARGET_USER:-${SUDO_USER:-$USER}}"
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

  log "  → Dependências de compilação (Hyprland, Rofi)..."
  apt-get install -y \
    build-essential git curl wget pkg-config cmake meson ninja-build \
    libwayland-dev libxkbcommon-dev libinput-dev libpixman-1-dev \
    libpango1.0-dev libdrm-dev libgbm-dev libegl-dev libgles2-mesa-dev \
    libseat-dev libsystemd-dev libudev-dev libdisplay-info-dev libliftoff-dev \
    libhwdata-dev libtomlplusplus-dev libre2-dev \
    libwebp-dev libjpeg-dev libpng-dev libgif-dev librsvg2-dev \
    libdbus-1-dev libpipewire-0.3-dev libspa-0.2-dev libxcb1-dev \
    libxcb-ewmh-dev libxcb-icccm4-dev libxcb-util-dev libstartup-notification0-dev \
    libxdg-basedir-dev libcheck-dev libjson-c-dev libinih-dev

  log "  → Sessão Hyprland (barra, terminal, notificações, logout)..."
  apt-get install -y \
    waybar sddm kitty \
    sway-notification-center wlogout fuzzel \
    nautilus

  log "  → Atalhos e utilitários (screenshot, clipboard, busca Rofi)..."
  apt-get install -y \
    grim slurp wl-clipboard cliphist jq \
    python3 python3-pip vim \
    libnotify-bin imagemagick xdotool

  log "  → Áudio e rede (CLI + agentes; sem GUIs opcionais)..."
  apt-get install -y \
    playerctl pamixer pulsemixer brightnessctl \
    network-manager nmtui \
    polkit-kde-agent-1 \
    pipewire pipewire-audio wireplumber

  log "  → Portals, temas GTK/Qt e fontes base..."
  apt-get install -y \
    xdg-desktop-portal xdg-desktop-portal-gtk \
    qt5ct qt6ct qt-style-kvantum \
    gnome-themes-extra adwaita-icon-theme \
    fonts-noto fonts-noto-color-emoji fonts-firacode

  log "  → Apps TUI (waybar, SwayNC, atalhos)..."
  apt-get install -y \
    zsh fastfetch btop nvtop golang-go glow

  log "  → Dependências para compilar kew v4 (player de música)..."
  apt-get install -y \
    libfaad-dev libtag1-dev libfftw3-dev libopus-dev libopusfile-dev \
    libvorbis-dev libogg-dev libchafa-dev libglib2.0-dev libgdk-pixbuf-2.0-dev g++

  log "  → Navegador padrão (Super+B; desinstale com apt se preferir outro)..."
  apt-get install -y firefox-esr
}

install_kew() {
  log "Compilando kew v4.0.0 para $TARGET_USER (~/.local/bin)..."
  bash "$SCRIPT_DIR/system/scripts/install-kew.sh" "$TARGET_USER"
  grep -qxF 'export PATH="\$HOME/.local/bin:\$PATH"' "$TARGET_HOME/.profile" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$TARGET_HOME/.profile"
}

install_hyprmoncfg() {
  log "Compilando hyprmoncfg para $TARGET_USER..."
  local build_dir="/tmp/meuhypr-hyprmoncfg-build"
  local bin_dir="$TARGET_HOME/.local/bin"

  mkdir -p "$bin_dir"
  rm -rf "$build_dir"
  git clone --depth 1 https://github.com/crmne/hyprmoncfg.git "$build_dir"

  sudo -u "$TARGET_USER" bash -lc "
    cd '$build_dir'
    go build -o bin/hyprmoncfg ./cmd/hyprmoncfg
    go build -o bin/hyprmoncfgd ./cmd/hyprmoncfgd
    install -Dm755 bin/hyprmoncfg '$bin_dir/hyprmoncfg'
    install -Dm755 bin/hyprmoncfgd '$bin_dir/hyprmoncfgd'
  "

  chown -R "$TARGET_USER:$TARGET_USER" "$bin_dir"
  grep -qxF 'export PATH="\$HOME/.local/bin:\$PATH"' "$TARGET_HOME/.profile" 2>/dev/null || \
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$TARGET_HOME/.profile"
}

install_cargo_tools() {
  log "Instalando ferramentas TUI via Cargo (wallust, bluetui, yazi, dua-cli, oxker)..."
  local cargo_home="$TARGET_HOME/.cargo"
  local cargo_bin="$cargo_home/bin"

  sudo -u "$TARGET_USER" bash -lc "
    command -v cargo >/dev/null || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source \"$cargo_home/env\"
    cargo install wallust bluetui dua-cli oxker
    cargo install --force yazi-build
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

install_oh_my_zsh() {
  log "Instalando oh-my-zsh para $TARGET_USER..."
  local zsh_bin
  zsh_bin="$(command -v zsh)"

  sudo -u "$TARGET_USER" bash -lc "
    if [[ ! -d \"\$HOME/.oh-my-zsh\" ]]; then
      RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"
    fi
  "

  if [[ -n "$zsh_bin" ]] && [[ "$(getent passwd "$TARGET_USER" | cut -d: -f7)" != "$zsh_bin" ]]; then
    chsh -s "$zsh_bin" "$TARGET_USER"
  fi
}

deploy_shell_config() {
  local zshrc_src="$CONFIG_SRC/zsh/zshrc"
  local zshrc_dst="$TARGET_HOME/.zshrc"

  [[ -f "$zshrc_src" ]] || return 0

  if [[ -f "$zshrc_dst" ]]; then
    log "  → ~/.zshrc já existe — mantido (use MEUHYPR_FORCE_ZSHRC=1 para sobrescrever)"
    [[ "${MEUHYPR_FORCE_ZSHRC:-0}" == "1" ]] || return 0
  fi

  log "Configurando ~/.zshrc (oh-my-zsh + Starship) para $TARGET_USER..."
  cp -a "$zshrc_src" "$zshrc_dst"
  chown "$TARGET_USER:$TARGET_USER" "$zshrc_dst"
}

deploy_kew_config() {
  local kewrc_src="$CONFIG_SRC/kew/kewrc"
  local kew_dir="$TARGET_HOME/.config/kew"

  [[ -f "$kewrc_src" ]] || return 0

  sudo -u "$TARGET_USER" mkdir -p "$kew_dir"

  if [[ -f "$kew_dir/kewrc" ]] && [[ "${MEUHYPR_FORCE_KEWRC:-0}" != "1" ]]; then
    log "  → ~/.config/kew/kewrc já existe — mantido"
    return 0
  fi

  log "Configurando kewrc padrão para $TARGET_USER..."
  cp -a "$kewrc_src" "$kew_dir/kewrc"
  chown "$TARGET_USER:$TARGET_USER" "$kew_dir/kewrc"
}

configure_sddm_login() {
  log "Configurando SDDM como gerenciador de login..."
  local sddm_bin="/usr/sbin/sddm"
  [[ -x "$sddm_bin" ]] || sddm_bin="$(command -v sddm 2>/dev/null || true)"
  [[ -n "$sddm_bin" ]] || {
    log "  → Aviso: binário sddm não encontrado"
    return 0
  }

  if command -v debconf-set-selections >/dev/null; then
    echo "sddm shared/default-x-display-manager select sddm" | debconf-set-selections
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive sddm 2>/dev/null || true
  fi

  if [[ -f /etc/X11/default-display-manager ]]; then
    echo "$sddm_bin" > /etc/X11/default-display-manager
  fi

  systemctl enable sddm.service 2>/dev/null || true
  systemctl set-default graphical.target 2>/dev/null || true
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
  for item in swaync swhkd kitty yazi wallust fuzzel xdg-desktop-portal fastfetch wlogout qt5ct qt6ct Kvantum; do
    rsync -a "$CONFIG_SRC/$item/" "$TARGET_HOME/.config/$item/"
  done
  # launcher.py é symlink gerado no pós-deploy — não copiar cópia estática
  rsync -a --exclude='scripts/launcher.py' --exclude='launcher-state.json' \
    "$CONFIG_SRC/rofi/" "$TARGET_HOME/.config/rofi/"

  rsync -a --exclude='bookmarks' "$CONFIG_SRC/gtk-3.0/" "$TARGET_HOME/.config/gtk-3.0/"
  rsync -a "$CONFIG_SRC/gtk-4.0/" "$TARGET_HOME/.config/gtk-4.0/"
  mkdir -p "$TARGET_HOME/.config/hypr/assets"
  cp -a "$CONFIG_SRC/gtk-3.0/gtk.css" "$TARGET_HOME/.config/hypr/assets/gtk-3.0.css"
  cp -a "$CONFIG_SRC/gtk-4.0/gtk.css" "$TARGET_HOME/.config/hypr/assets/gtk-4.0.css"
  cp -a "$CONFIG_SRC/starship.toml" "$TARGET_HOME/.config/"
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
  setup_display_preferences
  setup_default_wallpaper_user
  deploy_shell_config
  deploy_kew_config
  setup_nautilus
  repair_cursor_storage_if_needed
  finalize_config_permissions

  if [[ ! -f "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json" ]]; then
    cp -a "$CONFIG_SRC/hypr/wallpaper_effects/monitors.json.example" \
      "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/hypr/wallpaper_effects/monitors.json"
  fi
}

install_nautilus_extension() {
  # Extensão "abrir terminal aqui" (kitty) — Nautilus é instalado por padrão.
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
  # Aplica as preferências do Nautilus versionadas no repo (setup-nautilus.sh).
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

# Opt-in manual — requer Steam instalada pelo usuário.
setup_steam_hyprland() {
  local script="$SCRIPT_DIR/system/scripts/setup-steam-hyprland.sh"
  [[ -x "$script" ]] || chmod +x "$script"
  bash "$script" "$TARGET_USER"
}

# Legado — mantido como alias interno.
setup_steam_launcher() {
  setup_steam_hyprland
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
  setup_grub_theme
  setup_plymouth_theme
  disable_core_dumps
}

# Desativa a geração de core dumps (arquivos core.* poluindo as homes).
# Atua no kernel (vale p/ todos os usuários e sessões gráficas) e reforça
# via limits.conf, removendo configs antigas que reativavam os dumps.
disable_core_dumps() {
  log "Desativando core dumps (arquivos core.*)..."
  _write_coredump_sysctl
  _write_coredump_limits
  sysctl -p /etc/sysctl.d/50-coredump.conf >/dev/null 2>&1 || true
}

# Kernel descarta o dump em vez de gravar em disco.
_write_coredump_sysctl() {
  cat > /etc/sysctl.d/50-coredump.conf <<'EOF'
# MeuHypr: desativa a geracao de core dumps (arquivos core.*).
# "|/bin/false" faz o kernel descartar o dump em vez de gravar em disco.
kernel.core_pattern=|/bin/false
EOF
}

# Reforço via PAM: zera o limite de core para todos e remove regras conflitantes.
_write_coredump_limits() {
  rm -f /etc/security/limits.d/10-coredump-debian.conf \
        /etc/security/limits.d/20-coredump-debian.conf \
        /etc/security/limits.d/99-disable-coredump-igor.conf
  cat > /etc/security/limits.d/99-coredump.conf <<'EOF'
# MeuHypr: impede core dumps para todos os usuarios (defesa em profundidade).
*     soft  core  0
*     hard  core  0
root  soft  core  0
root  hard  core  0
EOF
}

# Tema GRUB "clean": só fundo + lista de boot (remove mensagens de ajuda).
# Repassa o fundo escolhido (ou vazio = imagem versionada do tema).
setup_grub_theme() {
  log "Aplicando tema GRUB (menu limpo)..."
  MEUHYPR_GRUB_BG="$GRUB_WALLPAPER" bash "$SYSTEM_SRC/scripts/setup-grub-theme.sh"
}

# Tema Plymouth "monoarch": splash de boot (só a bolinha girando, sem logo).
setup_plymouth_theme() {
  log "Aplicando tema Plymouth (splash de boot)..."
  bash "$SYSTEM_SRC/scripts/setup-plymouth-theme.sh"
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
  4. Driver NVIDIA (se aplicável): non-free + nvidia-driver
  5. Monitores: edite ~/.config/hypr/monitors.conf ou use hyprmoncfg (SwayNC 🖥️)
  6. Reinicie e faça login no SDDM (sessão Hyprland)

Apps opcionais (instale você mesmo conforme necessidade):
  Steam, Discord, pavucontrol, nwg-displays, nwg-look, etc.

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
  install_hyprmoncfg
  install_kew
  install_cargo_tools
  install_starship
  install_oh_my_zsh
  install_hypr_stack
  install_rofi_wayland
  install_nautilus_extension
  deploy_user_configs
  deploy_system_files
  configure_sddm_login
  post_install_notes
}

main "$@"
