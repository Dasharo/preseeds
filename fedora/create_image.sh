#!/usr/bin/env bash

set -euo pipefail

FEDORA_MAJOR_VERSION="42"
FEDORA_MINOR_VERSION="1.1"
FEDORA_VERSION=${FEDORA_MAJOR_VERSION}-${FEDORA_MINOR_VERSION}
ISO_DOWNLOAD_LINK="https://download.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_MAJOR_VERSION}/Everything/x86_64/iso/Fedora-Everything-netinst-x86_64-${FEDORA_VERSION}.iso"
SCRIPTDIR=$(readlink -f $(dirname "$0"))
PARTITIONING_KS="$SCRIPTDIR/partitioning.cfg"
MAIN_KS="$SCRIPTDIR/main.cfg"
OUTPUT_ISO="fedora-auto-${FEDORA_VERSION}.iso"
ISO_PATH="${ISO_PATH:-fedora.iso}"
ISO_EXTR_PATH=""
PARTITIONING=1

while getopts "hi:e:o:p" arg; do
    case "${arg}" in
        h)
            echo "This script builds a custom Fedora ISO using a Kickstart file."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -p            disable custom partitioning (omit partitioning.ks)"
            echo "    -i path       use a specific Fedora ISO file"
            echo "    -e path       use an extracted ISO directory instead of extracting"
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
        e)
            if ! [ -d "$OPTARG" ]; then
                echo "Directory $OPTARG does not exist"
                exit 2
            else
                ISO_EXTR_PATH=$OPTARG
            fi
            ;;
        o)
            OUTPUT_ISO=$OPTARG
            ;;
        p)
            PARTITIONING=0
            ;;
        *)
            echo "Unrecognized argument. Use -h to get help"
            exit 3
            ;;
    esac
done

# check prerequisities
if ! xorriso --version &> /dev/null
then
    echo "xorriso could not be found"
    exit 4
fi

# download iso image
if [[ ! -f "$ISO_PATH" ]]; then
    echo "Downloading Fedora Workstation ${FEDORA_VERSION} image..."
    wget -O "$ISO_PATH" $ISO_DOWNLOAD_LINK
fi

echo "Saving modified iso..."

# The iso is a hybrid el-torrito iso and the EFI partition is the second
# partition. Using xorriso '-map' won't work, because it only modifies the
# first partition, which is not the EFI partition.

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
echo "Done!"

# cleanup
echo "Removing temporary files..."
sudo umount $tmp
sudo losetup -d $LOOPDEV
rm -rf $tmp
echo "Done. Image file saved as: $OUTPUT_ISO"