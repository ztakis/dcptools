#!/bin/bash

# version=v1.1

source /opt/dcptools/common/local_config

if [ $EUID -ne 0 ]; then
    echo; echo -e "\033[1;93mError: Must be root\033[0m"; echo; exit 1
fi

# mapfile -t auto_mounted < <(grep '/dev/sd' /proc/mounts | grep -Ev $excluded_disks)
mapfile -t auto_mounted < <(grep '/dev/sd' /proc/self/mounts | grep -Ev $protected_disks)

echo; printf "%s\t\t%s\t\t\t%s\n" "DISK" "SERIAL" "MOUNTPOINT" 
echo "-----------------------------------------------------------------------"
for i in "${auto_mounted[@]}"; do
    dev=$(echo "$i" | awk '{print $1}')
    serial=$(smartctl -i "$dev" | grep 'Serial' | awk '{print $3}')
    mountpoint=$(echo "$i" | awk '{print $2}')
    printf "%s\t%s\t\t%s\n" "$dev" "$serial" "$mountpoint" 
done
echo