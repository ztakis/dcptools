#!/bin/bash

version=2.5
echo $version > /dev/null   # to quiet shellcheck

source /opt/dcptools/common/local_config

# short_delay=5
delay=10
long_delay=120
# extra_long_delay=300

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
    echo
}

function confirm_t {
    for (( i=$1; i>=0; i--)); do
        echo -en "\r${b_blue}Continue in${clear} $i ${b_blue}sec${clear} (y/n): "
        read -t 1 -n 1 -re reply
        if [[ $reply == [yY] ]]; then break
            # echo -n "Continuing..."; break
        elif [[ $reply == [nN] ]]; then
            echo "Exiting..."; echo; exit 1
        fi
    done; echo; echo
}

function auto_continue {
    for (( i=$1; i>=0; i--)); do
        echo -en "\r${b_blue}Auto continue in${clear} $i ${b_blue}sec${clear} (Press Ctrl+C to cancel) "
        sleep 1
    done; echo; echo
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
    lsblk | grep disk | awk '{print $1}' | grep -Ev "$protected_disks" | sort
}

function root_check {
    if [ $EUID -ne 0 ]; then
        echo -e "${b_yellow}Error: Must be root${clear}"; echo; exit 1
    fi
}

function error_log_check {
    if [ "$1" == "-h" ]; then
        for log in "$temp"/*_error.log; do
            if [ -s "$log" ]; then
                echo -e "${b_red}Some hashcheck error logs are not empty!${clear}"
            fi
        done
    elif [ "$1" == "-p" ]; then
        if [ -f "$temp"/error.log ]; then
            if [ -s "$temp"/error.log ]; then
                echo -e "${b_yellow}Previous error.log not empty! Delete?${clear}"
                confirm; rm "$temp"/error.log
            else rm "$temp"/error.log
            fi
        fi
    else
        if [ -s "$temp"/error.log ]; then
            echo; echo -e "${b_red}Errors reported while copying! Check error.log for details${clear}"
        fi
    fi
}

function no_disk_check {
    if [ -z "$(disk_list)" ]; then
        echo -e "${b_yellow}Error: No disk(s) found.${clear}"; echo; exit 1
    fi
}

function unmount_disks {
    if grep '/dev/sd' /proc/mounts | grep -Evq "$protected_disks"; then
        echo -e "${b_yellow}Found mounted disk(s). Unmounting...${clear}"; echo
        umount /media/"$SUDO_USER"/* 2>/dev/null
        mapfile -t mntusb < <(grep '/dev/sd' /proc/mounts | grep -Ev "$protected_disks" | awk '{print $2}')
        for usbmnt in "${mntusb[@]}"; do
            umount "$usbmnt"
        done
    fi
    sleep 1
    if grep '/dev/sd' /proc/mounts | grep -Evq "$protected_disks"; then
        echo -e "${b_yellow}Error: Unmounting disk(s) failed. Exiting...${clear}"; echo; exit 1
    fi
}

function automount_disks {
    echo -e "${b_blue}Automounting disks...${clear}"
    for disk in $(disk_list); do
        sudo -u "${SUDO_USER}" udisksctl mount --options noatime -b /dev/"$disk"1
    done; echo
}

function mount_disks_usb {
    echo -e "${b_blue}Mounting disks...${clear}"
    udevadm info -q path -n /dev/sd*1 | grep usb | awk 'BEGIN {FS = "[/]"} {print $(NF-6), $NF}' | \
    awk 'BEGIN {FS = "[-: ]"} {print $1, $2, $4}' | while IFS=' ' read -r usb_bus usb_port diskpart
    do
        echo Mounting /dev/"$diskpart" to /mnt/usb_b"$usb_bus"_p"$usb_port"
        if [ ! -d /mnt/usb_b"$usb_bus"_p"$usb_port" ]; then mkdir /mnt/usb_b"$usb_bus"_p"$usb_port"; fi
        mount -t auto -o no_prefetch_block_bitmaps /dev/"$diskpart" /mnt/usb_b"$usb_bus"_p"$usb_port"
    done
}

function destination_check {
    check_mnt_usb=$(mount -l | grep /mnt/usb_)
    if  [ -z "$check_mnt_usb" ]; then
        echo -e "${b_yellow}Error: No usb destination disks found in:${clear} /mnt/"; echo
        echo -e "${b_blue}Try to mount ?${clear}"
        confirm_t $delay
        umount /media/"$SUDO_USER"/* 2>/dev/null
        mount_disks_usb
        sleep 1
    fi
}

function get_destinations {
    destination_check
    mapfile -t usb_list < <(mount -l | grep /mnt/usb_ | awk '{print $3}' | sort -V)
    # echo "${usb_list[*]}"
    usb_count=${#usb_list[@]}
    disk_counter=$usb_count
    for ((p=0; p<usb_count; p++)); do prev+=(0); done
    for ((r=0; r<usb_count; r++)); do rem+=(0); done
    echo -e "${b_yellow}Destination disks found in:${clear} /mnt/"
    for bname in "${usb_list[@]}"; do basename "$bname"; done
    echo -e "${b_yellow}Total disks found:${clear} $usb_count"; echo
}

function get_threads {
    while [ -z "$valid_threads" ] ; do
    echo -en "${b_blue}Enter the number of disks for each batch : ${clear}"
    read -re threads
    if [[ "$threads" -gt "$disk_counter" || "$threads" -eq "0" ]]; then
        echo "Invalid input"; else valid_threads=1
    fi
    done
    confirm
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
        if [[ $reply == [yY] || $reply == [yY][eE][sS] ]]; then echo; continue; else break; fi
    done
    echo
}

function byte_check {
    for source in "${src_path_list[@]}"; do
        echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb "$source"
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------"
        for d in "${usb_list[@]}"; do du -sb --exclude=lost+found "$d"/"$(basename "$source")"; done
        echo; echo
    done
}

function get_serials {
    mapfile -t auto_mounted < <(grep '/dev/sd' /proc/self/mounts | grep -Ev "$protected_disks")
    printf "%s\t\t%s\t\t\t%s\n" "DISK" "SERIAL" "MOUNTPOINT"
    echo "-----------------------------------------------------------------"
    for u in "${auto_mounted[@]}"; do
        dev=$(echo "$u" | awk '{print $1}')
        serial=$(smartctl -i "$dev" | grep 'Serial' | awk '{print $3}')
        mountpoint=$(echo "$u" | awk '{print $2}')
        printf "%s\t%s\t\t%s\n" "$dev" "$serial" "$mountpoint" >> "$temp"/serials.txt
    done
    sort -k 3 -V "$temp"/serials.txt | cat
    rm "$temp"/serials.txt
    echo
}

################## DiskPrep Functions ##################-------------------------------------------------------------------------------------

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
        elif [[ $label =~ [^a-zA-Z0-9_]  ]]; then
            echo -e "${b_yellow}Error: label contains illegal characters${clear}"
        else valid_label=1
        fi
    done
    echo; echo -en "${b_blue}Disk(s) will be labeled as:${clear} $label"; echo
    confirm
}

function disks_found {
    disk_counter=0
    for disk in $(disk_list); do
    ((disk_counter++)); echo "Found disk: $disk"; done
    echo; echo -e "${b_blue}Total disks found:${clear} $disk_counter"; echo
}

function diskprep_start {
    unmount_disks
    trap "" SIGINT  # Ctrl+C blocked
    start=$SECONDS
    echo -e "${b_yellow}Initializing disk(s)...${clear}"
    echo "------------------------------------------------"
    spinner &
    SPIN_PID=$!
    disown
}

function diskprep_end {
    kill -9 $SPIN_PID; echo; echo; sleep 1
    echo -e "${b_green}Finished in:  $(date -ud @$(( SECONDS - start )) +%T)${clear}"; echo
    trap - SIGINT # Ctrl+C restored to default
    sleep 1
}

function show_disks {
    echo -e "${b_blue}Showing disk list:${clear}"
    lsblk -o name,type,size,label,fstype,mountpoint | grep -Ev "$protected_disks"
    parts_num=$(lsblk -ln | grep -Ev "$protected_disks" | grep -c part)
    echo; echo -e "${b_blue}Total disks found:${clear} $parts_num"; echo
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
    echo -e "${b_blue}Protected disks: ${clear}${b_yellow}""$protected_disks""${clear}"; echo
}

function init_all {
    confirm
    diskprep_warning
    disks_found
    confirm
    get_label
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
    get_label
    diskprep_start
    init_disk_b
    diskprep_end
}

function label_only {
    confirm
    disks_found
    confirm
    get_label
    diskprep_start
    label_disk
    diskprep_end
}

function diskprep_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
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
    echo -en "${b_blue}Source selected:${clear} $dcp"; echo
    set_source_permissions -n
    source_size=$(du -sb --exclude=lost+found "$source" | cut -f 1)
    if [ -z "$(find /mnt/usb_*/"$dcp" -prune -type d 2>/dev/null)" ]; then
        first_time=true
    else
        first_time=false
        echo -e "${b_yellow}Destination DCP folder exists. Will use rsync${clear}"
    fi
    echo
    confirm_t $delay
}

