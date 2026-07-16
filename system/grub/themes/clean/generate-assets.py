#!/usr/bin/env python3
"""Gera os assets E o theme.txt do tema GRUB do MeuHypr (dinâmico por Nº de itens).

Requer Pillow (PIL). Uso:
    python3 generate-assets.py                # auto-detecta itens/resolução
    MEUHYPR_GRUB_ITEMS=3 python3 generate-assets.py
    python3 generate-assets.py 3 1920 1080    # itens, largura, altura

Por que gerar o theme.txt aqui?
  O GRUB 2.12 força a lista (boot_menu) a reservar no mínimo 3 slots
  (num_items=3 fixo no código). Por isso o fundo escuro NÃO é da lista, e
  sim uma imagem separada (panelbg.png) dimensionada exatamente para os N
  itens. Como a geometria (altura do bloco, centralização) depende de N e
  da resolução, o theme.txt é calculado e escrito junto com a imagem.
"""

import os
import re
import sys

from PIL import Image, ImageDraw

OUT_DIR = os.path.dirname(os.path.abspath(__file__))

# --- Aparência (ajuste aqui) ------------------------------------------------
ITEM_HEIGHT = 40                     # altura da linha de cada item
ITEM_SPACING = 10                    # espaço vertical entre itens
RADIUS = 8                           # arredondamento do realce/itens
PANEL_PAD = 12                       # respiro do painel ao redor dos itens
PANEL_HPAD = 15                      # respiro horizontal do painel
MENU_LEFT_FRAC = 0.39                # posição/largura da lista (fração da tela)
MENU_WIDTH_FRAC = 0.22
PANEL_FILL = (12, 14, 20, 150)       # painel escuro translúcido
SELECTED_FILL = (56, 139, 253, 235)  # realce azul
# ---------------------------------------------------------------------------


def detect_screen():
    """Lê GRUB_GFXMODE (LxA) de /etc/default/grub; cai para 1920x1080."""
    try:
        with open("/etc/default/grub", encoding="utf-8") as fh:
            m = re.search(r"^\s*GRUB_GFXMODE=\"?(\d+)x(\d+)", fh.read(), re.M)
            if m:
                return int(m.group(1)), int(m.group(2))
    except OSError:
        pass
    return 1920, 1080


def detect_item_count():
    """Nº de itens: env MEUHYPR_GRUB_ITEMS, senão conta no grub.cfg, senão 2."""
    env = os.environ.get("MEUHYPR_GRUB_ITEMS")
    if env and env.isdigit():
        return max(1, int(env))
    try:
        with open("/boot/grub/grub.cfg", encoding="utf-8") as fh:
            n = len(re.findall(r"^\s*menuentry ", fh.read(), re.M))
            if n:
                return n
    except OSError:
        pass
    return 2


def rounded_rect(width, height, radius, fill):
    """Retângulo arredondado RGBA (cantos transparentes)."""
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle(
        [0, 0, width - 1, height - 1], radius=radius, fill=fill
    )
    return img


def solid(width, height, fill):
    """Bloco sólido (bordas/centro esticáveis do 9-slice)."""
    return Image.new("RGBA", (width, height), fill)


def save_nine_slice(prefix, radius, fill):
    """Fatia um retângulo arredondado em 9 partes no padrão do GRUB."""
    full = rounded_rect(2 * radius, 2 * radius, radius, fill)
    corners = {
        "nw": (0, 0, radius, radius),
        "ne": (radius, 0, 2 * radius, radius),
        "sw": (0, radius, radius, 2 * radius),
        "se": (radius, radius, 2 * radius, 2 * radius),
    }
    for name, box in corners.items():
        full.crop(box).save(f"{OUT_DIR}/{prefix}_{name}.png")
    solid(1, radius, fill).save(f"{OUT_DIR}/{prefix}_n.png")
    solid(1, radius, fill).save(f"{OUT_DIR}/{prefix}_s.png")
    solid(radius, 1, fill).save(f"{OUT_DIR}/{prefix}_w.png")
    solid(radius, 1, fill).save(f"{OUT_DIR}/{prefix}_e.png")
    solid(1, 1, fill).save(f"{OUT_DIR}/{prefix}_c.png")


