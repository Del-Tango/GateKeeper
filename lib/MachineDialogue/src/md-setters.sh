#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# SETTERS

function set_wpa_supplicant_configuration_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File (${RED}$FILE_PATH${RESET}) not found."
        return 1
    fi
    MD_DEFAULT['wpa-suplicant-conf']="$FILE_PATH"
    return 0
}

function set_wpa_supplicant_log_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File (${RED}$FILE_PATH${RESET}) not found."
        return 1
    fi
    MD_DEFAULT['wpa-suplicant-log']="$FILE_PATH"
    return 0
}

function set_dhcpcd_log_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "File (${RED}$FILE_PATH${RESET}) not found."
        return 1
    fi
    MD_DEFAULT['dhcpcd-log']="$FILE_PATH"
    return 0
}

function set_wireless_interface () {
    local WIRELESS_INTERFACE="$1"
    check_valid_wireless_interface "$WIRELESS_INTERFACE"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid wireless interface"\
            "(${RED}$WIRELESS_INTERFACE${RESET})."
        return 1
    fi
    MD_DEFAULT['wifi-interface']=$WIRELESS_INTERFACE
    return 0
}

function set_checksum_algorithm () {
    local CHECKSUM_ALGORITHM="$1"
    check_item_in_set "$CHECKSUM_ALLGORITHM" ${MD_CHECKSUM_ALGORITHMS[@]}
    if [ $? -ne 0 ]; then
        echo; warning_msg "Invalid checksum algorithm label"\
            "(${RED}$CHECKSUM_ALGORITHM${RESET})."
        return 1
    fi
    MD_DEFAULT['checksum']="$CHECKSUM_ALGORITHM"
    return 0
}

function set_connected_essid () {
    local TARGET_ESSID="$1"
    MD_DEFAULT['conn-essid']="$TARGET_ESSID"
    return 0
}

function set_owner () {
    local FILE_PATH="$1"
    local USER_NAME="$2"
    chown -R $USER_NAME $FILE_PATH
    return $?
}

function set_permission () {
    local FILE_PATH="$1"
    local PERMISSIONS=$2
    chmod -R $PERMISSIONS $FILE_PATH
    return $?
}

function set_imported_file () {
    local IMPORT_LABEL="$1"
    local FILE_PATH="$2"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        error_msg "File (${RED}$FILE_PATH${RESET}) does not exist."
        return 1
    fi
    MD_IMPORTS["$IMPORT_LABEL"]="$FILE_PATH"
    return 0
}

function set_log_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        error_msg "File (${RED}$FILE_PATH${RESET}) does not exist."
        return 1
    fi
    MD_DEFAULT['log-file']="$FILE_PATH"
    return 0
}

function set_log_lines () {
    local LOG_LINES=$1
    if [ -z "$LOG_LINES" ]; then
        error_msg "Log line value (${RED}$LOG_LINES${RESET}) is not a number."
        return 1
    fi
    MD_DEFAULT['log-lines']=$LOG_LINES
    return 0
}

function set_silent_flag () {
    local SILENCE="$1"
    if [[ "$SILENCE" != 'on' ]] && [[ "$SILENCE" != 'off' ]]; then
        error_msg "Invalid silence value ${RED}$SILENCE${RESET}."\
            "Defaulting to ${RED}OFF${RESET}."
        MD_SILENT='off'
        return 1
    fi
    MD_SILENT="$SILENCE"
    return 0
}

function set_menu_controller_extended_banner () {
    local MENU_CONTROLLER="$1"
    local DISPLAY_BANNER_FUNCTION_NAME="$2"
    check_function_is_defined "$DISPLAY_BANNER_FUNCTION_NAME"
    if [ $? -ne 0 ]; then
        error_msg "Display banner function"\
            "${RED}$DISPLAY_BANNER_FUNCTION_NAME${RESET} not found."
        return 1
    fi
    MD_CONTROLLER_BANNERS["$MENU_CONTROLLER"]="$DISPLAY_BANNER_FUNCTION_NAME"
    return 0
}