function progressbar {
    output="\n"
    output="$output ["
    total=$(($1/2))
    count=0
    while [ "$count" -lt "$total" ]; do
        output="$output="
        ((count++))
    done
    output="$output>"
    ((total=50-total))
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
                if (("$k" < 0)); then k=0; fi
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
    echo; echo
    echo -e "\e[1A\e[K${b_green}Finished in:${clear}  $(date -ud @$(( SECONDS - start )) +%T)"
    echo; echo
    tput cnorm
}

function copy2all {
    for source in "${src_path_list[@]}"; do
        pre_copy
        start=$SECONDS
        if [ "$first_time" == true ]; then
            for dest in "${usb_list[@]}"; do
                cp -rp "$source" "$dest/" 2>> "$temp"/error.log &
            done
        elif [ "$first_time" == false ]; then
            for dest in "${usb_list[@]}"; do
                rsync -aq "$source" "$dest/" 2>> "$temp"/error.log &
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
            cp -rp "$source" "$dest/" 2>> "$temp"/error.log &
        done
    elif [ "$1" == false ]; then
        for dest in "${usb_list[@]}"; do
            if ((c % threads == 0)); then wait; fi
            ((c++))
            rsync -aq "$source" "$dest/" 2>> "$temp"/error.log &
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
    get_threads
    get_sources
    copy2all_b
}

