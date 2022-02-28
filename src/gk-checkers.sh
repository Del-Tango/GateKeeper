#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# CHECKERS

function check_pid_running() {
    local PID_NO=$1
    ps -p ${PID_NO} &> /dev/null
    return $?
}

function check_command_watchdog_running() {
    if [ ! -f "${MD_DEFAULT['pid-cmd-wdg']}" ]; then
        return 1
    fi
    local WATCHDOG_PID=`cat ${MD_DEFAULT['pid-cmd-wdg']}`
    check_pid_running ${WATCHDOG_PID}
    if [ $? -ne 0 ]; then
        echo > "${MD_DEFAULT['pid-cmd-wdg']}"
        return 2
    fi
    return $?
}


