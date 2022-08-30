#!/bin/bash

version=0.6
echo $version > /dev/null   # to quiet shellcheck

source /opt/dcptools/common/local_config

delay=5
long_delay=60
extra_long_delay=240

#######################  Colors  #######################

b_red='\033[0;91m'
b_green='\033[1;92m'
b_yellow='\033[0;93m'
b_blue='\033[1;94m'
clear='\033[0m'

##################  Common functions  ##################

function confirm {
    echo -en "${b_blue}Continue?${clear} (y/N): "
    read -re reply && [[ $reply == [yY] || $reply == [yY][eE][sS] ]] || exit 1
}

function confirm_t {
    for (( i=$1; i>=0; i--)); do
        echo -en "\r${b_blue}Auto continue in${clear} $i ${b_blue}sec${clear} (y/n): "
        read -t 1 -n 1 -re reply
        if [[ $reply == [yY] ]]; then
            echo -n "Continuing..."; break
        elif [[ $reply == [nN] ]]; then
            echo "Exiting..."; echo; exit 1
        fi
    done
}

function auto_continue {
    for (( i=$1; i>=0; i--)); do
        echo -en "\r${b_blue}Auto continue in${clear} $i ${b_blue}sec${clear} (Press Ctrl+C to cancel) "
        sleep 1
    done
}

function spinner {
    arr=("-" "\\" "|" "/" "-")
    while true; do
        for x in "${arr[@]}"; do
            echo -en "\r${b_yellow}Please wait...${clear}  $x  Time elapsed: $(date -ud @$(( SECONDS - start )) +%T) "
            sleep .025
        done
    done
}

function disk_list {
    lsblk | grep disk | awk '{print $1}' | grep -Ev $protected_disks | sort
}

function root_check {
    if [ $EUID -ne 0 ]; then
        echo -e "${b_yellow}Error: Must be root${clear}"; echo; exit 1
    fi
}

function no_disk_check {
    if [ -z "$(disk_list)" ]; then
        echo -e "${b_yellow}Error: No disk(s) found.${clear}"; echo; exit 1
    fi
}

function automount_disks {
    echo -e "${b_blue}Automounting disks...${clear}"
    for disk in $(disk_list); do
        sudo -u "${SUDO_USER}" udisksctl mount --options noatime -b /dev/"$disk"1
    done
}

function destination_check {
    if [ -z "$(find /media/"$SUDO_USER"/* -prune -type d 2>/dev/null)" ]; then
    # if [ -z "$(find /media/"$USER"/* -prune -type d 2>/dev/null)" ]; then
        echo -e "${b_yellow}Error: No destination disks found in:${clear} /media/$SUDO_USER"; echo
        echo -e "${b_blue}Try to automount ?${clear}"
        confirm_t $delay; echo
        automount_disks
        sleep 1
    fi
}

