#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# SETUP

function load_import () {
    local IMPORT_LABEL="$1"
    local IMPORT_VALUE="$2"
    MD_CARGO[$IMPORT_LABEL]=$IMPORT_VALUE
    ok_msg "Successfully loaded import (${GREEN}$IMPORT_LABEL - $IMPORT_VALUE${RESET})."
    return 0
}

function load_cargo () {
    local CARGO_LABEL="$1"
    local CARGO_VALUE="$2"
    MD_CARGO[$CARGO_LABEL]=$CARGO_VALUE
    ok_msg "Successfully loaded cargo (${GREEN}$CARGO_LABEL - $CARGO_VALUE${RESET})."
    return 0
}


function load_apt_dependencies () {
    DEPENDENCIES=( $@ )
    update_apt_dependencies ${DEPENDENCIES[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not load APT dependecies (${RED}${DEPENDENCIES[@]}${RESET})."
    else
        ok_msg "Successfully loaded"\
            "APT dependencies (${GREEN}${DEPENDENCIES[@]}${RESET})."
    fi
    return $EXIT_CODE
}

function load_pip_dependencies () {
    DEPENDENCIES=( $@ )
    if [ ${#DEPENDENCIES[@]} -eq 0 ]; then
        warning_msg "No PIP dependencies found."
        return 1
    fi
    update_pip_dependencies ${DEPENDENCIES[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not load PIP dependecies (${RED}${DEPENDENCIES[@]}${RESET})."
    else
        ok_msg "Successfully loaded"\
            "PIP dependencies (${GREEN}${DEPENDENCIES[@]}${RESET})."
    fi
    return $EXIT_CODE
}

function load_pip3_dependencies () {
    DEPENDENCIES=( $@ )
    if [ ${#DEPENDENCIES[@]} -eq 0 ]; then
        warning_msg "No PIP3 dependencies found."
        return 1
    fi
    update_pip3_dependencies ${DEPENDENCIES[@]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not load PIP3 dependecies (${RED}${DEPENDENCIES[@]}${RESET})."
    else
        ok_msg "Successfully loaded"\
            "PIP3 dependencies (${GREEN}${DEPENDENCIES[@]}${RESET})."
    fi
    return $EXIT_CODE
}

function load_safety () {
    local SAFETY="$1"
    if [ -z "$SAFETY" ]; then
        warning_msg "No default safety flag value found."\
            "Defaulting to ($MD_SAFETY)."
        return 1
    fi
    check_item_in_set "$MD_SAFETY" 'on' 'off'
    if [ $? -ne 0 ]; then
        nok_msg "Invalid safety flag value (${RED}$MD_SAFETY${RESET})."
    fi
    MD_SAFETY=$SAFETY
    ok_msg "Successfully loaded safety flag value (${GREEN}$MD_SAFETY${RESET})."
    return 0
}

function load_prompt_string () {
    local PROMPT_STRING="$1"
    if [ -z "$PROMPT_STRING" ]; then
        warning_msg "No default prompt string found."\
            "Defaulting to (${YELLO}$PS3${RESET})."
        return 1
    fi
    set_project_prompt "$PROMPT_STRING"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not load prompt string (${RED}$PROMPT_STRING${RESET})."
    else
        ok_msg "Successfully loaded"\
            "prompt string (${GREEN}$PROMPT_STRING${RESET})."
    fi
    return $EXIT_CODE
}

function load_logging_levels () {
    local LOG_LVLS=( $@ )
    if [ ${#LOG_LVLS[@]} -eq 0 ]; then
        warning_msg "No ${BLUE}$SCRIPT_NAME${RESET} logging levels found."
        return 1
    fi
    MD_LOGGING_LEVELS=( ${LOG_LVLS[@]} )
    ok_msg "Successfully loaded ${BLUE}$SCRIPT_NAME${RESET} logging levels."
    return 0
}

function load_default_setting () {
    local LABEL="$1"
    local VALUE=$2
    MD_DEFAULT[$LABEL]=$VALUE
    ok_msg "Successfully loaded ${BLUE}$SCRIPT_NAME${RESET}"\
        "default setting (${GREEN}$LABEL - $VALUE${RESET})."
    return 0
}

function load_script_name () {
    local LOADED_NAME="$1"
    if [ -z "$LOADED_NAME" ]; then
        warning_msg "No default script name found. Defaulting to $SCRIPT_NAME."
        return 1
    fi
    set_project_name "$LOADED_NAME"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not load script name ${RED}$LOADED_NAME${RESET}."
    else
        ok_msg "Successfully loaded"\
            "script name ${GREEN}$LOADED_NAME${RESET}"
    fi
    return $EXIT_CODE
}

function setup_menu_controller_action_option () {
    local LABEL="$1"
    local OPTION="$2"
    local SUBROUTINE="$3"
    info_msg "Binding ${CYAN}$LABEL${RESET} option ${YELLOW}$OPTION${RESET}"\
        "to function ${MAGENTA}$SUBROUTINE${RESET}..."
    bind_controller_option 'to_action' "$LABEL" "$OPTION" "$SUBROUTINE"
    return $?
}

function setup_menu_controller_menu_option () {
    local LABEL="$1"
    local OPTION="$2"
    local TARGET_LABEL="$3"
    info_msg "Binding ${CYAN}$LABEL${RESET} option ${YELLOW}$OPTION${RESET}"\
        "to function ${MAGENTA}$SUBROUTINE${RESET}..."
    bind_controller_option 'to_menu' "$LABEL" "$OPTION" "$TARGET_LABEL"
    return $?
}

# CODE DUMP

