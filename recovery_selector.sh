# This script assumes interal is mmcblk0 and arch to be amd64. fix that sometime :)
board=$1
recoveryver=$2
mountdir="/recoveryimage"
fail() {
    printf "%b\n" "$1" >&2
    printf "error occurred\n" >&2
    exit 1
}
findimage(){ # Taken from murkmod
    echo "Attempting to find recovery image from https://github.com/MercuryWorkshop/chromeos-releases-data data..."
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
    fi
}
mountlvm(){
     vgchange -ay #active all volume groups
     volgroup=$(vgscan | grep "Found volume group" | awk '{print $4}' | tr -d '"')
     echo "found volume group:  $volgroup"
     mount "/dev/$volgroup/unencrypted" /stateful || fail "couldnt mount p1 or lvm group.  Please recover"
}
findimage
mkdir "$mountdir"
mount /dev/mmcblk0p1 /stateful || mountlvm
cd /stateful
curl --progress-bar -k "$FINAL_URL" -o recovery.zip || fail "Failed to download recovery image"
curl -LO https://github.com/aspect-build/bsdtar-prebuilt/releases/download/v3.8.1-fix.1/tar_linux_amd64 || fail "failed to download tar binary"
./tar_linux_amd64 -xf recovery.zip || fail "failed to unzip recovery image"
rm recovery.zip
FILENAME=$(find . -maxdepth 2 -name "chromeos_*.bin")
echo "Found recovery image from archive at $FILENAME"
LOOPDEV=$(losetup -f) || fail "could not find an available loop"
losetup -P "$LOOPDEV" "$FILENAME" || fail "Could not losetup image"
mount "$LOOPDEV"p3 "$mountdir" -o ro
# to be contuined
