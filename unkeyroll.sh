#!/bin/bash

# This script downloads a recovery key file and applies it to the firmware using futility.  This script is ONLY intended for use on Dedede, Nissa or Corsola. Use at your own risk. I might add more keyrolled devices in the near future
# Skidded from https://github.com/Cruzy22k/Firmware2 by HarryJarry1
mkdir /unkeyroll > /dev/null
DOWNLOADS_DIR="/unkeyroll"
RECOVERY_KEY_NISSA="https://raw.githubusercontent.com/Cruzy22k/NissaFW2/main/nissa_recovery_v1.vbpubk"
RECOVERY_KEY_NISSA_FILE="nissa_recovery_v1.vbpubk"
RECOVERY_KEY_DEDEDE="https://raw.githubusercontent.com/Cruzy22k/NissaFW2/main/dedede_recovery_v1.vbpubk"
RECOVERY_KEY_DEDEDE_FILE="dedede_recovery_v1.vbpubk"
RECOVERY_KEY_CORSOLA="https://raw.githubusercontent.com/Cruzy22k/NissaFW2/main/corsola_recovery_v1.vbpubk"
RECOVERY_KEY_CORSOLA_FILE="corsola_recovery_v1.vbpubk"

echo -e "\e[32m<Firmware2>  Copyleft (C) 2024  Cruzy22k\e[0m"
echo -e "\e[32mThis program comes with ABSOLUTELY NO WARRANTY.\e[0m"
echo -e "\e[32mThis is free software, and you are welcome to redistribute it under certain conditions.\e[0m"
echo "modified by kraeb and HarryJarry1"
echo


echo -e "Select your board\ndedede (1)\nnissa (2)\ncorsola (3)"
echo    
read -p "Enter the number of the device you have: " -n 1 -r
echo   


# echo "DEBUG: You entered '$REPLY'" (this is not necessary)
if [[ $REPLY =~ ^[1]$ ]]; then
    RECOVERY_KEY_URL="$RECOVERY_KEY_DEDEDE"
    RECOVERY_KEY_FILE="$RECOVERY_KEY_DEDEDE_FILE"
elif [[ $REPLY =~ ^[2]$ ]]; then
    RECOVERY_KEY_URL="$RECOVERY_KEY_NISSA"
    RECOVERY_KEY_FILE="$RECOVERY_KEY_NISSA_FILE"
elif [[ $REPLY =~ ^[3]$ ]]; then
    RECOVERY_KEY_URL="$RECOVERY_KEY_CORSOLA"
    RECOVERY_KEY_FILE="$RECOVERY_KEY_CORSOLA_FILE"
else
    echo "Invalid input. Please enter your board as instructed."
    exit 1
fi

#again, not necessary Debug output:
#echo "DEBUG: Selected URL: $RECOVERY_KEY_URL"
#echo "DEBUG: Selected file name: $RECOVERY_KEY_FILE"

mkdir -p "$DOWNLOADS_DIR"
echo "Downloading the recovery key file..."
cd "$DOWNLOADS_DIR" || exit 1
curl -L -o "$RECOVERY_KEY_FILE" "$RECOVERY_KEY_URL"
if [ ! -f "$RECOVERY_KEY_FILE" ]; then
    echo "Failed to download the recovery key file."
    exit 1
fi


echo "Downloaded the recovery key file to $DOWNLOADS_DIR/$RECOVERY_KEY_FILE."

# Ask for confirmation before applying the recovery key
flashrom -p internal --wp-disable # if HWWP is off, this'll work, this is more of a safety check
echo "WARNING: Before proceeding, ensure that Write Protect (WP) is disabled on your device."
echo "Failure to disable WP may result in the recovery key not being applied correctly."
read -p "Are you sure you want to apply the recovery key with futility? (y/n) " -n 1 -r
echo    
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting the process."
    exit 1
fi


echo "Applying recovery key..."
futility gbb -s --flash --recoverykey="$DOWNLOADS_DIR/$RECOVERY_KEY_FILE"
if [ $? -eq 0 ]; then
    echo "Successfully applied the recovery key."
else
    echo "Failed to apply recovery key!"
    exit 1
fi
echo "Process completed successfully, reboot and try to boot a shim" 
echo " "
echo "Made by cruzy22k - qol fixes by kraeb, port to the BadApple terminal by HarryJarry1" 
echo ":)"
echo " A reboot is required for the changes to take effect."
echo " "
read -p "Do you want to reboot now? (y/n) " -n 1 -r
echo   
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot -f
fi

echo   

echo "Please reboot your system manually to see changes take effect"
