#!/bin/sh
#skiddy mrchromebox for miniOS script
cd /
mount /dev/mmcblk0p3 /usb -o ro || /dev/mmcblk0p5 /usb -o ro
mount --bind /dev /usb/dev
mount --bind /proc /usb/proc
mount --bind /sys /usb/sys
mount --bind /run /usb/run
mount --bind /tmp /usb/tmp
cd /tmp
curl -LO https://mrchromebox.tech/firmware-util.sh
cd /
chroot usb bash /tmp/firmware-util.sh
