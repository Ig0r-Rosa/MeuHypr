#!/usr/bin/env bash
# Nautilus: "Abrir no terminal" usa kitty no diretório selecionado.
# Apenas configura — não abre o Nautilus.

KITTY_BIN="$(command -v kitty || true)"
[[ -z "$KITTY_BIN" ]] && exit 0

# Extensão nautilus-open-any-terminal (requer python3-nautilus).
if gsettings list-schemas 2>/dev/null | grep -q 'com.github.stunkymonkey.nautilus-open-any-terminal'; then
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal custom
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal custom-local-command \
    "${KITTY_BIN} --directory %s"
  gsettings set com.github.stunkymonkey.nautilus-open-any-terminal use-generic-terminal-name true
fi

# Reserva para o menu nativo do Nautilus (quando disponível).
mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}"
printf '%s\n' 'kitty.desktop' >"${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list"
