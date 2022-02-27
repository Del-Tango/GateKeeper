#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# ACTIONS

function action_display_available_wireless_access_points () {
    echo; info_msg "Discovering wireless network access points..."
    display_available_wireless_access_points
    if [ $? -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not display wireless access points."
        return 1
    fi
    return 0
}

function action_disconnect_from_wireless_access_point () {
    echo; info_msg "You are about to disconnect from wireless network."
    fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
    echo; if [ $? -ne 0 ]; then
        info_msg "Aborting action."
        return 1
    fi
    check_safety_on
    if [ $? -eq 0 ]; then
        warning_msg "Safety is ${GREEN}ON${RESET}."\
            "Connection with wireless access point will not be performed."
        return 2
    fi
    disconnect_from_wireless_access_point
    if [ $? -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not disconnect from wireless access point."
        return 3
    else
        ok_msg "Successfully disconected from wireless access point!"
    fi
    return 0
}

function action_connect_to_wireless_access_point () {
    echo; symbol_msg "${BLUE}$SCRIPT_NAME${RESET}" \
        "${CYAN}Wireless Network Gateways (Radios)${RESET}"
    info_msg "Discovering wireless network access points..."; echo
    TARGET_ESSID=`fetch_wireless_essid_from_user`
    if [ $? -ne 0 ]; then
        return 1
    fi
    SANITIZED=`echo $TARGET_ESSID | sed 's/\"//g'`
    check_essid_password_protected "$SANITIZED"
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 0 ]; then
        PASSWORD=`fetch_wireless_password_from_user "$SANITIZED"`
        echo "
        "; check_safety_on
        if [ $? -eq 0 ]; then
            warning_msg "Safety is ${GREEN}ON${RESET}."\
                "Connection with wireless access point will not be performed."
        fi
        connect_to_wireless_access_point "password-on" "$SANITIZED" "$PASSWORD"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not connect to protected wireless access point"\
                "${RED}$SANITIZED${RESET}."
            return 1
        fi
    elif [ $EXIT_CODE -eq 1 ]; then
        echo; check_safety_on
        if [ $? -eq 0 ]; then
            warning_msg "Safety is ${GREEN}ON${RESET}."\
                "Connection with wireless access point will not be performed."
            return 1
        fi
        connect_to_wireless_access_point "password-off" "$SANITIZED" "$PASSWORD"
        if [ $? -ne 0 ]; then
            warning_msg "Something went wrong."\
                "Could not connect to unprotected wireless access point"\
                "${RED}$SANITIZED${RESET}."
            return 1
        fi
    else
        warning_msg "Could not determine if wireless network"\
            "${RED}$SANITIZED${RESET} is password protected."
        return 1
    fi
    return 0
}

function action_install_dependencies () {
    PACKAGE_MANAGERS=( $@ )
    echo
    fetch_ultimatum_from_user "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    if [ ${#PACKAGE_MANAGERS[@]} -eq 0 ]; then
        PACKAGE_MANAGERS=( 'apt' 'pip' 'pip3' )
    fi
    for manager in ${PACKAGE_MANAGERS[@]}; do
        case "$manager" in
            'apt')
                apt_install_dependencies
                ;;
            'pip')
                pip_install_dependencies
                ;;
            'pip3')
                pip3_install_dependencies
                ;;
        esac
    done
    return $?
}

function action_help () {
    echo; info_msg "Select cargo script to view instructions for:
    "
    CLI_CARGO=`fetch_selection_from_user "Help" ${!MD_CARGO[@]}`
    if [ $? -ne 0 ]; then
        return 1
    fi
    ${MD_CARGO[$CLI_CARGO]} --help
    return $?
}

