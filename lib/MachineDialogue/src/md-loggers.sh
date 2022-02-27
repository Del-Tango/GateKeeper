#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# LOGGERS

function log_message () {
    local LOG_LEVEL="$1"
    local OPTIONAL="$2"
    local MSG="${@:3}"
    check_logging_on
    if [ $? -ne 0 ]; then
        return 1
    fi
    check_loglevel_set "$LOG_LEVEL"
    if [ $? -ne 0 ]; then
        return 2
    fi
    case "$LOG_LEVEL" in
        'SYMBOL')
            echo "${MAGENTA}`date`${RESET} - [ $OPTIONAL ]: $MSG" >> ${MD_DEFAULT['log-file']}
            ;;
        *)
            echo "${MAGENTA}`date`${RESET} - [ $LOG_LEVEL ]: $MSG" >> ${MD_DEFAULT['log-file']}
            ;;
    esac
    return $?
}

