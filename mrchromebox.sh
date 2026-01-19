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
#write script out to /tmp (idk if there is a better way to do this lol)
echo "cd /tmp" > /tmp/payload.sh
echo "bash /tmp/firmware-util.sh" >> /tmp/payload.sh
chroot /usb bash /tmp/payload.sh
umount /usb/*
umount /usb
sync
echo "exiting to minios shell"
