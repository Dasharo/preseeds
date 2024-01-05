#!/usr/bin/env bash

set -euo pipefail

UBUNTU_VERSION="22.04.3"
ISO_DOWNLOAD_LINK="https://ubuntu.task.gda.pl/ubuntu-releases/${UBUNTU_VERSION}/ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
SCRIPTDIR=$(readlink -f $(dirname "$0"))
PARTITIONING_PRESEED="$SCRIPTDIR/partitioning.cfg"
MAIN_PRESEED="$SCRIPTDIR/main.cfg"
OUTPUT_ISO="ubuntu-auto-${UBUNTU_VERSION}.iso"
ISO_PATH=""
ISO_EXTR_PATH=""
PARTITIONING=1

while getopts "hi:e:o:p" arg; do
    case "${arg}" in
        h)
            echo "This script automatically downloads Ubuntu release
${UBUNTU_VERSION}, extracts it, injects preseeds and packages the new
iso image. General preseed configuration can be found in
the ubuntu/main.cfg file, if necessary, it can be edited."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -p            make custom PARTITIONING during \
the installation"
            echo "    -i path       point the location of installation \
iso instead of downloading it"
            echo "    -e path       point the location of extracted iso"
            echo "    -o file_name  specify the output filename"
            exit 0
            ;;
        i)
            if ! [ -f "$OPTARG" ]; then
                echo "Image given does not exist: $OPTARG"
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


# prepare temp folder

tmpdir=$(mktemp -d)

# download iso image
if [[ $ISO_PATH == "" ]]; then
    ISO_PATH="ubuntu.iso"
    echo "Downloading Ubuntu Desktop ${UBUNTU_VERSION} image..."
    wget -O "$ISO_PATH" $ISO_DOWNLOAD_LINK
fi

# extract iso contents
if [[ $ISO_EXTR_PATH == "" ]]; then
    echo "Extracting iso contents..."
    ISO_EXTR_PATH="$tmpdir/extracted"
    xorriso -osirrox on -indev "$ISO_PATH" -extract / "$ISO_EXTR_PATH" #&>/dev/null
    # make iso contents modifiable
    chmod -R u+w "$ISO_EXTR_PATH"
fi

# set up kernel to use preseed
sed -i -e 's,file=/cdrom/preseed/ubuntu.seed maybe-ubiquity quiet splash,file=/cdrom/preseed/ubuntu.seed iso-scan/filename=${iso_path} auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell,g' "$ISO_EXTR_PATH/boot/grub/grub.cfg"
sed -i -e 's,file=/cdrom/preseed/ubuntu.seed maybe-ubiquity iso-scan/filename=${iso_path} quiet splash,file=/cdrom/preseed/ubuntu.seed iso-scan/filename=${iso_path} auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell,g' "$ISO_EXTR_PATH/boot/grub/loopback.cfg"
sed -i 's/Try or Install Ubuntu/Perform automatic installation/' "$ISO_EXTR_PATH/boot/grub/grub.cfg"

# inject preseed
echo "Injecting preseed..."
# preseed PARTITIONING only if argument -p was not given
if [ $PARTITIONING -eq 1 ]; then
    cat $PARTITIONING_PRESEED >> "$ISO_EXTR_PATH/preseed/ubuntu.seed"
fi
cat $MAIN_PRESEED >> "$ISO_EXTR_PATH/preseed/ubuntu.seed"

# update checksums
echo "Updating checksums..."
md5=$(md5sum "$ISO_EXTR_PATH/boot/grub/grub.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/grub.cfg" > "$ISO_EXTR_PATH//md5sum.txt"
md5=$(md5sum "$ISO_EXTR_PATH/boot/grub/loopback.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/loopback.cfg" >> "$ISO_EXTR_PATH//md5sum.txt"

# fetch partitioning data from iso
dd if=$ISO_PATH bs=1 count=432 of="$tmpdir/boot_hybrid.img"
EFI_START=$(xorriso -indev ${ISO_PATH} -report_system_area 2> /dev/null | grep "GPT start and size :   2" | cut -d ' ' -f 10)
EFI_SIZE=$(xorriso -indev ${ISO_PATH} -report_system_area 2> /dev/null | grep "GPT start and size :   2" | cut -d ' ' -f 12)
dd if=$ISO_PATH bs=512 skip=${EFI_START} count=${EFI_SIZE} of="$tmpdir/efi.img"

# fetch Vulume Creation Date
CREATION_DATE="$(dd if=$ISO_PATH bs=1 skip=33581 count=17 2>/dev/null | hexdump -e  "16 \"%_p\" \"\\n\"" | head -n1)"

# save modification to new iso file
echo "Saving modified iso..."
xorriso -as mkisofs -r \
-V 'Ubuntu Auto Installer' \
-o $OUTPUT_ISO \
--modification-date="${CREATION_DATE}" \
--grub2-mbr "$tmpdir/boot_hybrid.img" \
--protective-msdos-label \
-partition_cyl_align off \
-partition_offset 16 \
--mbr-force-bootable \
-append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b "$tmpdir/efi.img" \
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
-boot-load-size ${EFI_SIZE} \
$ISO_EXTR_PATH

echo "Removing temporary files..."
rm -rf $tmpdir
echo "Done. Image file saved as: $OUTPUT_ISO"
