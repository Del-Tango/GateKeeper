#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# GENERAL

function flowctrl_start() {
    local JSON_FILE_PATH="$1"
    local BACKGROUND=${2:-0}
    local ARGUMENTS=(
        `format_flowctrl_cargo_action_start_args ${JSON_FILE_PATH}`
    )
    local COMMAND="${MD_CARGO['flow-ctrl']} ${ARGUMENTS[@]}"
    if [[ ${BACKGROUND} -ne 0 ]]; then
        local COMMAND="${COMMAND} &> /dev/null &"
    fi
    ${COMMAND}
    return $?
}

function flowctrl_pause() {
    local ARGUMENTS=( `format_flowctrl_cargo_action_pause_args` )
    ${MD_CARGO['flow-ctrl']} ${ARGUMENTS[@]}
    return $?
}

function flowctrl_resume() {
    local ARGUMENTS=( `format_flowctrl_cargo_action_resume_args` )
    ${MD_CARGO['flow-ctrl']} ${ARGUMENTS[@]}
    return $?
}

function flowctrl_stop() {
    local ARGUMENTS=( `format_flowctrl_cargo_action_stop_args` )
    ${MD_CARGO['flow-ctrl']} ${ARGUMENTS[@]}
    return $?
}

function flowctrl_purge() {
    local ARGUMENTS=( `format_flowctrl_cargo_action_purge_args` )
    ${MD_CARGO['flow-ctrl']} ${ARGUMENTS[@]}
    return $?
}

function connect_to_wireless_access_point () {
    local CONNECTION_MODE="$1"
    local TARGET_ESSID="$2"
    local WIFI_PASSWORD="$3"
    check_safety_off
    if [ $? -ne 0 ]; then
        return 0
    fi
    case "$CONNECTION_MODE" in
        'password-on')
            ${MD_CARGO['wifi-commander']} \
                "$CONF_FILE_PATH" \
                '--connect-pass' "$TARGET_ESSID" "$WIFI_PASSWORD"
            ;;
        'password-off')
            ${MD_CARGO['wifi-commander']} \
                "$CONF_FILE_PATH" \
                '--connect-without-pass' "$TARGET_ESSID"
            ;;
        *)
            echo; info_msg "No connection mode specified,"\
                "defaulting to password protected."
            ${MD_CARGO['wifi-commander']} \
                "$CONF_FILE_PATH" \
                '--connect-pass' "$TARGET_ESSID" "$WIFI_PASSWORD"
            ;;
    esac
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        set_connected_essid "$TARGET_ESSID"
    fi
    return $EXIT_CODE
}

function disconnect_from_wireless_access_point () {
    check_safety_off
    if [ $? -ne 0 ]; then
        return 0
    fi
    wpa_cli terminate &> /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        set_connected_essid "Unconnected"
    fi
    return $EXIT_CODE
}

function remove_system_group () {
    local GROUP_NAME="$1"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET} safety is"\
            "(${GREEN}ON${RESET}). System group (${YELLOW}$GROUP_NAME${RESET})"\
            "is not beeing removed."
    else
        groupdel "$GROUP_NAME" &> /dev/null
        return $?
    fi
    return 1
}

function add_system_user_to_group () {
    local USER_NAME="$1"
    local GROUP_NAME="$2"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET} safety is"\
            "(${GREEN}ON${RESET}). System user (${YELLOW}$USER_NAME${RESET})"\
            "is not beeing added to group (${YELLOW}$GROUP_NAME${RESET})."
    else
        usermod -G "$GROUP_NAME" "$USER_NAME" &> /dev/null
        return $?
    fi
    return 1
}

function filter_file_content () {
    local FILE_PATH="$1"
    local START_PATTERN="$2"
    local STOP_PATTERN="$3"
    awk "/${START_PATTERN}/ {p=1}; p; /${STOP_PATTERN}/ {p=0}" "$FILE_PATH" 2> /dev/null
    return $?
}

function remove_system_user () {
    local USER_NAME="$1"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET} safety is"\
            "(${GREEN}ON${RESET}). System user (${YELLOW}$USER_NAME${RESET})"\
            "is not beeing removed."
    else
        deluser "$USER_NAME" &> /dev/null
        return $?
    fi
    return 1
}

