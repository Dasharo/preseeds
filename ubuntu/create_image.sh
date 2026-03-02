#!/usr/bin/env bash
set -euo pipefail

UBUNTU_VERSION="25.10"
ISO_NAME="ubuntu-${UBUNTU_VERSION}-desktop-amd64.iso"
ISO_URL="https://ubuntu.task.gda.pl/ubuntu-releases/${UBUNTU_VERSION}/${ISO_NAME}"
OUTPUT_ISO="ubuntu-${UBUNTU_VERSION}-autoinstall.iso"

SCRIPTDIR=$(readlink -f "$(dirname "$0")")
USER_DATA="$SCRIPTDIR/user-data"
META_DATA="$SCRIPTDIR/meta-data"

WORKDIR=$(mktemp -d)
GRUB_TMP="$WORKDIR/grub"

cleanup() {
    rm -rf "$WORKDIR"
}
trap cleanup EXIT

require() {
    command -v "$1" >/dev/null || { echo "Missing $1"; exit 1; }
}

require xorriso
require sed
require wget

[[ -f "$USER_DATA" ]] || { echo "Missing user-data"; exit 1; }
[[ -f "$META_DATA" ]] || { echo "Missing meta-data"; exit 1; }

echo "Downloading ISO if needed..."
if [[ ! -f "$ISO_NAME" ]]; then
    wget -O "$ISO_NAME" "$ISO_URL"
fi

echo "Copying ISO..."
cp "$ISO_NAME" "$OUTPUT_ISO"

mkdir -p "$GRUB_TMP"

echo "Extracting grub configs..."
xorriso -osirrox on -indev "$OUTPUT_ISO" \
    -extract /boot/grub/grub.cfg "$GRUB_TMP/grub.cfg" \
    -extract /boot/grub/loopback.cfg "$GRUB_TMP/loopback.cfg"

echo "Patching grub for autoinstall..."

sed -i 's@quiet splash@quiet splash autoinstall ds=nocloud\\;s=/cdrom/nocloud/@g' \
    "$GRUB_TMP/grub.cfg"

sed -i 's@quiet splash@quiet splash autoinstall ds=nocloud\\;s=/cdrom/nocloud/@g' \
    "$GRUB_TMP/loopback.cfg"

echo "Injecting NoCloud data (in-place)..."

xorriso \
  -indev "$OUTPUT_ISO" \
  -outdev "$OUTPUT_ISO" \
  -boot_image any keep \
  -map "$USER_DATA" /nocloud/user-data \
  -map "$META_DATA" /nocloud/meta-data \
  -map "$GRUB_TMP/grub.cfg" /boot/grub/grub.cfg \
  -map "$GRUB_TMP/loopback.cfg" /boot/grub/loopback.cfg

echo "Updating md5sum..."

MD5TMP="$WORKDIR/md5"
mkdir -p "$MD5TMP"

# extract file list
xorriso -indev "$OUTPUT_ISO" \
        -find / -type f \
        -exec lsdl \
        | awk '{print $NF}' \
        | sed 's:^/::' \
        | grep -v '^md5sum.txt$' \
        > "$MD5TMP/files.txt"

# extract files
mkdir -p "$MD5TMP/root"

while read -r f; do
    mkdir -p "$MD5TMP/root/$(dirname "$f")"
    xorriso -osirrox on -indev "$OUTPUT_ISO" \
        -extract "/$f" "$MD5TMP/root/$f" >/dev/null 2>&1
done < "$MD5TMP/files.txt"

# compute md5
(
cd "$MD5TMP/root"
find . -type f -print0 | xargs -0 md5sum | sed 's|\./||'
) > "$MD5TMP/md5sum.txt"

# inject back
xorriso -indev "$OUTPUT_ISO" \
        -outdev "$OUTPUT_ISO" \
        -boot_image any keep \
        -map "$MD5TMP/md5sum.txt" /md5sum.txt

echo ""
echo "Done: $OUTPUT_ISO ready"
