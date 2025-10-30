#!/usr/bin/env bash

set -euo pipefail
QUBES_VERSION="R4.3.0-rc3"
ISO_DOWNLOAD_LINK="https://mirrors.edge.kernel.org/qubes/iso/Qubes-${QUBES_VERSION}-x86_64.iso"
OUTPUT_ISO="qubesos-auto-${QUBES_VERSION}.iso"
ISO_PATH="${ISO_PATH:-qubesos_${QUBES_VERSION}.iso}"

while getopts "hi:o" arg; do
    case "${arg}" in
        h)
            echo "This script builds a custom QubesOS ISO using a Kickstart file."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -i path       use a specific QubesOS ISO file"
            echo "    -o file_name  output ISO filename"
            exit 0
            ;;
        i)
            if ! [ -f "$OPTARG" ]; then
                echo "Image does not exist: $OPTARG"
                exit 1
            else
                ISO_PATH=$OPTARG
            fi
            ;;
        o)
            OUTPUT_ISO=$OPTARG
            ;;
        *)
            echo "Unrecognized argument. Use -h to get help"
            exit 3
            ;;
    esac
done


# download iso image
if [[ ! -f "$ISO_PATH" ]]; then
    echo "Downloading QubesOS ${QUBES_VERSION} image..."
    wget -O "$ISO_PATH" $ISO_DOWNLOAD_LINK
fi

if [[ -f $OUTPUT_ISO ]]; then
    echo "$OUTPUT_ISO already exists, replacing the file."
    rm -f "$OUTPUT_ISO"
fi

xorriso -indev $ISO_PATH \
    -outdev $OUTPUT_ISO \
    -compliance no_emul_toc \
    -map "qubesos/grub-efi.cfg" "EFI/BOOT/grub.cfg" \
    -boot_image any replay

tmp=$(mktemp -d)
cp -f $ISO_PATH $OUTPUT_ISO

# Modifying the second partition manually
# find out where the partition starts

echo "Scanning the original ISO..."
start=$(fdisk -l $OUTPUT_ISO | grep "EFI System" | tr -s ' '  | cut -d' ' -f2)
sector_size=$(fdisk -l $OUTPUT_ISO | grep "Sector size" | tr -s ' ' | cut -d' ' -f4)
start_byte=$(( $start * $sector_size ))

# mount
echo "Modifying the ISO..."
LOOPDEV=$(sudo losetup --find --show --offset $start_byte -f $OUTPUT_ISO)
echo $LOOPDEV
sudo mount $LOOPDEV $tmp

# modify EFI partition
echo "Modifying EFI partition"
sudo cp -f qubesos/grub-efi.cfg $tmp/EFI/BOOT/grub.cfg

sudo umount $tmp
sudo losetup -d $LOOPDEV
rm -rf $tmp

# Modifying the EFI directory on the first partition too.
# QEMU uses it instead of the EFI partition
echo "Modifying main partition"
mv $OUTPUT_ISO $tmp
xorriso -indev $tmp \
    -outdev $OUTPUT_ISO \
    -compliance no_emul_toc \
    -map "qubesos/grub-efi.cfg" "EFI/BOOT/grub.cfg" \
    -boot_image any replay

echo "Done. Image file saved as: $OUTPUT_ISO"