function get_destinations {
    destination_check
    mapfile -t usb_list < <(find /media/"$SUDO_USER"/* -prune -type d | sort -V)
    usb_count=${#usb_list[@]}
    disk_counter=$usb_count
    for ((p=0; p<usb_count; p++)); do prev+=(0); done
    for ((r=0; r<usb_count; r++)); do rem+=(0); done
    echo -e "${b_yellow}Destination disks found in:${clear} /media/$SUDO_USER"
    for bname in "${usb_list[@]}"; do basename "$bname"; done
    echo -e "${b_yellow}Total disks found:${clear} $usb_count"
}

function get_threads {
    while [ -z "$valid_threads" ] ; do
    echo -en "${b_blue}Enter the number of disks for each batch : ${clear}"
    read -re threads
    if [[ "$threads" -gt "$disk_counter" || "$threads" -eq "0" ]]; then
        echo "Invalid input"; else valid_threads=1
    fi
    done
}

function get_sources {
    while true; do
        input=""
        while [ -z "$input" ] ; do
            echo -en "${b_blue}Drag and drop source folder and press [ENTER]: ${clear}"
            read -re input
            if [ -z "$input" ]; then
                echo; echo -e "${b_yellow}Error: source path cannot be empty${clear}"
            fi
        done
        source_path=$(echo "$input" | tr -d "'")
        source_folder=$(basename "$source_path")
        src_path_list+=("$source_path")
        src_folder_list+=("$source_folder")
        echo -e "${b_yellow}DCP sources are:${clear}"
        printf "%s\n" "${src_folder_list[@]}"
        # echo -e "${b_yellow}DCP sources paths are:${clear}"
        # printf "%s\n" "${src_path_list[@]}"
        echo; echo -en "${b_blue}Add another?${clear} (y/N): "
        read -rp "" reply
        if [[ $reply == [yY] || $reply == [yY][eE][sS] ]]; then continue; else break; fi
    done
}

function byte_check {
    for source in "${src_path_list[@]}"; do
        echo; echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb "$source"
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------"
        for d in "${usb_list[@]}"; do du -sb --exclude=lost+found "$d"/"$(basename "$source")"; done
    done
}

function get_serials {
    mapfile -t auto_mounted < <(grep '/dev/sd' /proc/self/mounts | grep -Ev $protected_disks)
    printf "%s\t\t%s\t\t\t%s\n" "DISK" "SERIAL" "MOUNTPOINT"
    echo "-----------------------------------------------------------------"
    for u in "${auto_mounted[@]}"; do
        dev=$(echo "$u" | awk '{print $1}')
        serial=$(smartctl -i "$dev" | grep 'Serial' | awk '{print $3}')
        mountpoint=$(echo "$u" | awk '{print $2}')
        printf "%s\t%s\t\t%s\n" "$dev" "$serial" "$mountpoint"
    done
}

################## DiskPrep Functions ##################-------------------------------------------------------------------------------------

function unmount_disks {
    if grep '/dev/sd' /proc/mounts | grep -Evq $protected_disks; then
        echo -e "${b_yellow}Found mounted disk(s). Unmounting...${clear}"
        umount -f /media/"$SUDO_USER"/*
    fi
    if grep '/dev/sd' /proc/mounts | grep -Evq $protected_disks; then
        echo -e "${b_yellow}Error: Unmounting disk(s) failed. Exiting...${clear}"; echo; exit 1
    fi
}

function get_label {
    while [ -z "$valid_label" ] ; do
        echo -en "${b_blue}Enter disk label: ${clear}"
        read -re label
        if [[ $label = "" ]]; then
            echo -e "${b_yellow}Error: label name cannot be empty${clear}"
        elif [ ${#label} -gt 16 ]; then
            echo -e "${b_yellow}Error: label has more than 16 characters${clear}"
        elif [[ $label = *" "* ]]; then
            echo -e "${b_yellow}Error: label contains spaces${clear}"
        # elif [[ $label = *[~!\#$%^\&*()[]{}\;\'\\:\"\|,./\<\>?]* ]]; then             TBD
        #     echo -e "${b_yellow}Error: label contains illegal characters${clear}"
        else valid_label=1
        fi
    done
    echo; echo -en "${b_blue}Disk(s) will be labeled as:${clear} $label"
}

function disks_found {
    disk_counter=0
    for disk in $(disk_list); do
    ((disk_counter++)); echo "Found disk: $disk"; done
    echo; echo -e "${b_blue}Total disks found:${clear} $disk_counter"
}

function diskprep_start {
    unmount_disks
    trap "" SIGINT  # Ctrl+C blocked
    start=$SECONDS
    echo
    spinner &
    SPIN_PID=$!
    disown
}

function diskprep_end {
    kill -9 $SPIN_PID; echo; echo; sleep 1
    echo -e "${b_green}Finished in:  $(date -ud @$(( SECONDS - start )) +%T)${clear}"
    trap - SIGINT # Ctrl+C restored to default
    sleep 1
}

function show_disks {
    echo; echo -e "${b_blue}Showing disk list:${clear}"
    lsblk -o name,type,size,label,fstype,mountpoint | grep -Ev $protected_disks
    parts_num=$(lsblk -ln | grep -Ev $protected_disks | grep -c part)
    echo; echo -e "${b_blue}Total disks found:${clear} $parts_num"
}

function init_disk {
    for i in $(disk_list); do
        parted --script /dev/"$i" mklabel msdos -a optimal mkpart primary ext2 0% 100%
        partprobe /dev/"$i"
        sleep 1
    done
    for i in $(disk_list); do
        mkfs.ext2 -q -I 128 -L "$label" -F /dev/"$i"'1' &
        partprobe /dev/"$i"
        sleep 1
    done
    wait && sleep 2
}

function init_disk_b {
    for i in $(disk_list); do
        parted --script /dev/"$i" mklabel msdos -a optimal mkpart primary ext2 0% 100%
        partprobe /dev/"$i"
        sleep 1
    done
    for i in $(disk_list); do
        if (( j % threads == 0 )); then
            wait
        fi
        ((j++))
        mkfs.ext2 -q -I 128 -L "$label" -F /dev/"$i"'1' &
        partprobe /dev/"$i"
        sleep 1
    done
    wait && sleep 2
}

function label_disk {
    for i in $(disk_list); do
        e2label /dev/"$i"'1' "$label" && sleep 2
    done
}

function diskprep_warning {
    echo -e "${b_red}!!! ==================== WARNING =================== !!!${clear}"
    echo -e "${b_yellow}!!! Any removable ${clear}${b_red}source${clear}${b_yellow} disk might be formatted too !!!${clear}"; echo
    echo -e "${b_blue}Protected disks: ${clear}${b_yellow}$protected_disks${clear}"; echo
}

function init_all {
    confirm
    diskprep_warning
    disks_found
    confirm
    get_label
    confirm
    diskprep_start
    init_disk
    diskprep_end
}

function batch_init {
    confirm
    diskprep_warning
    disks_found
    confirm
    get_threads
    confirm
    get_label
    confirm
    diskprep_start
    init_disk_b
    diskprep_end
}

function label_only {
    confirm
    disks_found
    confirm
    get_label
    confirm
    diskprep_start
    label_disk
    diskprep_end
}

function diskprep_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Initialize all" "Initialize in batches" "Label only" "Exit"
        do
            case $opt in
                "Initialize all") echo; echo -e "${b_yellow}$opt${clear}"; init_all; break;;
                "Initialize in batches") echo; echo -e "${b_yellow}$opt${clear}"; batch_init; break;;
                "Label only") echo; echo -e "${b_yellow}$opt${clear}"; label_only; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function diskprep_main {
    root_check
    no_disk_check
    diskprep_menu
    automount_disks
    show_disks
}

################## CopyDCP Functions ##################------------------------------------------------------------------------------------------------------------



function set_source_permissions {
    if [ "$1" == "-f" ]; then
        echo -e "${b_yellow}Setting DCP source ownership to ${clear}${b_red}root:root${clear}"\
        "+ ${b_green}full (777)${clear}${b_yellow} permissions${clear}"
        chown -R root:root "$source"
        chmod -R 777 "$source"
    elif [ "$1" == "-n" ]; then
        echo -e "${b_yellow}Setting DCP source ownership to ${clear}${b_red}root:root${clear}"\
        "+ ${b_blue}normal (755,644)${clear}${b_yellow} permissions${clear}"
        chown -R root:root "$source"
        find "$source" -type d | while read -r dir; do chmod 755 "$dir"; done
        find "$source" -type f | while read -r file; do chmod 644 "$file"; done
    else
        echo -e "${b_yellow}Setting DCP source ownership to ${clear}${b_blue}1000:1000${clear}"\
        "+ ${b_green}full (777)${clear}${b_yellow} permissions${clear}"
        chown -R 1000:1000 "$source"
        chmod -R 777 "$source"
    fi
}

function pre_copy {
    dcp=$(basename "$source")
    echo; echo -en "${b_blue}Source selected:${clear} $dcp"; echo
    set_source_permissions -n
    source_size=$(du -sb --exclude=lost+found "$source" | cut -f 1)
    if [ -z "$(find /media/"$SUDO_USER"/*/"$dcp" -prune -type d 2>/dev/null)" ]; then
        first_time=true
    else
        first_time=false
        echo -e "${b_yellow}Destination DCP folder exists. Will use rsync${clear}"
    fi
    echo
    auto_continue $delay
}

