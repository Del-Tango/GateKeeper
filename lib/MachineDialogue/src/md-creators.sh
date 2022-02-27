#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# CREATORS

function create_system_group() {
    local GROUP_NAME="$1"
    symbol_msg "${GREEN}+${RESET}" "Creating system group"\
        "${YELLOW}$GROUP_NAME${RESET}..."
    addgroup --force-badname $GROUP_NAME
    return $?
}

function create_system_user() {
    local USER_NAME="$1"
    symbol_msg "${GREEN}+${RESET}" "Creating system user"\
        "${YELLOW}$USER_NAME${RESET}..."
    adduser --force-badname $USER_NAME
    return $?
}

function create_directory() {
    local DIRECTORY_PATH="$1"
    symbol_msg "${GREEN}+${RESET}" "Creating directory"\
        "${YELLOW}$DIRECTORY_PATH${RESET}..."
    mkdir $DIRECTORY_PATH
    return $?
}

function create_symbolic_link() {
    local SRC_DIR_PATH="$1"
    local DST_DIR_PATH="$2"
    symbol_msg "${GREEN}+${RESET}" "Creating symbolic link between"\
        "${YELLOW}$SRC_DIR_PATH${RESET} and ${YELLOW}$DST_DIR_PATH${RESET}..."
    ln -s $SRC_DIR_PATH $DST_DIR_PATH
    return $?
}

function create_data_checksum () {
    local DATA="$@"
    echo "$DATA" | ${MD_CHECKSUM_ALGORITHMS[${MD_DEFAULT['checksum']}]}
    return $?
}

function create_file_checksum () {
    local FILE_PATH="$1"
    ${MD_CHECKSUM_ALGORITHMS[${MD_DEFAULT['checksum']}]} "$FILE_PATH" \
        | awk '{print $1}'
    return $?
}

function create_directory_checksum () {
    local DIR_PATH="$1"
    tar -cf - "$DIR_PATH" &> /dev/null | \
        ${MD_CHECKSUM_ALGORITHMS[${MD_DEFAULT['checksum']}]} | \
        awk '{print $1}'
    return $?
}

function create_partition_on_block_device () {
    local BLOCK_DEVICE="$1"
    check_valid_block_device "$BLOCK_DEVICE"
    if [ $? -ne 0 ]; then
        echo; error_msg "Invalid block device ${RED}$BLOCK_DEVICE${RESET}."
        return 1
    fi
    fdisk "$BLOCK_DEVICE"
    EXIT_CODE=$?
    info_msg "Informing the OS of partition table changes..."
    partprobe; return $EXIT_CODE
}

function create_file () {
    local FILE_PATH="$1"
    symbol_msg "${GREEN}+${RESET}" "Creating file"\
        "${YELLOW}$FILE_PATH${RESET}..."
    touch $FILE_PATH
    return $?
}

function create_directory() {
    local DIRECTORY_PATH="$1"
    symbol_msg "${GREEN}+${RESET}" "Creating directory"\
        "${YELLOW}$DIRECTORY_PATH${RESET}..."
    mkdir $DIRECTORY_PATH
    return $?
}

function create_menu_controller () {
    local LABEL="$1"
    local DESCRIPTION="$2"
    local OPTIONS="$3"
    info_msg "Creating menu controller ${YELLOW}$LABEL${RESET}..."
    add_menu_controller "$LABEL" "$DESCRIPTION"
    info_msg "Setting ${CYAN}$LABEL${RESET} options..."
    set_menu_controller_options "$LABEL" "$OPTIONS"
    return 0
}
