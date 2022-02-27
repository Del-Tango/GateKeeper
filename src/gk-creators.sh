#!/bin/bash
#
# Regards, the Alveare Solutions #!/Society -x
#
# CREATORS

function create_project_menu_controllers () {
    create_main_menu_controller
    create_manual_ctrl_menu_controller
    create_log_viewer_menu_cotroller
    create_settings_menu_controller
    done_msg "${BLUE}$SCRIPT_NAME${RESET} controller construction complete."
    return 0
}

function create_manual_ctrl_menu_controller () {
    create_menu_controller "$MANUALCTL_CONTROLLER_LABEL" \
        "${CYAN}$MANUALCTL_CONTROLLER_DESCRIPTION${RESET}" \
        "$MANUALCTL_CONTROLLER_OPTIONS"
    info_msg "Setting ${CYAN}$MANUALCTL_CONTROLLER_LABEL${RESET} extented"\
        "banner function ${MAGENTA}display_manual_ctrl_settings${RESET}..."
    set_menu_controller_extended_banner "$MANUALCTL_CONTROLLER_LABEL" \
        'display_manual_ctrl_settings'
    return $?
}

function create_main_menu_controller () {
    create_menu_controller "$MAIN_CONTROLLER_LABEL" \
        "${CYAN}$MAIN_CONTROLLER_DESCRIPTION${RESET}" "$MAIN_CONTROLLER_OPTIONS"
    info_msg "Setting ${CYAN}$MAIN_CONTROLLER_LABEL${RESET} extented"\
        "banner function ${MAGENTA}display_main_settings${RESET}..."
    set_menu_controller_extended_banner "$MAIN_CONTROLLER_LABEL" \
        'display_main_settings'
    return $?
}

function create_log_viewer_menu_cotroller () {
    create_menu_controller "$LOGVIEWER_CONTROLLER_LABEL" \
        "${CYAN}$LOGVIEWER_CONTROLLER_DESCRIPTION${RESET}" \
        "$LOGVIEWER_CONTROLLER_OPTIONS"
    return $?
}

function create_settings_menu_controller () {
    create_menu_controller "$SETTINGS_CONTROLLER_LABEL" \
        "${CYAN}$SETTINGS_CONTROLLER_DESCRIPTION${RESET}" \
        "$SETTINGS_CONTROLLER_OPTIONS"
    info_msg "Setting ${CYAN}$SETTINGS_CONTROLLER_LABEL${RESET} extented"\
        "banner function ${MAGENTA}display_project_settings${RESET}..."
    set_menu_controller_extended_banner "$SETTINGS_CONTROLLER_LABEL" \
        'display_project_settings'
    return 0
}

