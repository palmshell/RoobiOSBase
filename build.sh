#!/bin/bash

set -e

echo "Starting script..."


OUTPUT_FILE=Roobi.img

apt install kpartx -y
apt install btrfs-progs -y

# Get the base os
curl -L  $1 -o roobi.img.zip

unzip -d ./ roobi.img.zip

# ^^^^^^^^^^^^^^^^^^^^^^^^ configure pacman ^^^^^^^^^^^^^^^^^^^^^^^^

# ------------------------ set disk --------------------------------

mount_image() {
  sudo kpartx -a "$OUTPUT_FILE"

  for i in /sys/class/block/loop*; do
    if [[ "$(cat "$i/loop/backing_file")" == "$(realpath "$OUTPUT_FILE")" ]]; then
      echo "$(basename "$i")"
      return
    fi
  done
}


TARGET_DEV="/dev/mapper/$(mount_image)"

echo TARGET_DEV: $TARGET_DEV

EFI="${TARGET_DEV}p1"
ROOT="${TARGET_DEV}p2"


mount -o compress=zstd $ROOT /mnt
mount $EFI /mnt/boot

# ^^^^^^^^^^^^^^^^^^^^^^^^ set disk ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

sudo cp -r "./root/." /mnt

sed -i "s/token_here/$2/g" /mnt/usr/factory/progress/_config.hjson

sed -i "s/url/$3/g" /mnt/usr/factory/progress/_config.hjson



find_root_part() {
  local ROOT_PART
  ROOT_PART="$(sgdisk -p "$1" | grep "rootfs" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 2)"
  if [[ -z $ROOT_PART ]]; then
    ROOT_PART="$(sgdisk -p "$1" | grep -e "8300" -e "EF00" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 2)"
  fi
  echo $ROOT_PART
}

SHRINK_SIZE=1
sudo btrfs filesystem usage -b /mnt | grep "Free (estimated)" | sed "s/.*min: \([0-9]*\).*/\1/"
while sudo btrfs filesystem resize -${SHRINK_SIZE} /mnt; do
  SHRINK_SIZE=$(($(sudo btrfs filesystem usage -b /mnt | grep "Free (estimated)" | sed "s/.*min: \([0-9]*\).*/\1/") / 8))
done
DEVICE_SIZE=$(($(sudo btrfs filesystem usage -b /mnt | grep "Device size" | tr -s ' ' | cut -d ' ' -f 4)))

echo "Kill GPG..."

kill -9 `lsof | grep /mnt/etc/pacman.d/gnupg/ | awk 'NR==1 {print $2}'` || true

echo "Unmount filesystem..."
sudo umount -lR /mnt

echo "Unmount image..."
sudo kpartx -d "$OUTPUT_FILE"

echo "Update partition table..."
ROOT_PART="$(find_root_part "$OUTPUT_FILE")"
SECTOR_SIZE="$(sgdisk -p "$OUTPUT_FILE" | grep "Sector size (logical):" | tail -n 1 | tr -s ' ' | cut -d ' ' -f 4)"
START_SECTOR="$(sgdisk -i "$ROOT_PART" "$OUTPUT_FILE" | grep "First sector:" | cut -d ' ' -f 3)"
NEW_SIZE=$(($START_SECTOR * $SECTOR_SIZE + $DEVICE_SIZE))
cat <<EOF | parted ---pretend-input-tty "$OUTPUT_FILE" >/dev/null 2>&1``
resizepart $ROOT_PART 
${NEW_SIZE}B
yes
EOF

echo "Shrink image..."
END_SECTOR="$(sgdisk -i "$ROOT_PART" "$OUTPUT_FILE" | grep "Last sector:" | cut -d ' ' -f 3)"
# leave some space for the secondary GPT header
FINAL_SIZE="$((($END_SECTOR + 34) * $SECTOR_SIZE))"
truncate "--size=$FINAL_SIZE" "$OUTPUT_FILE" >/dev/null

echo "Fix backup GPT table..."
sgdisk -ge "$OUTPUT_FILE" &>/dev/null || true

echo "Test partition table for additional issue..."
sgdisk -v "$OUTPUT_FILE" >/dev/null

echo "Compress image."
echo "skip"
#xz -fT 0 "$OUTPUT_FILE"

#echo "Image build completed."
