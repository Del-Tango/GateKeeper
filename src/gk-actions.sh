#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# ACTIONS

function action_floodgate_cargo() {
    local ARGUMENTS=( $@ )
    trap 'trap - SIGINT; echo ''[ SIGINT ]: Aborting action.''; return 0' SIGINT
    echo; ${GK_CARGO['gate-keeper']} ${ARGUMENTS[@]}; trap - SIGINT
    return $?
}

function action_command_watchdog() {
    local OPTIONS=( 'Start-CMD-Watchdog' 'Stop-CMD-Watchdog' )
    echo; while :; do
        info_msg "Select CMD Watchdog action or ${MAGENTA}Back${RESET}.
        "
        ACTION=`fetch_selection_from_user 'Watchdog' ${OPTIONS[@]}`
        if [ $? -ne 0 ]; then
            echo; info_msg "Aborting action."
            return 1
        fi
        break
    done
    case "$ACTION" in
        'Start-CMD-Watchdog')
            cli_action_start_command_watchdog
        ;;
        'Stop-CMD-Watchdog')
            cli_action_stop_command_watchdog
        ;;
        *)
            warning_msg "Invalid option! (${RED}$ACTION${RESET})"
            return 1
        ;;
    esac
    return $?
}

function cli_action_stop_watchdog() {
    check_command_watchdog_running
    if [ $? -ne 0 ]; then
        echo "[ WARNING ]: CMD Watchdog not running!"
        return 0
    fi
    echo "[ INFO ]: Stopping Gate CMD Watchdog..."
    touch ${MD_DEFAULT['pid-cmd-wdg']}
    local WATCHDOG_PID=`cat ${MD_DEFAULT['pid-cmd-wdg']}`
    if [ $? -ne 0 ] || [ -z "$WATCHDOG_PID" ]; then
        echo "[ NOK ]: No currently running CMD Watchdog process!"
        return 1
    fi
    ps -aux | grep ${WATCHDOG_PID} | grep -v 'grep' &> /dev/null
    if [ $? -ne 0 ]; then
        echo > ${MD_DEFAULT['pid-cmd-wdg']}
        echo "[ NOK ]: Process ${RED}${WATCHDOG_PID}${RESET} not found! Cleaning up..."
        return 2
    fi
    kill -9 $WATCHDOG_PID &> /dev/null
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        echo "[ NOK ]: Could not terminate PID! ${RED}${WATCHDOG_PID}${RESET}"
    else
        echo > ${MD_DEFAULT['pid-cmd-wdg']}
        echo "[ OK ]: Terminated PID: ${RED}${WATCHDOG_PID}${RESET}"
    fi
    return $EXIT_CODE
}