function progressbar {
    output="\n"
    output="$output ["
    total=$1
    count=0
    while [ "$count" -lt "$total" ]; do
        output="$output="
        ((count++))
    done
    output="$output>"
    ((total=100-total))
    count=0
    while [ $count -lt $total ]; do
        output="$output-"
        ((count++))
    done
    output="$output] $(printf "%3d %s %4d %s %s" "$1" "%  -" "$3" "MB/s  - " "$4   ")"
    tput rc
    tput cud $(($2+1))
    echo -e "$output"
}

function multi_bars {
    tput civis
    tput clear
    echo; echo -en "${b_yellow}Now copying:${clear} $dcp"
    tput sc
    t=0
    while true ; do
        for ((j=0; j<usb_count; j++)); do
            dst=${usb_list[j]}
            l=$(basename "$dst")
            if [ -d "$dst"/"$dcp" ]; then
                current_size=$(du -sb --exclude=lost+found "$dst"/"$dcp" | cut -f 1)
                i=$(echo "100 * $current_size / $source_size" | bc)
                k=$(echo "($current_size - ${prev[j]}) / 1000000" | bc)
                if (("$k" > 999)); then k=999; fi
                progressbar "$i" "$j" "$k" "$l"
                rem_bytes=$(( (source_size - current_size) / ((current_size - prev[j]) + 1) ))
                rem[$j]=$rem_bytes
                prev[$j]=$current_size
                else progressbar 0 "$j" 0
            fi
            ((t=t+i))
        done
        elapsed=$((SECONDS-start))
        if [ $t -eq $((usb_count * 100)) ]; then break; else t=0; fi
        if [ "$1" == -b ]; then
        echo; echo -e "${b_blue}Elapsed:${clear} $(date -ud @"$elapsed" +%T)"; echo
        else
            remaining=$(printf "%d\n" "${rem[@]}" | sort -n | tail -1)
            echo; echo -e "${b_blue}Elapsed:${clear} $(date -ud @"$elapsed" +%T)"\
            " /  ${b_blue}Remaining:${clear} $(date -ud @"$remaining" +%T)"; echo
        fi
        sleep 1
    done
    echo; printf "%${COLUMNS}s" ""
    echo -e "${b_green}Finished in:${clear}  $(date -ud @$(( SECONDS - start )) +%T)"; echo
    tput cnorm
}