function copy_menu {
    echo "-------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
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
    error_log_check -p
    get_destinations
    copy_menu
    sleep 1
    byte_check
    get_serials
    error_log_check
    echo
    unmount_disks
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
        echo -en "${b_yellow}Hash checking:${clear} $dcp"; echo
        echo "----------------------------------------------------------------------------------------"
        spinner &
        SPIN_PID=$!
        disown
        trap cleanup SIGINT
        for dest in /mnt/usb_*/"$dcp"/; do
            cd "$dest" || exit 1
            if [ "$1" == "-b" ]; then
                if (( j % threads == 0 )); then wait; fi; ((j++))
            fi
            k=$(echo "$dest" | grep -o -P "(?<=/mnt/).*(?=/$dcp/)")
            # sha1sum -c "$temp"/hashes.sha1 | tee -a "$temp"/"$(date '+%y%m%d%H%M')_$k".log | grep "FAILED" &
            sha1sum -c "$temp"/hashes.sha1 2>> "$temp"/"$(date '+%y%m%d%H%M')"_"$k"_error.log | tee -a "$temp"/"$(date '+%y%m%d%H%M')"_"$k".log | grep "FAILED" &
        done
        cd "$temp" || exit 1
        wait &&
        sleep 1; kill -9 "$SPIN_PID"; echo; echo; sleep 1
        rm -f "$temp"/hashes.sha1
        error_log_check -h
        echo -e "${b_green}Finished in:${clear}  $(date -ud @$(( SECONDS - start )) +%T)"; echo
        echo
    done
}