function update_apt_dependencies () {
    DEPENDENCIES=( $@ )
    MD_APT_DEPENDENCIES=( ${MD_APT_DEPENDENCIES[@]} ${DEPENDENCIES[@]} )
    return 0
}

function update_pip_dependencies () {
    DEPENDENCIES=( $@ )
    MD_PIP_DEPENDENCIES=( ${MD_PIP_DEPENDENCIES[@]} ${DEPENDENCIES[@]} )
    return 0
}

function update_pip3_dependencies () {
    DEPENDENCIES=( $@ )
    MD_PIP3_DEPENDENCIES=( ${MD_PIP3_DEPENDENCIES[@]} ${DEPENDENCIES[@]} )
    return 0
}

function lan_scan () {
    for i in `seq ${MD_DEFAULT['start-addr-range']} ${MD_DEFAULT['end-addr-range']}`; do
        ping "${MD_DEFAULT['subnet-addr']}.$i" -c 1 -w 5 > /dev/null && (
            arp -a "${MD_DEFAULT['subnet-addr']}.$i" | \
            egrep -e '([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.' | \
            sort -u | \
            awk '{print $2$4}' | \
            sed -e 's/)/ /g' -e 's/(//g'
        ) &
    done; sleep 1
    return 0
}

function shred_directory () {
    local TARGET_DIR="$1"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET} safety is (${GREEN}ON${RESET})."\
            "File (${YELLOW}$TARGET_FILE${RESET}) is not beeing shredded."
    else
        find "$TARGET_DIR" -type f | xargs shred f -n 10 -z -u &> /dev/null
        rm -rf "$TARGET_DIR" &> /dev/null
        return $?
    fi
    return 1
}

function shred_file () {
    local TARGET_FILE="$1"
    check_safety_off
    if [ $? -ne 0 ]; then
        warning_msg "${GREEN}$SCRIPT_NAME${RESET} safety is (${GREEN}ON${RESET})."\
            "File (${YELLOW}$TARGET_FILE${RESET}) is not beeing shredded."
    else
        shred -f -n 10 -z -u "$TARGET_FILE" &> /dev/null
        return $?
    fi
    return 1
}

function view_block_device_sector_hexdump () {
    local DEVICE=$1
    local BLOCK_SIZE=$2
    local SECTOR_NUMBER=$3
    local BLOCK_COUNT=$4
    dd if=$DEVICE bs=$BLOCK_SIZE count=$BLOCK_COUNT skip=$SECTOR_NUMBER | \
        hexdump \
            -e '/24 "%004_ax     " ' \
            -e '24/1 "%02x "' \
            -e '"     |"24/1 " %_p" "  |" "\n"' -v | \
            grep '|'
    return $?
}

function truncate_file_to_size () {
    local FILE_PATH="$1"
    local SIZE=$2
    truncate --size=$SIZE $FILE_PATH &> /dev/null
    return $?
}

function clone_directory_structure () {
    local SOURCE_DIR_PATH="$1"
    local TARGET_DIR_PATH="$2"
    cp -r "$SOURCE_DIR_PATH" "$TARGET_DIR_PATH" &> /dev/null
    if [ ! -d "$TARGET_DIR_PATH" ]; then
        echo; error_msg "Something went wrong. Could not clone directory"\
            "structure of ${YELLOW}$SOURCE_DIR_PATH${RESET}"\
            "to ${RED}$TARGET_DIR_PATH${RESET}."
        return 1
    fi
    for discovered_path in `find "$TARGET_DIR_PATH"`; do
        check_file_exists "$discovered_path"
        if [ $? -ne 0 ]; then
            continue
        fi
        rm $discovered_path &> /dev/null
    done
    return 0
}

function remove_directory () {
    local DIR_PATH="$1"
    check_directory_exists "$DIR_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid directory path ${RED}$DIR_PATH${RESET}."
        return 1
    fi
#   find "$DIR_PATH" -type f | xargs shred -f -n 10 -z -u &> /dev/null
    rm -rf "$DIR_PATH" &> /dev/null
    return $?
}

function remove_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid file path ${RED}$FILE_PATH${RESET}."
        return 1
    fi
    shred -f -n 10 -z -u "$FILE_PATH" &> /dev/null
    rm -f "$FILE_PATH" &> /dev/null
    return $?
}

function archive_file () {
    local FILE_PATH="$1"
    local OUT_FILE_PATH="$2"
    tar -cf "$OUT_FILE_PATH" "$FILE_PATH" &> /dev/null
    return $?
}