function copy2all {
    for source in "${src_path_list[@]}"; do
        pre_copy
        start=$SECONDS
        if [ "$first_time" == true ]; then
            for dest in "${usb_list[@]}"; do
                cp -rp "$source" "$dest/" 2>> $temp/error.log &
            done
        elif [ "$first_time" == false ]; then
            for dest in "${usb_list[@]}"; do
                rsync -aq "$source" "$dest/" 2>> $temp/error.log &
            done
        fi
        multi_bars
    done
}

function batch_copy {
    if [ "$1" == true ]; then
        for dest in "${usb_list[@]}"; do
            if ((c % threads == 0)); then wait; fi
            ((c++))
            cp -rp "$source" "$dest/" 2>> $temp/error.log &
        done
    elif [ "$1" == false ]; then
        for dest in "${usb_list[@]}"; do
            if ((c % threads == 0)); then wait; fi
            ((c++))
            rsync -aq "$source" "$dest/" 2>> $temp/error.log &
        done
    fi
}

function copy2all_b {
    for source in "${src_path_list[@]}"; do
        pre_copy
        start=$SECONDS
        batch_copy "$first_time" &
        multi_bars -b
    done
}

function copy_to_all {
    confirm
    get_sources
    copy2all
}

function copy_to_all_in_batches {
    confirm
    get_threads; confirm
    get_sources
    copy2all_b
}

