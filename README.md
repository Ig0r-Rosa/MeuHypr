# MeuHypr

Backup completo do ambiente **Hyprland + SDDM** personalizado (baseado nos dotfiles [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)), pronto para reinstalar em outra máquina Debian.

> **Wallpapers não estão incluídos.** Após instalar, coloque suas imagens em `~/Pictures/wallpapers/` e configure o SDDM em `sddm/themes/noc-sddm/theme.conf`.

---

## O que está incluído

| Pasta | Conteúdo |
|-------|----------|
| `config/hypr/` | Hyprland, scripts, regras de janela, wallust |
| `config/waybar/` | Barra superior minimalista (Igor Essential) |
| `config/rofi/` | Launcher Super+D, menu de energia, temas Wallust |
| `config/swaync/` | Painel de notificações |
| `config/kitty/` | Terminal sem decoração, opacidade no fundo |
| `config/wlogout/` | Menu de energia (Super+Alt+Delete) |
| `config/wallust/` | Geração de cores a partir do wallpaper |
| `config/gtk-*`, `qt*ct`, `fuzzel/` | Temas GTK/Qt e alternador de janelas |
| `config/starship.toml` | Prompt do Zsh |
| `system/` | SDDM, sessão Wayland e wrapper `hyprland-session` |
| `sddm/themes/noc-sddm/` | Tema SDDM minimalista personalizado |

---

## Requisitos

- **Debian 13 (trixie)** ou similar
- GPU NVIDIA híbrida (config em `UserConfigs/ENVariables.conf` — ajuste se necessário)
- Teclado **ABNT2** (`UserConfigs/UserSettings.conf`)
- Usuário com sudo

---

## Instalação rápida

```bash
cd MeuHypr
chmod +x install.sh
sudo ./install.sh
```

O script:

1. Instala pacotes APT (waybar, kitty, swww, swaync, etc.)
2. Compila **Hyprland**, **hyprsunset** e **Rofi Wayland**
3. Instala **wallust**, **bluetui** (Cargo) e **starship**
4. Copia configs para `~/.config/`
5. Instala tema SDDM `noc-sddm` e sessão Hyprland

### Só reaplicar configs (sem reinstalar pacotes)

```bash
sudo MEUHYPR_CONFIG_ONLY=1 ./install.sh
```

### Pós-instalação manual

1. **Wallpapers:** `~/Pictures/wallpapers/` — use `Super+W` para escolher
2. **SDDM:** edite `background=` em `/usr/share/sddm/themes/noc-sddm/theme.conf`
3. **Fonte:** [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) → `~/.local/share/fonts/`
4. **Monitores:** `nwg-displays` → gera `~/.config/hypr/monitors.conf`
5. Reinicie e escolha **Hyprland** no SDDM

---

## Dependências (pacotes e apps)

### Compositor e ecossistema Hypr

| Pacote / binário | Função |
|------------------|--------|
| Hyprland | Compositor Wayland (compilado em `/usr/local/bin`) |
| hyprsunset | Filtro de luz noturna |
| hyprctl | Controle do compositor |
| xdg-desktop-portal-hyprland | Portals (screenshot, etc.) |

### Barra, launcher e notificações

| Pacote | Função |
|--------|--------|
| waybar | Barra superior |
| rofi (Wayland) | Launcher Super+D |
| fuzzel | Alternador de janelas Super+J |
| swaync | Centro de notificações Super+N |
| wlogout | Menu de energia Super+Alt+Delete |
| swww | Daemon de wallpaper |

### Terminal e arquivos

| Pacote | Função |
|--------|--------|
| kitty | Terminal padrão (`Super+Return`) |
| nautilus | Gerenciador de arquivos (`Super+E`) |
| zsh + starship | Shell com prompt customizado |

### Áudio, rede e energia

| Pacote | Função |
|--------|--------|
| pipewire, wireplumber | Áudio |
| pamixer, playerctl | Atalhos de volume/mídia |
| pavucontrol | Mixer (via painel SwayNC) |
| network-manager, nm-applet | Rede |
| nmtui | Super+ç — utilitário de rede |
| bluetui | Super+; — Bluetooth (Cargo) |
| brightnessctl | Brilho máximo no boot |

### Captura e clipboard

| Pacote | Função |
|--------|--------|
| grim, slurp | Screenshot (`Print`) |
| wl-clipboard, cliphist | Histórico de clipboard |

### Temas e aparência

| Pacote | Função |
|--------|--------|
| wallust | Cores dinâmicas do wallpaper |
| qt5ct, qt6ct, kvantum | Apps Qt |
| nwg-displays, nwg-look | Monitores e temas GTK |
| fonts-noto, fonts-firacode | Fontes base |

### Login

| Pacote | Função |
|--------|--------|
| sddm | Gerenciador de login |
| noc-sddm (este repo) | Tema SDDM personalizado |

---

## Atalhos de teclado

`Super` = tecla Windows. Atalhos desativados na config **não** aparecem abaixo.

### Aplicativos e launcher

| Atalho | Ação |
|--------|------|
| `Super+D` | Launcher de apps (Rofi, grid central) |
| `Super+Shift+D` | Apps ocultos no launcher |
| `Super+Return` | Abrir terminal (kitty) |
| `Super+E` | Gerenciador de arquivos (Nautilus) |
| `Super+B` | Abrir navegador padrão |
| `Super+A` | Kitty no Nautilus ou overview |
| `Super+L` | Abrir lixeira no Nautilus |
| `Super+J` | Alternador de janelas (Fuzzel) |
| `Super+S` | Busca web (Rofi) |
| `Super+H` | Buscar atalhos disponíveis |
| `Super+Alt+E` | Menu de emoji |
| `Super+Alt+R` | Recarregar Waybar e menus |

