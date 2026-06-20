#!/usr/bin/env bash
# Fecha o painel swaync (se estiver aberto).

swaync-client -cp -sw 2>/dev/null || true