function hashcheck_all {
    confirm
    get_destinations
    get_sources
    hashcheck
}

function hashcheck_all_in_batches {
    confirm
    get_destinations
    get_threads
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
        echo -en "${b_yellow}Hash checking:${clear} $dcp"; echo
        echo "----------------------------------------------------------------------------------------"
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
        error_log_check -h
        echo -e "${b_green}Finished in:${clear}  $(date -ud @$(( SECONDS - start )) +%T)"; echo
    done
}

function bytecheck {
    confirm
    get_destinations
    echo -en "${b_blue}Drag and drop source folder and press [ENTER]: ${clear}"
    read -re input
    source=$(echo "$input" | tr -d "'")
    if [ -z "$source" ]; then
        echo; echo; echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb "$default_sources_dir"/*/
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb --exclude=lost+found/ /mnt/usb_*/*/
    else
        sources_dir=$(dirname "$source")
        dcp=$(basename "$source")
        echo; echo -e "${b_yellow}DCP source(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb "$sources_dir/$dcp"/
        echo; echo -e "${b_yellow}Destination disk(s)${clear}"
        echo "-----------------------------------------------------------------"
        du -sb --exclude=lost+found/ /mnt/usb_*/"$dcp"/
    fi
}

function hashcheck_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Source hashcheck" "Hashcheck all" "Hashcheck in batches" "Bytecheck" "Exit"; do
        case $opt in
            "Source hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; source_hashcheck; exit;;
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
    hashcheck_menu
    unmount_disks
}

################# Utilities Functions ##################

function automount_main {
    root_check
    mount_disks_usb
}

function getserials_main {
    root_check
    destination_check
    echo
    get_serials
    echo
    unmount_disks
}

################# SetPerms Functions ##################

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
        echo "Destination mode"
        confirm
        dest=$(ls -d /mnt/usb_*/"$dcp_folder")
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
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
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

function permissions_main {
    root_check
    permissions_menu "$1"
    echo; echo -e "${b_green}Finished${clear}"; echo
}

################# DCPCombo Functions ###################

function init_cp {
    confirm
    no_disk_check
    diskprep_warning
    disks_found
    confirm
    get_label
    get_sources
    echo -e "${b_yellow}From this point no user interaction is required${clear}"
    confirm_t $delay
    master_start=$SECONDS
    diskprep_start
    init_disk
    diskprep_end
    mount_disks_usb
    show_disks
    confirm_t $delay
    get_destinations
    copy2all
    byte_check
    get_serials
    error_log_check
    echo; echo -e "${b_green}Total time elapsed:${clear}  $(date -ud @$(( SECONDS - master_start )) +%T)"; echo
    echo; echo -e "${b_blue}Please wait until no disk leds are blinking before unmounting"; echo
    confirm_t $long_delay
    unmount_disks
}

function init_cp_b {
    confirm
    no_disk_check
    diskprep_warning
    disks_found
    confirm
    get_threads
    get_label
    get_sources
    echo -e "${b_yellow}From this point no user interaction is required${clear}"
    confirm_t $delay
    master_start=$SECONDS
    diskprep_start
    init_disk_b
    diskprep_end
    mount_disks_usb
    show_disks
    confirm_t $delay
    get_destinations
    copy2all_b
    byte_check
    get_serials
    error_log_check
    echo; echo -e "${b_green}Total time elapsed:${clear}  $(date -ud @$(( SECONDS - master_start )) +%T)"; echo
    echo; echo -e "${b_blue}Please wait until no disk leds are blinking before unmounting"; echo
    confirm_t $long_delay
    unmount_disks
}

function init_cp_hsck {
    confirm
    no_disk_check
    diskprep_warning
    disks_found
    confirm
    get_label
    get_sources
    echo -e "${b_yellow}From this point no user interaction is required${clear}"
    confirm_t $delay
    master_start=$SECONDS
    diskprep_start
    init_disk
    diskprep_end
    mount_disks_usb
    show_disks
    confirm_t $delay
    get_destinations
    copy2all
    echo; echo -e "${b_blue}Please wait until no disk leds are blinking"; echo
    confirm_t $long_delay
    echo
    hashcheck
    get_serials
    error_log_check
    error_log_check -h
    echo; echo -e "${b_green}Total time elapsed:${clear}  $(date -ud @$(( SECONDS - master_start )) +%T)"; echo
    unmount_disks
}

