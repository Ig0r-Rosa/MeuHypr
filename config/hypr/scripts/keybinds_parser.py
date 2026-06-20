#!/usr/bin/env python3
import sys
import re
import os

def normalize_combo(combo):
    return combo.replace(" ", "").replace("\t", "")

def extract_combo(line):
    # Remove comments and whitespace
    line = re.sub(r'\s*#.*$', '', line).strip()
    
    if '=' not in line:
        return None
        
    try:
        rhs = line.split('=', 1)[1]
        parts = [p.strip() for p in rhs.split(',')]
        if len(parts) < 2:
            return None
            
        mods = parts[0]
        key = parts[1]
        return f"{mods},{key}"
    except Exception:
        return None

def parse_files(files):
    # Data structures to match original logic
    binding_map = {}        # combo -> effective line
    source_map = {}         # combo -> source file
    user_bind_map = {}      # combo -> user bind line
    unbound_user = {}       # combo -> True if explicitly unbound in user file
    seen_any_bind = {}      # combo -> True if seen
    default_seen = {}       # combo -> True if default bind exists
    
    # We assume the last file in the list is the user config (UserKeybinds.conf)
    # This matches the bash script logic where user_keybinds_conf is passed last
    if not files:
        return [], []
        
    user_conf_path = files[-1] if len(files) > 1 else None

    for file_path in files:
        if not os.path.exists(file_path):
            continue
            
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                for line in f:
                    line = line.rstrip('\n')
                    if not line or line.strip().startswith('#'):
                        continue
                        
                    is_bind = re.match(r'^\s*bind[a-z]*\s*=', line)
                    is_unbind = re.match(r'^\s*unbind\s*=', line)
                    
                    if is_bind:
                        combo_raw = extract_combo(line)
                        if not combo_raw:
                            continue
                        combo = normalize_combo(combo_raw)
                        seen_any_bind[combo] = True
                        
                        is_user_file = (file_path == user_conf_path)
                        
                        if not is_user_file:
                            default_seen[combo] = True
                            
                        # prefer user bind, else first seen
                        if combo not in source_map:
                            binding_map[combo] = line
                            source_map[combo] = file_path
                            
                        if is_user_file:
                            user_bind_map[combo] = line
                            binding_map[combo] = line
                            source_map[combo] = file_path
                            
                    elif is_unbind:
                        combo_raw = extract_combo(line)
                        if not combo_raw:
                            continue
                        combo = normalize_combo(combo_raw)
                        
                        if file_path == user_conf_path:
                            unbound_user[combo] = True
                            
                        # If unbind is found, we should remove the bind from our map
                        # so it doesn't show up in the menu.
                        if combo in binding_map:
                            del binding_map[combo]
                        if combo in source_map:
                            del source_map[combo]
                            
        except Exception as e:
            # Silently ignore read errors to mimic bash behavior or log to stderr
            sys.stderr.write(f"Error reading {file_path}: {e}\n")
            continue

    # Build results
    raw_keybinds = []
    missing_unbind_suggestions = []
    
    for combo in seen_any_bind:
        eff_line = binding_map.get(combo)
        src = source_map.get(combo)
        
        if not eff_line:
            continue
            
        raw_keybinds.append(eff_line)
        
        # Check for missing unbind suggestions
        # If user overrides a default but didn't unbind in user file
        if (src == user_conf_path and 
            combo in default_seen and 
            combo not in unbound_user):
            
            # Create suggestion: replace 'bind' with 'unbind'
            suggest = re.sub(r'^\s*bind[a-z]*', 'unbind', eff_line)
            missing_unbind_suggestions.append(suggest)
            
    return raw_keybinds, missing_unbind_suggestions

# Teclas e modificadores legíveis em português
KEY_LABELS = {
    "mouse_down": "scroll↓",
    "mouse_up": "scroll↑",
    "mouse:272": "botão esquerdo",
    "mouse:273": "botão direito",
    "$mainMod_L": "Super",
    "bracketleft": "[",
    "bracketright": "]",
    "equal": "=",
    "minus": "-",
    "period": ".",
    "comma": ",",
    "Return": "Enter",
    "Print": "Print",
    "tab": "Tab",
    "SPACE": "Espaço",
}

MOD_LABELS = {
    "SUPER": "Super",
    "CTRL": "Ctrl",
    "SHIFT": "Shift",
    "ALT": "Alt",
}

EXEC_LABELS = {
    "SuperDoubleFullscreen.sh": "Alternar tela cheia (duplo Super)",
    "RetileAfterDrag.sh": "Reintegrar janela após arrastar",
}

