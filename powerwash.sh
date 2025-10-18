#!/bin/sh
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

. /usr/sbin/write_gpt.sh
load_base_vars
TARGET_DEVICE=$(get_fixed_dst_drive)

if echo "$TARGET_DEVICE" | grep -q '[0-9]$'; then
	TARGET_DEVICE_P="$TARGET_DEVICE"p
else
	TARGET_DEVICE_P="$TARGET_DEVICE"
fi

echo "Found internal disk: $TARGET_DEVICE"
echo "Found internal disk: $TARGET_DEVICE_P"
mount "$TARGET_DEVICE_P"1 /stateful || mountlvm
echo "fast safe keepimg preserve_lvs reason=session_manager_dbus_request" > /stateful/factory_install_reset
sleep 3 # wait for disk activity to stop / write changes to disk
umount /stateful
echo "powerwash should be started on next boot"
