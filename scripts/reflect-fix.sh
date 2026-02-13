#!/bin/bash

TITLE="Arch Linux Mirror Updater"

# Timezone-based state grouping
ZONE=$(whiptail --title "$TITLE" --menu "Select your timezone region:" 15 60 4 \
    "pacific"  "Pacific (CA, OR, WA, NV)" \
    "mountain" "Mountain (CO, AZ, UT, MT)" \
    "central"  "Central (TX, IL, MN, WI)" \
    "eastern"  "Eastern (NY, FL, PA, GA)" \
    3>&1 1>&2 2>&3) || exit 1

# Sort method
SORT=$(whiptail --title "$TITLE" --menu "Sort mirrors by:" 15 60 3 \
    "rate"  "Download speed" \
    "score" "Mirror score" \
    "age"   "Last sync time" \
    3>&1 1>&2 2>&3) || exit 1

# Number of mirrors
NUM_MIRRORS=$(whiptail --title "$TITLE" --inputbox "How many mirrors to save?" 10 60 "10" \
    3>&1 1>&2 2>&3) || exit 1

# Confirmation
whiptail --title "$TITLE" --yesno "Run reflector with these settings?\n\n\
Region: $ZONE\n\
Country: US\n\
Sort by: $SORT\n\
Protocol: https\n\
Mirrors: $NUM_MIRRORS" 15 60 || exit 1

# Backup current mirrorlist
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

# Run reflector
{
    echo 10
    echo "XXX"
    echo "Running reflector..."
    echo "XXX"
    sudo reflector --country US --protocol https --sort "$SORT" \
        --latest "$NUM_MIRRORS" --save /etc/pacman.d/mirrorlist 2>&1
    echo 100
} | whiptail --title "$TITLE" --gauge "Updating mirrors..." 8 60 0

if [ $? -eq 0 ]; then
    whiptail --title "$TITLE" --msgbox "Mirrorlist updated!\n\nBackup: /etc/pacman.d/mirrorlist.bak" 10 60
else
    whiptail --title "$TITLE" --msgbox "Error! Restoring backup..." 10 60
    sudo cp /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist
fi