DISPATCHER_LABELS = {
    "movefocus": "Mover foco",
    "movewindow": "Mover janela",
    "resizewindow": "Redimensionar janela",
    "cyclenext": "Alternar janela",
    "bringactivetotop": "Trazer janela para frente",
    "killactive": "Fechar janela ativa",
    "togglegroup": "Alternar grupo",
    "changegroupactive": "Alternar janela no grupo",
    "moveintogroup": "Mover para o grupo",
    "moveoutofgroup": "Tirar janela do grupo",
    "movetoworkspace": "Mover para área de trabalho",
    "movetoworkspacesilent": "Mover silenciosamente para área",
    "workspace": "Ir para área de trabalho",
    "togglespecialworkspace": "Alternar área especial",
    "layoutmsg": "Layout",
}

DESC_PT = {
    "app launcher": "Launcher de apps",
    "open default browser": "Abrir navegador",
    "open kitty in nautilus": "Abrir kitty no Nautilus",
    "open terminal": "Abrir terminal",
    "file manager": "Gerenciador de arquivos",
    "searchable keybinds": "Buscar atalhos",
    "refresh bar and menus": "Atualizar barra e menus",
    "emoji menu": "Menu de emoji",
    "web search": "Busca na web",
    "toggle game mode": "Alternar modo jogo",
    "zoom in": "Aumentar zoom",
    "zoom out": "Diminuir zoom",
    "restore waybar": "Restaurar Waybar",
    "online music": "Música online",
    "select wallpaper": "Escolher papel de parede",
    "wallpaper effects": "Efeitos do wallpaper",
    "random wallpaper": "Wallpaper aleatório",
    "close active window": "Fechar janela ativa",
    "terminate active process": "Encerrar processo ativo",
    "quick settings menu": "Menu de configurações rápidas",
    "remove master": "Remover master",
    "cycle next window": "Alternar próxima janela",
    "janela anterior": "Janela anterior",
    "próxima janela": "Próxima janela",
    "bring active to top": "Trazer janela para frente",
    "volume up": "Aumentar volume",
    "volume down": "Diminuir volume",
    "volume up precise": "Aumentar volume (preciso)",
    "volume down precise": "Diminuir volume (preciso)",
    "toggle mic mute": "Alternar mute do microfone",
    "toggle mute": "Alternar mute",
    "sleep": "Suspender",
    "airplane mode": "Modo avião",
    "play/pause": "Reproduzir/pausar",
    "pause": "Pausar",
    "play": "Reproduzir",
    "next track": "Próxima faixa",
    "previous track": "Faixa anterior",
    "stop": "Parar",
    "toggle group": "Alternar grupo",
    "change active in group": "Alternar janela no grupo",
    "move left into group": "Mover para grupo à esquerda",
    "move right into group": "Mover para grupo à direita",
    "move active out of group": "Tirar janela do grupo",
    "focus left": "Focar à esquerda",
    "focus right": "Focar à direita",
    "focus up": "Focar acima",
    "focus down": "Focar abaixo",
    "add workspace": "Adicionar área de trabalho",
    "remove workspace": "Remover área de trabalho",
    "cycle monitor": "Alternar monitor",
    "move to special workspace": "Mover para área especial",
    "toggle special workspace": "Alternar área especial",
    "move to previous workspace": "Mover para área anterior",
    "move to next workspace": "Mover para área seguinte",
    "move silently to previous workspace": "Mover silenciosamente para área anterior",
    "move silently to next workspace": "Mover silenciosamente para área seguinte",
    "next workspace on monitor": "Próxima área no monitor",
    "previous workspace on monitor": "Área anterior no monitor",
    "window switcher": "Alternador de janelas",
    "toggle float window": "Alternar janela flutuante",
    "notification panel": "Painel de notificações",
    "powermenu": "Menu de energia",
    "abrir kitty no nautilus": "Abrir kitty no Nautilus",
    "alternador de janelas": "Alternador de janelas",
    "alternar janela flutuante": "Alternar janela flutuante",
    "painel de notificações": "Painel de notificações",
    "menu de energia": "Menu de energia",
    "captura de tela": "Captura de tela",
    "buscar atalhos": "Buscar atalhos",
}


def format_key_label(key):
    if key in KEY_LABELS:
        return KEY_LABELS[key]
    code_match = re.fullmatch(r"code:(\d+)", key)
    if code_match:
        code = int(code_match.group(1))
        digit_map = {10: "1", 11: "2", 12: "3", 13: "4", 14: "5",
                     15: "6", 16: "7", 17: "8", 18: "9", 19: "0"}
        return digit_map.get(code, str(code))
    return key


def format_mods_label(mods):
    mods = mods.replace("$mainMod", "SUPER")
    mods = re.sub(r"[ \t]+", "+", mods)
    parts = [MOD_LABELS.get(part, part) for part in mods.split("+") if part]
    return "+".join(parts)


