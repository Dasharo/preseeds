#!/usr/bin/env bash

set -euo pipefail

FEDORA_MAJOR_VERSION="42"
FEDORA_MINOR_VERSION="1.1"
FEDORA_VERSION=${FEDORA_MAJOR_VERSION}-${FEDORA_MINOR_VERSION}
ISO_DOWNLOAD_LINK="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_MAJOR_VERSION}/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${FEDORA_VERSION}.iso"
OUTPUT_ISO="fedora-auto-${FEDORA_VERSION}.iso"
ISO_PATH="${ISO_PATH:-fedora.iso}"

while getopts "hi:o" arg; do
    case "${arg}" in
        h)
            echo "This script builds a custom Fedora ISO using a Kickstart file."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -i path       use a specific Fedora ISO file"
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
    echo "Downloading Fedora Workstation ${FEDORA_VERSION} image..."
    wget -O "$ISO_PATH" $ISO_DOWNLOAD_LINK
fi

if [[ -f $OUTPUT_ISO ]]; then
    echo "$OUTPUT_ISO already exists, replacing the file."
    rm -f "$OUTPUT_ISO"
fi

xorriso -indev $ISO_PATH \
    -outdev $OUTPUT_ISO \
    -compliance no_emul_toc \
    -map "fedora/grub-efi.cfg" "EFI/BOOT/grub.cfg" \
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
sudo cp -f fedora/grub-efi.cfg $tmp/EFI/BOOT/grub.cfg

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
    -map "fedora/grub-efi.cfg" "EFI/BOOT/grub.cfg" \
    -boot_image any replay

echo "Done. Image file saved as: $OUTPUT_ISO"