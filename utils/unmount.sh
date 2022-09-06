#!/bin/bash

source ../common/dcp_functions_combo.sh

echo; echo -e "${b_blue}unmount ${clear}${b_green}v$version${clear}"; echo

root_check
unmount_disks

exit 0

# umount /media/"$USER"/*