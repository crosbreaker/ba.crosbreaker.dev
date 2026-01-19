#!/bin/sh
#skiddy mrchromebox for miniOS script 
mount /dev/mmcblk0p3 /usb -o ro || /dev/mmcblk0p5 /usb -o ro
mount --bind /dev /usb/dev
mount --bind /proc /usb/proc
mount --bind /sys /usb/sys
mount --bind /run /ush/run
mount --bind /tmp /usb/tmp
chroot /usb "cd /tmp && curl -LO https://mrchromebox.tech/firmware-util.sh && bash firmware-util.sh"
