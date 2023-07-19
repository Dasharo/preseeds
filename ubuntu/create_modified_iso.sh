#!/bin/bash
#This script suppouses that iso contents are extracted into the directory
isodir="iso_extr"

md5=$(md5sum "$isodir/boot/grub/grub.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/grub.cfg" > "$isodir/md5sum.txt"
md5=$(md5sum "$isodir/boot/grub/loopback.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/loopback.cfg" >> "$isodir/md5sum.txt"

dd if=ubuntu-original.iso bs=1 count=432 of=boot_hybrid.img
dd if=ubuntu-original.iso bs=512 skip=9613460 count=10068 of=efi.img

xorriso -as mkisofs -r \
-V 'Ubuntu 22.04 LTS Auto Installer' \
-o ubuntu-auto.iso \
--modification-date='2023022304134400' \
--grub2-mbr boot_hybrid.img \
--protective-msdos-label \
-partition_cyl_align off \
-partition_offset 16 \
--mbr-force-bootable \
-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b efi.img \
-appended_part_as_gpt \
-iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
-c '/boot.catalog' \
-b '/boot/grub/i386-pc/eltorito.img' \
-no-emul-boot \
-boot-load-size 4 \
-boot-info-table \
--grub2-boot-info \
-eltorito-alt-boot \
-e '--interval:appended_partition_2_start_2403365s_size_10068d:all::' \
-no-emul-boot \
-boot-load-size 10068 \
"$isodir"
