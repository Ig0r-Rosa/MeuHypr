#!/usr/bin/env bash
# Instala o Visor Boot Manager (substitui GRUB como menu de boot UEFI).
# Repositório: https://github.com/IO-ZetZor/Visor-BootManager

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VISOR_SRC="${VISOR_BUILD_DIR:-/tmp/visor-bootmanager-build}"
VISOR_REPO="${VISOR_REPO_URL:-https://github.com/IO-ZetZor/Visor-BootManager.git}"
VISOR_COMMIT="${VISOR_COMMIT:-01f64ea}"
VISOR_REL="EFI/visor"
ESP="${VISOR_ESP:-}"

log() { printf '\n[Visor] %s\n' "$*"; }
die() { printf '[Visor] ERRO: %s\n' "$*" >&2; exit 1; }

need_root() {
  [[ "${EUID:-0}" -eq 0 ]] || die "Execute com sudo."
}

install_build_deps() {
  log "Dependências de compilação..."
  apt-get update -qq
  apt-get install -y gnu-efi build-essential git efibootmgr python3-pil
}

detect_esp() {
  local m p
  if [[ -n "$ESP" ]]; then
    echo "$ESP"
    return 0
  fi
  for m in /boot/efi /efi /boot; do
    [[ -d "$m" ]] || continue
    findmnt -no FSTYPE "$m" 2>/dev/null | grep -qx vfat || continue
    echo "$m"
    return 0
  done
  p="$(bootctl --print-esp-path 2>/dev/null || true)"
  [[ -n "$p" && -d "$p" ]] && { echo "$p"; return 0; }
  die "ESP não encontrada. Use VISOR_ESP=/boot/efi"
}

clone_and_build_visor() {
  if [[ -f "$VISOR_SRC/visor_x64.efi" && "${VISOR_SKIP_BUILD:-0}" == "1" ]]; then
    log "Usando build existente em $VISOR_SRC"
    return 0
  fi
  log "Compilando Visor Boot Manager (${VISOR_COMMIT})..."
  rm -rf "$VISOR_SRC"
  git clone "$VISOR_REPO" "$VISOR_SRC"
  git -C "$VISOR_SRC" checkout "$VISOR_COMMIT"
  make -C "$VISOR_SRC" --no-print-directory
  [[ -f "$VISOR_SRC/visor_x64.efi" ]] || die "visor_x64.efi não gerado."
}

sync_kernel_to_esp() {
  local esp="$1"
  local kernel_ver="$2"
  log "Copiando kernel e initrd para a ESP..."
  cp -f "/boot/vmlinuz-${kernel_ver}" "$esp/$VISOR_REL/vmlinuz"
  cp -f "/boot/initrd.img-${kernel_ver}" "$esp/$VISOR_REL/initrd.img"
}

latest_kernel_version() {
  ls -1 /boot/vmlinuz-* 2>/dev/null | sort -V | tail -1 | sed 's|.*/vmlinuz-||'
}

root_partuuid() {
  blkid -s PARTUUID -o value "$(findmnt -no SOURCE /)"
}

linux_cmdline_from_grub() {
  local line
  line="$(grep -m1 '^[[:space:]]*linux[[:space:]]' /boot/grub/grub.cfg 2>/dev/null || true)"
  if [[ -n "$line" ]]; then
    echo "$line" | sed -E 's/^[[:space:]]*linux[[:space:]]+\/boot\/vmlinuz-[^[:space:]]+[[:space:]]*//'
    return
  fi
  local root_uuid
  root_uuid="$(findmnt -no UUID /)"
  # shellcheck source=/dev/null
  source /etc/default/grub 2>/dev/null || true
  echo "root=UUID=${root_uuid} ro ${GRUB_CMDLINE_LINUX_DEFAULT:-quiet}"
}

