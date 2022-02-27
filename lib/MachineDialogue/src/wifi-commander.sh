#!/bin/bash
#
# Regards, the Alveare Solutions society.
#
# WIFI COMMANDER

CONF_FILE_PATH="$1"
WC_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
WPA_SUPPLICANT_CONF_FILE="${WC_DIRECTORY}/wpa-supplicant.conf"

if [ ! -z "$CONF_FILE_PATH" ] && [ -f "$CONF_FILE_PATH" ]; then
    declare -A MD_DEFAULT
    declare -A MD_CONTROLLERS
    declare -A MD_CONTROLLER_BANNERS
    declare -A MD_CONTROLLER_OPTIONS
    declare -A MD_CONTROLLER_OPTION_KEYS
    declare -A MD_SOURCE
    declare -A MD_LOGS
    declare -a MD_LOGGING_LEVELS
    declare -a MD_APT_DEPENDENCIES
    declare -A MD_IMPORTS
    declare -A MD_CARGO
    declare -A MD_PAYLOAD
    declare -a MD_PIP_DEPENDENCIES
    declare -a MD_PIP3_DEPENDENCIES
    source "$CONF_FILE_PATH"
else
    echo "
[ WARNING ]: No config file found to source!"
fi

PIPE_DHCPCD="${MD_DEFAULT['tmp-dir']}/wc-dhcpcd.pipe"
PIPE_WPA="${MD_DEFAULT['tmp-dir']}/wc-wpa.pipe"

for md_script in `ls ${WC_DIRECTORY} | grep -e '^md-'`; do
    source "${WC_DIRECTORY}/$md_script"
done

function get_wireless_interfaces(){
	local LIST_INTERFACES=`ls /sys/class/net | egrep "^wl|^ml"`
	local CNT_INT=`echo "$LIST_INTERFACES" | wc -l`
	if [ "$CNT_INT" = "0" ]; then
        info_msg "Could not detect any wireless interfaces."
		exit 1
	elif [ "$CNT_INT" = "1" ]; then
		local CNT_DEVTYPE=`cat /sys/class/net/$LIST_INTERFACES/uevent |\
            grep -c "DEVTYPE=wlan"`
		if [ "$CNT_DEVTYPE" = "0" ]; then
            error_msg "No wireless interface found."
			exit 1
		elif [ "$CNT_DEVTYPE" = "1" ]; then
			INTERFACE="$LIST_INTERFACES"
		else
            error_msg "Software error."
			exit 101
		fi
	else
        error_msg "Too many wireless interfaces detected."
		exit 2
	fi
}

function show_uniq_interfaces(){
    ifconfig $INTERFACE up
	local ALL=`iwlist "$INTERFACE" s |\
		 egrep 'Quality|Encrypt|ESSID' |\
		 awk 'NR%3{printf "%s", $0;next}1' |\
		 sed 's/[=,:]/ /g' |\
		 awk '{$1=$3=$4=$5=$6=$7=$8=$10=""; print $0}' |\
		 sed -e 's/^ //' -e 's/ \+ /\t/g' |\
		 sort -r |\
		 awk -F"\t" '!_[$3]++'`
	echo -e "${CYAN}QUAL \tENC \tESSID\n${RESET}$ALL"
}

function check_wifi_state(){
	local IDX=$(rfkill list | awk -F ":" '/phy/ {print $1}')
	local IS_BLOCK=$(rfkill list $IDX | awk '/Soft blocked: / {print $NF}')
	if [ "$IS_BLOCK" = "no" ]; then
        info_msg "Wireless network is ${GREEN}ON${RESET} (${GREEN}$IDX${RESET})"
        return 0
	elif [ "$IS_BLOCK" = "yes" ]; then
        error_msg "Wireless network is ${RED}OFF${RESET} (${RED}$IDX${RESET})."
		exit 4
	else
        error_msg "Software error."
		exit 101
	fi
    return 1
}

function check_is_connected(){
	IS_ALLREADY_CONNECTE=0
	local RET=$(iwgetid)
	local RET=${RET:-NULL}
	if [ "$RET" = "NULL" ]; then
        info_msg "Wireless network not connected."
        return 1
	else
		OLD_SSID=$(echo "$RET" | awk -F ":" '/ESSID/ {print $2}' | sed 's/\"//g')
        info_msg "Wireless network is already connected on (${GREEN}$OLD_SSID${RESET})."
		IS_ALLREADY_CONNECTE=1
	fi
    return 0
}

function verify_status_dhcpcd(){
	while read line < $PIPE_DHCPCD
	do
		case "$line" in
			*offered*from*)
                info_msg "$line"
				;;
			*carrier*)
                info_msg "$line"
				;;
			*leased*for*)
                info_msg "$line"
				;;
			 *"adding default route via"*)
                info_msg "$line"
				kill -TERM $TAILPID_DHCPCD
				local EXIT=0
				break
				;;
		esac
	done
	rm "$PIPE_DHCPCD"
}