def translate_description(desc):
    if not desc:
        return desc
    normalized = desc.strip().lower()
    if normalized in DESC_PT:
        return DESC_PT[normalized]

    patterns = [
        (r"^workspace (\d+)$", r"Área de trabalho \1"),
        (r"^move to workspace (\d+)$", r"Mover para área de trabalho \1"),
        (r"^move silently to workspace (\d+)$", r"Mover silenciosamente para área \1"),
    ]
    for pattern, repl in patterns:
        match = re.fullmatch(pattern, normalized, flags=re.I)
        if match:
            return re.sub(pattern, repl, desc.strip(), flags=re.I)
    return desc.strip()


def translate_fallback(dispatcher, params):
    if dispatcher == "exec" and params:
        script = os.path.basename(params.split()[0])
        if script in EXEC_LABELS:
            return EXEC_LABELS[script]
        return f"Executar {script}"

    if dispatcher in DISPATCHER_LABELS:
        label = DISPATCHER_LABELS[dispatcher]
        if params:
            if dispatcher in ("moveintogroup", "movefocus", "movewindow"):
                side = {"l": "esquerda", "r": "direita", "u": "cima", "d": "baixo"}.get(params.strip(), params)
                return f"{label} ({side})"
            if dispatcher in ("workspace", "movetoworkspace", "movetoworkspacesilent"):
                return f"{label} {params.strip()}"
        return label

    if params:
        return f"{dispatcher} {params}".strip()
    return dispatcher


def format_for_rofi(raw_binds):
    formatted_lines = []
    
    for line in raw_binds:
        # line is like "bind = MODS, KEY, DISPATCHER, PARAMS" or "bindd = ..."
        # Parsing logic from awk script:
        
        # 1. Cleaner binder
        match = re.match(r'^\s*(bind[a-z]*)\s*=(.*)', line)
        if not match:
            continue
            
        binder = match.group(1).replace(" ", "").replace("\t", "")
        rhs = match.group(2).strip()
        
        # "bind" ends in d, but doesn't have a description. "bindd" does.
        # Original script logic `index(binder, "d")>0` was likely buggy for "bind".
        # We'll assume strict check for bindd or similar if needed, 
        # but avoiding "bind" having a description is crucial for correct output.
        has_desc = binder in ("bindd", "bindld", "bindeld", "binded")

        # Split by comma regex (handling spaces)
        parts = [p.strip() for p in rhs.split(',')]
        
        if len(parts) < 2:
            continue
            
        mods = parts[0]
        key = parts[1]
        
        desc = ""
        dispatcher = ""
        params = ""
        
        start_idx = 0
        
        if has_desc:
            desc = parts[2] if len(parts) >= 3 else ""
            dispatcher = parts[3] if len(parts) >= 4 else ""
            start_idx = 4
        else:
            dispatcher = parts[2] if len(parts) >= 3 else ""
            start_idx = 3
            
        # Collect params
        remaining_parts = []
        if start_idx < len(parts):
            for i in range(start_idx, len(parts)):
                if parts[i]:
                    remaining_parts.append(parts[i])
        
        if remaining_parts:
            params = ", ".join(remaining_parts)
            
        combo_mods = format_mods_label(mods)
        combo_key = format_key_label(key)
        combo_str = f"{combo_mods}+{combo_key}" if combo_mods and combo_key else (combo_key or combo_mods)

        if has_desc and desc:
            label = translate_description(desc)
        elif dispatcher:
            label = translate_fallback(dispatcher, params)
        else:
            label = ""

        if label:
            formatted_lines.append(f"{combo_str} — {label}")
        else:
            formatted_lines.append(combo_str)
            
    return formatted_lines

def main():
    if len(sys.argv) < 2:
        # No files provided
        sys.exit(0)
        
    config_files = sys.argv[1:]
    
    binds, suggestions = parse_files(config_files)
    
    if not binds:
        print("Nenhum atalho encontrado.")
        sys.exit(1)
        
    formatted = format_for_rofi(binds)
    
    for line in formatted:
        print(line)
        
    # Handle suggestions (print to stderr or a specific file if needed, 
    # but the original script assigns it to a variable 'msg'.
    # To pass this back to bash, we might need a separate mechanism or just print to a known file.)
    if suggestions:
        import tempfile
        try:
            with tempfile.NamedTemporaryFile(mode='w', delete=False, prefix='hypr-unbind-suggestions-', suffix='.conf') as tf:
                tf.write('\n'.join(suggestions) + '\n')
                # We print a special marker line to stdout that the bash script can capture?
                # Or better, just print to stderr and let the user ignore it, 
                # OR, since the original script specifically puts it in the Rofi message,
                # we can print a special string at the END of stdout or to a side channel.
                
                # Let's decide to print the valid keybinds to stdout (for rofi).
                # And print the suggestion file path to a known location or specific fd if possible.
                # Simplest: Write to a fixed temp file location that the bash script checks.
                with open("/tmp/hypr_keybind_suggestions_file", "w") as sf:
                    sf.write(tf.name)
        except Exception:
            pass

if __name__ == "__main__":
    main()
