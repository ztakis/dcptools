#!/bin/bash

source ../common/dcp_functions.sh


function get_dcp {
    echo; echo -en "${b_blue}Drag and drop DCP folder and press [ENTER]: ${clear}"
    read -re input; if [ -z "$input" ]; then echo; exit 1; fi
    source=$(echo "$input" | tr -d "'")
    dcp_folder=$(basename "$source")
}

function perms {
    echo -e "Setting ownership to${b_yellow} $2:$2 + $3 ${clear}permissions to $1"
    chown -R "$2":"$2" "$1"
    if [ "$3" == "full" ]; then
        chmod -R 777 "$1"
    elif [ "$3" == "normal" ]; then
        find "$1" -type d | while read -r dir; do chmod 755 "$dir"; done
        find "$1" -type f | while read -r file; do chmod 644 "$file"; done
    fi
}

function set_perms {
    get_dcp
    if [[ $3 == "-d" ]]; then
        dest=$(ls -d /media/"$SUDO_USER"/*/"$dcp_folder")
        echo -e "${b_blue}DCP is: ${clear}""$dcp_folder"
        echo -e "${b_blue}Destnations are: ${clear}"
        echo "$dest"
        confirm
        for i in $dest; do perms "$i" "$1" "$2"; done
    else
        echo; echo -e "${b_blue}Source is: ${clear}""$source"
        confirm
        perms "$source" "$1" "$2"
    fi
}

function permissions_menu {
    echo; echo "------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "------------------------"
    export COLUMNS=20
    select perms in "normal_root" "full_root" "normal_1000" "full_1000" "Exit"
        do
            case $perms in
                "normal_root") echo; set_perms root normal "$1"; break;;
                "full_root") echo; set_perms root full "$1"; break;;
                "normal_1000") echo; set_perms 1000 normal "$1"; break;;
                "full_1000") echo; set_perms 1000 full "$1"; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

#########################  Main  ########################

echo; echo -e "${b_blue}perms_set ${clear}${b_green}$version${clear}"

if [[ $EUID -ne 0 ]]; then
    echo; echo -e "${b_yellow}Error: Must be root${clear}"; echo; exit 1
fi

permissions_menu "$1"

echo; echo -e "${b_green}Finished${clear}"; echo
exit 0