### Janelas

| Atalho | Ação |
|--------|------|
| `Super+Q` | Fechar janela ativa |
| `Super+Shift+Q` | Encerrar processo da janela |
| `Super+Space` | Alternar janela flutuante (reduz/centraliza) |
| `Super+←` / `Super+→` | Janela anterior / próxima na área atual |
| `Alt+Tab` | Alternar janelas |
| `Super+Ctrl+Tab` | Alternar janela dentro do grupo |
| `Super+Ctrl+H` | Tirar janela do grupo |
| `Super+Ctrl+K` / `Super+Ctrl+L` | Mover janela para grupo (esq/dir) |

### Áreas de trabalho

| Atalho | Ação |
|--------|------|
| `Super+1` … `Super+0` | Ir para área 1–10 |
| `Super+Shift+1` … `Super+0` | Mover janela para área 1–10 |
| `Super+Ctrl+1` … `Super+0` | Mover silenciosamente para área |
| `Super+Shift+[` / `Super+Shift+]` | Mover janela para área anterior/próxima |
| `Super+=` / `Super+-` | Criar / remover área de trabalho |
| `Super+Scroll` / `Super+,` / `Super+.` | Navegar entre áreas do monitor |
| `Super+Shift+Tab` | Alternar monitor |
| `Super+U` | Área especial (scratchpad) |
| `Super+Shift+U` | Mover janela para área especial |

### Wallpaper e visual

| Atalho | Ação |
|--------|------|
| `Super+W` | Selecionar wallpaper |
| `Super+Shift+W` | Efeitos de wallpaper |
| `Ctrl+Alt+W` | Wallpaper aleatório |
| `Super+Shift+G` | Modo jogo |
| `Super+Shift+B` | Restaurar Waybar |
| `Super+Alt+Scroll` | Zoom do cursor |

### Sistema, rede e energia

| Atalho | Ação |
|--------|------|
| `Super+N` | Painel de notificações (SwayNC) |
| `Super+Alt+Delete` | Menu de energia (logout/reiniciar/desligar) |
| `Super+ç` | nmtui (rede) no terminal |
| `Super+;` | bluetui (Bluetooth) no terminal |
| `Print` | Captura de tela (selecionar área → clipboard) |
| `Super+Ctrl+D` | Remover master (layout) |

### Teclas de mídia e hardware

| Atalho | Ação |
|--------|------|
| `XF86AudioRaiseVolume` / `LowerVolume` | Volume ± |
| `Alt+XF86AudioRaise/LowerVolume` | Volume ± preciso |
| `XF86AudioMute` | Mudo |
| `XF86AudioMicMute` | Mudo do microfone |
| `XF86AudioPlay/Pause/Next/Prev` | Controles de mídia |
| `XF86Sleep` | Suspender |
| `XF86Rfkill` | Modo avião |

### Mouse

| Atalho | Ação |
|--------|------|
| `Super+arrastar` | Mover janela |
| `Super+botão direito+arrastar` | Redimensionar janela |
| Ao soltar após arrastar | Reintegra janela ao layout (tile) |

---

## Waybar — cliques na barra

| Ícone | Ação |
|-------|------|
| 📅 | Calendário (`Super` implícito via script) |
| Hora / Data | Apenas exibição |
| 🟢/⚪ | Áreas de trabalho — clique para ir; scroll para navegar |
| ➕ | Criar nova área de trabalho |
| 🚀 | Launcher Rofi |
| 📜 | Terminal |
| 📑 | Nautilus |
| ⚙️ | Painel SwayNC (clique direito: DND) |

---

## SwayNC — painel de notificações

Abra com `Super+N`. Botões rápidos no topo:

| Botão | Ação |
|-------|------|
| 🎮 | Modo jogo |
| 🌀 | bluetui (Bluetooth) |
| 🌐 | nmtui (rede) |
| ⚡ | Menu de energia (wlogout) |

---

## wlogout — menu de energia

Aberto com `Super+Alt+Delete`:

| Tecla | Ação |
|-------|------|
| `E` | Logout |
| `R` | Reiniciar |
| `S` | Desligar |

---

## Estrutura de personalização

Edite preferencialmente estes arquivos (não serão sobrescritos por updates genéricos):

| Arquivo | O que muda |
|---------|------------|
| `~/.config/hypr/UserConfigs/UserKeybinds.conf` | Atalhos |
| `~/.config/hypr/UserConfigs/UserSettings.conf` | Layout de teclado, gaps gerais |
| `~/.config/hypr/UserConfigs/UserDecorations.conf` | Bordas vermelhas, blur, opacidade |
| `~/.config/hypr/UserConfigs/UserAnimations.conf` | Animações |
| `~/.config/hypr/UserConfigs/WindowRules.conf` | Regras de janelas |
| `~/.config/hypr/monitors.conf` | Monitores (via nwg-displays) |
| `~/.config/waybar/config` + `style.css` | Barra superior |

---

## Apps padrão

Definidos em `UserConfigs/01-UserDefaults.conf`:

- **Terminal:** kitty  
- **Arquivos:** nautilus  
- **Busca:** Google (`Super+S`)

---

## Idle

- Brilho da tela fixo no máximo ao iniciar (`brightnessctl set 100%`)
- Sem bloqueio de tela por inatividade
- `swhkd` está **desabilitado** (interceptava a tecla Super)

---

## Créditos

- Base: [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)
- Hyprland: [hyprwm/Hyprland](https://github.com/hyprwm/Hyprland)
- Tema SDDM `noc-sddm`: personalizado localmente

---

## Licença

Configs derivados de projetos open source (KooLit/Hyprland). Use e adapte livremente.
