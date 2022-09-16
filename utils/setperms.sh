#!/bin/bash

source ../common/dcp_functions.sh

echo; echo -e "${b_blue}setperms ${clear}${b_green}$version${clear}"; echo

permissions_main "$1"

exit 0