function mount_block_device () {
    local BLOCK_DEVICE="$1"
    local MOUNT_POINT_DIR_PATH="$2"
    mount "$BLOCK_DEVICE" "$MOUNT_POINT_DIR_PATH" &> /dev/null
    if [ $? -ne 0 ]; then
        error_msg "Something went wrong."\
            "Could not mount ${YELLOW}$BLOCK_DEVICE${RESET}"\
            "on ${RED}$MOUNT_POINT_DIR_PATH${RESET}."
        return 1
    fi
    ok_msg "Successfully mounted ${YELLOW}$BLOCK_DEVICE${RESET}"\
        "on ${GREEN}$MOUNT_POINT_DIR_PATH${RESET}."
    return 0
}

function unmount_block_device () {
    local BLOCK_DEVICE="$1"
    umount "$BLOCK_DEVICE" &> /dev/null
    if [ $? -ne 0 ]; then
        error_msg "Something went wrong."\
            "Could not unmount ${RED}$BLOCK_DEVICE${RESET}."
        return 1
    fi
    ok_msg "Successfully unmounted ${GREEN}$BLOCK_DEVICE${RESET}."
    return 0
}

function write_to_file () {
    local FILE_PATH="$1"
    local CONTENT="${@:2}"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File (${RED}$FILE_PATH${RESET}) does not exist."
        echo; return 1
    elif [ -z "$CONTENT" ]; then
        echo; warning_msg "No content specified."
        echo; return 2
    fi
    echo "$CONTENT" >> "$FILE_PATH"
    return $?
}

function clear_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; warning_msg "File (${RED}$FILE_PATH${RESET}) does not exist."
        echo; return 1
    fi
    echo -n > $FILE_PATH
    return $?
}

function is_alive_ping () {
    local TARGET=$1
    ping -c 1 $TARGET &> /dev/null
    [ $? -eq 0 ] && return 0 || return 1
}

function three_second_count_down () {
    for item in `seq 3`; do
        echo -n '.'; sleep 1
    done; echo; return 0
}

function sort_alphanumerically () {
    local ITEMS="$@"
    echo -n > ${MD_DEFAULT['tmp-file']}
    echo $ITEMS > ${MD_DEFAULT['tmp-file']}
    sort ${MD_DEFAULT['tmp-file']}
    EXIT_CODE=$?
    echo -n > ${MD_DEFAULT['tmp-file']}
    return $EXIT_CODE
}

function edit_file () {
    local FILE_PATH="$1"
    ${MD_DEFAULT['file-editor']} $FILE_PATH
    return $?
}

function untrap_persistent_menu_return_signal_sigint () {
    trap - SIGINT
    return $?
}

function trap_persistent_menu_return_signal_sigint () {
    local MESSAGE="$@"
    trap_interrupt_signal "'echo $MESSAGE; return 0'"
    return $?
}

function trap_single_menu_return_signal_sigint () {
    local MESSAGE="$@"
    trap_interrupt_signal "'trap - SIGINT; echo $MESSAGE; return 0'"
    return $?
}

function trap_signals () {
    local ACTIONS="$1"
    local SIGNALS="$2"
    trap $ACTIONS $SIGNALS
    return $?
}

function trap_interrupt_signal () {
    local COMMAND_STRING="$@"
    trap_signals "$COMMAND_STRING" "SIGINT"
    return 0
}

function self_destruct () {
    if [ -z "${MD_DEFAULT['project-path']}" ]; then
        error_msg "No project path declared."
        return 1
    fi
    rm -rf "${MD_DEFAULT['project-path']}" &> /dev/null
    return $?
}

function add_apt_dependency () {
    local APT_DEPENDENCY="$1"
    check_apt_dependency_set "$APT_DEPENDENCY"
    if [ $? -eq 0 ]; then
        nok_msg "Dependency ${RED}$APT_DEPENDENCY${RESET}"\
            "is already set to be installed using the APT package manager."
        return 1
    fi
    MD_APT_DEPENDENCIES+=( "$APT_DEPENDENCY" )
    ok_msg "Successfully set dependency ${GREEN}$APT_DEPENDENCY${RESET}"\
        "up to be installed using the APT package manager."
    return 0
}

