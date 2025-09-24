#!/bin/bash

# TODO: add checks for cryptohome / device_management_client failing to remove FWMP?
# improve the look and also show if FWMP is active when the menu shows
# add an option to set FWMP
# add check for being root/chronos and adjust the commands being run

get_device_info() {
    CROS_VER=$(grep -m 1 "^CHROMEOS_RELEASE_CHROME_MILESTONE=" /etc/lsb-release | cut -d'=' -f2)
    if [ "$CROS_VER" -le 124 ]; then
        FULL_FWMP_OUTPUT=$(cryptohome --action=get_firmware_management_parameters)
        CUR_FWMP=$(echo "$FULL_FWMP_OUTPUT" | grep "flags=" | cut -d'=' -f2)
    else
        FULL_FWMP_OUTPUT=$(device_management_client --action=get_firmware_management_parameters)
        CUR_FWMP=$(echo "$FULL_FWMP_OUTPUT" | grep "flags=" | cut -d'=' -f2)
    fi
    if [ "$CUR_FWMP" != "0x00000000" ]; then # read line 38
        FWMP_ACTIVE=1
    else
        FWMP_ACTIVE=0
    fi
}

clear
echo "This is not an unenrollment script. it assumes you are in VT2 logged in as root."
echo "This was made to be able to easily remove FWMP with gbb flags set."
echo "If you end up re enrolling you can run the following in the SH1MMER bash shell (might need to boot with CTRL+U) to unblock devmode:"
echo "vpd -i RW_VPD -s block_devmode=0"
echo "crossystem block_devmode=0"
echo "The above commands will not remove FWMP, that is what this script is for."
echo ""
read -p "Press enter to continue."

while true; do
    clear
    echo ""
    echo "crosbreaker FWMP utility"
    echo "https://crosbreaker.dev/"
    echo ""
    echo "(1) Check for FWMP" # is there a better way to do this?
    echo "(2) Get current FWMP flags"
    echo "(3) Remove FWMP"
    echo "(4) Exit"
    echo ""
    read -p "> " choice
    echo ""

    case "$choice" in
        1)
            get_device_info
            if [ "$FWMP_ACTIVE" -eq 1 ]; then
                echo "FWMP is active."
            else
                echo "FWMP is not active."
            fi
            ;;
        2)
            get_device_info
            echo "Current FWMP Flags: $CUR_FWMP"
            ;;
        3)
            get_device_info
            if [ "$FWMP_ACTIVE" -eq 1 ]; then # ill test this later
                echo "Attempting to remove FWMP..."
                echo "Taking ownership of the tpm..."
                TPM_OWNERSHIP_OUTPUT=$(tpm_manager_client take_ownership)
                if echo "$TPM_OWNERSHIP_OUTPUT" | grep -q "STATUS_SUCCESS"; then
                    echo "Success."
                    if [ "$CROS_VER" -le 124 ]; then
                        echo "ChromeOS is on version 124 or lower. going through OOBE after this should not enroll the device." # sommeone correct this if im wrong
                        echo "Removing FWMP..."
                        cryptohome --action=remove_firmware_management_parameters # should probably add a check for this failing.
                        echo "Setting VPD..."
                        vpd -i RW_VPD -s check_enrollment=0
                        echo "Done."
                    else
                        echo "ChromeOS is on a version higher than 124. going through OOBE after this will still enroll the device." # idk if its 124 or 114 but this should still be right
                        echo "Removing FWMP..."
                        device_management_client --action=remove_firmware_management_parameters # same with this one
                        # vpd -i RW_VPD -s check_enrollment=0 --- I dont think this is needed past 124 because it will always try to reenroll, right?
                        echo "Done."
                    fi
                else
                    echo "FAILED: Could not take TPM ownership."
                fi
            else
                echo "FWMP is not active."
            fi
            ;;
        4)
            echo "bye"
            exit 0
            ;;
        *)
            echo "wrong choice."
            ;;
    esac
    echo ""
    read -p "Press enter to go back."
done
