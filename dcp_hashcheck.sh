#!/bin/bash

source common/dcp_functions.sh

echo; echo -e "${b_blue}dcp_hashcheck ${clear}${b_green}v$version${clear}"; echo

hashcheck_main

exit 0