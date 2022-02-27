#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# GENERAL

function process_cli_args() {
    local ARGUMENTS=( $@ )
    local FAILURE_COUNT=0
    if [ ${#ARGUMENTS[@]} -eq 0 ]; then
        return 1
    fi
    for opt in "${ARGUMENTS[@]}"; do
        case "$opt" in
            -h|--help)
                display_usage
                exit 0
                ;;
            -S|--setup)
                cli_action_setup
                if [ $? -ne 0 ]; then
                    local FAILURE_COUNT=$((FAILURE_COUNT + 1))
                fi
                ;;
            -O|--open-gates)
                cli_action_open_gates 'all'
                if [ $? -ne 0 ]; then
                    local FAILURE_COUNT=$((FAILURE_COUNT + 1))
                fi
                ;;
            -C|--close-gates)
                cli_action_close_gates 'all'
                if [ $? -ne 0 ]; then
                    local FAILURE_COUNT=$((FAILURE_COUNT + 1))
                fi
                ;;
            *)
                echo "[ WARNING ]: Invalid CLI arg! (${opt})"
                ;;
        esac
    done
    return 0
}

function start_ssh_service() {
    check_ssh_service_running
    if [ $? -eq 0 ]; then
        ok_msg "SSH Service already running."
        return 0
    fi
    service ssh start
    return $?
}

function stop_ssh_service() {
    check_ssh_service_running
    if [ $? -ne 0 ]; then
        ok_msg "SSH Service not running."
        return 0
    fi
    service ssh stop
    return $?
}

