#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# INIT

function init_menu () {
    local MENU_LABEL="$1"
    MENU_OPTIONS=( `fetch_all_menu_controller_options "$MENU_LABEL"` )
    if [ ${#MENU_OPTIONS[@]} -eq 0 ]; then
        warning_msg "No options found for menu controller"\
            "${RED}$MENU_LABEL${RESET}."
        return 1
    fi; while :
    do
        menu_controller "$MENU_LABEL" ${MENU_OPTIONS[@]}
        if [ $? -ne 0 ]; then
            break
        fi
    done
    return 0
}



