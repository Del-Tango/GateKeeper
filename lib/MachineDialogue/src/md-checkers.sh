#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# CHECKERS

function check_fifo_exists () {
    local FIFO_PATH="$1"
    if [ ! -p "$FIFO_PATH" ]; then
        return 1
    fi
    return 0
}

function check_valid_wireless_interface () {
    local WIRELESS_INTERFACE="$1"
    WIFI_INTERFACES=( `fetch_all_wireless_interfaces` )
    check_item_in_set "$WIRELESS_INTERFACE" ${WIFI_INTERFACES[@]}
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

function check_essid_password_protected () {
    local TARGET_ESSID="$1"
    for count in `seq 3`; do
        ENCODED=`display_available_wireless_access_points | \
            grep "$TARGET_ESSID" | \
            awk '{print $2}'`
        case $ENCODED in
            'on')
                echo; info_msg "Wireless access point"\
                    "(${YELLOW}$TARGET_ESSID${RESET})"\
                    "${GREEN}is password protected${RESET}."
                return 0
                ;;
            'off')
                echo; info_msg "Wireless access point"\
                    "(${YELLOW}$TARGET_ESSID${RESET})"\
                    "${RED}is not password protected${RESET}."
                return 1
                ;;
            *)
                echo; warning_msg "Could not determine if"\
                    "${YELLOW}ESSID${RESET} (${RED}$TARGET_ESSID${RESET})"\
                    "is password protected on try number"\
                    "(${WHITE}$count${RESET})."
                ;;
        esac
    done
    error_msg "Something went wrong."\
        "Could not detemine if ${YELLOW}ESSID${RESET}"\
        "(${RED}$TARGET_ESSID${RESET}) is password protected."
    return 2
}

function check_privileged_access () {
    if [ $EUID -ne 0 ]; then
        return 1
    fi
    return 0
}

function check_device_exists () {
    local DEVICE_PATH="$1"
    fdisk -l $DEVICE_PATH &> /dev/null
    return $?
}

function check_number_is_divisible_by_two () {
    local NUMBER=$1
    if (( $NUMBER % 2 == 0 )); then
        return 0
    fi
    return 1
}

function check_is_subnet_address () {
    local IPV4_SUBNET="$1"
    local SUBNET_REGEX_PATTERN='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'
    echo "$IPV4_SUBNET" | egrep -e $SUBNET_REGEX_PATTERN &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    IFS='.'
    for octet in $IPV4_SUBNET; do
        check_value_is_number $octet
        if [ $? -ne 0 ]; then
            IFS=' '
            return 1
        elif [ $octet -gt 254 ]; then
            IFS=' '
            return 1
        fi
    done
    IFS=' '
    return 0
}

function check_is_ipv4_address () {
    local IPV4_ADDRESS="$1"
    local IPV4_REGEX_PATTERN='^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$'
    echo "$IPV4_ADDRESS" | egrep -e $IPV4_REGEX_PATTERN &> /dev/null
    if [ $? -ne 0 ]; then
        return 1
    fi
    IFS='.'
    for octet in $IPV4_ADDRESS; do
        check_value_is_number $octet
        if [ $? -ne 0 ]; then
            IFS=' '
            return 1
        elif [ $octet -gt 254 ]; then
            IFS=' '
            return 1
        fi
    done
    IFS=' '
    return 0
}

function check_is_mac_address () {
    local MAC_ADDRESS="$1"
    local MAC_REGEX_PATTERN='^([0-9A-Fa-f]{1,2}[:-]){5}([0-9A-Fa-f]{1,2})$'
    echo "$MAC_ADDRESS" | egrep -e $MAC_REGEX_PATTERN &> /dev/null
    EXIT_CODE=$?
    if [ "$EXIT_CODE" -ne 1 ]; then
        return 0
    fi
    return 1
}

function check_directory_exists () {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        return 0
    fi
    return 1
}