function action_create_checksum_of_file () {
    local FILE_PATH="$1"
    FILE_CHECKSUM=`create_file_checksum "$FILE_PATH"`
    EXIT_CODE=$?
    echo; symbol_msg "${CYAN}$FOXFACE_CHECKSUM${RESET}" \
        "${GREEN}$FILE_CHECKSUM${RESET}"
    if [ $EXIT_CODE -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not create ${RED}$FILE_PATH${RESET} file"\
            "${CYAN}$FOXFACE_CHECKSUM${RESET} checksum."
        return $EXIT_CODE
    fi
    ok_msg "Successfully computed ${GREEN}$FILE_PATH${RESET} file"\
        "${CYAN}$FOXFACE_CHECKSUM${RESET} checksum."
    return $EXIT_CODE
}

function action_compare_checksum_of_string () {
    local STRING_CHECKSUM="$1"
    local STRING_TO_COMPARE="$2"
    VALID_CHECKSUM=`create_data_checksum "$STRING_TO_COMPARE"`
    SANITIZED_CHECKSUM=`echo "$STRING_CHECKSUM" | sed -e 's/ //g' -e 's/-//g'`
    SANITIZED_VALID_CHECKSUM=`echo "$VALID_CHECKSUM" | sed -e 's/ //g' -e 's/-//g'`
    debug_msg "$STRING_CHECKSUM - $STRING_TO_COMPARE - $VALID_CHECKSUM -"\
        "$SANITIZED_CHECKSUM - $SANITIZED_VALID_CHECKSUM"
    check_identical_strings "$SANITIZED_CHECKSUM" "$SANITIZED_VALID_CHECKSUM"
    if [ $? -ne 0 ]; then
        echo; nok_msg "${CYAN}$FOXFACE_CHECKSUM${RESET} checksum of"\
            "given data is ${YELLOW}$SANITIZED_VALID_CHECKSUM${RESET} not"\
            "${RED}$STRING_CHECKSUM${RESET}."
        return 2
    fi
    echo; ok_msg "It's a match! Given data ${CYAN}$FOXFACE_CHECKSUM${RESET}"\
        "checksum is ${GREEN}$STRING_CHECKSUM${RESET}."
    return 0
}

function action_compare_checksum_of_file () {
    local FILE_PATH="$1"
    local FILE_CHECKSUM="$2"
    VALID_CHECKSUM=`create_file_checksum "$FILE_PATH"`
    SANITIZED_CHECKSUM=`echo "$FILE_CHECKSUM | sed -e 's/ //g' -e 's/-//g'"`
    SANITIZED_VALID_CHECKSUM=`echo "$VALID_CHECKSUM | sed -e 's/ //g' -e 's/-//g'"`
    check_identical_strings "$SANITIZED_CHECKSUM" "$SANITIZED_VALID_CHECKSUM"
    if [ $? -ne 0 ]; then
        echo; nok_msg "${MD_DEFAULT['checksum']} checksum of"\
            "(${YELLOW}$FILE_PATH${RESET}) is $FILE_CHECKSUM not"\
            "$({RED}$CHECKSUM${RESET})."
        return 2
    fi
    echo; ok_msg "It's a match! (${YELLOW}$FILE_PATH${RESET})"\
        "file ${CYAN}${MD_DEFAULT['checksum']}${RESET}"\
        "checksum is (${GREEN}$CHECKSUM${RESET})."
    return 0
}

function action_create_checksum_of_string () {
    local STRING_TO_HASH="$@"
    DATA_CHECKSUM=`create_data_checksum "$STRING_TO_HASH"`
    EXIT_CODE=$?
    echo; symbol_msg "${CYAN}${MD_DEFAULT['checksum']}${RESET}" \
        "${GREEN}$DATA_CHECKSUM${RESET}"
    if [ $EXIT_CODE -ne 0 ]; then
        warning_msg "Something went wrong."\
            "Could not create (${CYAN}${MD_DEFAULT['checksum']}${RESET}"\
            "checksum from given data: (${RED}$STRING_TO_HASH${RESET})."
        return $EXIT_CODE
    fi
    ok_msg "Successfully computed given data"\
        "(${CYAN}${MD_DEFAULT['checksum']}${RESET}) checksum."
    return $EXIT_CODE
}

function action_set_hashing_algorithm () {
    VALID_HASHING_ALGORITHMS=( `fetch_checksum_algorithm_labels` )
    if [ $? -ne 0 ]; then
        echo; error_msg "Something went wrong."\
            "Could not fetch hashing algorithm labels."
        return 2
    fi
    while :
    do
        echo; info_msg "Select ${BLUE}$SCRIPT_NAME${RESET}"\
            "hashing algorithm."; echo
        HASHING_ALGORITHM=`fetch_selection_from_user \
            "HashAlgorithm" ${VALID_HASHING_ALGORITHMS[@]}`
        if [ $? -ne 0 ]; then
            return 1
        fi
        echo; info_msg "Setting checksum hashing algorithm to"\
            "${YELLOW}$HASHING_ALGORITHM${RESET}."
        echo; fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            continue
        fi
        set_checksum_algorithm "$HASHING_ALGORITHM"
        if [ $? -ne 0 ]; then
            echo; warning_msg "Something went wrong."\
                "Could not set checksum hashing algorithm"\
                "${RED}$HASHING_ALGORITHM${RESET}."
            return 3
        fi
        break
    done
    ok_msg "Successfully set checksum hashing algorithm"\
        "${GREEN}$HASHING_ALGORITHM${RESET}."
    return 0
}

function action_edit_temporary_file () {
    echo; info_msg "Editing temporary file"\
        "(${YELLOW}${MD_DEFAULT['tmp-file']}${RESET})"
    ${MD_DEFAULT['file-editor']} ${MD_DEFAULT['tmp-file']}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not edit (${RED}${MD_DEFAULT['tmp-file']}${RESET})."
    else
        check_file_empty "$ROT_SCRIPT"
        if [ $? -eq 0 ]; then
            warning_msg "File (${RED}${MD_DEFAULT['tmp-file']}${RESET})"\
                "is empty."
            return 3
        fi
        ok_msg "Successfully edited file"\
            "(${GREEN}${MD_DEFAULT['tmp-file']}${RESET})."
    fi
    return $EXIT_CODE
}

function action_edit_imported_file () {
    local IMPORT_LABEL="$1"
    echo; info_msg "Editing (${MAGENTA}$IMPORT_LABEL${RESET}) imported file"\
        "(${YELLOW}${MD_IMPORTS[$IMPORT_LABEL]}${RESET})"
    ${MD_DEFAULT['file-editor']} ${MD_IMPORTS[$IMPORT_LABEL]}
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not edit (${RED}${MD_IMPORTS[$IMPORT_LABEL]}${RESET})."
    else
        check_file_empty "$ROT_SCRIPT"
        if [ $? -eq 0 ]; then
            warning_msg "File (${RED}${MD_IMPORTS[$IMPORT_LABEL]}${RESET})"\
                "is empty."
            return 3
        fi
        ok_msg "Successfully edited file"\
            "(${GREEN}${MD_IMPORTS[$IMPORT_LABEL]}${RESET})."
    fi
    return $EXIT_CODE
}

function action_import_file () {
    local IMPORT_LABEL="$1"
    echo; info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    while :
    do
        FILE_PATH=`fetch_data_from_user 'FilePath'`
        local EXIT_CODE=$?
        echo
        if [ $EXIT_CODE -ne 0 ]; then
            info_msg "Aborting action."
            return 1
        fi
        check_file_exists "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "File (${RED}$FILE_PATH${RESET}) does not exists."
            echo; continue
        fi; break
    done
    set_imported_file "$IMPORT_LABEL" "$FILE_PATH"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not import file (${RED}$FILE_PATH${RESET})."
    else
        ok_msg "Successfully imported file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_temporary_file () {
    echo; info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    while :
    do
        FILE_PATH=`fetch_data_from_user 'FilePath'`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        check_file_exists "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "File (${RED}$FILE_PATH${RESET}) does not exists."
            echo; continue
        fi; break
    done
    set_temporary_file "$FILE_PATH"
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) temporary file."
    else
        ok_msg "Successfully set temporary file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_safety_on () {
    echo; qa_msg "Getting scared, are we?"
    fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_safety 'on'
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${BLUE}$SCRIPT_NAME${RESET}) safety"\
            "to (${GREEN}ON${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) safety"\
            "to (${GREEN}ON${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_safety_off () {
    echo; qa_msg "Taking off the training wheels. Are you sure about this?"
    fetch_ultimatum_from_user "${YELLOW}Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
    fi
    set_safety 'off'
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${BLUE}$SCRIPT_NAME${RESET}) safety"\
            "to (${RED}OFF${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) safety"\
            "to (${RED}OFF${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_log_file () {
    echo; info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    while :
    do
        FILE_PATH=`fetch_data_from_user 'FilePath'`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        check_file_exists "$FILE_PATH"
        if [ $? -ne 0 ]; then
            warning_msg "File (${RED}$FILE_PATH${RESET}) does not exists."
            echo; continue
        fi; break
    done
    echo; set_log_file "$FILE_PATH"
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) log file."
    else
        ok_msg "Successfully set (${BLUE}$SCRIPT_NAME${RESET}) log file"\
            "(${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_log_lines () {
    echo; info_msg "Type log line number to display or (${MAGENTA}.back${RESET})."
    while :
    do
        LOG_LINES=`fetch_data_from_user 'LogLines'`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        check_value_is_number $LOG_LINES
        if [ $? -ne 0 ]; then
            warning_msg "LogViewer number of lines required,"\
                "not (${RED}$LOG_LINES${RESET})."
            echo; continue
        fi; break
    done
    echo; set_log_lines $LOG_LINES
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${BLUE}$SCRIPT_NAME${RESET}) default"\
            "${RED}log lines${RESET} to (${RED}$LOG_LINES${RESET})."
    else
        ok_msg "Successfully set ${BLUE}$SCRIPT_NAME${RESET} default"\
            "${GREEN}log lines${RESET} to (${GREEN}$LOG_LINES${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_file_editor () {
    echo; info_msg "Type file editor name or ${MAGENTA}.back${RESET}."
    while :
    do
        FILE_EDITOR=`fetch_data_from_user 'Editor'`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        check_util_installed "$FILE_EDITOR"
        if [ $? -ne 0 ]; then
            warning_msg "File editor (${RED}$FILE_EDITOR${RESET}) is not installed."
            echo; continue
        fi; break
    done
    set_file_editor "$FILE_EDITOR"
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_EDITOR${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) default file editor."
    else
        ok_msg "Successfully set default file editor"\
            "(${GREEN}$FILE_EDITOR${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_silent_flag_on () {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_silent_flag 'on'
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) silence"\
            "to (${GREEN}ON${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) silence"\
            "to (${GREEN}ON${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_silent_flag_off () {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
    fi
    set_silent_flag 'off'
    EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) safety"\
            "to (${RED}OFF${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) safety"\
            "to (${RED}OFF${RESET})."
    fi
    return $EXIT_CODE
}

function action_self_destruct () {
    check_safety_on
    if [ $? -eq 0 ]; then
        echo; warning_msg "Safety is (${GREEN}ON${RESET})."\
            "Aborting self destruct sequence."
        return 0
    fi
    echo; warning_msg "Initiating (${BLUE}$SCRIPT_NAME${RESET})"\
        "self destruct sequence!"
    self_destruct
    return $?
}

function action_back () {
    return 1
}

function action_clear_log_file () {
    check_file_exists "${MD_DEFAULT['log-file']}"
    if [ $? -ne 0 ]; then
        warning_msg "Log file ${RED}${MD_DEFAULT['log-file']}${RESET}"\
            "not found."
        return 1
    fi
    echo -n > "${MD_DEFAULT['log-file']}"
    check_file_empty "${MD_DEFAULT['log-file']}"
    if [ $? -ne 0 ]; then
        error_msg "Something went wrong."\
            "Could not clear ${BLUE}$SCRIPT_NAME${RESET}"\
            "log file ${RED}${MD_DEFAULT['log-file']}${RESET}."
        return 4
    fi
    ok_msg "Successfully cleared ${BLUE}$SCRIPT_NAME${RESET}"\
        "log file ${GREEN}${MD_DEFAULT['log-file']}${RESET}."
    return 0
}

function action_log_view_tail () {
    check_file_exists "${MD_DEFAULT['log-file']}"
    if [ $? -ne 0 ]; then
        warning_msg "Log file ${RED}${MD_DEFAULT['log-file']}${RESET}"\
            "not found."
        return 1
    fi
    echo; tail -n ${MD_DEFAULT['log-lines']} ${MD_DEFAULT['log-file']}
    return $?
}

function action_log_view_head () {
    check_file_exists "${MD_DEFAULT['log-file']}"
    if [ $? -ne 0 ]; then
        warning_msg "Log file ${RED}${MD_DEFAULT['log-file']}${RESET}"\
            "not found."
        return 1
    fi
    echo; head -n ${MD_DEFAULT['log-lines']} ${MD_DEFAULT['log-file']}
    return $?
}

function action_log_view_more () {
    check_file_exists "${MD_DEFAULT['log-file']}"
    if [ $? -ne 0 ]; then
        warning_msg "Log file ${RED}${MD_DEFAULT['log-file']}${RESET}"\
            "not found."
        return 1
    fi
    echo; more ${MD_DEFAULT['log-file']}
    return $?
}

