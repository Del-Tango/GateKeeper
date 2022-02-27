#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# ACTIONS

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

function action_floodgate_cargo() {
    local ARGUMENTS=( $@ )
    trap 'trap - SIGINT; echo ''[ SIGINT ]: Aborting action.''; return 0' SIGINT
    echo; ${GK_CARGO['gate-keeper']} ${ARGUMENTS[@]}; trap - SIGINT
    return $?
}

