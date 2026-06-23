# MeuHypr

Backup completo do ambiente **Hyprland + SDDM** personalizado (baseado nos dotfiles [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)), pronto para reinstalar em outra máquina Debian.

> **Wallpaper padrão:** `assets/wallpapers/matrix-default.jpg` (SDDM + fallback Hyprland). Wallpapers extras em `~/Pictures/wallpapers/`.

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
| `assets/wallpapers/` | Wallpaper padrão Matrix (SDDM + fallback) |
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

O script instala **apenas o essencial** para a sessão Hyprland funcionar com os atalhos configurados:

1. **Sessão:** Hyprland (compilado), waybar, kitty, swaync, wlogout, fuzzel, swww, portals
2. **Atalhos:** Rofi Wayland (Super+D, Super+S, Super+H), grim/slurp, cliphist
3. **TUIs:** yazi, btop, nvtop, cmatrix, bluetui (Cargo), hyprmoncfg, nmtui
4. **Navegador:** firefox-esr (Super+B — remova com `apt` se preferir outro)
5. **Boot:** Visor Boot Manager com dual-boot Linux/Windows e wallpaper `espaco_1`
5. Copia configs para `~/.config/` e instala tema SDDM `noc-sddm`

**Não** instala automaticamente: Steam, Discord, Nautilus, pavucontrol, nwg-displays, nwg-look, etc. Instale depois conforme sua necessidade.

### Só reaplicar configs (sem reinstalar pacotes)

```bash
sudo MEUHYPR_CONFIG_ONLY=1 ./install.sh
```

### Pós-instalação manual

1. **Wallpapers:** padrão Matrix em `assets/wallpapers/`; extras em `~/Pictures/wallpapers/` — use `Super+W` para escolher
2. **SDDM:** fundo Matrix em `sddm/themes/noc-sddm/backgrounds/matrix.jpg` (aplicado no install)
3. **Fonte:** [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) → `~/.local/share/fonts/`
4. **Monitores:** edite `~/.config/hypr/monitors.conf` ou use **hyprmoncfg** (botão 🖥️ no SwayNC)
5. Reinicie e escolha **Hyprland** no SDDM

### Apps opcionais (instalação manual)

| App | Comando sugerido | Atalho / uso |
|-----|------------------|--------------|
| Nautilus | `sudo apt install nautilus` | Super+E (fallback automático para yazi) |
| pavucontrol | `sudo apt install pavucontrol` | Mixer de áudio GUI |
| Steam | `sudo apt install steam` + `setup-steam-hyprland.sh` | Scripts em `hypr/scripts/Steam*.sh` |
| nwg-displays | via repositório nwg ou AUR equivalente | Menu KooL Quick Settings |
| Discord, etc. | flatpak / snap / apt | Pelo launcher Super+D |

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
| rofi (Wayland) | Launcher Super+D, busca Super+S, atalhos Super+H |
| fuzzel | Alternador de janelas Super+J |
| swaync | Centro de notificações Super+N |
| wlogout | Menu de energia Super+Alt+Delete |
| swww | Daemon de wallpaper |

### Terminal, arquivos e navegador

| Pacote | Função |
|--------|--------|
| kitty | Terminal padrão (`Super+Return`) |
| yazi (Cargo) | Gerenciador TUI (`Super+E`, waybar 📑) |
| firefox-esr | Navegador padrão (`Super+B`, waybar 🧭) |
| zsh + starship | Shell com prompt customizado |

### TUIs e monitoramento

| Pacote / binário | Função |
|------------------|--------|
| btop, nvtop | Monitor de sistema (waybar 📊) |
| cmatrix | Efeito Matrix (waybar 🌎) |
| bluetui (Cargo) | Bluetooth Super+; / SwayNC 🌀 |
| nmtui | Rede Super+ç / SwayNC 🌐 |
| hyprmoncfg | Layout de monitores SwayNC 🖥️ |

### Áudio, rede e energia

| Pacote | Função |
|--------|--------|
| pipewire, wireplumber | Áudio |
| pamixer, playerctl | Atalhos de volume/mídia |
| network-manager, nmtui | Rede |
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
| fonts-noto, fonts-firacode | Fontes base |

### Login

| Pacote | Função |
|--------|--------|
| sddm | Gerenciador de login |
| noc-sddm (este repo) | Tema SDDM personalizado |

### Boot (UEFI)

| Componente | Função |
|------------|--------|
| [Visor Boot Manager](https://github.com/IO-ZetZor/Visor-BootManager) | Menu gráfico de boot (Linux + Windows), estilo minimalista |
| `system/scripts/setup-visor-bootmanager.sh` | Compila, instala na ESP e define Visor como boot padrão |
| `system/visor/backgrounds/espaco_1.png` | Wallpaper do menu de boot |

Instalação isolada (sem reinstalar o Hyprland):

```bash
sudo /caminho/MeuHypr/system/scripts/setup-visor-bootmanager.sh
```

Pular no `install.sh` completo: `sudo MEUHYPR_SKIP_VISOR=1 ./install.sh`

---

## Atalhos de teclado

`Super` = tecla Windows. Atalhos desativados na config **não** aparecem abaixo.

### Aplicativos e launcher

| Atalho | Ação |
|--------|------|
| `Super+D` | Launcher de apps (Rofi, grid central) |
| `Super+Shift+D` | Apps ocultos no launcher |
| `Super+Return` | Abrir terminal (kitty) |
| `Super+E` | yazi (ou Nautilus se instalado) |
| `Super+B` | Abrir navegador padrão (Firefox) |
| `Super+A` | Kitty no Nautilus ou overview |
| `Super+L` | Abrir lixeira no Nautilus (requer Nautilus) |
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
| 🌎 | cmatrix em nova área de trabalho |
| 🚀 | Launcher Rofi |
| Hora / Data | Apenas exibição |
| 🟢/⚪ | Áreas de trabalho — clique para ir; scroll para navegar |
| ➕ | Criar nova área de trabalho |
| 🧭 | Navegador padrão (igual Super+B) |
| 📜 | Terminal |
| 📑 | yazi (gerenciador TUI) |
| 📊 | Nova área com btop + nvtop |
| 🎮 | Modo jogo |
| ⚙️ | Painel SwayNC (clique direito: DND) |

---

## SwayNC — painel de notificações

Abra com `Super+N`. Botões rápidos no topo:

| Botão | Ação |
|-------|------|
| 🖥️ | hyprmoncfg (layout de monitores) |
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
| `~/.config/hypr/monitors.conf` | Monitores (hyprmoncfg ou edição manual) |
| `~/.config/waybar/config` + `style.css` | Barra superior |

---

## Apps padrão

Definidos em `UserConfigs/01-UserDefaults.conf`:

- **Terminal:** kitty  
- **Arquivos:** yazi (Nautilus opcional)  
- **Navegador:** firefox-esr (via APT)  
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
