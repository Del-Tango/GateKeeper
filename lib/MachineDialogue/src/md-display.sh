#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# DISPLAY

function display_loading_message () {
    local WAIT_SECONDS=$1
    local LOADING_STRING="$2"
    local PREVIOUS='-'
    ITERCOUNT=`echo "$WAIT_SECONDS * 2" | bc`
    for item in `seq $ITERCOUNT`; do
        local MESSAGE_STRING=""
        case "$PREVIOUS" in
            '/')
                local PREVIOUS='-'
                ;;
            '-')
                local PREVIOUS='\'
                ;;
            '\')
                local PREVIOUS='/'
                ;;
        esac
        local MESSAGE_STRING="${LOADING_STRING}($PREVIOUS)"
        clear; echo "$MESSAGE_STRING"; sleep 0.5
    done
    return 0
}

function display_script_banner () {
    local CLEAR_SCREEN=${1:-clear-screen-on}
    figlet -f lean -w 1000 "$SCRIPT_NAME" > "${MD_DEFAULT['tmp-file']}"
    case "$CLEAR_SCREEN" in
        'clear-screen-on')
            clear
            ;;
    esac; echo -n "${BLUE}`cat ${MD_DEFAULT['tmp-file']}`${RESET}"
    echo -n > ${MD_DEFAULT['tmp-file']}
    return 0
}

# TODO - Under construction
function display_settings () {
    DISPLAY_LOGGING=`format_flag_colors "$MD_LOGGING"`
    DISPLAY_MENU_BANNER=`format_flag_colors "$MD_MENU_BANNER"`
    DISPLAY_SAFETY=`format_flag_colors "$MD_SAFETY"`
    DISPLAY_SUPERUSER=`format_flag_colors "$MD_ROOT"`
    echo "
[ ${CYAN}Project Name${RESET}           ]: "${BLUE}$SCRIPT_NAME${RESET}"
[ ${CYAN}Project Prompt${RESET}         ]: "${BLUE}$PS3${RESET}"
[ ${CYAN}Temporary Directory${RESET}    ]: "${BLUE}${MD_DEFAULT['tmp-dir']}${RESET}"
[ ${CYAN}Temporary File${RESET}         ]: "${YELLOW}${MD_DEFAULT['tmp-file']}${RESET}"
[ ${CYAN}Source Directory${RESET}       ]: "${BLUE}${MD_DEFAULT['source-dir']}${RESET}"
[ ${CYAN}Source File${RESET}            ]: "${YELLOW}${MD_DEFAULT['source-file']}${RESET}"
[ ${CYAN}Config Directory${RESET}       ]: "${BLUE}${MD_DEFAULT['conf-dir']}${RESET}"
[ ${CYAN}Config File${RESET}            ]: "${YELLOW}${MD_DEFAULT['conf-file']}${RESET}"
[ ${CYAN}Log Directory${RESET}          ]: "${BLUE}${MD_DEFAULT['log-dir']}${RESET}"
[ ${CYAN}Log File${RESET}               ]: "${YELLOW}${MD_DEFAULT['log-file']}${RESET}"
[ ${CYAN}Docs Directory${RESET}         ]: "${BLUE}${MD_DEFAULT['docs-dir']}${RESET}"
[ ${CYAN}File Editor${RESET}            ]: "${MAGENTA}${MD_DEFAULT['file-editor']}${RESET}"
[ ${CYAN}Logging${RESET}                ]: $DISPLAY_LOGGING
[ ${CYAN}Menu Banner${RESET}            ]: $DISPLAY_MENU_BANNER
[ ${CYAN}Safety${RESET}                 ]: $DISPLAY_SAFETY
[ ${CYAN}Superuser${RESET}              ]: $DISPLAY_SUPERUSER
    " | column
    return $?
}

function display_available_wireless_access_points () {
    AVAILABLE_ESSID=`${MD_CARGO['wifi-commander']} \
        "$CONF_FILE_PATH" '--show-ssid' 2> /dev/null | \
        sed 's/\"//g' 2> /dev/null`
    EXIT_CODE=$?
    echo "
${CYAN}Wireless Network Access Points${RESET}
$AVAILABLE_ESSID"
    return $EXIT_CODE
}

function display_block_devices () {
    echo; echo -n "${CYAN}DEVICE${RESET}" && \
        echo ${CYAN}`lsblk | grep -e MOUNTPOINT`${RESET} && \
        lsblk | grep -e 'disk' | sed 's/^/\/dev\//g'
    EXIT_CODE=$?
    echo; return $EXIT_CODE
}

function display_file_content () {
    local FILE_PATH="$1"
    check_file_exists "$FILE_PATH"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid file path ${RED}$FILE_PATH${RESET}."
        return 1
    fi
    cat "$FILE_PATH"
    return $?
}

function display_project_banner () {
    figlet -f lean -w 1000 "$SCRIPT_NAME" > "${MD_DEFAULT['tmp-file']}"
    clear; echo -n "${RED}`cat ${MD_DEFAULT['tmp-file']}`${RESET}
    "
    echo -n > ${MD_DEFAULT['tmp-file']}
    return 0
}

function display_menu_controller_banner () {
    local MENU_LABEL="$1"
    check_md_menu_banner_on
    if [ $? -ne 0 ]; then
        return 1
    fi
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${MD_CONTROLLERS[$MENU_LABEL]}"; echo
    check_menu_controller_extended_banner "$MENU_LABEL"
    if [ $? -eq 0 ]; then
        ${MD_CONTROLLER_BANNERS["$MENU_LABEL"]}
    fi
    return $?
}

function debug_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    log_message 'SYMBOL' "${MAGENTA}DEBUG${RESET}" "$MSG"
    return 0
}

function done_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${BLUE}DONE${RESET} ]: $MSG"
    log_message 'SYMBOL' "${BLUE}DONE${RESET}" "$MSG"
    return 0
}

function ok_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${GREEN}OK${RESET} ]: $MSG"
    log_message 'SYMBOL' "${GREEN}OK${RESET}" "$MSG"
    return 0
}

function nok_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}NOK${RESET} ]: $MSG"
    log_message 'SYMBOL' "${RED}NOK${RESET}" "$MSG"
    return 0
}

function qa_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${YELLOW}Q/A${RESET} ]: $MSG"
    log_message 'SYMBOL' "${YELLOW}Q/A${RESET}" "$MSG"
    return 0
}

function info_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${YELLOW}INFO${RESET} ]: $MSG"
    log_message 'SYMBOL' "${YELLOW}INFO${RESET}" "$MSG"
    return 0
}

function error_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}ERROR${RESET} ]: $MSG"
    log_message 'SYMBOL' "${RED}ERROR${RESET}" "$MSG"
    return 0
}

function warning_msg () {
    local MSG="$@"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ ${RED}WARNING${RESET} ]: $MSG"
    log_message 'SYMBOL' "${RED}WARNING${RESET}" "$MSG"
    return 0
}

function symbol_msg () {
    local SYMBOL="$1"
    local MSG="${@:2}"
    if [ -z "$MSG" ]; then
        return 1
    fi
    echo "[ $SYMBOL ]: $MSG"
    log_message 'SYMBOL' "$SYMBOL" "$MSG"
    return 0
}


