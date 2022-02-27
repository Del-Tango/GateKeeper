#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# CONTROLLERS

function menu_controller () {
    local MENU_LABEL="$1"
    local MENU_OPTIONS=( ${@:2} )
    display_menu_controller_banner "$MENU_LABEL"
    debug_msg "Controller: ${CYAN}$MENU_LABEL${RESET},"\
        "Options: ${YELLOW}${MENU_OPTIONS[@]}${RESET}."
    select opt in ${MENU_OPTIONS[@]}; do
        debug_msg "Selected option is ${YELLOW}$opt${RESET}."
        ACTION_KEY=`fetch_controller_option_id "$MENU_LABEL" "$opt"`
        EXIT_CODE=$?; debug_msg "Action key is ${YELLOW}$ACTION_KEY${RESET}"\
            "(${WHITE}$EXIT_CODE${RESET})."
        if [ $EXIT_CODE -ne 0 ]; then
            error_msg "Something went wrong."\
                "Could not fetch ${RED}$MENU_LABEL${RESET}"\
                "action key for option ${RED}$opt${RESET}."
            return 2
        fi
        ${MD_CONTROLLER_OPTION_KEYS["$ACTION_KEY"]}
        return $?
    done
    error_msg "${RED}System failure!${RESET}"
    return 3
}