function remove_apt_dependency () {
    local APT_DEPENDENCY="$1"
    check_apt_dependency_set "$APT_DEPENDENCY"
    if [ $? -ne 0 ]; then
        nok_msg "Dependency ${RED}$APT_DEPENDENCY${RESET}"\
            "is not set to be installed using the APT package manager."
        return 1
    fi
    MD_APT_DEPENDENCIES=( "${MD_APT_DEPENDENCIES[@]/$APT_DEPENDENCY}" )
    ok_msg "Successfully removed dependency ${GREEN}$APT_DEPENDENCY${RESET}."
    return 0
}

function bind_controller_option_to_menu () {
    local MENU_CONTROLLER="$1"
    local MENU_OPTION="$2"
    local MENU_RESOURCE="$3"
    check_menu_controller_exists "$MENU_CONTROLLER"
    if [ $? -ne 0 ]; then
        error_msg "Initial menu controller ${RED}$MENU_CONTROLLER${RESET}"\
            "not found."
        return 1
    fi
    debug_msg "Confirmed menu controller"\
        "${GREEN}$MENU_CONTROLLER${RESET} exists."
    check_controller_option_exists "$MENU_CONTROLLER" "$MENU_OPTION"
    if [ $? -ne 0 ]; then
        error_msg "Menu controller option ${RED}$MENU_OPTION${RESET}"\
            "not found."
        return 2
    fi
    debug_msg "Confirmed ${CYAN}$MENU_CONTROLLER${RESET} controller"\
        "option ${GREEN}$MENU_OPTION${RESET} exists."
    check_menu_controller_exists "$MENU_RESOURCE"
    if [ $? -ne 0 ]; then
        error_msg "Endpoint menu controller ${RED}$MENU_RESOURCE${RESET}"\
            "not found."
        return 3
    fi
    # TODO - WARNING - Following debug messages may lead to log spam
#   debug_msg "Confirmed bind target menu controller"\
#       "${GREEN}$MENU_RESOURCE${RESET} exists."
    CONTROLLER_JUMP_KEY=`format_menu_controller_jump_key \
        "$MENU_CONTROLLER" "$MENU_OPTION"`
#   debug_msg "${CYAN}$MENU_CONTROLLER${RESET} controller jump key is"\
#       "${GREEN}$CONTROLLER_JUMP_KEY${RESET}."
    NEXT_MENU_OPTIONS=( `fetch_all_menu_controller_options "$MENU_CONTROLLER"` )
#   debug_msg "${CYAN}$MENU_CONTROLLER${RESET} options are"\
#       "${YELLOW}${NEXT_MENU_OPTIONS[@]}${RESET}."
    FUNCTION_RESOURCE=`format_menu_controller_jumper_function_resource \
        "$MENU_RESOURCE"`
#   debug_msg "Function resource for controller option"\
#       "${YELLOW}$MENU_OPTION${RESET} is ${GREEN}$FUNCTION_RESOURCE${RESET}."
    set_menu_controller_action_key "$CONTROLLER_JUMP_KEY" "$FUNCTION_RESOURCE"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        error_msg "Something went wrong."\
            "Could not set ${CYAN}$MENU_CONTROLLER${RESET}"\
            "option ${RED}$MENU_OPTION${RESET}"\
            "jump key ${RED}$CONTROLLER_JUMP_KEY${RESET}."
    fi
    return $EXIT_CODE
}

function bind_controller_option_to_action () {
    local MENU_CONTROLLER="$1"
    local MENU_OPTION="$2"
    local FUNCTION_RESOURCE="$3"
    check_menu_controller_exists "$MENU_CONTROLLER"
    if [ $? -ne 0 ]; then
        error_msg "Menu controller ${RED}$MENU_CONTROLLER${RESET}"\
            "not found."
        return 1
    fi
    check_controller_option_exists "$MENU_CONTROLLER" "$MENU_OPTION"
    if [ $? -ne 0 ]; then
        error_msg "Menu controller option ${RED}$MENU_OPTION${RESET}"\
            "not found."
        return 2
    fi
    check_function_is_defined "$FUNCTION_RESOURCE"
    if [ $? -ne 0 ]; then
        error_msg "Function ${RED}$FUNCTION_RESOURCE${RESET} not found."
        return 3
    fi
    CONTROLLER_ACTION_KEY=`format_menu_controller_action_key \
        "$MENU_CONTROLLER" "$MENU_OPTION"`
    set_menu_controller_action_key "$CONTROLLER_ACTION_KEY" "$FUNCTION_RESOURCE"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        error_msg "Something went wrong."\
            "Could not set ${CYAN}$MENU_CONTROLLER${RESET}"\
            "option ${RED}$MENU_OPTION${RESET}"\
            "action key ${RED}$CONTROLLER_ACTION_KEY${RESET}."
    fi
    return $EXIT_CODE
}

