#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# CONVERTORS

function convert_array_to_delimited_string () {
    local DELIMITER="$1"
    local ARRAY=( "${@:2}" )
    echo "${ARRAY[@]}" | sed "s/ /${DEFAULT['delimiter']}/g"
    return $?
}