function check_file_has_number_of_lines () {
    local FILE_PATH="$1"
    local LINE_COUNT=$2
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File ${RED}$FILE_PATH${RESET} not found."
        echo; return 2
    fi
    check_value_is_number $LINE_COUNT
    if [ $? -ne 0 ]; then
        echo; warning_msg "Line count must be a number, not ${RED}$LINE_COUNT${RESET}."
        echo; return 3
    fi
    if [ `cat $FILE_PATH | wc -l` -eq $LINE_COUNT ]; then
        return 0
    fi
    return 1
}

function check_internet_access () {
    local ADDRESS="$1"
    ping -c 1 $ADDRESS 2> /dev/null
    return $?
}

function check_python3_library_installed () {
    local LIBRARY="$1"
    python3 -c "import $LIBRARY" &> /dev/null
    return $?
}

function check_apt_dependency_set () {
     local APT_DEPENDENCY="$1"
     check_item_in_set "$APT_DEPENDENCY" ${MD_APT_DEPENDENCIES[@]}
     EXIT_CODE=$?
     if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Dependency ${RED}$APT_DEPENDENCY${RESET} is not set to be"\
            "installed using the APT package manager."
     else
        debug_msg "Dependency ${GREEN}$APT_DEPENDENCY${RESET} is set to be"\
            "installed using the APT package manager."
     fi
     return $EXIT_CODE
}

