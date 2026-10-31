#!/usr/bin/env bash
set -euo pipefail
build_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
root="${1:-$build_root/boot-images/ipxe/efi-source}"
for file in boot/ipxe/undionly.kpxe boot/ipxe/ipxe.efi \
    boot/ipxe/autoexec.ipxe boot/vmlinuz boot/initrd \
    boot/image.md5 EFI/BOOT/BOOTX64.EFI; do
    if [ ! -s "$root/$file" ]; then
        echo "Missing or empty iPXE output: $root/$file" >&2
        exit 1
    fi
done
if [ -e "$root/boot/grub2" ] || [ -e "$root/EFI/BOOT/grubx64.efi" ]; then
    echo "Unexpected GRUB payload in iPXE output" >&2
    exit 1
fi
if grep -q '\$KERNEL_PARAMETERS' "$root/boot/ipxe/autoexec.ipxe"; then
    echo "Unsubstituted iPXE kernel parameter placeholder" >&2
    exit 1
fi
echo "iPXE output verified: $root"
