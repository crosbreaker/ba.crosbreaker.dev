#!/bin/sh
mountlvm(){
     vgchange -ay #active all volume groups
     volgroup=$(vgscan | grep "Found volume group" | awk '{print $4}' | tr -d '"')
     echo "found volume group:  $volgroup"
     mount "/dev/$volgroup/unencrypted" /stateful || fail "couldnt mount p1 or lvm group.  Please recover"
}
mount /dev/mmcblk0p1 /stateful || mountlvm
touch /stateful/.developer_mode
sleep 3 # wait for disk activity to stop / write changes to disk
umount /stateful
echo "5 minute wait skipped"
