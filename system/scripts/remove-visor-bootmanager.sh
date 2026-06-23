#!/usr/bin/env bash
# Remove Visor/rEFInd e restaura GRUB (debian) + Windows no UEFI.

set -euo pipefail

ESP="${VISOR_ESP:-/boot/efi}"
log() { printf '[cleanup-boot] %s\n' "$*"; }

[[ "${EUID:-0}" -eq 0 ]] || { echo "Execute com sudo." >&2; exit 1; }

remove_systemd_hooks() {
  systemctl disable --now meuhypr-visor-boot-order.service 2>/dev/null || true
  rm -f /etc/systemd/system/meuhypr-visor-boot-order.service
  rm -f /etc/kernel/postinst.d/zz-meuhypr-visor-boot-order
  rm -f /usr/local/sbin/meuhypr-visor-boot-order /usr/local/bin/visor
  systemctl daemon-reload 2>/dev/null || true
}

remove_uefi_entry() {
  local label="$1"
  local num
  num="$(efibootmgr 2>/dev/null | grep -m1 "$label" | sed -n 's/^Boot\([0-9]*\).*/\1/p' || true)"
  [[ -n "$num" ]] || return 0
  efibootmgr -b "$num" -B >/dev/null 2>&1 || true
  log "Removida entrada UEFI: $label (Boot${num})"
}

restore_bootx64() {
  local boot_dir="$ESP/EFI/BOOT"
  local shim="$ESP/EFI/debian/shimx64.efi"
  local restored=0

  for bak in "$boot_dir/BOOTX64.EFI.grub-shim.bak" "$boot_dir/BOOTX64.EFI.linpus.bak"; do
    [[ -f "$bak" ]] || continue
    cp -a "$bak" "$boot_dir/BOOTX64.EFI"
    log "BOOTX64.EFI restaurado de $(basename "$bak")"
    restored=1
    break
  done

  if [[ "$restored" -eq 0 && -f "$shim" ]]; then
    cp -a "$shim" "$boot_dir/BOOTX64.EFI"
    log "BOOTX64.EFI restaurado do shim Debian"
  fi
}

set_grub_first() {
  local debian_num windows_num order
  debian_num="$(efibootmgr 2>/dev/null | grep -m1 'debian' | sed -n 's/^Boot\([0-9]*\).*/\1/p' || true)"
  windows_num="$(efibootmgr 2>/dev/null | grep -m1 'Windows Boot Manager' | sed -n 's/^Boot\([0-9]*\).*/\1/p' || true)"
  [[ -n "$debian_num" ]] || { log "Entrada debian não encontrada."; return 1; }
  order="$debian_num"
  [[ -n "$windows_num" ]] && order="${order},${windows_num}"
  order="${order},2001,2002,2003"
  efibootmgr -o "$order" >/dev/null
  log "Ordem de boot: debian, Windows"
}

main() {
  remove_systemd_hooks
  remove_uefi_entry "Visor"
  while efibootmgr 2>/dev/null | grep -q 'rEFInd'; do
    remove_uefi_entry "rEFInd"
  done
  while [[ "$(efibootmgr 2>/dev/null | grep -c 'Windows Boot Manager' || echo 0)" -gt 1 ]]; do
    num="$(efibootmgr 2>/dev/null | grep 'Windows Boot Manager' | tail -1 | sed -n 's/^Boot\([0-9]*\).*/\1/p')"
    [[ -n "$num" ]] && efibootmgr -b "$num" -B >/dev/null 2>&1
    log "Removida entrada Windows duplicada (Boot${num})"
  done
  rm -rf "$ESP/EFI/visor" "$ESP/EFI/refind"
  rm -f /boot/refind_linux.conf
  restore_bootx64
  set_grub_first
  DEBIAN_FRONTEND=noninteractive apt-get remove -y refind 2>/dev/null || true
  log "Limpeza concluída. Reinicie para validar o GRUB."
}

main "$@"
