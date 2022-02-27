#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# FETCHERS

function fetch_all_available_block_devices () {
    AVAILABLE_DEVS=(
        `lsblk | \
        grep -e '^[a-z].*' -e 'disk' | \
        awk '{print $1}' | \
        sed 's:^:/dev/:g'`
    )
    if [ ${#AVAILABLE_DEVS[@]} -eq 0 ]; then
        error_msg "Could not detect any devices connected to machine."
        return 1
    fi
    echo "${AVAILABLE_DEVS[@]}"
    return 0
}

function fetch_all_directory_files () {
    local DIR_PATH="$1"
    local DIRECTORY_FILE_PATHS=()
    for discovered_path in `find "$DIR_PATH"`; do
        if [[ "$discovered_path" == "$DIR_PATH" ]]; then
            continue
        fi
        DIRECTORY_FILE_PATHS=( ${DIRECTORY_FILE_PATHS[@]} "$discovered_path" )
    done
    echo ${DIRECTORY_FILE_PATHS[@]}
    return 0
}

function fetch_file_name_from_path () {
    local FILE_PATH="$1"
    basename "$FILE_PATH"
    return $?
}

function fetch_directory_from_file_path () {
    local FILE_PATH="$1"
    dirname "$FILE_PATH"
    return $?
}

function fetch_alive_lan_machines_ipv4_addresses () {
    LAN_SCAN=`lan_scan`
    IPV4_ADDRESSES=( `echo "$LAN_SCAN" | awk '{print $1}'` )
    echo ${IPV4_ADDRESSES[@]}
    return 0
}

function fetch_alive_lan_machines_mac_addresses () {
    LAN_SCAN=`lan_scan`
    MAC_ADDRESSES=( `echo "$LAN_SCAN" | awk '{print $2}'` )
    echo ${MAC_ADDRESSES[@]}
    return 0
}

function fetch_all_wireless_interfaces () {
    WIFI_INTERFACES=( `iw dev | grep Interface | awk '{print $NF}'` )
    if [ ${#WIFI_INTERFACES[@]} -eq 0 ]; then
        return 1
    fi
    echo ${WIFI_INTERFACES[@]}
    return 0
}

function fetch_currently_connected_gateway_essid () {
    CURRENT_ESSID=`iwgetid | sed 's/\"//g' | cut -d ':' -f 2`
    if [ -z "$CURRENT_ESSID" ]; then
        return 1
    fi
    echo "$CURRENT_ESSID"
    return 0
}

function fetch_checksum_algorithm_labels () {
    if [ ${#MD_CHECKSUM_ALGORITHMS[@]} -eq 0 ]; then
        echo; error_msg "No checksum algorithms set."
        return 1
    fi
    echo "${!MD_CHECKSUM_ALGORITHMS[@]}"
    return $?
}

function fetch_wireless_gateway_channel_by_interface () {
    WIRELESS_INTERFACE="$1"
    RADIO_CHANNEL=`iwlist $WIRELESS_INTERFACE scan | \
        grep Channel: | \
        cut -d':' -f 2 | \
        head -n 1`
    if [ -z "$RADIO_CHANNEL" ]; then
        return 1
    fi
    echo $RADIO_CHANNEL
    return 0
}

function fetch_wireless_gateway_bssid () {
    WIRELESS_INTERFACE=`fetch_wireless_interface`
    if [ $? -ne 0 ]; then
        return 2
    fi
    ROUTER_BSSID=`iwlist "$WIRELESS_INTERFACE" scan | \
        grep 'Address' | \
        awk '{print $NF}' | \
        head -n 1`
    if [ -z "$ROUTER_BSSID" ]; then
        return 1
    fi
    echo $ROUTER_BSSID
    return 0
}

function fetch_wireless_interface () {
    WIRELESS_INTERFACE=`iwgetid | awk '{print $1}' | head -n 1`
    if [ -z "$WIRELESS_INTERFACE" ]; then
        return 1
    fi
    echo $WIRELESS_INTERFACE
    return 0
}

function fetch_wireless_interface_from_user () {
    local PROMPT_STRING="${1:-WiFiInterface}"
    while :
    do
        WIRELESS_INTERFACE=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_valid_wireless_interface "$WIRELESS_INTERFACE"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid wireless interface"\
                "${RED}$WIRELESS_INTERFACE${RESET}."
            continue
        fi
        break
    done
    echo "$WIRELESS_INTERFACE"
    return 0
}

function fetch_external_ipv4_address () {
    check_internet_access
    if [ $? -ne 0 ]; then
        warning_msg "No internet access!"
        return 1
    fi
    curl whatismyip.akamai.com 2> /dev/null
    return $?
}

function fetch_local_ipv4_address () {
    hostname -I | cut -d' ' -f1
    return $?
}

function fetch_all_directory_content () {
    local DIRECTORY_PATH="$1"
    check_directory_exists "$DIRECTORY_PATH"
    if [ $? -ne 0 ]; then
        error_msg "Directory (${RED}$DIRECTORY_PATH${RESET}) not found."
        return 1
    fi
    ls -1 "$DIRECTORY_PATH"
    return $?
}

function fetch_file_size_in_bytes () {
    local FILE_PATH="$1"
    BYTES=`ls -la "$FILE_PATH" | awk '{print $5}'`
    echo $BYTES
    return 0
}

function fetch_all_bios_data () {
    dmidecode -t bios
    return $?
}

function fetch_all_system_data () {
    dmidecode -t system
    return $?
}

function fetch_all_baseboard_data () {
    dmidecode -t baseboard
    return $?
}

function fetch_all_chassis_data () {
    dmidecode -t chassis
    return $?
}

function fetch_all_processor_data () {
    dmidecode -t processor
    return $?
}

function fetch_all_memory_data () {
    dmidecode -t memory
    return $?
}

function fetch_block_devices () {
    BLOCK_DEVICES=(
        `lsblk | grep -e disk | sed 's/^/\/dev\//g' | awk '{print $1}'`
    )
    echo ${BLOCK_DEVICES[@]}
    return 0
}

function fetch_file_size_in_bytes () {
    local FILE_PATH="$1"
    if [ ! -f "$FILE_PATH" ]; then
        touch $FILE_PATH
    fi
    BYTES=`ls -la "$FILE_PATH" | awk '{print $5}'`
    echo $BYTES
    return 0
}

function fetch_device_size () {
    local TARGET_DEVICE="$1"
    check_device_exists $TARGET_DEVICE
    if [ $? -ne 0 ]; then
        warning_msg "Device $TARGET_DEVICE not found."
        return 2
    fi
    local SIZE=`lsblk -bo NAME,SIZE "$TARGET_DEVICE" | \
        grep -e '^[a-z].*' | \
        awk '{print $NF}'`
    if [ -z "$SIZE" ]; then
        return 1
    fi
    echo "$SIZE"
    return 0
}

function fetch_wireless_password_from_user () {
    local PROMPT_STRING="${1:-Password}"
    echo; info_msg "Type wifi ${YELLOW}Password${RESET}"\
        "or ${MAGENTA}.back${RESET}."
    while :
    do
        ESSID_PASSWORD=`fetch_data_from_user "$PROMPT_STRING" "password"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$ESSID_PASSWORD"
        break
    done
    return 0
}

function fetch_available_wireless_access_point_essid_set () {
    ESSID_SET=(
        `display_available_wireless_access_points | \
            egrep -e '[0-9]{2}/[0-9]{2}' | awk '{print $3}' | \
            sed 's/\"//g'`
    )
    if [ ${#ESSID_SET[@]} -eq 0 ]; then
        echo; warning_msg "No available wireless access points found."
        return 1
    fi
    echo ${ESSID_SET[@]}
    return 0
}

function fetch_wireless_essid_from_user () {
    AVAILABLE_ESSID=( `fetch_available_wireless_access_point_essid_set` )
    echo; TARGET_ESSID=`fetch_selection_from_user \
        "${MAGENTA}ESSID${RESET}" ${AVAILABLE_ESSID[@]}`
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo "$TARGET_ESSID"
    return 0
}

function fetch_file_length () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File (${RED}$FILE_PATH${RESET}) not found."
        return 1
    fi
    cat $FILE_PATH | wc -l
    return $?
}

function fetch_single_port_number_from_user () {
    local PROMPT_STRING="${1:-TargetPort}"
    while :
    do
        PORT_NUMBER=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_value_is_number "$PORT_NUMBER"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid machine port number"\
                "${RED}$PORT_NUMBER${RESET}."
            continue
        fi
        echo $PORT_NUMBER
        break
    done
    return 0
}

function fetch_ipv4_address_from_user () {
    local PROMPT_STRING="${1:-IPv4Address}"
    while :
    do
        IPV4_ADDRESS=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_is_ipv4_address "$IPV4_ADDRESS"`
        if [ $? -ne 0 ]; then
            echo; warning_msg "Invalid IPv4 address"\
                "${RED}$IPV4_ADDRESS${RESET}."
            continue
        fi
        echo "$IPV4_ADDRESS"
        break
    done
    return 0
}

function fetch_router_bssid_from_user () {
    local PROMPT_STRING="${1:-BSSID}"
    while :
    do
        BSSID=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$BSSID"
        break
    done
    return 0
}

function fetch_wireless_gateway_channel_from_user () {
    local PROMPT_STRING="${1:-Channel}"
    while :
    do
        CHANNEL_NUMBER=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        echo "$CHANNEL_NUMBER"
        break
    done
    return 0
}

function fetch_mac_address_from_user () {
    local PROMPT_STRING="${1:-MACAddress}"
    while :
    do
        MAC_ADDRESS=`fetch_data_from_user "$PROMPT_STRING"`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            echo; return 1
        fi
        CHECK_VALID=`check_is_mac_address "$MAC_ADDRESS"`
        if [ $? -ne 0 ]; then
            fetch_ultimatum_from_user "Do you wish to continue? ${YELLOW}Y/N${RESET}"
            if [ $? -ne 0 ]; then
                echo; info_msg "Aborting action."
                echo; return 1
            fi
        fi
        echo "$MAC_ADDRESS"; break
    done
    return 0
}

function fetch_data_from_user () {
    local PROMPT="$1"
    local OPTIONAL="${@:2}"
    while :
    do
        if [[ $OPTIONAL == 'password' ]]; then
            read -sp "$PROMPT: " DATA
        else
            read -p "$PROMPT> " DATA
        fi
        if [ -z "$DATA" ]; then
            continue
        elif [[ "$DATA" == ".back" ]]; then
            return 1
        fi
        echo "$DATA"; break
    done
    return 0
}

function fetch_ultimatum_from_user () {
    PROMPT="$1"
    while :
    do
        local ANSWER=`fetch_data_from_user "$PROMPT"`
        case "$ANSWER" in
            'y' | 'Y' | 'yes' | 'Yes' | 'YES')
                return 0
                ;;
            'n' | 'N' | 'no' | 'No' | 'NO')
                return 1
                ;;
            *)
        esac
    done
    return 2
}

function fetch_selection_from_user () {
    local PROMPT="$1"
    local OPTIONS=( "${@:2}" "Back" )
    local OLD_PS3=$PS3
    PS3="$PROMPT> "
    select opt in "${OPTIONS[@]}"; do
        case "$opt" in
            'Back')
                PS3="$OLD_PS3"
                return 1
                ;;
            *)
                local CHECK=`check_item_in_set "$opt" "${OPTIONS[@]}"`
                if [ $? -ne 0 ]; then
                    warning_msg "Invalid option."
                    continue
                fi
                PS3="$OLD_PS3"
                echo "$opt"
                return 0
                ;;
        esac
    done
    PS3="$OLD_PS3"
    return 2
}

function fetch_menu_controllers_with_extended_banner () {
    # TODO - Following log message may lead to log spam
#   debug_msg "Detected (${WHITE}${#MD_CONTROLLER_BANNERS[@]}${RESET})"\
#       "controllers with extended banners:"\
#       "${YELLOW}${!MD_CONTROLLER_BANNERS[@]}${RESET}"
    echo ${!MD_CONTROLLER_BANNERS[@]}
    return $?
}

function fetch_controller_option_id () {
    local CONTROLLER_LABEL="$1"
    local OPTION_LABEL="$2"
    VALID_JUMP_KEYS=( `fetch_jump_keys` )
    debug_msg "Valid jumper keys found: ${YELLOW}${VALID_JUMP_KEYS[@]}${RESET}"
    check_item_in_set "$CONTROLLER_LABEL-jump-$OPTION_LABEL" ${VALID_JUMP_KEYS[@]}
    if [ $? -ne 0 ]; then
        KEY_TO_SEARCH_BY="$CONTROLLER_LABEL-$OPTION_LABEL"
        debug_msg "Menu controller action ${YELLOW}$KEY_TO_SEARCH_BY${RESET}"\
            "triggered."
    else
        KEY_TO_SEARCH_BY="$CONTROLLER_LABEL-jump-$OPTION_LABEL"
        debug_msg "Menu controller jumper ${YELLOW}$KEY_TO_SEARCH_BY${RESET}"\
            "triggered."
    fi
    echo "$KEY_TO_SEARCH_BY"
    return $?
}

function fetch_jump_keys () {
    JUMP_KEYS=()
    for action_key in "${!MD_CONTROLLER_OPTION_KEYS[@]}"; do
        check_string_matches_regex_pattern "$action_key" "*-jump-*"
        if [ $? -ne 0 ]; then
            debug_msg "Action key ${RED}$action_key${RESET} does not match"\
                "pattern ${RED}*-jump-*${RESET}"
            continue
        fi
        JUMP_KEYS=( ${JUMP_KEYS[@]} "$action_key" )
        debug_msg "Controller jumper key ${GREEN}$action_key${RESET} detected."
    done
    echo ${JUMP_KEYS[@]}
    return $?
}

function fetch_action_keys () {
    # TODO - Following log message may lead to log spam
#   debug_msg "Detected (${WHITE}${#MD_CONTROLLER_OPTION_KEYS[@]}${RESET})"\
#       "option keys: ${YELLOW}${!MD_CONTROLLER_OPTION_KEYS[@]}${RESET}."
    if [ ${#MD_CONTROLLER_OPTION_KEYS[@]} -eq 0 ]; then
        error_msg "No ${BLUE}$SCRIPT_NAME${RESET}"\
            "${RED}action keys${RESET} found."
        return 1
    fi
    echo ${!MD_CONTROLLER_OPTION_KEYS[@]}
    return $?
}

function fetch_all_menu_controller_options () {
    local MENU_CONTROLLER_LABEL="$1"
    CONTROLLER_OPTIONS=(
        `echo "${MD_CONTROLLER_OPTIONS[$MENU_CONTROLLER_LABEL]}" | tr ',' ' '`
    )
    # TODO - Following log message may lead to log spam
#   debug_msg "Controller: ${CYAN}$MENU_CONTROLLER_LABEL${RESET},"\
#       "Options: ${YELLOW}${CONTROLLER_OPTIONS[@]}${RESET}."
    echo "${CONTROLLER_OPTIONS[@]}"
    return $?
}

function fetch_action_key_count () {
    KEY_COUNT=${#MD_CONTROLLER_OPTION_KEYS[@]}
    debug_msg "Detected (${WHITE}$KEY_COUNT${RESET}) action keys."
    echo $KEY_COUNT
    return $?
}

function fetch_action_key_regex_pattern () {
    local MENU_CONTROLLER_LABEL="$1"
    local REGEX_PATTERN="$MENU_CONTROLLER_LABEL-"
    debug_msg "Computed action key REGEX pattern ${YELLOW}$REGEX_PATTERN${RESET}."
    echo "$REGEX_PATTERN"
    return $?
}

function fetch_menu_controllers () {
    debug_msg "Detected (${WHITE}${#MD_CONTROLLERS[@]}${RESET})"\
        "menu controllers: ${YELLOW}${!MD_CONTROLLERS[@]}${RESET}."
    if [ ${#MD_CONTROLLERS[@]} -eq 0 ]; then
        echo; error_msg "No ${BLUE}$SCRIPT_NAME${RESET}"\
            "${RED}menu controllers${RESET} found."
        return 1
    fi
    echo ${!MD_CONTROLLERS[@]}
    return $?
}

function fetch_set_log_levels () {
    if [ ${#MD_LOGGING_LEVELS[@]} -eq 0 ]; then
        echo; error_msg "No ${BLUE}$SCRIPT_NAME${RESET}"\
            "${RED}logging levels${RESET} found."
        return 1
    fi
    echo ${MD_LOGGING_LEVELS[@]}
    return 0
}


