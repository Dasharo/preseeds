#!/usr/bin/env bash

set -euo pipefail
OUTPUT_ISO="windows-auto.iso"
ISO_PATH="${ISO_PATH:-windows.iso}"
CUSTOM_DATA_DIR="windows/custom_data"

while getopts "hi:o" arg; do
    case "${arg}" in
        h)
            echo "This script builds a custom automatic install Windows ISO."
            echo "The ISO must be downloaded manually due to a download verification system at Microsoft's site."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -i path       path to the Windows ISO file"
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
            echo "Unrecognized argument. Unetwork in windows on qemuse -h to get help"
            exit 3
            ;;
    esac
done

tmp=$(mktemp -d)
tmp2="$OUTPUT_ISO"_tmp
rm -rf $tmp2
mkdir $tmp2

# Copying all Windows files
cp -f "$ISO_PATH" "$OUTPUT_ISO"
sudo mount -o loop "$ISO_PATH" "$tmp"
cp -r "$tmp"/* "$tmp2/"

sudo umount "$tmp"
rm -rf "$tmp"

# Copy custom autounattend.xml
cp windows/autounattend.xml "$tmp2/autounattend.xml"


# Custom files
desktop="$tmp2"'/$OEM$/$1/Users/Public/Desktop'

# Copy drivers from protectli-docs
# git clone git@github.com:Dasharo/protectli-docs
cp -r protectli-docs/SDIO/drivers $CUSTOM_DATA_DIR

# Copy custom scripts and other files to the desktop
mkdir -p $desktop
cp -r $CUSTOM_DATA_DIR "$desktop/"

# Rebuild iso
xorriso -as mkisofs \
  -iso-level 3 -U -J -l \
  -b boot/etfsboot.com \
  -c boot/boot.cat \
  -no-emul-boot -boot-load-size 8 -boot-info-table \
  -eltorito-alt-boot \
  -e efi/microsoft/boot/efisys.bin -no-emul-boot \
  -o "$OUTPUT_ISO" \
  -joliet-long \
  "$tmp2"

# cleanup
echo "Removing temporary files..."
rm -rf "$tmp2"
echo "Done. Image file saved as: $OUTPUT_ISO"