function bind_controller_option () {
    local BIND_TARGET="$1"
    local MENU_CONTROLLER="$2"
    local MENU_OPTION="$3"
    local OPTION_RESOURCE="$4"
    case "$BIND_TARGET" in
        'to_menu')
            bind_controller_option_to_menu "$MENU_CONTROLLER" \
                "$MENU_OPTION" "$OPTION_RESOURCE"
            ;;
        'to_action')
            bind_controller_option_to_action "$MENU_CONTROLLER" \
                "$MENU_OPTION" "$OPTION_RESOURCE"
            ;;
        *)
            error_msg "Invalid bind target ${RED}$BIND_TARGET${RESET}."
            return 1
            ;;
    esac
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not bind ${CYAN}$MENU_CONTROLLER${RESET} option"\
            "${RED}$MENU_OPTION${RESET} to target resource"\
            "${RED}$OPTION_RESOURCE${RESET}."
    else
        ok_msg "Menu option ${GREEN}$MENU_OPTION${RESET} bind to"\
            "${GREEN}$OPTION_RESOURCE${RESET} successful."
    fi
    return $EXIT_CODE
}

function remove_all_menu_controller_option_keys () {
    local MENU_CONTROLLER_LABEL="$1"
    REGEX_PATTERN="`fetch_action_key_regex_pattern`"
    KEY_COUNT=`fetch_action_key_count`
    CONTROLLER_ACTION_KEYS=( `fetch_action_keys` )
    SUCCESS_COUNT=0; FAILURE_COUNT=0
    for action_key in ${CONTROLLER_ACTION_KEYS[@]}; do
        check_string_matches_regex_pattern "$action_key" "$REGEX_PATTERN"
        if [ $? -ne 0 ]; then
            debug_msg "Skipping key $action_key."
            continue
        fi
        unset MD_CONTROLLER_OPTION_KEYS["$action_key"]
        if [ $? -ne 0 ]; then
            FAILURE_COUNT=$((FAILURE_COUNT + 1))
            warning_msg "Something went wrong."\
                "Could not remove ${CYAN}$MENU_CONTROLLER_LABEL${RESET}"\
                "controller action key ${RED}$action_key${RESET}."
            continue
        fi
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        ok_msg "Successfully removed ${CYAN}$MENU_CONTROLLER_LABEL${RESET}"\
            "controller action key ${GREEN}$action_key${RESET}."
    done
    info_msg "Remove ${GREEN}$SUCCESS_COUNT${RESET}/${WHITE}$KEY_COUNT${RESET}"\
        "controller action keys. ${RED}$FAILURE_COUNT${RESET} removal failures."
    if [ $SUCCESS_COUNT -eq 0 ]; then
        warning_msg "No controller action keys removed."
        return 1
    fi
    return 0
}

function remove_menu_controller () {
    local MENU_CONTROLLER_LABEL="$1"
    check_menu_controller_exists "$MENU_CONTROLLER_LABEL"
    if [ $? -ne 0 ]; then
        warning_msg "Invalid menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET}."
        return 1
    fi
    remove_all_menu_controller_option_keys "$MENU_CONTROLLER_LABEL"
    unset MD_CONTROLLERS["$MENU_CONTROLLER_LABEL"] &> /dev/null
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not remove menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET}."
    else
        ok_msg "Successfully removed menu controller"\
            "${GREEN}$MENU_CONTROLLER_LABEL${RESET}."
    fi
    return $EXIT_CODE
}

function add_menu_controller () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_DESCRIPTION="$2"
    set_menu_controller "$MENU_CONTROLLER_LABEL" "$MENU_CONTROLLER_DESCRIPTION"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not add new menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET}."
    else
        ok_msg "Successfully added new menu controller"\
            "${GREEN}$MENU_CONTROLLER_LABEL${RESET}."
    fi
    return $EXIT_CODE
}