function copy_menu {
    echo; echo "-------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "-------------------------"
    export COLUMNS=20
    select opt in "Copy to all" "Copy to all in batches" "Exit"; do
        case $opt in
            "Copy to all") echo; echo -e "${b_yellow}$opt${clear}"; copy_to_all; break;;
            "Copy to all in batches") echo; echo -e "${b_yellow}$opt${clear}"; copy_to_all_in_batches; break;;
            "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
            * ) echo "Invalid option"
        esac
    done
}

function copy_main {
    root_check
    if [ -f $temp/error.log ]; then
        if [ -s $temp/error.log ]; then
            echo -e "${b_yellow}Previous error.log not empty! Delete?${clear}"
            confirm; rm $temp/error.log
        else rm $temp/error.log
        fi
    fi
    get_destinations
    copy_menu
    sleep 1
    byte_check
    get_serials
    if [ -s $temp/error.log ]; then
        echo; echo -e "${b_yellow}Errors reported! Check error.log for details${clear}"
    fi
    echo
}

################## HashCheck Functions ##################-------------------------------------------------------------------------------------------------------

function make_source_hashes {
    if [ -f "$temp"/hashes.sha1 ]; then rm -f "$temp"/hashes.sha1; fi
    for tmp_file in "$temp"/*.tmp; do
        if [ -f "$tmp_file" ]; then rm -f "$temp"/*.tmp; fi
    done
    xmllint "$source"/PKL_* --xpath '//*[local-name()="Asset"]/*[local-name()="Id"]/text() | //*[local-name()="Hash"]/text()' | xargs -n2 | sort >> "$temp"/hashes.tmp
    xmllint "$source"/ASSETMAP* --xpath '//*[local-name()="Asset"]/*[local-name()="Id"]/text() | //*[local-name()="Path"]/text()' | xargs -n2 | grep -v PKL_ | sort >> "$temp"/paths.tmp
    paste -d " " "$temp"/hashes.tmp "$temp"/paths.tmp | awk '$1=$3{print $2,$4}' >> "$temp"/combo.tmp
    awk '{print $1}' < "$temp"/combo.tmp | while IFS= read -r line; do
    echo -n "$line" | base64 -d | od -t x1 -An | tr -d '\n' | tr -d ' ' | xargs echo >> "$temp"/hex.tmp; done
    paste -d " " "$temp"/hex.tmp "$temp"/paths.tmp | awk '{print $1,"*./"$3}' >> "$temp"/hashes.sha1
    rm "$temp"/*.tmp
}

function cleanup {
    kill -9 "$SPIN_PID"
    pkill -9 -f sha1sum
    echo; echo "Received Ctrl+C"; sleep .5
    echo; echo -e "${b_yellow}Cleaning up...${clear}"
    rm -f "$temp"/hashes.sha1; sleep 1
    echo; echo -e "${b_red}Aborting...${clear}"; echo; exit
}

function hashcheck {
    for source in "${src_path_list[@]}"; do
        start=$SECONDS
        make_source_hashes
        dcp=$(basename "$source")
        echo; echo -en "${b_yellow}Now checking:${clear} $dcp"; echo; echo
        spinner &
        SPIN_PID=$!
        disown
        trap cleanup SIGINT
        for dest in /media/"$SUDO_USER"/*/"$dcp"/; do
            cd "$dest" || exit 1
            if [ "$1" == "-b" ]; then
                if (( j % threads == 0 )); then wait; fi; ((j++))
            fi
            k=$(echo "$dest" | grep -o -P "(?<=/media/$SUDO_USER/).*(?=/$dcp/)")
            # sha1sum -c "$temp"/hashes.sha1 | tee -a "$temp"/"$(date '+%y%m%d%H%M')_$k".log | grep "FAILED" &
            sha1sum -c "$temp"/hashes.sha1 2>> "$temp"/"$(date '+%y%m%d%H%M')"_"$k"_error.log | tee -a "$temp"/"$(date '+%y%m%d%H%M')"_"$k".log | grep "FAILED" &
        done
        wait &&
        sleep 1; kill -9 "$SPIN_PID"; echo; echo; sleep 1
        rm -f "$temp"/hashes.sha1
        echo -e "${b_green}Finished in:  $(date -ud @$(( SECONDS - start )) +%T)${clear}"
    done
}