function set_requiered_privileges () {
    local PRIVILEGES="$1"
    if [[ "$PRIVILEGES" != 'on' ]] && [[ "$PRIVILEGES" != 'off' ]]; then
        error_msg "Invalid superuser privileges flag value"\
            "${RED}$PRIVILEGES${RESET}. Defaulting to ${GREEN}ON${RESET}."
        MD_ROOT='on'
        return 1
    fi
    MD_ROOT=$PRIVILEGES
    return 0
}

function set_project_name () {
    local PROJECT_NAME="$1"
    SCRIPT_NAME="$PROJECT_NAME"
    return 0
}

function set_project_prompt () {
    local PROJECT_PROMPT="$1"
    PS3="$PROJECT_PROMPT"
    return 0
}

function set_menu_controller_action_key () {
    local CONTROLLER_ACTION_KEY="$1"
    local CONTROLLER_ACTION_RESOURCE="$2"
    REGISTERED_ACTION_KEYS=( `fetch_action_keys` )
    check_item_in_set "$CONTROLLER_ACTION_KEY" ${REGISTERED_ACTION_KEYS[@]}
    if [ $? -eq 0 ]; then
        warning_msg "Controller action key"\
            "${RED}$CONTROLLER_ACTION_KEY${RESET} already exists."
        return 1
    fi
    MD_CONTROLLER_OPTION_KEYS["$CONTROLLER_ACTION_KEY"]="$CONTROLLER_ACTION_RESOURCE"
    return 0
}

function set_menu_controller_options () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_OPTIONS="$2"
    check_menu_controller_exists "$MENU_CONTROLLER_LABEL"
    if [ $? -ne 0 ]; then
        warning_msg "Menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET} does not exists."
        return 1
    fi
    MD_CONTROLLER_OPTIONS["$MENU_CONTROLLER_LABEL"]="$MENU_CONTROLLER_OPTIONS"
    return 0
}

function set_menu_controller_description () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_DESCRIPTION="${@:2}"
    check_menu_controller_exists "$MENU_CONTROLLER_LABEL"
    if [ $? -ne 0 ]; then
        warning_msg "Menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET} does not exists."
        return 1
    fi
    MD_CONTROLLERS["$MENU_CONTROLLER_LABEL"]="$MENU_CONTROLLER_DESCRIPTION"
    return 0
}

function set_menu_controller () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_DESCRIPTION="${@:2}"
    check_menu_controller_exists "$MENU_CONTROLLER_LABEL"
    if [ $? -eq 0 ]; then
        warning_msg "Menu controller"\
            "${RED}$MENU_CONTROLLER_LABEL${RESET} already exists."
        return 1
    fi
    MD_CONTROLLERS["$MENU_CONTROLLER_LABEL"]="$MENU_CONTROLLER_DESCRIPTION"
    return 0
}

function set_file_editor () {
    local FILE_EDITOR="$1"
    check_util_installed "$FILE_EDITOR"
    if [ $? -ne 0 ]; then
        warning_msg "Editor ${RED}$FILE_EDITOR${RESET} not installed."
        return 1
    fi
    MD_DEFAULT['file-editor']=$FILE_EDITOR
    return 0
}

function set_logging () {
    local LOGGING="$1"
    if [[ "$LOGGING" != 'on' ]] && [[ "$LOGGING" != 'off' ]]; then
        error_msg "Invalid logging value ${RED}$LOGGING${RESET}."\
            "Defaulting to ${GREEN}ON${RESET}."
        MD_LOGGING='on'
        return 1
    fi
    MD_LOGGING=$LOGGING
    return 0
}

function set_safety () {
    local SAFETY="$1"
    if [[ "$SAFETY" != 'on' ]] && [[ "$SAFETY" != 'off' ]]; then
        error_msg "Invalid safety value ${RED}$SAFETY${RESET}."\
            "Defaulting to ${GREEN}ON${RESET}."
        MD_SAFETY='on'
        return 1
    fi
    MD_SAFETY=$SAFETY
    return 0
}

function set_temporary_file () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        error_msg "File ${RED}$FILE_PATH${RESET} not found."
        return 1
    fi
    MD_DEFAULT['tmp-file']="$FILE_PATH"
    return 0
}