def save_transparent_cover(prefix, screen):
    """Caixa 9-slice transparente (centro do tamanho da tela) p/ terminal-box."""
    transparent = (0, 0, 0, 0)
    edge = Image.new("RGBA", (1, 1), transparent)
    for name in ("nw", "ne", "sw", "se", "n", "s", "e", "w"):
        edge.save(f"{OUT_DIR}/{prefix}_{name}.png")
    Image.new("RGBA", screen, transparent).save(f"{OUT_DIR}/{prefix}_c.png")


def compute_layout(n, screen_w, screen_h):
    """Geometria (em px) da lista e do painel para N itens, centralizados."""
    step = ITEM_HEIGHT + ITEM_SPACING
    # Altura real do bloco: cada item ocupa ITEM_HEIGHT + 2*RADIUS (bordas do
    # realce); o último item soma a borda inferior.
    items_h = (n - 1) * step + (ITEM_HEIGHT + 2 * RADIUS)
    menu_left = round(MENU_LEFT_FRAC * screen_w)
    menu_width = round(MENU_WIDTH_FRAC * screen_w)
    menu_top = round(screen_h / 2 - items_h / 2)
    # Altura da lista: garante num_shown >= N e respeita o mínimo de 3 slots.
    menu_height = max(n * step + 14, 3 * ITEM_HEIGHT + 2 * ITEM_SPACING + 2 * RADIUS)
    return {
        "items_h": items_h,
        "menu_left": menu_left,
        "menu_width": menu_width,
        "menu_top": menu_top,
        "menu_height": menu_height,
        "panel_left": menu_left - PANEL_HPAD,
        "panel_top": menu_top - PANEL_PAD,
        "panel_width": menu_width + 2 * PANEL_HPAD,
        "panel_height": items_h + 2 * PANEL_PAD,
    }


def write_theme(lay, n, screen):
    """Escreve o theme.txt com as coordenadas calculadas."""
    theme = f"""# Tema GRUB do MeuHypr — GERADO por generate-assets.py (não editar à mão).
# Itens={n}  Resolução={screen[0]}x{screen[1]}
# O painel escuro é uma imagem separada (panelbg.png) dimensionada para os
# {n} itens, pois o GRUB 2.12 força a lista a reservar no mínimo 3 slots.

title-text: ""
desktop-image: "background.jpg"
desktop-image-scale-method: "stretch"

# Console de boot transparente cobrindo a tela: sem retângulo preto.
terminal-box: "terminal_*.png"
terminal-left: "0"
terminal-top: "0"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {{
  left = {lay['menu_left']}
  top = {lay['menu_top']}
  width = {lay['menu_width']}
  height = {lay['menu_height']}

  item_font = "MeuHypr Menu Regular 30"
  selected_item_font = "MeuHypr Menu Regular 30"
  item_color = "#cbd5e1"
  selected_item_color = "#ffffff"

  item_height = {ITEM_HEIGHT}
  item_spacing = {ITEM_SPACING}
  item_padding = 0
  item_icon_space = 0
  icon_width = 0
  icon_height = 0
  scrollbar = false

  item_pixmap_style = "item_*.png"
  selected_item_pixmap_style = "selected_*.png"
}}

# Painel atrás dos itens (DEPOIS do boot_menu = pintado atrás dele).
+ image {{
  left = {lay['panel_left']}
  top = {lay['panel_top']}
  width = {lay['panel_width']}
  height = {lay['panel_height']}
  file = "panelbg.png"
}}
"""
    with open(f"{OUT_DIR}/theme.txt", "w", encoding="utf-8") as fh:
        fh.write(theme)


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else detect_item_count()
    screen = (
        (int(sys.argv[2]), int(sys.argv[3]))
        if len(sys.argv) > 3
        else detect_screen()
    )
    lay = compute_layout(n, *screen)

    rounded_rect(lay["panel_width"], lay["panel_height"], 22, PANEL_FILL).save(
        f"{OUT_DIR}/panelbg.png"
    )
    save_nine_slice("selected", RADIUS, SELECTED_FILL)
    save_nine_slice("item", RADIUS, (0, 0, 0, 0))
    save_transparent_cover("terminal", screen)
    write_theme(lay, n, screen)
    print(f"Tema GRUB gerado: {n} itens, {screen[0]}x{screen[1]}, "
          f"painel {lay['panel_width']}x{lay['panel_height']}")


if __name__ == "__main__":
    main()