function hashcheck_all {
    confirm
    get_sources
    hashcheck
}

function hashcheck_all_in_batches {
    confirm
    get_threads; confirm
    get_sources
    hashcheck -b
}

function source_hashcheck {
    confirm
    get_sources
    for source in "${src_path_list[@]}"; do
        start=$SECONDS
        make_source_hashes
        dcp=$(basename "$source")
        echo; echo -en "${b_yellow}Now checking:${clear} $dcp"; echo; echo
        spinner &
        SPIN_PID=$!
        disown
        trap cleanup SIGINT
        cd "$source" || exit 1
        # sha1sum -c "$temp"/hashes.sha1
        # sha1sum -c "$temp"/hashes.sha1 | tee -a "$temp"/"$dcp".log | grep "FAILED"
        sha1sum -c "$temp"/hashes.sha1 2>> "$temp"/"$dcp"_error.log | tee -a "$temp"/"$dcp".log | grep "FAILED"
        wait &&
        sleep 1; kill -9 "$SPIN_PID"; echo; echo; sleep 1
        rm -f "$temp"/hashes.sha1
        echo -e "${b_green}Finished in:  $(date -ud @$(( SECONDS - start )) +%T)${clear}"
    done
}

function bytecheck {
    confirm
    echo -en "${b_blue}Drag and drop source folder and press [ENTER]: ${clear}"
    read -re input
    source=$(echo "$input" | tr -d "'")
    if [ -z "$source" ]; then
        echo; echo; echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb $default_sources_dir/*/
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------"
        # du -sb --exclude={lost+found/,"System Volume Information"/} /media/$SUDO_USER/*/*/
        du -sb --exclude=lost+found/ /media/"$SUDO_USER"/*/*/
    else
        sources_dir=$(dirname "$source")
        dcp=$(basename "$source")
        echo; echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------------------"
        du -sb "$sources_dir/$dcp"/
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------------------"
        du -sb --exclude=lost+found/ /media/"$SUDO_USER"/*/"$dcp"/
    fi
}

function hashcheck_menu {
    echo; echo "------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Source hashcheck" "Hashcheck all" "Hashcheck in batches" "Bytecheck" "Exit"; do
        case $opt in
            "Source hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; source_hashcheck; break;;
            "Hashcheck all") echo; echo -e "${b_yellow}$opt${clear}"; hashcheck_all; break;;
            "Hashcheck in batches") echo; echo -e "${b_yellow}$opt${clear}"; hashcheck_all_in_batches; break;;
            "Bytecheck") echo; echo -e "${b_yellow}$opt${clear}"; bytecheck; break;;
            "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
            * ) echo "Invalid option"
        esac
    done
}

function hashcheck_main {
    root_check
    get_destinations
    hashcheck_menu
}

################# DCPCombo Functions ###################

function init_cp {
    confirm
    no_disk_check
    diskprep_warning
    disks_found
    confirm
    get_label;confirm
    get_sources
    echo; echo -e "${b_yellow}From this point no user interaction is required${clear}"
    auto_continue $delay
    echo
    master_start=$SECONDS
    diskprep_start
    init_disk
    diskprep_end
    automount_disks
    show_disks
    confirm_t $extra_long_delay
    # auto_continue $extra_long_delay
    get_destinations
    copy2all
    sleep 1
    byte_check
    get_serials
    echo; echo -e "${b_green}Total time elapsed:  $(date -ud @$(( SECONDS - master_start )) +%T)${clear}"
}

function init_cp_b {
    master_start=$SECONDS
    confirm
    get_threads; confirm
    get_label;confirm
    get_sources
    echo; echo -e "${b_yellow}From this point no user interaction is required${clear}"
    auto_continue $delay; echo
    diskprep_start
    init_disk_b
    diskprep_end
    automount_disks
    show_disks
    confirm_t $extra_long_delay
    # auto_continue $extra_long_delay
    get_destinations
    copy2all_b
    sleep 1
    byte_check
    get_serials
    echo -e "${b_green}Total time elapsed:  $(date -ud @$(( SECONDS - master_start )) +%T)${clear}"
}

function init_cp_hsck {
    master_start=$SECONDS
    confirm
    diskprep_warning
    disks_found
    confirm
    get_label;confirm
    get_sources
    echo; echo -e "${b_yellow}From this point no user interaction is required${clear}"
    auto_continue $delay; echo
    diskprep_start
    init_disk
    diskprep_end
    automount_disks
    show_disks
    confirm_t $extra_long_delay
    # auto_continue $extra_long_delay
    get_destinations
    copy2all
    confirm_t $long_delay
    # auto_continue $long_delay
    hashcheck
    get_serials
    echo; echo -e "${b_green}Total time elapsed:  $(date -ud @$(( SECONDS - master_start )) +%T)${clear}"
}

function init_cp_hsck_b {
    master_start=$SECONDS
    init_disk
    diskprep_end
    confirm_t $extra_long_delay
    # auto_continue $extra_long_delay
    get_destinations
    copy2all_b
    confirm_t $long_delay
    # auto_continue $long_delay
    hashcheck -b
    get_serials
    echo -e "${b_green}Total time elapsed:  $(date -ud @$(( SECONDS - master_start )) +%T)${clear}"
}

function more_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Initialize + copy in batches" "Initialize + copy + hashcheck in batches" \
    "Label only" "Bytecheck" "Source hashcheck" "Main menu" "Exit"
        do
            case $opt in
                "Initialize + copy in batches") echo; echo -e "${b_yellow}$opt${clear}"; init_cp_b; break;;
                "Initialize + copy + hashcheck in batches") echo; echo -e "${b_yellow}$opt${clear}"; echo "TBD"; break;;
                "Label only") echo; echo -e "${b_yellow}$opt${clear}"; label_only; echo; exit;;
                "Bytecheck") echo; echo -e "${b_yellow}$opt${clear}"; bytecheck; echo; exit;;
                "Source hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; source_hashcheck; echo; exit;;
                "Main menu") echo; echo -e "${b_yellow}$opt${clear}"; main_menu; break;;   # TBD: subnenu
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function main_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:     ${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Initialize + copy" "Initialize + copy + hashcheck" "More options" "Exit"
        do
            case $opt in
                "Initialize + copy") echo; echo -e "${b_yellow}$opt${clear}"; init_cp; break;;
                "Initialize + copy + hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; init_cp_hsck; break;;
                "More options") echo; echo -e "${b_yellow}$opt${clear}"; more_menu; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function combo_main {
    root_check
    main_menu
    if [ -s $temp/error.log ]; then
        echo; echo -e "${b_yellow}Errors reported! Check error.log for details${clear}"
    fi
    echo
}