verify_status_wpa(){
	while read line < $PIPE_WPA
	do
		case "$line" in
			*CTRL-EVENT-DISCONNECTED*)
                info_msg "$line"
				;;
			*"Trying to authenticate with"*)
                info_msg "$line"
				;;
			*CTRL-EVENT-SSID-TEMP-DISABLED*auth_failures=1*reason=CONN_FAILED)
                info_msg "$line"
				;;
			*CTRL-EVENT-CONNECTED*)
                info_msg "$line"
				kill -TERM $TAILPID_WPA
				local EXIT=0
				break
				;;
			*CTRL-EVENT-SSID-TEMP-DISABLED*auth_failures=1*reason=WRONG_KEY)
                info_msg "$line"
				kill -TERM $TAILPID_WPA
				local EXIT=1
				break
				;;
			*CTRL-EVENT-SSID-TEMP-DISABLED*auth_failures=2*reason=CONN_FAILED)
                info_msg "$line"
				kill -TERM $TAILPID_WPA
				local EXIT=2
				break
				;;
		esac
	done
	rm "$PIPE_WPA"
	if [ "$EXIT" = "0" ]; then
        info_msg "Successfully established connection with gateway."
		verify_status_dhcpcd
        for item in `seq 5`; do
            sleep 2
            ping -I $INTERFACE -c 1 $REMOTE_RESOURCE &> /dev/null
            if [ $? -eq 0 ]; then
                info_msg "Network is ok."
                exit 0
            fi
        done
        errror_msg "No internet connection."
        exit 6
	elif [ "$EXIT" = "1" ]; then
    	killall wpa_supplicant &> /dev/null
    	kill -TERM $TAILPID_DHCPCD
        error_msg "Wrong password. Registered 2 failed authentication attempts."
        exit 5
	elif [ "$EXIT" = "2" ]; then
    	killall wpa_supplicant &> /dev/null
    	kill -TERM $TAILPID_DHCPCD
        error_msg "Connection failed."
		exit 7
	else
		  kill -TERM $TAILPID_DHCPCD
          error_msg "Software error."
		  exit 101
	fi
}

function clean_all(){
	rm -f /tmp/fifo* &> /dev/null
    ifconfig $INTERFACE down
	local RUN=`dhcpcd $INTERFACE -x 2>&1`
	local RUN_EXIT="$?"
	RUN=`echo "$RUN" | tr '\n' ' '`
    info_msg "Stopped dhpcd instance for wlan interface. ($RUN) exit code ($RUN_EXIT)"

	killall wpa_supplicant &>/dev/null
	local RET2="$?"
    info_msg "Killall wpa_supplicant, exit code ($RET2)"

	rm -f "$LOG_FILE_WPA_SUPPLICANT" &> /dev/null
	local RET3="$?"
    info_msg "Removed log file ${YELLOW}$LOG_FILE_WPA_SUPPLICANT${RESET},"\
        "exit code ($RET3)"
}

function reinit_dhcpcd(){
    local RUN=`dhcpcd -L -t 30 "$INTERFACE" 2>&1`
	local RUN_EXIT="$?"
    RUN=`echo "$RUN" | tr '\n' ' '`
    info_msg "Started dhpcd instance for wlan interface. ($RUN) exit code ($RUN_EXIT)"

	if [ ! -p "$PIPE_DHCPCD" ]; then mkfifo "$PIPE_DHCPCD"; fi
	tail -fn 100 "$LOG_FILE_DHCPCD" >> $PIPE_DHCPCD &
	TAILPID_DHCPCD="$!"

	if [ ! -p "$PIPE_WPA" ]; then mkfifo "$PIPE_WPA"; fi
	tail -fn100 "$LOG_FILE_WPA_SUPPLICANT" >> $PIPE_WPA &
	TAILPID_WPA="$!"
}

function connection_wifi(){
	local SSID="$1"

	if [ "$IS_ALLREADY_CONNECTE" = "1" ]; then
		if [ "$OLD_SSID" = "$SSID" ]; then
            error_msg "Trying to connect to the same network!"
			exit 3
		else
            info_msg "Connect to other network (${YELLOW}$SSID${RESET})"
		fi
	fi

    clean_all
	reinit_dhcpcd
    info_msg "Restarting network interface (${YELLOW}$INTERFACE${RESET})"

	for i in $(seq 1 3); do
		ifconfig $INTERFACE up
		RET="$?"
		if [ "$i" = "3" ]; then
            error_msg "${RED}ifconfig${RESET} returned after 3 failed"\
                "attempts exit code ${RED}$RET${RESET}."
			exit 8
		fi
		if [ "$RET" -eq 0 ]; then
			break
		else
            info_msg "(ifconfig $INTERFACE up) return $RET"
		fi
	done

    info_msg "Done waiting for status!"
	local CNT=0

	while :
    do
		if [ -e "$LOG_FILE_WPA_SUPPLICANT" ]; then
            info_msg "File $LOG_FILE_WPA_SUPPLICANT found on try <$CNT>."
			break
		else
            info_msg "File $LOG_FILE_WPA_SUPPLICANT not found, try <$CNT>"
			sleep 1
			CNT=$((CNT + 1))
			if [ $CNT -eq 15 ]; then
				exit 9
			fi
		fi
	done

	verify_status_wpa
}

