#!/usr/bin/env python3
"""Trunca títulos longos de menuentry/submenu no grub.cfg, com reticências.

O GRUB não tem reticências nativas: ele corta o texto no limite da caixa.
Para exibir "Nome muito long..." truncamos o próprio título no grub.cfg.
Deve ser reaplicado após cada update-grub (o setup-grub-theme.sh já faz).

Uso: grub_truncate_titles.py [max_chars] [caminho_grub.cfg]
"""

import os
import re
import sys

DEFAULT_MAX = int(os.environ.get("MEUHYPR_GRUB_TITLE_MAX", "26"))
ELLIPSIS = "..."
# Casa "menuentry '...'" ou 'menuentry "..."' e captura o título (grupo 3).
ENTRY_RE = re.compile(r'^(\s*(?:menuentry|submenu)\s+)(["\'])(.*?)(\2)(.*)$')


def truncate(title, max_chars):
    """Corta o título e adiciona reticências se passar do limite."""
    if len(title) <= max_chars:
        return title
    keep = max(1, max_chars - len(ELLIPSIS))
    return title[:keep].rstrip() + ELLIPSIS


def process_line(line, max_chars):
    """Trunca o título de uma linha de menuentry/submenu (se houver)."""
    match = ENTRY_RE.match(line)
    if not match:
        return line
    new_title = truncate(match.group(3), max_chars)
    return (f"{match.group(1)}{match.group(2)}{new_title}"
            f"{match.group(4)}{match.group(5)}")


def main():
    max_chars = int(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_MAX
    path = sys.argv[2] if len(sys.argv) > 2 else "/boot/grub/grub.cfg"

    with open(path, encoding="utf-8") as fh:
        original = fh.readlines()
    updated = [process_line(l.rstrip("\n"), max_chars) + "\n" for l in original]

    if updated != original:
        with open(path, "w", encoding="utf-8") as fh:
            fh.writelines(updated)
    print(f"Títulos do GRUB truncados em {max_chars} caracteres: {path}")


if __name__ == "__main__":
    main()
