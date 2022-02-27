#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# Broken-_-Record

SCRIPT_NAME='Broken-_-Record'
VERSION='1.0Spam'
OUT_FILE="$1"
ANCHOR_FILE="$2"
INTERVAL_OF_SECONDS=$3
MESSAGE="${@:4}"


function display_header() {
     cat <<EOF
    ___________________________________________________________________________

     *                      *      ${SCRIPT_NAME}      *                    *
    _____________________________________________________v.${VERSION}_____________
                        Regards, the Alveare Solutions society.
EOF
    return $?
}

function display_usage() {
    display_header
    cat <<EOF

  [ DESCRIPTION ]: Utilitarian script to be used as a paralel process with the
      application using it in order to continuously write to a file or STDOUT a
      message at a given interval of seconds until the anchor file is removed
      from the filesystem.

  [ USECASE     ]: In cases of long waiting times this will provide feedback to
      the user that the application is not in a hanging state.


  [ NOTE        ]: If the specified out file (first arg) is '-' the message will
      be written to STDOUT (a.k.a. your terminal).


  [ EXAMPLE     ]: Writing dots every minute -

    [ EX1 ]: To a log file:
        $ ./`basename $0` /out/file.txt /anchor/file.txt 60 '.'

    [ EX2 ]: To STDOUT (your terminal):
        $ ./`basename $0` - /anchor/file.txt 60 '.'

  [ USAGE       ]: Positional args only - quite a primitive thing going on... -
        $ ./`basename $0` <out-file> <anchor-file> <interval-sec> <message>

EOF
    return $?
}

function check_preconditions() {
    local FAILURE_COUNT=0
    if [[ "$OUT_FILE" != '-' ]] && [ ! -f "${OUT_FILE}" ]; then
        touch ${OUT_FILE} &> /dev/null
        if [ $? -ne 0 ]; then
            local FAILURE_COUNT=$((FAILURE_COUNT + 1))
            echo "[ ERROR ]: Could not open output file! (${OUT_FILE})"
        fi
    fi
    if [ ! -f "${ANCHOR_FILE}" ]; then
        touch "${ANCHOR_FILE}" &> /dev/null
        if [ $? -ne 0 ]; then
            local FAILURE_COUNT=$((FAILURE_COUNT + 1))
            echo "[ ERROR ]: Could not find/create anchor file! (${ANCHOR_FILE})"
        fi
    fi
    if [ ${INTERVAL_OF_SECONDS} -ne ${INTERVAL_OF_SECONDS} ]; then
        echo "[ WARNING ]: Invalid interval of seconds given! (${INTERVAL_OF_SECONDS})"
        return 3
    fi
    if [ -z "${MESSAGE}" ]; then
        local FAILURE_COUNT=$((FAILURE_COUNT + 1))
        echo "[ WARNING ]: No message given!"
    fi

    return $FAILURE_COUNT
}

function start_broken-_-record() {
    while :; do
        if [ ! -f "${ANCHOR_FILE}" ]; then
            break
        fi
        if [[ "$OUT_FILE" == '-' ]]; then
            echo -n ${MESSAGE}
        else
            echo -n ${MESSAGE} >> ${OUT_FILE}
        fi
        sleep ${INTERVAL_OF_SECONDS}
    done
    return 0
}

function init_broken-_-record() {
    check_preconditions
    if [ $? -ne 0 ]; then
        display_usage $@
        return 1
    fi
    start_broken-_-record
    return $?
}

if [[ "$1" == '-h' ]] || [[ "$1" == '--help' ]]; then
    display_usage $@
    exit 0
fi

init_broken-_-record $@
exit $?