write_boot_conf() {
  local dest="$1" kernel_ver partuuid cmdline template out
  kernel_ver="$(latest_kernel_version)"
  cmdline="$(linux_cmdline_from_grub)"
  template="$REPO_ROOT/system/visor/boot.conf.template"
  out="$(mktemp)"

  [[ -n "$kernel_ver" ]] || die "Kernel não encontrado em /boot."
  [[ -f "$template" ]] || die "Template ausente: $template"

  python3 - "$template" "$out" "$cmdline" <<'PY'
import sys
tpl, out, cmdline = sys.argv[1:4]
text = open(tpl, encoding="utf-8").read()
text = text.replace("@LINUX_CMDLINE@", cmdline)
open(out, "w", encoding="utf-8").write(text)
PY

  install -Dm0644 "$out" "$dest/boot.conf"
  rm -f "$out"
  log "boot.conf gerado (kernel ${kernel_ver})."
}

install_assets() {
  local esp="$1"
  local dest="$esp/$VISOR_REL"
  log "Copiando ícones e fundo..."
  mkdir -p "$dest/icons" "$dest/backgrounds" "$dest/themes"
  cp -f "$VISOR_SRC/assets/icons/"{linux,windows,power_shutdown,power_reboot,power_bios}.png \
    "$dest/icons/"
  cp -f "$REPO_ROOT/system/visor/backgrounds/espaco_1.png" "$dest/backgrounds/"
}

install_visor_binary() {
  local esp="$1"
  local dest="$esp/$VISOR_REL"
  install -Dm0644 "$VISOR_SRC/visor_x64.efi" "$dest/visor_x64.efi"
  [[ -f "$VISOR_SRC/visor" ]] && install -Dm0755 "$VISOR_SRC/visor" /usr/local/bin/visor
}

visor_boot_num() {
  efibootmgr 2>/dev/null | grep -m1 'Visor' | sed -n 's/^Boot\([0-9]*\).*/\1/p'
}

register_uefi_entry() {
  local esp="$1" src disk partnum loader num order new_order item
  src="$(findmnt -no SOURCE "$esp" | head -1)"
  disk="$(lsblk -no PKNAME "$src")"
  partnum="$(lsblk -no PARTN "$src" | tr -d '[:space:]')"
  loader="\\EFI\\visor\\visor_x64.efi"

  num="$(visor_boot_num)"
  if [[ -z "$num" ]]; then
    efibootmgr --create --disk "/dev/$disk" --part "$partnum" \
      --label "Visor" --loader "$loader" >/dev/null
    num="$(visor_boot_num)"
  else
    log "Entrada UEFI Visor já existe (Boot${num})."
  fi

  [[ -n "$num" ]] || die "Não foi possível criar entrada UEFI Visor."
  order="$(efibootmgr | awk -F': ' '/BootOrder/{print $2}')"
  new_order="$num"
  IFS=',' read -ra items <<<"$order"
  for item in "${items[@]}"; do
    [[ "$item" == "$num" ]] && continue
    new_order="${new_order},${item}"
  done
  efibootmgr -o "$new_order" >/dev/null
  log "Boot padrão: Visor (Boot${num})."
}

install_boot_persistence() {
  log "Instalando persistência da ordem de boot..."
  install -Dm755 "$REPO_ROOT/system/local-bin/meuhypr-visor-boot-order" \
    /usr/local/sbin/meuhypr-visor-boot-order
  install -Dm644 "$REPO_ROOT/system/systemd/meuhypr-visor-boot-order.service" \
    /etc/systemd/system/meuhypr-visor-boot-order.service
  install -Dm755 "$REPO_ROOT/system/kernel-postinst.d/zz-meuhypr-visor-boot-order" \
    /etc/kernel/postinst.d/zz-meuhypr-visor-boot-order
  systemctl daemon-reload
  systemctl enable --now meuhypr-visor-boot-order.service >/dev/null 2>&1 || true
  /usr/local/sbin/meuhypr-visor-boot-order
}

main() {
  need_root
  ESP="$(detect_esp)"
  [[ -w "$ESP" ]] || die "Sem permissão de escrita em $ESP"
  install_build_deps
  clone_and_build_visor
  install_visor_binary "$ESP"
  install_assets "$ESP"
  sync_kernel_to_esp "$ESP" "$(latest_kernel_version)"
  write_boot_conf "$ESP/$VISOR_REL"
  register_uefi_entry "$ESP"
  install_boot_persistence
  log "Visor instalado em $ESP/$VISOR_REL — reinicie para testar."
}

main "$@"
