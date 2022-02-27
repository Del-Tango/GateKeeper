#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# COLD BANNER

CONF_FILE_PATH="$1"
SCRIPT_NAME="FloodGate"
TMP_FILE="/tmp/.fg-head-${RANDOM}.tmp"
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`
RESET=`tput sgr0`

function display_cold_banner () {
    figlet -f lean -w 1000 "$SCRIPT_NAME" > "$TMP_FILE"
    clear; echo -n "${BLUE}`cat $TMP_FILE`${RESET}
" && rm $TMP_FILE &> /dev/null
    return 0
}

display_cold_banner
