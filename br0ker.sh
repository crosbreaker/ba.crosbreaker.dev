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


scripthost="https://cdn.crosbreaker.dev/"
kernroothost="https://nightly.link/crosbreaker/sh1mmer/actions/runs/17080634078/$board"
scriptname="br0ker_part2.sh"
directory="/br0ker"
echo "Starting br0ker payload download ($board)"
echo "Making needed directory..."
mkdir "$directory"
echo "Moving to new directory"
cd "$directory"
echo "Downloading the rest of this script"
curl -LO "$scripthost/$scriptname" || fail "br0ker_part2.sh failed to download"
cd /
sh "$directory/$scriptname"
echo "Something went wrong!  You shouldn't have gotten this far"
exit
