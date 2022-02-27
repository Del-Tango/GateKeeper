#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# FORMATTERS

function format_flowctrl_cargo_action_pause_args() {
    local ARGUMENTS=( "--pause" `format_flowctrl_cargo_constant_args` )
    echo -n ${ARGUMENTS[@]}
    return $?
}

function format_flowctrl_cargo_action_resume_args() {
    local ARGUMENTS=( "--resume" `format_flowctrl_cargo_constant_args` )
    echo -n ${ARGUMENTS[@]}
    return $?
}

function format_flowctrl_cargo_action_stop_args() {
    local ARGUMENTS=( "--stop" `format_flowctrl_cargo_constant_args` )
    echo -n ${ARGUMENTS[@]}
    return $?
}

function format_flowctrl_cargo_action_purge_args() {
    local ARGUMENTS=( "--purge" `format_flowctrl_cargo_constant_args` )
    echo -n ${ARGUMENTS[@]}
    return $?
}

function format_flowctrl_cargo_action_start_args() {
    local SKETCH_FILE_PATH="$1"
    local ARGUMENTS=(
        "--start"
        "--sketch-file ${SKETCH_FILE_PATH}"
        `format_flowctrl_cargo_constant_args`
    )
    echo -n ${ARGUMENTS[@]}
    return $?
}

function format_flowctrl_cargo_constant_args() {
    local ARGUMENTS=(
        "--log-file ${MD_DEFAULT['log-file']}"
        "--config-file ${MD_DEFAULT['conf-json-file']}"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_lan_scan () {
    lan_scan | column -t > ${MD_DEFAULT['tmp-file']}
    local COUNT=1
    local ACTIVE_MACHINES=`fetch_file_length ${MD_DEFAULT['tmp-file']}`
    CURRENT_ESSID=`fetch_currently_connected_gateway_essid`
    DISPLAY_ESSID=${CURRENT_ESSID:-'Unconnected'}
    echo "${CYAN}Active Machines On WiFi Network"\
        "${GREEN}$DISPLAY_ESSID${CYAN}(${WHITE}$ACTIVE_MACHINES${CYAN})${RESET}"
    echo "${CYAN}   IPV4 Address      MAC Address${RESET}"
    while read line; do
        echo "${WHITE}$COUNT${RESET}) ${GREEN}$line${RESET}"
        local COUNT=$((COUNT + 1))
    done < ${DEFAULT['tmp-file']}
    echo -n > ${MD_DEFAULT['tmp-file']}
    return 0
}

function format_menu_controller_jumper_function_resource () {
    local MENU_CONTROLLER_LABEL="$1"
    local FUNCTION_RESOURCE="init_menu $MENU_CONTROLLER_LABEL"
    echo "$FUNCTION_RESOURCE"
    return $?
}

function format_menu_controller_jump_key () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_OPTION="$2"
    local FORMATTED_JUMP_KEY="$MENU_CONTROLLER_LABEL-jump-$MENU_CONTROLLER_OPTION"
    echo "$FORMATTED_JUMP_KEY"
    return $?
}

function format_menu_controller_action_key () {
    local MENU_CONTROLLER_LABEL="$1"
    local MENU_CONTROLLER_OPTION="$2"
    local FORMATTED_ACTION_KEY="$MENU_CONTROLLER_LABEL-$MENU_CONTROLLER_OPTION"
    echo "$FORMATTED_ACTION_KEY"
    return $?
}

function format_flag_colors () {
    local FLAG="$1"
    case "$FLAG" in
        'on')
            local DISPLAY="${GREEN}ON${RESET}"
            ;;
        'off')
            local DISPLAY="${RED}OFF${RESET}"
            ;;
        *)
            local DISPLAY=$FLAG
            ;;
    esac; echo $DISPLAY
    return 0
}