function check_menu_controller_extended_banner () {
    local MENU_LABEL="$1"
    CONTROLLERS_WITH_EBANNERS=( `fetch_menu_controllers_with_extended_banner` )
    debug_msg "Menu controllers with extended banners:"\
        "${YELLOW}${CONTROLLERS_WITH_EBANNERS[@]}${RESET}."
    check_item_in_set "$MENU_LABEL" ${CONTROLLERS_WITH_EBANNERS[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "No extended banner detected for menu controller"\
            "${RED}$MENU_LABEL${RESET}."
    else
        debug_msg "Menu controller ${GREEN}$MENU_LABEL${RESET}"\
            "has extended banner set."
    fi
    return $EXIT_CODE
}

function check_required_privileges () {
    check_flag_is_on "$MD_ROOT"
    EXIT_CODE=$?
    FLAG_VALUE=`format_flag_colors "$MD_ROOT"`
    debug_msg "Elevated privilege restriction flag is"\
        "${YELLOW}$FLAG_VALUE${RESET}."
    return $EXIT_CODE
}

function check_function_is_defined () {
    local FUNCTION_NAME="$1"
    type "$FUNCTION_NAME" &> /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Function ${RED}$FUNCTION_NAME${RESET} is not defined."
    else
        debug_msg "Function ${GREEN}$FUNCTION_NAME${RESET} is defined."
    fi
    return $EXIT_CODE
}

function check_controller_option_exists () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_OPTION_LABEL="$2"
    VALID_MENU_OPTIONS=(
        `fetch_all_menu_controller_options "$MENU_CONTROLLER_LABEL"`
    )
    # TODO - The following log message may lead to log spam
#   debug_msg "Valid menu options detected:"\
#       "${YELLOW}${VALID_MENU_OPTIONS[@]}${RESET}"
    check_item_in_set "$MENU_CONTROLLER_OPTION_LABEL" ${VALID_MENU_OPTIONS[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "${YELLOW}$MENU_CONTROLLER_LABEL${RESET} menu controller"\
            "option ${RED}$MENU_CONTROLLER_OPTION_LABEL${RESET}"\
            "does not exists."
    else
        debug_msg "${YELLOW}$MENU_CONTROLLER_LABEL${RESET} menu controller"\
            "option ${GREEN}$MENU_CONTROLLER_OPTION_LABEL${RESET} exists."
    fi
    return $EXIT_CODE
}

function check_string_matches_regex_pattern () {
    local TARGET_STRING="$1"
    local REGEX_STRING="$2"
    echo "$TARGET_STRING" | egrep -e "$REGEX_STRING" &> /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Target string ${YELLOW}$TARGET_STRING${RESET}"\
            "does not match given REGEX pattern ${RED}$REGEX_STRING${RESET}."
    else
        debug_msg "Target string ${YELLOW}$TARGET_STRING${RESET}"\
            "matches given REGEX pattern ${GREEN}$REGEX_STRING${RESET}."
    fi
    return $EXIT_CODE
}

function check_menu_controller_exists () {
    local MENU_CONTROLLER_LABEL="$1"
    VALID_MENU_CONTROLLERS=( `fetch_menu_controllers` )
    # TODO - The following log message may lead to log spam
#   debug_msg "Valid menu controllers detected:"\
#       "${YELLOW}${VALID_MENU_CONTROLLERS[@]}${RESET}"
    check_item_in_set "$MENU_CONTROLLER_LABEL" ${VALID_MENU_CONTROLLERS[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "${RED}$MENU_CONTROLLER_LABEL${RESET} menu controller"\
            "does not exists."
    else
        debug_msg "${GREEN}$MENU_CONTROLLER_LABEL${RESET} menu controller"\
            "exists."
    fi
    return $EXIT_CODE
}

function check_valid_action_key () {
    local ACTION_KEY="$1"
    VALID_ACTION_KEYS=( `fetch_action_keys` )
    # TODO - The following log message may lead to log spam
#   debug_msg "Valid action keys detected:"\
#       "${YELLOW}${VALID_ACTION_KEYS[@]}${RESET}"
    check_item_in_set "$ACTION_KEY" ${VALID_ACTION_KEYS[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Action key ${RED}$ACTION_KEY${RESET} is not valid."
    else
        debug_msg "Action key ${GREEN}$ACTION_KEY${RESET} is valid."
    fi
    return $EXIT_CODE
}

function check_logging_on () {
    check_flag_is_on "$MD_LOGGING"
    return $EXIT_CODE
}

function check_logging_off () {
    check_flag_is_off "$MD_LOGGING"
    return $EXIT_CODE
}

function check_safety_on () {
    check_flag_is_on "$MD_SAFETY"
    EXIT_CODE=$?
    FLAG_VALUE=`format_flag_colors "$MD_SAFETY"`
    debug_msg "${BLUE}$SCRIPT_NAME${RESET} safety flag is $FLAG_VALUE."
    return $EXIT_CODE
}

function check_safety_off () {
    check_flag_is_off "$MD_SAFETY"
    EXIT_CODE=$?
    FLAG_VALUE=`format_flag_colors "$MD_SAFETY"`
    debug_msg "${BLUE}$SCRIPT_NAME${RESET} safety flag is $FLAG_VALUE."
    return $EXIT_CODE
}

function check_md_menu_banner_on () {
    check_flag_is_on "$MD_MENU_BANNER"
    EXIT_CODE=$?
    FLAG_VALUE=`format_flag_colors "$MD_MENU_BANNER"`
    debug_msg "${BLUE}$SCRIPT_NAME${RESET} menu banner flag is $FLAG_VALUE."
    return $EXIT_CODE
}

function check_md_menu_banner_off () {
    check_flag_is_off "$MD_MENU_BANNER"
    EXIT_CODE=$?
    FLAG_VALUE=`format_flag_colors "$MD_MENU_BANNER"`
    debug_msg "${BLUE}$SCRIPT_NAME${RESET} menu banner flag is $FLAG_VALUE."
    return $EXIT_CODE
}

function check_file_empty () {
    local FILE_PATH="$1"
    if [ ! -s "$FILE_PATH" ]; then
        debug_msg "File ${GREEN}$FILE_PATH${RESET} is empty."
        return 0
    fi
    debug_msg "File ${RED}$FILE_PATH${RESET} is not empty."
    return 1
}

function check_directory_empty () {
    local DIR_PATH="$1"
    FILE_COUNT=`ls -a1 "$DIR_PATH" | grep -v '^.$' | grep -v '^..$' | wc -l`
    if [ $FILE_COUNT -eq 0 ]; then
        debug_msg "Directory ${GREEN}$DIR_PATH${RESET} is empty."
        return 0
    fi
    debug_msg "(${WHITE}$FILE_COUNT${RESET}) files detected"\
        "in directory ${RED}$DIR_PATH${RESET}."
    return 1
}

function check_directory_exists () {
    local DIRECTORY_PATH="$1"
    if [ ! -d "$DIRECTORY_PATH" ]; then
        debug_msg "Directory ${RED}$DIRECTORY_PATH${RESET} does not exist."
        return 1
    fi
    debug_msg "Directory ${GREEN}$DIRECTORY_PATH${RESET} exists."
    return 0
}

function check_flag_is_on () {
    local FLAG_VALUE="$1"
    if [[ "$FLAG_VALUE" != 'on' ]]; then
        return 1
    fi
    return 0
}

function check_flag_is_off () {
    local FLAG_VALUE="$1"
    if [[ "$FLAG_VALUE" != 'off' ]]; then
        return 1
    fi
    return 0
}

function check_identical_strings () {
    local FIRST_STRING="$1"
    local SECOND_STRING="$2"
    if [[ "$FIRST_STRING" != "$SECOND_STRING" ]]; then
        debug_msg "String ${YELLOW}$FIRST_STRING${RESET}"\
            "is not identical to ${RED}$SECOND_STRING${RESET}."
        return 1
    fi
        debug_msg "String ${YELLOW}$FIRST_STRING${RESET}"\
            "is identical to ${GREEN}$SECOND_STRING${RESET}."
    return 0
}

function check_file_exists () {
    local FILE_PATH="$1"
    if [ -f "$FILE_PATH" ]; then
        debug_msg "File ${GREEN}$FILE_PATH${RESET} exists."
        return 0
    fi
    debug_msg "File ${RED}$FILE_PATH${RESET} does not exist."
    return 1
}

function check_directory_exists () {
    local DIR_PATH="$1"
    if [ -d "$DIR_PATH" ]; then
        debug_msg "Directory ${GREEN}$DIR_PATH${RESET} exists."
        return 0
    fi
    debug_msg "Directory ${RED}$DIR_PATH${RESET} does not exist."
    return 1
}

function check_value_is_number () {
    local VALUE=$1
    test $VALUE -eq $VALUE &> /dev/null
    if [ $? -ne 0 ]; then
        debug_msg "Value ${RED}$VALUE${RESET} is not a number."
        return 1
    fi
    debug_msg "Value ${GREEN}$VALUE${RESET} is a number."
    return 0
}

function check_checksum_is_valid () {
    local CHECKSUM="$1"
    local CHECKSUM_LENGTH_MAX="$2"
    local REGEX="$3"
    if [ -z "$CHECKSUM" ]; then
        error_msg "No checksum specified."
        return 3
    elif [ -z "$CHECKSUM_LENGTH_MAX" ]; then
        error_msg "No maximum checksum length specified."
        return 4
    elif [ -z "$REGEX" ]; then
        error_msg "No checksum regex pattern specified."
        return 5
    fi
    echo "$CHECKSUM" | egrep -e $REGEX &> /dev/null
    if [ $? -ne 0 ]; then
        debug_msg "Given checksum value ${RED}$CHECKSUM${RESET} does not"\
            "corespond to REGEX pattern ${RED}$REGEX${RESET}."
        return 1
    fi
    CHECKSUM_LENGTH=`echo "$CHECKSUM" | wc -c`
    debug_msg "Detected checksum length (${WHITE}$CHECKSUM_LENGTH${RESET})."
    CHECKSUM_LENGTH_MIN=$((CHECKSUM_LENGTH_MAX - 6))
    debug_msg "Computed error margin checksum length"\
        "floor value (${WHITE}$CHECKSUM_LENGTH_MIN${RESET} characters)."
    if [ $CHECKSUM_LENGTH -le $CHECKSUM_LENGTH_MIN ] \
            || [ $CHECKSUM_LENGTH -gt $CHECKSUM_LENGTH_MAX ]; then
        debug_msg "Given checksum value (${RED}$CHECKSUM${RESET}) does not"\
            "corespond to valid hash length range"\
            "(${WHITE}$CHECKSUM_LENGTH_MIN - $CHECKSUM_LENGTH_MAX${RESET}"\
            "characters)."
        return 2
    fi
    return 0
}

function check_valid_md5_checksum () {
    local CHECKSUM="$1"
    check_checksum_is_valid "$CHECKSUM" 36 '[a-zA-Z0-9]'
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Checksum hash ${RED}$CHECKSUM${RESET}"\
            "could not be confirmed as MD5."
    else
        debug_msg "Checksum hash ${GREEN}$CHECKSUM${RESET} confirmed as MD5."
    fi
    return $EXIT_CODE
}

function check_valid_sha1_checksum () {
    local CHECKSUM="$1"
    check_checksum_is_valid "$CHECKSUM" 44 '[a-zA-Z0-9]'
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Checksum hash ${RED}$CHECKSUM${RESET}"\
            "could not be confirmed as SHA1."
    else
        debug_msg "Checksum hash ${GREEN}$CHECKSUM${RESET} confirmed as SHA1."
    fi
    return $EXIT_CODE
}

function check_valid_sha256_checksum () {
    local CHECKSUM="$1"
    check_checksum_is_valid "$CHECKSUM" 68 '[a-zA-Z0-9]'
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Checksum hash ${RED}$CHECKSUM${RESET}"\
            "could not be confirmed as SHA256."
    else
        debug_msg "Checksum hash ${GREEN}$CHECKSUM${RESET} confirmed as SHA256."
    fi
    return $EXIT_CODE
}

function check_valid_sha512_checksum () {
    local CHECKSUM="$1"
    check_checksum_is_valid "$CHECKSUM" 132 '[a-zA-Z0-9]'
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        debug_msg "Checksum hash ${RED}$CHECKSUM${RESET}"\
            "could not be confirmed as SHA512."
    else
        debug_msg "Checksum hash ${GREEN}$CHECKSUM${RESET} confirmed as SHA512."
    fi
    return $EXIT_CODE
}

function check_valid_checksum () {
    local CHECKSUM_TYPE="$1"
    local CHECKSUM="$2"
    if [ -z "$CHECKSUM_TYPE" ]; then
        error_msg "${BLUE}$SCRIPT_NAME${RESET} checksum"\
            "hashing algorithm not specified."
        return 1
    fi
    SANITIZED_CHECKSUM=`echo "$CHECKSUM" | sed -e 's/ //g' -e 's/-//g'`
    debug_msg "Original checksum ${YELLOW}$CHECKSUM${RESET}"\
        "sanitized to ${GREEN}$SANITIZED_CHECKSUM${RESET}."
    case "$CHECKSUM_TYPE" in
        'MD5')
            check_valid_md5_checksum "$CHECKSUM"
            ;;
        'SHA1')
            check_valid_sha1_checksum "$CHECKSUM"
            ;;
        'SHA256')
            check_valid_sha256_checksum "$CHECKSUM"
            ;;
        'SHA512')
            check_valid_sha512_checksum "$CHECKSUM"
            ;;
        *)
            return 2
            ;;
    esac
    return $?
}

function check_util_installed () {
    local UTIL_NAME="$1"
    type "$UTIL_NAME" &> /dev/null && return 0 || return 1
}

function check_loglevel_set () {
    local LOG_LEVEL="$1"
    LOG_LEVELS=( `fetch_set_log_levels` )
    check_item_in_set "$LOG_LEVEL" ${LOG_LEVELS[@]}
    return $?
}

function check_item_in_set () {
    local ITEM="$1"
    ITEM_SET=( "${@:2}" )
    for SET_ITEM in "${ITEM_SET[@]}"; do
        if [[ "$ITEM" == "$SET_ITEM" ]]; then
            return 0
        fi
    done
    return 1
}

