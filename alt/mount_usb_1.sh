#!/bin/bash

source ../common/dcp_functions.sh

# umount /media/"$SUDO_USER"/*
# umount /mnt/usb*

udevadm info -q path -n /dev/sd*1 | grep usb | awk 'BEGIN {FS = "[/]"} {print $(NF-6), $NF}' | awk 'BEGIN {FS = "[-: ]"} {print $1, $2, $4}' | \
while IFS=' ' read -r i j k
do
    echo $i $j $k
    # lsblk -l -o NAME,MOUNTPOINT | awk '{print $1}' | while read -r l
    # disk_list | while read -r l
    # do
        # echo $l
        # if [[ $k == "$l"1 ]]; then
            echo Mounting /dev/"$k" to /mnt/usb_b"$i"_p"$j"
            if [ ! -d /mnt/usb_b"$i"_p"$j" ]; then mkdir /mnt/usb_b"$i"_p"$j"; fi
            mount -t auto /dev/"$k" /mnt/usb_b"$i"_p"$j"
        # fi
    # done
done