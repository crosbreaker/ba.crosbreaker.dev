#!/bin/sh
#skiddy mrchromebox for miniOS script 
mount /dev/mmcblk0p3 /usb -o ro || /dev/mmcblk0p5 /usb -o ro
mount --bind /dev /usb/dev
mount --bind /proc /usb/proc
mount --bind /sys /usb/sys
mount --bind /run /ubh/run
mount --bind /tmp /usb/tmp
curl -L https://mrchromebox.tech/firmware-util.sh -O /tmp/firmware-util.sh
chroot usb bash /tmp/firmware-util.sh
