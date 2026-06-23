#!/usr/bin/env bash
# Atualiza vmlinuz/initrd na ESP após upgrade do kernel Debian.

set -euo pipefail

ESP="${VISOR_ESP:-/boot/efi}"
VISOR_REL="EFI/visor"

latest_kernel_version() {
  ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|.*/vmlinuz-||'
}

[[ "${EUID:-0}" -eq 0 ]] || { echo "Execute com sudo." >&2; exit 1; }
kernel_ver="$(latest_kernel_version)"
[[ -n "$kernel_ver" ]] || { echo "Kernel não encontrado." >&2; exit 1; }

cp -f "/boot/vmlinuz-${kernel_ver}" "$ESP/$VISOR_REL/vmlinuz"
cp -f "/boot/initrd.img-${kernel_ver}" "$ESP/$VISOR_REL/initrd.img"
echo "Kernel ${kernel_ver} copiado para $ESP/$VISOR_REL/"