function connect_without_enc(){
	local SSID="$1"
    info_msg "Wireless (${RED}without_enc${RESET}):\n\tINTERFACE:"\
        "'${YELLOW}$INTERFACE${RESET}'\n\tSSID: '${YELLOW}$SSID${RESET}'"
	echo -e "update_config=1\nctrl_interface=/var/run/wpa_supplicant\nctrl_interface_group=0\neapol_version=1\nap_scan=1\nfast_reauth=1" > $WPA_SUPPLICANT_CONF_FILE
	echo -e "network={\n\tscan_ssid=0\n\tkey_mgmt=NONE\n\tssid=\"$SSID\"\n}" >> $WPA_SUPPLICANT_CONF_FILE
	if [ -e "$WPA_SUPPLICANT_CONF_FILE" ]; then
        info_msg "Starting wifi on (${YELLOW}$INTERFACE${RESET})"
		connection_wifi "$SSID"
	else
        error_msg "Config error."
		exit 100
	fi
	exit
}

function connect_with_enc(){
	local SSID="$1"
	local PASSWORD="$2"
	echo -e "update_config=1\nctrl_interface=/var/run/wpa_supplicant\nctrl_interface_group=0\neapol_version=1\nap_scan=1\nfast_reauth=1" > $WPA_SUPPLICANT_CONF_FILE
	wpa_passphrase "$SSID" "$PASSWORD" >> $WPA_SUPPLICANT_CONF_FILE 2> /dev/null
	sed -i 's/network={/network={\n\tscan_ssid=0\n\tkey_mgmt=WPA-PSK/' $WPA_SUPPLICANT_CONF_FILE
	if [ -e "$WPA_SUPPLICANT_CONF_FILE" ]; then
        info_msg "Starting wifi on (${YELLOW}$INTERFACE${RESET})"
		connection_wifi "$SSID"
	else
        error_msg "Config error."
		exit 100
	fi
}

function display_header () {
    echo "
    ___________________________________________________________________________

     *            *           *    WiFi Commander   *           *            *
    _______________________________________________________v.AirShip___________
                        Regards, the Alveare Solutions society.
    "
}

function print_help () {
    display_header
    local SCRIPT_NAME=`basename "$0"`
    cat <<EOF
    [ USAGE ]:

        $SCRIPT_NAME --show-ssid"
        $SCRIPT_NAME --state"
        $SCRIPT_NAME --connect-pass <ESSID> <PASSWORD>"
        $SCRIPT_NAME --connect-without-pass <ESSID>"
        $SCRIPT_NAME --block"
        $SCRIPT_NAME --unblock"

    [ EXAMPLE ]: $SCRIPT_NAME" '--connect-pass ChurchOfSubGenious send1\$ToThechurchOfSuBgEnIoUs'

    [ EXIT CODES ]:

        0 - Execution terminated successfully"
        1 - No wireless interfaces"
        2 - Too many wireless interfaces"
        3 - Trying to connect to the same network"
        4 - Wireless interface is blocked"
        5 - Wrong password"
        6 - Connected with no internet access"
        7 - Connection failure! Possibly blocked by router"
        8 - 3 failed attempts at setting up the interface"
        9 - wpa_supplicant not started"
       10 - Password length not between 8 and 63 characters"
       11 - Invalid SSID"
       99 - No arguments found"
      100 - Config-error (internal error)"
      101 - Software-error (internal error)"

EOF
}

if [ -z "$1" ]; then
	print_help
	exit 99
fi

get_wireless_interfaces

while [ $# -gt 0 ]; do
    if [ -f $1 ]; then shift; continue; fi
	case $1 in
		--connect-pass)
			check_wifi_state
			check_is_connected
            if [ $? -eq 0 ]; then
                break
            fi
			connect_with_enc "$2" "$3"
		;;
		--connect-without-pass)
			check_wifi_state
            if [ $? -eq 0 ]; then
                break
            fi
			check_is_connected
			connect_without_enc "$2"
		;;
		--state)
			check_wifi_state
			check_is_connected
		;;
		--show-ssid)
			show_uniq_interfaces
		;;
		--block)
			rfkill block wifi
		;;
		--unblock)
			rfkill unblock wifi
			ifconfig $INTERFACE up
		;;
		--help)
			print_help
		;;
	esac; shift
done

exit 0
