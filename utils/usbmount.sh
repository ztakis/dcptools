#!/bin/bash

source ../common/dcp_functions_combo.sh

echo; echo -e "${b_blue}usbmount ${clear}${b_green}v$version${clear}"; echo

root_check
automount_disks
echo

exit 0