function cli_action_start_watchdog() {
    check_command_watchdog_running
    if [ $? -eq 0 ]; then
        local WATCHDOG_PID=`cat ${MD_DEFAULT['pid-cmd-wdg']}`
        echo "[ WARNING ]: CMD Watchdog already running! PID: ${WATCHDOG_PID}"
        return 0
    fi
    local ARGUMENTS=( `format_start_watchdog_cargo_arguments` )
    echo "[ INFO ]: Starting Gate CMD Watchdog...
[ INFO ]: Executing (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_floodgate_cargo ${ARGUMENTS[@]} &> /dev/null &
    local WATCHDOG_PID=$!
    if [ -z "$WATCHDOG_PID" ]; then
        echo "[ NOK ]: Something went wrong! Could not start Command Watchdog service!"
        return 1
    fi
    echo $WATCHDOG_PID > ${MD_DEFAULT['pid-cmd-wdg']}
    echo "[ OK ]: CMD Watchdog PID: ${WATCHDOG_PID}"
    return $?
}

function cli_action_gate_status_check() {
    local ARGUMENTS=( `format_check_gates_cargo_arguments` )
    echo "
[ INFO ]: About to execute (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function cli_action_open_gates() {
    local ARGUMENTS=( `format_open_gates_cargo_arguments` )
    echo "
[ INFO ]: About to execute (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function cli_action_close_gates() {
    local ARGUMENTS=( `format_close_gates_cargo_arguments` )
    echo "
[ INFO ]: About to execute (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function action_gate_status_check() {
    local ARGUMENTS=( `format_check_gates_cargo_arguments` )
    echo; info_msg "About to execute (${MAGENTA}`format_cargo_exec_string ${ARGUMENTS[@]}`${RESET})"
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function action_set_gate_csv(){
    echo; info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} gate ID CSV -"
    info_msg "Type CSV string or (${MAGENTA}.back${RESET})."
    local GATE_CSV=`fetch_string_from_user 'Gates(CSV)'`
    if [ $? -ne 0 ] || [ -z "$GATE_CSV" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_gate_csv_string "$GATE_CSV"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set gate ID CSV string (${RED}$GATE_CSV${RESET})"
    else
        ok_msg "Successfully set gate ID CSV string (${GREEN}$GATE_CSV${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_debug_flag() {
    echo; case "$FG_DEFAULT['debug']" in
        'on'|'On'|'ON')
            info_msg "Debug is (${GREEN}ON${RESET}), switching to (${RED}OFF${RESET}) -"
            action_set_debug_off
            ;;
        'off'|'Off'|'OFF')
            info_msg "Debug is (${RED}OFF${RESET}), switching to (${GREEN}ON${RESET}) -"
            action_set_debug_on
            ;;
        *)
            info_msg "Debug not set, switching to (${GREEN}OFF${RESET}) -"
            action_set_debug_off
            ;;
    esac
    return $?
}

function action_set_silence_flag() {
    echo; case "$FG_DEFAULT['silence']" in
        'on'|'On'|'ON')
            info_msg "Silence is (${GREEN}ON${RESET}), switching to (${RED}OFF${RESET}) -"
            action_set_silence_off
            ;;
        'off'|'Off'|'OFF')
            info_msg "Silence is (${RED}OFF${RESET}), switching to (${GREEN}ON${RESET}) -"
            action_set_silence_on
            ;;
        *)
            info_msg "Silence not set, switching to (${GREEN}OFF${RESET}) -"
            action_set_silence_off
            ;;
    esac
    return $?
}

function action_set_config_file() {
    echo; info_msg "Setting config file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_config_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) config file."
    else
        ok_msg "Successfully set config file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_config_json_file() {
    echo; info_msg "Setting JSON config file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_json_config_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) JSON config file."
    else
        ok_msg "Successfully set JSON config file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_wpa_supplicant_file() {
    echo; info_msg "Setting system wpa_supplicant config file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_system_wpa_supplicant_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) system wpa_supplicant config file."
    else
        ok_msg "Successfully set system wpa_supplicant config file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_bashrc_file() {
    echo; info_msg "Setting user .bashrc file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_user_bashrc_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) user bashrc file."
    else
        ok_msg "Successfully set user bashrc file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_bashrc_template_file() {
    echo; info_msg "Setting user .bashrc template file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_user_bashrc_template_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) user bashrc template file."
    else
        ok_msg "Successfully set user bashrc template file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_bashaliases_file() {
    echo; info_msg "Setting user .bash_aliases file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_user_bash_aliases_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) user bash aliases file."
    else
        ok_msg "Successfully set user bash aliases file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_hostname_file() {
    echo; info_msg "Setting system hostname file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_system_hostname_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) system hostname file."
    else
        ok_msg "Successfully set system hostname file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_hosts_file() {
    echo; info_msg "Setting system hosts file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_system_hosts_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) system hosts file."
    else
        ok_msg "Successfully set system hosts file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_cron_file() {
    echo; info_msg "Setting user cron job file -"
    info_msg "Type absolute file path or (${MAGENTA}.back${RESET})."
    local FILE_PATH=`fetch_file_path_from_user 'FilePath'`
    if [ $? -ne 0 ] || [ -z "$FILE_PATH" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_user_cron_file "$FILE_PATH"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$FILE_PATH${RESET}) as"\
            "(${BLUE}$SCRIPT_NAME${RESET}) user cron job file."
    else
        ok_msg "Successfully set user cron job file (${GREEN}$FILE_PATH${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_wifi_essid() {
    echo; info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} HEAD machine WiFi ESSID -"
    info_msg "Type wireless gateway ESSID or (${MAGENTA}.back${RESET})."
    local WIFI_ESSID=`fetch_string_from_user 'WiFi(ESSID)'`
    if [ $? -ne 0 ] || [ -z "$WIFI_ESSID" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_wifi_essid "$WIFI_ESSID"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set wireless gateway ESSID (${RED}$WIFI_ESSID${RESET})"
    else
        ok_msg "Successfully set wireless gateway ESSID (${GREEN}$WIFI_ESSID${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_wifi_password() {
    echo; info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} HEAD machine WiFi Password -"
    info_msg "Type wireless gateway password or (${MAGENTA}.back${RESET})."
    local WIFI_PSK=`fetch_password_from_user 'WiFi(PSK)'`
    if [ $? -ne 0 ] || [ -z "$WIFI_PSK" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_wifi_password $WIFI_PSK
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set wireless gateway password (${RED}$WIFI_PSK${RESET})"
    else
        ok_msg "Successfully set wireless gateway password (${GREEN}$WIFI_PSK${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_system_user() {
    echo; info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} machine user name -"
    info_msg "Type system user name or (${MAGENTA}.back${RESET})."
    local SYS_USER=`fetch_string_from_user 'User'`
    if [ $? -ne 0 ] || [ -z "$SYS_USER" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_system_user $SYS_USER
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set system user name (${RED}$SYS_USER${RESET})"
    else
        ok_msg "Successfully set system user name (${GREEN}$SYS_USER${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_system_password() {
    echo; info_msg "Setting ${BLUE}$SCRIPT_NAME${RESET} machine user password -"
    info_msg "Type password or (${MAGENTA}.back${RESET})."
    local SYS_PASS=`fetch_password_from_user 'Password'`
    if [ $? -ne 0 ] || [ -z "$SYS_PASS" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_system_password $SYS_PASS
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set system password (${RED}$SYS_PASS${RESET})"
    else
        ok_msg "Successfully set system password (${GREEN}$SYS_PASS${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_system_permissions() {
    echo; info_msg "Setting user file permissions (NNN) -"
    info_msg "Type file permissions using octal notation or (${MAGENTA}.back${RESET})."
    local SYS_PERMS=`fetch_number_from_user 'Permsissions'`
    if [ $? -ne 0 ] || [ -z "$SYS_PERMS" ]; then
        echo; info_msg 'Aborting action.'
        return 0
    fi
    set_user_file_permissions $SYS_PERMS
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set user file permissions (${RED}$SYS_PERMS${RESET})"
    else
        ok_msg "Successfully set user file permissions (${GREEN}$SYS_PERMS${RESET})."
    fi
    return $EXIT_CODE
}

function action_update_config_json_file() {
    local FILE_CONTENT="`format_config_json_file_content`"
    debug_msg "Formatted JSON config file content: ${FILE_CONTENT}"
    if [ $? -ne 0 ] || [ -z "$FILE_CONTENT" ]; then
        echo; nok_msg 'Something went wrong -'\
            'Could not format JSON config file content!'
        return 0
    fi
    clear_file "${GK_DEFAULT['conf-json-file']}"
    write_to_file "${GK_DEFAULT['conf-json-file']}" "$FILE_CONTENT"
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong -"\
            "Could not update JSON config file"\
            "(${RED}${GK_DEFAULT['conf-json-file']}${RESET})"
    else
        echo "$FILE_CONTENT
        "
        ok_msg "Successfully updated JSON config file"\
            "(${GREEN}${GK_DEFAULT['conf-json-file']}${RESET})."
    fi
    return $EXIT_CODE
}

function action_close_gates() {
    check_flag_is_on "${MD_DEFAULT['action-prompt']}"
    local ACTION_PROMP=$?
    echo; info_msg "Closing the following gates: (${MD_DEFAULT['gates-csv']})"
    if [[ "$ACTION_PROMPT" == '0' ]]; then
        echo; while :; do
            fetch_ultimatum_from_user "Change gate IDs? ${YELLOW}Y/N${RESET}"
            if [ $? -eq 0 ]; then
                action_set_gate_csv
                if [ $? -ne 0 ]; then
                    warning_msg "Could not set new Gate IDs! Aborting action."
                    return 1
                fi
            fi
            break
        done
    fi
    local ARGUMENTS=( `format_close_gates_cargo_arguments` )
    local EXEC_STR="~$ ./`basename ${GK_CARGO['gate-keeper']}` ${ARGUMENTS[@]}"
    info_msg "About to execute (${MAGENTA}${EXEC_STR}${RESET})"
    if [[ "$ACTION_PROMPT" == '0' ]]; then
        fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            info_msg "Aborting action."
            return 0
        fi
    fi
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function action_open_gates() {
    check_flag_is_on "${MD_DEFAULT['action-prompt']}"
    local ACTION_PROMP=$?
    echo; info_msg "Opening the following gates: (${MD_DEFAULT['gates-csv']})"
    if [[ "$ACTION_PROMPT" == '0' ]]; then
        echo; while :; do
            fetch_ultimatum_from_user "Change gate IDs? ${YELLOW}Y/N${RESET}"
            if [ $? -eq 0 ]; then
                action_set_gate_csv
                if [ $? -ne 0 ]; then
                    warning_msg "Could not set new Gate IDs! Aborting action."
                    return 1
                fi
            fi
            break
        done
    fi
    local ARGUMENTS=( `format_open_gates_cargo_arguments` )
    local EXEC_STR="~$ ./`basename ${GK_CARGO['gate-keeper']}` ${ARGUMENTS[@]}"
    info_msg "About to execute (${MAGENTA}${EXEC_STR}${RESET})"
    if [[ "$ACTION_PROMPT" == '0' ]]; then
        fetch_ultimatum_from_user "Are you sure about this? ${YELLOW}Y/N${RESET}"
        if [ $? -ne 0 ]; then
            info_msg "Aborting action."
            return 0
        fi
    fi
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function action_set_silence_off() {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_silence_flag 'off'
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) debug"\
            "to (${RED}OFF${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) debug"\
            "to (${RED}OFF${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_silence_on() {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_silence_flag 'on'
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) debug"\
            "to (${GREEN}ON${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) debug"\
            "to (${GREEN}ON${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_debug_off() {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_debug_flag 'off'
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) debug"\
            "to (${RED}OFF${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) debug"\
            "to (${RED}OFF${RESET})."
    fi
    return $EXIT_CODE
}

function action_set_debug_on() {
    echo; fetch_ultimatum_from_user \
        "${YELLOW}Are you sure about this? Y/N${RESET}"
    if [ $? -ne 0 ]; then
        echo; info_msg "Aborting action."
        return 1
    fi
    set_debug_flag 'on'
    local EXIT_CODE=$?
    echo; if [ $EXIT_CODE -ne 0 ]; then
        nok_msg "Something went wrong."\
            "Could not set (${RED}$SCRIPT_NAME${RESET}) debug"\
            "to (${GREEN}ON${RESET})."
    else
        ok_msg "Succesfully set (${BLUE}$SCRIPT_NAME${RESET}) debug"\
            "to (${GREEN}ON${RESET})."
    fi
    return $EXIT_CODE
}

function cli_action_setup() {
    local ARGUMENTS=( `format_setup_machine_cargo_arguments` )
    action_floodgate_cargo ${ARGUMENTS[@]}
    return $?
}

function cli_update_config_json_file() {
    local FILE_CONTENT="`format_config_json_file_content`"
    if [ $? -ne 0 ] || [ -z "$FILE_CONTENT" ]; then
        return 1
    fi
    echo "${FILE_CONTENT}" > ${MD_DEFAULT['conf-json-file']}
    return $?
}


