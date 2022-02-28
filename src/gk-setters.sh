#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# SETTERS

function set_gate_csv_string() {
    local GATE_IDS_CSV="$@"
    MD_DEFAULT['gates-csv']="$GATE_IDS_CSV"
    return 0
}

function set_wifi_password() {
    local WIFI_PASS="$1"
    MD_DEFAULT['wifi-pass']="$WIFI_PASS"
    return 0
}

function set_wifi_essid() {
    local WIFI_ESSID="$1"
    MD_DEFAULT['wifi-essid']="$WIFI_ESSID"
    return 0
}

function set_system_user() {
    local USER_NAME="$1"
    MD_DEFAULT['system-user']="$USER_NAME"
    return 0
}

function set_system_password() {
    local SYS_PASS="$1"
    MD_DEFAULT['system-pass']="$SYS_PASS"
    return 0
}

function set_machine_id() {
    local MACHINE_ID="$1"
    MD_DEFAULT['machine-id']="$MACHINE_ID"
    return 0
}

function set_user_file_permissions() {
    local OCTAL_PERMS=$1
    MD_DEFAULT['system-perms']=$OCTAL_PERMS
    return 0
}

function set_debug_flag() {
    local FLAG="$1"
    MD_DEFAULT['debug']="$FLAG"
    return 0
}

function set_silence_flag() {
    local FLAG="$1"
    MD_DEFAULT['silence']="$FLAG"
    return 0
}

function set_user_cron_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['cron-file']="$FILE_PATH"
    return 0
}

function set_system_hosts_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['hosts-file']="$FILE_PATH"
    return 0
}

function set_system_hostname_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['hostname-file']="$FILE_PATH"
    return 0
}

function set_user_bash_aliases_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['bashaliases-files']="$FILE_PATH"
    return 0
}

function set_user_bashrc_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['bashrc-file']="$FILE_PATH"
    return 0
}

function set_user_bashrc_template_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['bashrc-template']="$FILE_PATH"
    return 0
}

function set_system_wpa_supplicant_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['wpa-file']="$FILE_PATH"
    return 0
}

function set_json_config_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['conf-json-file']="$FILE_PATH"
    return 0
}

function set_config_file() {
    local FILE_PATH="$1"
    MD_DEFAULT['conf-file']="$FILE_PATH"
    return 0
}

# CODE DUMP

