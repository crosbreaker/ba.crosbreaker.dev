#!/bin/bash
fail(){
	printf "$1\n"
	printf "error occurred\n"
	exit
}
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

board=$(echo "$BOARD" | tr '[:upper:]' '[:lower:]')


scripthost="https://crosbreaker.pages.dev/ba"
kernroothost="https://nightly.link/crosbreaker/sh1mmer/actions/runs/17003742014/$board"
scriptname="br0ker_part2.sh"
directory="/br0ker"
echo "Starting br0ker payload download ($board)"
echo "Making needed directory..."
mkdir "$directory"
echo "Moving to new directory"
cd "$directory"
echo "Downloading the rest of this script"
curl -LO "$scripthost/$scriptname" || fail "br0ker_part2.sh failed to download"
echo "Downloading root. THIS WILL TAKE TIME!  THIS IS LIKELY NOT FROZEN"
curl --progress-bar -LO ""$kernroothost"_root.gz.zip" || fail "root.gz failed to download"
echo "Downloading kern"
curl -LO ""$kernroothost"_kern.gz.zip" || fail "kern.gz failed to download"
unzip ""$board"_root.gz.zip" || fail "failed to unzip root.gz.zip"
unzip ""$board"_kern.gz.zip" || fail "failed to unzip kern.gz.zip"
cd /
sh "$directory/$scriptname"
echo "Something went wrong!  You shouldn't have gotten this far"
exit
