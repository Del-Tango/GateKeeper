#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# FORMATTERS

function format_cargo_exec_string() {
    local ARGUMENTS=( ${@} )
    if [ ${#ARGUMENTS[@]} -eq 0 ]; then
        return 1
    fi
    local EXEC_STR="~$ ./`basename ${GK_CARGO['gate-keeper']}` ${ARGUMENTS[@]}"
    echo "${EXEC_STR}"
    return $?
}

function format_start_watchdog_cargo_arguments() {
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args`
        "--action start-watchdog"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_open_gates_cargo_arguments() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args "${GATES_CSV}"`
        "--action open-gates"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_close_gates_cargo_arguments() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args "${GATES_CSV}"`
        "--action close-gates"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_floodgate_cargo_constant_args() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        "--log-file ${MD_DEFAULT['log-file']}"
        "--config-file ${MD_DEFAULT['conf-json-file']}"
    )
    if [[ ${MD_DEFAULT['silence']} == 'on' ]]; then
        local ARGUMENTS=( ${ARGUMENTS[@]} '--silence' )
    fi
    if [[ ${MD_DEFAULT['debug']} == 'on' ]]; then
        local ARGUMENTS=( ${ARGUMENTS[@]} '--debug' )
    fi
    if [ -z "$GATES_CSV" ]; then
        local ARGUMENTS=( ${ARGUMENTS[@]} "--gate ${MD_DEFAULT['gates-csv']}" )
    else
        local ARGUMENTS=( ${ARGUMENTS[@]} "--gate $GATES_CSV" )
    fi
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_setup_machine_cargo_arguments() {
    local ARGUMENTS=( `format_floodgate_cargo_constant_args` '--action setup' )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_check_gates_cargo_arguments() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args`
        "--action check-gates"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_close_gates_cargo_arguments() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args "${GATES_CSV}"`
        "--action close-gates"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_open_gates_cargo_arguments() {
    local GATES_CSV="$1"
    local ARGUMENTS=(
        `format_floodgate_cargo_constant_args "${GATES_CSV}"`
        "--action open-gates"
    )
    echo -n "${ARGUMENTS[@]}"
    return $?
}

function format_config_json_flag() {
    local FLAG_VALUE="$1"
    case "$FLAG_VALUE" in
        'on'|'On'|'ON')
            echo 'true'
            ;;
        'off'|'Off'|'OFF')
            echo 'false'
            ;;
        *)
            echo $FLAG_VALUE
            return 1
            ;;
    esac
    return 0
}

function format_config_json_file_content() {
    cat<<EOF
{
    "GK_SCRIPT_NAME":        "${GK_SCRIPT_NAME}",
    "GK_VERSION":            "${GK_VERSION}",
    "GK_VERSION_NO":         "${GK_VERSION_NO}",
    "GK_DIRECTORY":          "$GK_DIRECTORY",
    "GK_DEFAULT": {
         "project-path":     "${MD_DEFAULT['project-path']}",
         "home-dir":         "${MD_DEFAULT['home-dir']}",
         "log-dir":          "${MD_DEFAULT['log-dir']}",
         "conf-dir":         "${MD_DEFAULT['conf-dir']}",
         "lib-dir":          "${MD_DEFAULT['lib-dir']}",
         "src-dir":          "${MD_DEFAULT['src-dir']}",
         "dox-dir":          "${MD_DEFAULT['dox-dir']}",
         "dta-dir":          "${MD_DEFAULT['dta-dir']}",
         "tmp-dir":          "${MD_DEFAULT['tmp-dir']}",
         "cron-dir":         "${MD_DEFAULT['cron-dir']}",
         "log-file":         "`basename ${MD_DEFAULT['log-file']}`",
         "conf-file":        "`basename ${MD_DEFAULT['conf-json-file']}`",
         "hostname-file":    "${MD_DEFAULT['hostname-file']}",
         "hosts-file":       "${MD_DEFAULT['hosts-file']}",
         "wpa-file":         "${MD_DEFAULT['wpa-file']}",
         "cron-file":        "${MD_DEFAULT['cron-file']}",
         "boot-file":        "${MD_DEFAULT['boot-file']}",
         "log-format":       "${MD_DEFAULT['log-format']}",
         "timestamp-format": "${MD_DEFAULT['timestamp-format']}",
         "debug":            `format_config_json_flag ${MD_DEFAULT['debug']}`,
         "silence":          `format_config_json_flag ${MD_DEFAULT['silence']}`,
         "machine-id":       "${MD_DEFAULT['machine-id']}",
         "machine-ip":       "${MD_DEFAULT['machine-ip']}",
         "system-user":      "${MD_DEFAULT['system-user']}",
         "system-pass":      "${MD_DEFAULT['system-pass']}",
         "system-perms":      ${MD_DEFAULT['system-perms']},
         "service-pass":     "${MD_DEFAULT['service-pass']}",
         "wifi-essid":       "${MD_DEFAULT['wifi-essid']}",
         "wifi-pass":        "${MD_DEFAULT['wifi-pass']}",
         "bashrc-file":      "${MD_DEFAULT['bashrc-file']}",
         "bashrc-template":  "${MD_DEFAULT['bashrc-template']}",
         "bashaliases-file": "${MD_DEFAULT['bashaliases-file']}",
         "gate-index":       "${MD_DEFAULT['gate-index']}"
    },
    "GK_CARGO": {
        "gate-keeper":       "${MD_CARGO['gate-keeper']}"
    }
}
EOF
    return $?
}

function format_display_manual_ctrl_settings_args () {
    format_display_main_settings_args
    return $?
}

function format_display_main_settings_args () {
    local ARGUMENTS=( 'machine-id' 'local-ip' 'external-ip' 'gate-status' )
    echo ${ARGUMENTS[@]}
    return $?
}

function format_display_project_settings_args () {
    local ARGUMENTS=(
        'machine-id'
        'local-ip'
        'external-ip'
        'wifi-essid'
        'wifi-pass'
        'system-user'
        'system-pass'
        'system-perms'
        'gates-csv'
        'log-lines'
        'debug'
        'silence'
        'project-path'
        'log-file'
        'conf-file'
        'conf-json-file'
        'hostname-file'
        'hosts-file'
        'wpa-file'
        'cron-file'
        'bashrc-file'
        'bashaliases-file'
        'bashrc-template'
    )
    echo ${ARGUMENTS[@]}
    return $?
}
