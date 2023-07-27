#!/usr/bin/env bash

ISO_DOWNLOAD_LINK="https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-desktop-amd64.iso"
partitioning_preseed="partitioning.cfg"
main_preseed="main.cfg"
output_name="ubuntu-auto.iso"
isopath=""
iso_extr_path=""
partitioning=1

while getopts "hi:e:o:p" arg; do
    case "${arg}" in
        h)
            echo "This script automatically downloads Ubuntu release
22.04.2, extracts it, injects preseeds and packages the new
iso image. General preseed configuration can be found in
the ubuntu/main.cfg file, if necessary, it can be edited."
            echo "Help:"
            echo "    -h            shows help"
            echo "    -p            make custom partitioning during \
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
                isopath=$OPTARG
            fi
            ;;
        e)
            if ! [ -d "$OPTARG" ]; then
                echo "Directory $OPTARG does not exist"
                exit 2
            else
                iso_extr_path=$OPTARG
            fi
            ;;
        o)
            output_name=$OPTARG
            ;;
        p)
            partitioning=0
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
if [[ $isopath == "" ]]; then
    echo "Downloading Ubuntu Desktop 22.04.2 image..."
    wget -O "$tmpdir/ubuntu.iso" $ISO_DOWNLOAD_LINK
    isopath="$tmpdir/ubuntu.iso"
fi

# extract iso contents
if [[ $iso_extr_path == "" ]]; then
    echo "Extracting iso contents..."
    iso_extr_path="$tmpdir/extracted"
    xorriso -osirrox on -indev "$isopath" -extract / "$iso_extr_path" &>/dev/null
    # make iso contents modifiable
    chmod -R u+w "$iso_extr_path"
fi

# set up kernel to use preseed
sed -i -e 's,file=/cdrom/preseed/ubuntu.seed maybe-ubiquity quiet splash,file=/cdrom/preseed/ubuntu.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell,g' "$iso_extr_path/boot/grub/grub.cfg"
sed -i -e 's,file=/cdrom/preseed/ubuntu.seed maybe-ubiquity iso-scan/filename=${iso_path} quiet splash,file=/cdrom/preseed/ubuntu.seed auto=true priority=critical boot=casper automatic-ubiquity quiet splash noprompt noshell,g' "$iso_extr_path/boot/grub/loopback.cfg"
sed -i 's/Try or Install Ubuntu/Perform automatic installation/' "$iso_extr_path/boot/grub/grub.cfg"

# inject preseed
echo "Injecting preseed..."
# preseed partitioning only if argument -p was not given
if [ $partitioning -eq 1 ]; then
    cat $partitioning_preseed >> "$iso_extr_path/preseed/ubuntu.seed"
fi
cat $main_preseed >> "$iso_extr_path/preseed/ubuntu.seed"

# update checksums
echo "Updating checksums..."
md5=$(md5sum "$iso_extr_path/boot/grub/grub.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/grub.cfg" > "$iso_extr_path//md5sum.txt"
md5=$(md5sum "$iso_extr_path/boot/grub/loopback.cfg" | cut -f1 -d ' ')
echo "$md5  ./boot/grub/loopback.cfg" >> "$iso_extr_path//md5sum.txt"

# fetch partitioning data from iso
dd if=$isopath bs=1 count=432 of="$tmpdir/boot_hybrid.img"
dd if=$isopath bs=512 skip=9613460 count=10068 of="$tmpdir/efi.img"

# save modification to new iso file
echo "Saving modified iso..."
xorriso -as mkisofs -r \
-V 'Ubuntu Auto Installer' \
-o $output_name \
--modification-date='2023022304134400' \
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
-boot-load-size 10068 \
$iso_extr_path

echo "Removing temporary files..."
rm -rf $tmpdir
echo "Done. Image file saved as: $output_name"

