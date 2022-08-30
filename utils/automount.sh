#!/bin/bash

source ../common/dcp_functions.sh

echo -e "Automounting disks..."; echo
for i in $(lsblk | grep disk | awk '{print $1}' | grep -Ev $protected_disks | sort); do
    udisksctl mount --options noatime -b /dev/"$i"1
done
echo