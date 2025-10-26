#!/bin/sh
recoveryver=$1
fail() {
    printf "%b\n" "$1" >&2
    printf "error occurred\n" >&2
	losetup -d "$LOOPDEV" > /dev/null 2>&1
    umount /stateful > /dev/null 2>&1
    exit 1
}
findimage(){ # Taken from murkmod
    echo "Attempting to find recovery image from the https://github.com/MercuryWorkshop/chromeos-releases-data repo..."
    local mercury_data_url="https://raw.githubusercontent.com/MercuryWorkshop/chromeos-releases-data/refs/heads/main/data.json"
    local mercury_url=$(curl -ks "$mercury_data_url" | jq -r --arg board "$board" --arg version "$recoveryver" '
      .[$board].images
      | map(select(
          .channel == "stable-channel" and
          (.chrome_version | type) == "string" and
          (.chrome_version | startswith($version + "."))
        ))
      | sort_by(.platform_version)
      | .[0].url
    ')

    if [ -n "$mercury_url" ] && [ "$mercury_url" != "null" ]; then
        echo "Found a match!"
        FINAL_URL="$mercury_url"
        MATCH_FOUND=1
        echo "$mercury_url"
	else
		fail "Failed to find your recovery image"
    fi
}
mountlvm(){
     vgchange -ay #active all volume groups
     volgroup=$(vgscan | grep "Found volume group" | awk '{print $4}' | tr -d '"')
     echo "found volume group:  $volgroup"
     mount "/dev/$volgroup/unencrypted" /stateful || fail "couldnt mount p1 or lvm group.  Please recover"
}
get_fixed_dst_drive() {
	local dev
	if [ -z "${DEFAULT_ROOTDEV}" ]; then
		for dev in /sys/block/sd* /sys/block/mmcblk*; do
			if [ ! -d "${dev}" ] || [ "$(cat "${dev}/removable")" = 1 ] || [ "$(cat "${dev}/size")" -lt 2097152 ]; then
				continue
			fi
			if [ -f "${dev}/device/type" ]; then
				case "$(cat "${dev}/device/type")" in
				SD*)
					continue;
					;;
				esac
			fi
			DEFAULT_ROOTDEV="{$dev}"
		done
	fi
	if [ -z "${DEFAULT_ROOTDEV}" ]; then
		dev=""
	else
		dev="/dev/$(basename ${DEFAULT_ROOTDEV})"
		if [ ! -b "${dev}" ]; then
			dev=""
		fi
	fi
	echo "${dev}"
}
if [ -z "$recoveryver" ]; then
    echo "Error: please enter a version to recover with"
	fail "example command:  sh recovery_selector.sh {version}"
fi
#automatic board determination taken from br0ker, thanks olyb
RECOVERY_KEY_LIST=short_recovery_keys.txt
if [ -f /etc/lsb-release ]; then
	BOARD=$(grep -m 1 "^CHROMEOS_RELEASE_BOARD=" /etc/lsb-release)
	BOARD="${BOARD#*=}"
	BOARD="${BOARD%-signed-*}"
else
  curl -LO https://raw.githubusercontent.com/MercuryWorkshop/sh1mmer/beautifulworld/wax/payloads/short_recovery_keys.txt
	[ -f "$RECOVERY_KEY_LIST" ] || fail "Missing recovery key list!"
	TMPFILE=$(mktemp)
	flashrom -i GBB -r "$TMPFILE" >/dev/null 2>&1
	futility gbb -g --recoverykey="$TMPFILE".vbpubk "$TMPFILE" >/dev/null 2>&1
	recoverykeysum=$(futility show "$TMPFILE".vbpubk | grep "Key sha1sum" | sed "s/ *Key sha1sum: *//")
	BOARD=$(grep ";$recoverykeysum" "$RECOVERY_KEY_LIST" | cut -d";" -f1)
	BOARD="${BOARD#board:}"
	rm "$TMPFILE" "$TMPFILE".vbpubk
fi
echo "Found board:  $BOARD"
board="$BOARD"
. /usr/sbin/write_gpt.sh
load_base_vars
TARGET_DEVICE=$(get_fixed_dst_drive)

if echo "$TARGET_DEVICE" | grep -q '[0-9]$'; then
	TARGET_DEVICE_P="$TARGET_DEVICE"p
else
	TARGET_DEVICE_P="$TARGET_DEVICE"
fi
arch=$(uname -m)

case "$arch" in
    x86_64)
        tar_url="https://github.com/aspect-build/bsdtar-prebuilt/releases/latest/download/tar_linux_amd64"
        ;;
    aarch64)
        tar_url="https://github.com/aspect-build/bsdtar-prebuilt/releases/latest/download/tar_linux_arm64"
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac
echo "using tar from:  $tar_url"
echo "Found internal disk: $TARGET_DEVICE"
echo "Found partition selection:  $TARGET_DEVICE_P"
findimage
mount "$TARGET_DEVICE_P"1 /stateful || mountlvm
cd /stateful
read -p "Do you want to disable dev mode on next boot (skipping the beep)? (Y/N) " -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]; then
	echo "setting flag to disable dev mode on next boot..."
    crossystem disable_dev_request=1 > /dev/null 2>&1
	echo "Done! returning to main script"
fi
read -p "Do you want to copy miniOS from the recovery image (will patch badapple if it is 132+)? (Y/N) " -n 1 -r
echo
curl --progress-bar -k "$FINAL_URL" -o recovery.zip || fail "Failed to download recovery image"
curl --progress-bar -Lko /stateful/tar_linux "$tar_url" || fail "failed to download tar binary"
chmod +x tar_linux
echo "Unzipping file..."
./tar_linux -xf recovery.zip || fail "failed to unzip recovery image"
rm recovery.zip
FILENAME=$(find . -maxdepth 2 -name "chromeos_*.bin")
echo "Found recovery image from archive at $FILENAME"
LOOPDEV=$(losetup -f) || fail "could not find an available loop"
losetup -P "$LOOPDEV" "$FILENAME" || fail "Could not losetup image"
sleep 2 #wait for mounting to finish 
echo "dd p4 image p2 internal"
dd if="$LOOPDEV"p4 of="$TARGET_DEVICE_P"2 bs=1M || fail "Could not copy partition to disk" #thanks for telling me kern-b was the copied one olyb :)
echo "dd p3 image p3 internal"
dd if="$LOOPDEV"p3 of="$TARGET_DEVICE_P"3 bs=1M || fail "Could not copy partition to disk"
echo "Cloning root and kern a to root and kern b..."
dd if="$LOOPDEV"p4 of="$TARGET_DEVICE_P"4 bs=1M || fail "Could not copy partition to disk"
dd if="$LOOPDEV"p3 of="$TARGET_DEVICE_P"5 bs=1M || fail "Could not copy partition to disk"
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Copying miniOS by users request..."
	dd if="$LOOPDEV"p9 of="$TARGET_DEVICE_P"9 bs=1M || fail "Could not copy partition to disk"
	dd if="$LOOPDEV"p10 of="$TARGET_DEVICE_P"10 bs=1M || fail "Could not copy partition to disk"
fi
cd /
echo "Wiping stateful by removing its contents" #we cant do mkfs.ext4 because of cryptohome issues
rm -rf /stateful/*
echo "Touching .developer_mode"
touch /stateful/.developer_mode
losetup -d "$LOOPDEV" || fail "Failed to unmount loopdev"
umount /stateful
echo "Done! Dropping shell..."
exit