function init_cp_hsck_b {
    confirm
    no_disk_check
    diskprep_warning
    disks_found
    confirm
    get_threads
    get_label
    get_sources
    echo -e "${b_yellow}From this point no user interaction is required${clear}"
    confirm_t $delay
    master_start=$SECONDS
    diskprep_start
    init_disk_b
    diskprep_end
    mount_disks_usb
    show_disks
    confirm_t $delay
    get_destinations
    copy2all_b
    echo; echo -e "${b_blue}Please wait until no disk leds are blinking"; echo
    confirm_t $long_delay
    echo
    hashcheck -b
    get_serials
    error_log_check
    error_log_check -h
    echo; echo -e "${b_green}Total time elapsed:${clear}  $(date -ud @$(( SECONDS - master_start )) +%T)"; echo
    unmount_disks
}

function mount_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Auto mount" "Usb mount" "Unmount all" "Main menu" "Exit"
        do
            case $opt in
                "Auto mount") echo; echo -e "${b_yellow}$opt${clear}"; confirm; unmount_disks; automount_disks; break;;
                "Usb mount") echo; echo -e "${b_yellow}$opt${clear}"; confirm; unmount_disks; mount_disks_usb; break;;
                "Unmount all") echo; echo -e "${b_yellow}$opt${clear}"; confirm; unmount_disks; exit;;
                "Main menu") echo; echo -e "${b_yellow}$opt${clear}"; main_menu; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function more_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Initialize + copy in batches" "Initialize + copy + hashcheck in batches" \
    "DiskPrep" "CopyDCP" "Hashcheck" "Set permissions" "Get serials" "Main menu" "Exit"
        do
            case $opt in
                "Initialize + copy in batches") echo; echo -e "${b_yellow}$opt${clear}"; init_cp_b; break;;
                "Initialize + copy + hashcheck in batches") echo; echo -e "${b_yellow}$opt${clear}"; init_cp_hsck_b; break;;
                "DiskPrep") echo; echo -e "${b_yellow}$opt${clear}"; confirm; diskprep_main; echo; exit;;
                "CopyDCP") echo; echo -e "${b_yellow}$opt${clear}"; confirm; copy_main; echo; exit;;
                "Hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; confirm; hashcheck_main; echo; exit;;
                "Set permissions") echo; echo -e "${b_yellow}$opt${clear}"; confirm; permissions_main "$1"; echo; exit;;
                "Get serials") echo; echo -e "${b_yellow}$opt${clear}"; confirm; getserials_main; echo; exit;;
                "Main menu") echo; echo -e "${b_yellow}$opt${clear}"; main_menu; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function main_menu {
    echo "------------------------"
    echo -e "${b_blue}Select to continue:${clear}"
    echo "------------------------"
    export COLUMNS=20
    select opt in "Initialize + copy" "Initialize + copy + hashcheck" "Source hashcheck" "Mount/Unmount" "More options" "Exit"
        do
            case $opt in
                "Initialize + copy") echo; echo -e "${b_yellow}$opt${clear}"; init_cp; break;;
                "Initialize + copy + hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; init_cp_hsck; break;;
                "Source hashcheck") echo; echo -e "${b_yellow}$opt${clear}"; source_hashcheck; exit;;
                "Mount/Unmount") echo; echo -e "${b_yellow}$opt${clear}"; mount_menu; exit;;
                "More options") echo; echo -e "${b_yellow}$opt${clear}"; more_menu "$1"; break;;
                "Exit") echo; echo -e "${b_yellow}Bye!${clear}"; echo; exit;;
                * ) echo "Invalid option"
            esac
        done
}

function combo_main {
    root_check
    error_log_check -p
    main_menu "$1"
}