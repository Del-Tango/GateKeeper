#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# DISPLAY

function display_usage () {
    clear; display_header; local FILE_NAME="./`basename $0`"
    cat<<EOF

    [ DESCRIPTION ]: ${GK_SCRIPT_NAME} Interface.
    [ USAGE       ]: $FILE_NAME

    -h  | --help                   Display this message.

    -S  | --setup                  Setup machine.

    -O  | --open-gates             Open gates specified in config file.

    -C  | --close-gates            Close gates specified in config file.

    -s  | --gate-status            Check if gates are opened or closed.

    -W  | --start-watchdog         Starts the watchdog daemon process that
        |                          monitors signals comming through the GPIO
        |                          command pins.


    [ EXAMPLE     ]:

        $~ $FILE_NAME --setup --open-gates --gate-status

        $~ $FILE_NAME --close-gates

EOF
    return $?
}

function display_header () {
    cat <<EOF
    ___________________________________________________________________________

     *             *             *   ${BLUE}${GK_SCRIPT_NAME}${RESET}   *             *            *
    ___________________________________________________________________________
                    Regards, the Alveare Solutions #!/Society -x
EOF
    return $?
}

function display_server_ctrl_settings () {
    local ARGUMENTS=( `format_display_server_ctrl_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_manual_ctrl_settings () {
    local ARGUMENTS=( `format_display_manual_ctrl_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_main_settings () {
    local ARGUMENTS=( `format_display_main_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} && echo
    return $?
}

function display_project_settings () {
    local ARGUMENTS=( `format_display_project_settings_args` )
    debug_msg "Displaying settings: (${MAGENTA}${ARGUMENTS[@]}${RESET})"
    display_fg_settings ${ARGUMENTS[@]} | column && echo
    return $?
}

function display_banners () {
    if [ -z "${MD_DEFAULT['banner']}" ]; then
        return 1
    fi
    case "${MD_DEFAULT['banner']}" in
        *','*)
            for cargo_key in `echo ${MD_DEFAULT['banner']} | sed 's/,/ /g'`; do
                ${MD_CARGO[$cargo_key]} "${MD_DEFAULT['conf-file']}"
            done
            ;;
        *)
            ${MD_CARGO[${MD_DEFAULT['banner']}]} "${MD_DEFAULT['conf-file']}"
            ;;
    esac
    return $?
}

function display_gate_status() {
    local CONTENT="`cat ${MD_DEFAULT['gate-index']} | xargs`"
    debug_msg "Gate index content: (${CONTENT})"
    if [ ! -f "${MD_DEFAULT['gate-index']}" ] || [[ -z "${CONTENT}" ]]; then
        local VALUE="${RED}Unknown${RESET}"
    else
        # WARNING:
        if [[ "$CONTENT" == "0" ]]; then
            local VALUE="${RED}Closed${RESET}"
        elif [[ "$CONTENT" == "1" ]]; then
            local VALUE="${GREEN}Open${RESET}"
        fi
    fi
    debug_msg  "Gate Status: (${VALUE})"
    echo "[ ${CYAN}Gate Status${RESET}              ]: ${VALUE}"
    return $?
}

function display_setting_project_path () {
    echo "[ ${CYAN}Project Path${RESET}             ]: ${BLUE}${MD_DEFAULT['project-path']}${RESET}"
    return $?
}

function display_setting_log_dir_path () {
    echo "[ ${CYAN}Log Dir${RESET}                  ]: ${BLUE}${MD_DEFAULT['log-dir']}${RESET}"
    return $?
}

function display_setting_conf_dir_path () {
    echo "[ ${CYAN}Conf Dir${RESET}                 ]: ${BLUE}${MD_DEFAULT['conf-dir']}${RESET}"
    return $?
}

function display_setting_cron_dir_path () {
    echo "[ ${CYAN}Cron Dir${RESET}                 ]: ${BLUE}${MD_DEFAULT['cron-dir']}${RESET}"
    return $?
}

function display_setting_log_file_path () {
    echo "[ ${CYAN}Log File${RESET}                 ]: ${BLUE}`dirname ${MD_DEFAULT['log-file']}`/${YELLOW}`basename ${GK_DEFAULT['log-file']}`${RESET}"
    return $?
}

function display_setting_conf_file_path () {
    echo "[ ${CYAN}Conf File${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['conf-file']}`/${YELLOW}`basename ${GK_DEFAULT['conf-file']}`${RESET}"
    return $?
}

function display_setting_conf_json_file_path () {
    echo "[ ${CYAN}Conf JSON${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['conf-json-file']}`/${YELLOW}`basename ${GK_DEFAULT['conf-json-file']}`${RESET}"
    return $?
}

function display_setting_log_lines () {
    echo "[ ${CYAN}Log Lines${RESET}                ]: ${WHITE}${MD_DEFAULT['log-lines']}${RESET}"
    return $?
}

function display_setting_system_user () {
    echo "[ ${CYAN}System User${RESET}              ]: ${YELLOW}${MD_DEFAULT['system-user']}${RESET}"
    return $?
}

function display_setting_system_pass () {
    if [ -z "${MD_DEFAULT['system-pass']}" ]; then
        local VALUE="${RED}Not Set${RESET}"
    else
        local VALUE="${GREEN}Locked'n Loaded${RESET}"
    fi
    echo "[ ${CYAN}User PSK${RESET}                 ]: $VALUE"
    return $?
}

function display_setting_system_perms () {
    echo "[ ${CYAN}File Perms${RESET}               ]: ${WHITE}${MD_DEFAULT['system-perms']}${RESET}"
    return $?
}

function display_setting_hostname_file () {
    echo "[ ${CYAN}Hostname File${RESET}            ]: ${BLUE}`dirname ${MD_DEFAULT['hostname-file']}`/${YELLOW}`basename ${GK_DEFAULT['hostname-file']}`${RESET}"
    return $?
}

function display_setting_hosts_file () {
    echo "[ ${CYAN}Hosts File${RESET}               ]: ${BLUE}`dirname ${MD_DEFAULT['hosts-file']}`/${YELLOW}`basename ${GK_DEFAULT['hosts-file']}`${RESET}"
    return $?
}

function display_setting_wpa_file () {
    echo "[ ${CYAN}WPA Supplicant Conf${RESET}      ]: ${BLUE}`dirname ${MD_DEFAULT['wpa-file']}`/${YELLOW}`basename ${GK_DEFAULT['wpa-file']}`${RESET}"
    return $?
}

function display_setting_cron_file () {
    echo "[ ${CYAN}Cron File${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['cron-file']}`/${YELLOW}`basename ${GK_DEFAULT['cron-file']}`${RESET}"
    return $?
}

function display_setting_bashrc_file () {
    echo "[ ${CYAN}BashRC File${RESET}              ]: ${BLUE}`dirname ${MD_DEFAULT['bashrc-file']}`/${YELLOW}`basename ${GK_DEFAULT['bashrc-file']}`${RESET}"
    return $?
}

function display_setting_bashaliases_file () {
    echo "[ ${CYAN}BashAliases File${RESET}         ]: ${BLUE}`dirname ${MD_DEFAULT['bashaliases-file']}`/${YELLOW}`basename ${GK_DEFAULT['bashaliases-file']}`${RESET}"
    return $?
}

function display_setting_bashrc_template () {
    echo "[ ${CYAN}BashRC Template${RESET}          ]: ${BLUE}`dirname ${MD_DEFAULT['bashrc-template']}`/${YELLOW}`basename ${GK_DEFAULT['bashrc-template']}`${RESET}"
    return $?
}

function display_setting_debug_flag () {
    echo "[ ${CYAN}Debug${RESET}                    ]: `format_flag_colors ${MD_DEFAULT['debug']}`"
    return $?
}

function display_setting_silence_flag () {
    echo "[ ${CYAN}Silence${RESET}                  ]: `format_flag_colors ${MD_DEFAULT['silence']}`"
    return $?
}

function display_setting_machine_id () {
    echo "[ ${CYAN}Machine ID${RESET}               ]: ${BLUE}${MD_DEFAULT['machine-id']}${RESET}"
    return $?
}

function display_setting_wifi_essid () {
    echo "[ ${CYAN}WiFi ESSID${RESET}               ]: ${MAGENTA}${MD_DEFAULT['wifi-essid']}${RESET}"
    return $?
}

function display_setting_wifi_pass () {
    if [ -z "${GK_DEFAULT['wifi-pass']}" ]; then
        local VALUE="${RED}Not Set${RESET}"
    else
        local VALUE="${GREEN}Locked'n Loaded${RESET}"
    fi
    echo "[ ${CYAN}WiFi PSK${RESET}                 ]: $VALUE"
    return $?
}

function display_setting_gates_csv () {
    echo "[ ${CYAN}Gate CSV IDs${RESET}             ]: ${MD_DEFAULT['gates-csv']}"
    return $?
}

function display_wpa_supplicant_dir() {
    echo "[ ${CYAN}WPA Supplicant Dir${RESET}       ]: ${BLUE}`dirname ${MD_DEFAULT['wpa-file']}`${RESET}"
    return $?
}

function display_hosts_dir() {
    echo "[ ${CYAN}Hosts Dir${RESET}                ]: ${BLUE}`dirname ${MD_DEFAULT['hosts-file']}`${RESET}"
    return $?
}

function display_hostname_dir() {
    echo "[ ${CYAN}Hostname Dir${RESET}             ]: ${BLUE}`dirname ${MD_DEFAULT['hostname-file']}`${RESET}"
    return $?
}

function display_data_dir() {
    echo "[ ${CYAN}Data Dir${RESET}                 ]: ${BLUE}${MD_DEFAULT['dta-dir']}${RESET}"
    return $?
}

function display_local_ipv4_address () {
    local LOCAL_IPV4=`fetch_local_ipv4_address`
    local TRIMMED_STDOUT=`echo -n ${LOCAL_IPV4} | sed 's/\[ WARNING \]: //g'`
    if [[ "${TRIMMED_STDOUT}" =~ "No LAN access!" ]]; then
        local DISPLAY_VALUE="${RED}Unknown${RESET}"
    else
        local DISPLAY_VALUE="${MAGENTA}$LOCAL_IPV4${RESET}"
    fi
    echo "[ ${CYAN}Local IPv4${RESET}               ]: ${DISPLAY_VALUE}"
    return $?
}

function display_external_ipv4_address () {
    local EXTERNAL_IPV4="`fetch_external_ipv4_address`"
    local EXIT_CODE=$?
    local TRIMMED_STDOUT=`echo -n ${EXTERNAL_IPV4} | sed 's/\[ WARNING \]: //g'`
    if [ $EXIT_CODE -ne 0 ] || [[ "${TRIMMED_STDOUT}" =~ "No internet access!" ]]; then
        local DISPLAY_VALUE="${RED}Unknown${RESET}"
    else
        local DISPLAY_VALUE="${MAGENTA}$EXTERNAL_IPV4${RESET}"
    fi
    echo "[ ${CYAN}External IPv4${RESET}            ]: ${DISPLAY_VALUE}"
    return $?
}

function display_fg_settings () {
    local SETTING_LABELS=( $@ )
    for setting in ${SETTING_LABELS[@]}; do
        case "$setting" in
            'project-path')
                display_setting_project_path; continue
                ;;
            'log-dir')
                display_setting_log_dir_path; continue
                ;;
            'conf-dir')
                display_setting_conf_dir_path; continue
                ;;
            'cron-dir')
                display_setting_cron_dir_path; continue
                ;;
            'log-file')
                display_setting_log_file_path; continue
                ;;
            'conf-file')
                display_setting_conf_file_path; continue
                ;;
            'conf-json-file')
                display_setting_conf_json_file_path; continue
                ;;
            'log-lines')
                display_setting_log_lines; continue
                ;;
            'system-user')
                display_setting_system_user; continue
                ;;
            'system-pass')
                display_setting_system_pass; continue
                ;;
            'system-perms')
                display_setting_system_perms; continue
                ;;
            'hostname-file')
                display_setting_hostname_file; continue
                ;;
            'hosts-file')
                display_setting_hosts_file; continue
                ;;
            'wpa-file')
                display_setting_wpa_file; continue
                ;;
            'cron-file')
                display_setting_cron_file; continue
                ;;
            'bashrc-file')
                display_setting_bashrc_file; continue
                ;;
            'bashaliases-file')
                display_setting_bashaliases_file; continue
                ;;
            'bashrc-template')
                display_setting_bashrc_template; continue
                ;;
            'debug')
                display_setting_debug_flag; continue
                ;;
            'silence')
                display_setting_silence_flag; continue
                ;;
            'machine-id')
                display_setting_machine_id; continue
                ;;
            'local-ip')
                display_local_ipv4_address; continue
                ;;
            'external-ip')
                display_external_ipv4_address; continue
                ;;
            'wifi-essid')
                display_setting_wifi_essid; continue
                ;;
            'wifi-pass')
                display_setting_wifi_pass; continue
                ;;
            'gates-csv')
                display_setting_gates_csv; continue
                ;;
            'wpa-dir')
                display_wpa_supplicant_dir; continue
                ;;
            'hosts-dir')
                display_hosts_dir; continue
                ;;
            'hostname-dir')
                display_hostname_dir; continue
                ;;
            'servo-dir')
                display_servo_dir; continue
                ;;
            'data-dir')
                display_data_dir; continue
                ;;
            'gate-status')
                display_gate_status; continue
                ;;
        esac
    done
    return 0
}

