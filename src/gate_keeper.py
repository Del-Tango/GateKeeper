#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# Gate Keeper (Cargo)

import time
import optparse
import os
import json
import crypt
import threading
import pysnooper
import random
import subprocess
import RPi.GPIO as GPIO

from backpack.bp_log import log_init
from backpack.bp_ensurance import ensure_files_exist,ensure_directories_exist
from backpack.bp_shell import shell_cmd
from backpack.bp_checkers import check_file_exists, check_superuser
from backpack.bp_threads import threadify
from backpack.bp_general import stdout_msg, clear_screen, write2file, read_from_file
from backpack.bp_filters import filter_file_name_from_path, filter_directory_from_path

# Hot Parameters

GK_SCRIPT_NAME='GateKeeper'
GK_VERSION='Hold'
GK_VERSION_NO='1.0'
GK_DEFAULT = {
    'project-path': str(),
    'system-user': 'gate-keeper',
    'system-pass': 'gatekeeper',
    'system-perms': 755,
    'service-pass': 'GateKeeperService',
    'home-dir': '/home',
    'cron-dir': '/var/spool/cron/crontabs/gate-keeper',
    'conf-dir': 'conf',
    'conf-file': 'gate-keeper.conf.json',
    'log-dir': 'log',
    'log-file': 'gate-keeper.log',
    'hostname-file': '/etc/hostname',
    'hosts-file': '/etc/hosts',
    'wpa-file': '/etc/wpa_supplicant/wpa_supplicant.conf',
    'cron-file': '/var/spool/cron/crontabs/gate-keeper/gate-keeper.cron.gatekeeper',
    'bashrc-file': '/home/gate-keeper/.bashrc',
    'bashaliases-file': '/home/gate-keeper/.bash_aliases',
    'boot-file': '/boot/config.txt',
    'gate-index': '/home/gate-keeper/.gk-gate.index',
    'bashrc-template': '/home/gate-keeper/GateKeeper/data/.bashrc',
    'log-format': '[ %(asctime)s ] %(name)s [ %(levelname)s ] %(thread)s - '\
                  '%(filename)s - %(lineno)d: %(funcName)s - %(message)s',
    'timestamp-format': '%d/%m/%Y-%H:%M:%S',
    'debug': True,
    'machine-id': 'GateKeeper01',
    'machine-ip': '127.0.0.1',
    'silence': False,
    'wifi-essid': 'GateKeeperService',
    'wifi-pass': 'gatekeeper',
    'gpio-mode': GPIO.BCM,
    'pi-warnings': False,
    'watchdog-interval': 0.1,
}
GK_CARGO = {
    'gate-keeper': __file__,
}
GK_ACTIONS_CSV = str() # (open-gates | close-gates | check-gates | start-watchdog | help | setup | setup,open-gate)
GK_GATES_CSV = str()   # (1 | all ,etc) - [ NOTE ]: Makes no sense now, but it will, when you try controlling multiple gates

# Cold Parameters

GK_GATE_NO = 1         # WARNING: System currently only supports 1 gate under control
GK_GATE_STATES = {
    0: 'Closed',
    1: 'Open',
    'Closed': 0,
    'Open': 1,
    False: 0,
    True: 1,
}
GK_GATE_MAP = [GK_GATE_STATES['Closed'] for gate_id in range(GK_GATE_NO)]
ERROR_CODES = {
    'preconditions': 1,
}
WARNING_CODES = {
    'preconditions': 2,
    'action-fail': 3,
    'preconditions-privileges': 4,
    'preconditions-conf': 5,
    'preconditions-log': 6,
    'preconditions-servo': 7,
    'gpio-setup': 8,
}
GK_PIN_STATES = {
    True: GPIO.HIGH,
    False: GPIO.LOW,
}
log = log_init(
    '/'.join([GK_DEFAULT['log-dir'], GK_DEFAULT['log-file']]),
    GK_DEFAULT['log-format'], GK_DEFAULT['timestamp-format'],
    GK_DEFAULT['debug'], log_name=GK_SCRIPT_NAME
)

# CHECKERS

#@pysnooper.snoop()
def check_config_file():
    log.debug('')
    conf_file_path = GK_DEFAULT['conf-dir'] + "/" + GK_DEFAULT['conf-file']
    ensure_directories_exist(GK_DEFAULT['conf-dir'])
    cmd_out, cmd_err, exit_code = shell_cmd('touch ' + conf_file_path)
    return False if exit_code != 0 else True

#@pysnooper.snoop()
def check_log_file():
    log.debug('')
    log_file_path = GK_DEFAULT['log-dir'] + "/" + GK_DEFAULT['log-file']
    ensure_directories_exist(GK_DEFAULT['log-dir'])
    cmd_out, cmd_err, exit_code = shell_cmd('touch ' + log_file_path)
    return False if exit_code != 0 else True

def check_preconditions():
    log.debug('')
    checkers = {
        'preconditions-conf': check_config_file(),
        'preconditions-log': check_log_file(),
    }
    if False in checkers.values():
        return warning_preconditions_check_failed(checkers)
    return 0

def check_action_privileges():
    log.debug('')
    for action in GK_ACTIONS_CSV.split(','):
        if action.strip('\n') in ['setup'] and not check_superuser():
            return False
    return True

# ACTIONS

#@pysnooper.snoop()
def action_start_watchdog(*args, **kwargs):
    log.debug('')
    while True:
        cmd_open = GPIO.input(GK_PINS['in']['gate1-open'])
        log.debug('CMD Watchdog scan - Open pin ({}) state: ({})'.format(
            GK_PINS['in']['gate1-open'], cmd_open
        ))
        if cmd_open == 1:
            log.info('CMD Watchdog - Opening gates!')
            action_open_gates 'all'
        cmd_close = GPIO.input(GK_PINS['in']['gate1-close'])
        log.debug('CMD Watchdog scan - Close pin ({}) state: ({})'.format(
            GK_PINS['in']['gate1-open'], cmd_close
        ))
        if cmd_open == 1:
            log.info('CMD Watchdog - Closing gates!')
            action_close_gates 'all'
        time.sleep(GK_DEFAULT['watchdog-interval'])

def action_setup(*args, **kwargs):
    log.debug('')
    setup_procedure = {
        'service-pass': setup_root_password(),
        'create-user': create_system_user(),
        'export': export_project(),
        'setup-user': setup_system_user(),
        'setup-cron': setup_cron_jobs(),
        'setup-wifi': setup_wifi(),
        'machine-id': setup_machine_id(),
    }
    failure_count = len([item for item in setup_procedure.values() if not item])
    stdout_msg('[ INFO ]: Setup complete! Reboot required.')
    return failure_count

def action_check_gates(*args, **kwargs):
    log.debug('')
    stdout_msg('[ INFO ]: Checking gates...')
    action = check_gate()
    if not action:
        stdout_msg("[ NOK ]: Could not check gate status! ({})".format(args))
        return 1
    stdout_msg("[ OK ]: Gate status check!")
    return 0

#@pysnooper.snoop()
def action_close_gates(*args, **kwargs):
    log.debug('')
    targets = ['all'] if 'all' in args else [int(item) for item in args]
    stdout_msg('[ INFO ]: Closing flood gates... ({})'.format(targets))
    action = close_gate(*targets)
    if not action:
        stdout_msg("[ NOK ]: Could not close HEAD flood gates! ({})".format(args))
        return 1
    stdout_msg("[ OK ]: Gates closed! ({})".format(args))
    write = write2file(*GK_GATE_MAP, file_path=GK_DEFAULT['gate-index'])
    return 1 if not write else 0

#@pysnooper.snoop()
def action_open_gates(*args, **kwargs):
    log.debug('')
    targets = ['all'] if 'all' in args else [int(item) for item in args]
    stdout_msg('[ INFO ]: Opening flood gates... ({})'.format(targets))
    action = open_gate(*targets)
    if not action:
        stdout_msg("[ NOK ]: Could not open HEAD flood gates! ({})".format(targets))
        return 1
    stdout_msg("[ OK ]: Gates open! ({})".format(targets))
    write = write2file(*GK_GATE_MAP, file_path=GK_DEFAULT['gate-index'])
    return 1 if not write else 0

# GENERAL

#@pysnooper.snoop()
def gate_position_open(gate_ids, state=True):
    '''
    [ NOTE ]: Turns on the relay that opens the gate, until the fully-open
              button gets pressed which turns it off.
    '''
    log.debug('')
    try:
        for gate_id in gate_ids:
            GPIO.output(
                GK_PINS['out'][gate_id], GK_GATE_STATES[state]
            )
    except Exception as e:
        log.error(e)
        return False
    return True

#@pysnooper.snoop()
def gate_position_close(gate_ids, state=True):
    '''
    [ NOTE ]: Turns on the relay that closes the gate, until the fully-closed
              button gets pressed which turns it off.
    '''
    log.debug('')
    try:
        for gate_id in gate_ids:
            GPIO.output(
                GK_PINS['out'][gate_id], GK_GATE_STATES[state]
            )
    except Exception as e:
        log.error(e)
        return False
    return True

def check_gate():
    log.debug('')
    if not check_file_exists(GK_DEFAULT['gate-index']):
        stdout_msg('[ ERROR ]: No gate index file found! ({})'.format(
            GK_DEFAULT['gate-index']
        ))
        return False
    gate_index_content = read_from_file(file_path=GK_DEFAULT['gate-index'])
    if not gate_index_content or len(gate_index_content) == 0:
        stdout_msg('[ WARNING ]: Could not read gate index file! ({})'.format(
            GK_DEFAULT['gate-index']
        ))
        return False
    display_content = [
        str(item).replace('0', 'Closed').replace('1', 'Open')
        for item in gate_index_content
    ]
    for gate_index in range(len(display_content)):
        stdout_msg(
            '[ STATUS ]: Gate {} - {}'.format(
                gate_index + 1, display_content[gate_index-1]
            )
        )
    return True if display_content else False

#@pysnooper.snoop()
def open_gate(*gate_ids):
    '''
    [ INPUT ]: 1, all, ALL
    '''
    log.debug('')
    global GK_GATE_MAP
    threads = list()
    for gate_id in gate_ids:
        if gate_id == 'all' or gate_id == 'ALL':
            return open_all_flood_gates()
        t = threading.Thread(target=gate_position_open, args=([gate_id], True,))
        threads.append(t)
        # WARNING: System currently supports 1 gate only
        GK_GATE_MAP = [GK_GATE_STATES['Open']]
    for thread in threads:
        thread.start()
        thread.join()
    return True

#@pysnooper.snoop()
def close_gate(*gate_ids):
    '''
    [ INPUT ]: 1, all, ALL
    '''
    log.debug('')
    global GK_GATE_MAP
    threads = list()
    for gate_id in gate_ids:
        if gate_id == 'all' or gate_id == 'ALL':
            return close_all_flood_gates()
        t = threading.Thread(target=gate_position_close, args=([gate_id], False,))
        threads.append(t)
        # WARNING: System currently supports 1 gate only
        GK_GATE_MAP = [GK_GATE_STATES['Closed']]
    for thread in threads:
        thread.start()
        thread.join()
    return True

#@pysnooper.snoop()
def load_gate_index_from_file(file_path):
    log.debug('')
    global GK_GATE_MAP
    with open(file_path, 'r', encoding='utf-8', errors='ignore') \
            as active_file:
        status_map = []
        for line in active_file.readlines():
            log.debug('Read gate index line: {}'.format(line.strip('\n')))
            try:
                status_map.append(int(line))
            except Exception as e:
                log.error(e)
        if len(status_map) != GK_GATE_NO:
            log.warning(
                'Gate index file ({}) contains malformed data! ({})'.format(
                    file_path, status_map
                )
            )
            return False
        else:
            GK_GATE_MAP = status_map
    return True

#@pysnooper.snoop()
def export_project():
    log.debug('')
    stdout_msg('[ INFO ]: Exporting project...')
    project_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    dir_name = os.path.basename(project_dir)
    new_dir = GK_DEFAULT['home-dir'] + '/' + GK_DEFAULT['system-user'] + '/' + dir_name
    if project_dir == new_dir:
        stdout_msg(
            '[ WARNING ]: Source and target directories are identical! Aborting.'
        )
        return False
    cmd_out, cmd_err, exit_code = shell_cmd(
        'cp -r ' + project_dir + ' ' + new_dir + ' &> /dev/null'
    )
    if exit_code != 0:
        stdout_msg(
            '[ NOK ]: Could not move directory ({}) to ({}).'\
            .format(project_dir, new_dir)
        )
    else:
        stdout_msg('[ OK ]: Project export complete!')
    return False if exit_code != 0 else True

#@pysnooper.snoop()
def load_config_file():
    log.debug('')
    global GK_DEFAULT
    global GK_SCRIPT_NAME
    global GK_VERSION
    global GK_VERSION_NO
    stdout_msg('[ INFO ]: Loading config file...')
    conf_file_path = GK_DEFAULT['conf-dir'] + '/' + GK_DEFAULT['conf-file']
    if not os.path.isfile(conf_file_path):
        stdout_msg('[ NOK ]: File not found! ({})'.format(conf_file_path))
        return False
    with open(conf_file_path, 'r', encoding='utf-8', errors='ignore') as conf_file:
        try:
            content = json.load(conf_file)
            GK_DEFAULT.update(content['GK_DEFAULT'])
            GK_CARGO.update(content['GK_CARGO'])
            GK_SCRIPT_NAME = content['GK_SCRIPT_NAME']
            GK_VERSION = content['GK_VERSION']
            GK_VERSION_NO = content['GK_VERSION_NO']
        except Exception as e:
            log.error(e)
            stdout_msg(
                '[ NOK ]: Could not load config file! ({})'.format(conf_file_path)
            )
            return False
    stdout_msg(
        '[ OK ]: Settings loaded from config file! ({})'.format(conf_file_path)
    )
    return True

def open_all_flood_gates():
    log.debug('')
    return open_gate(*['gate1-open'])

def close_all_flood_gates():
    log.debug('')
    return close_gate(*['gate1-close'])

# HANDLERS

def handle_gate_fully_closed_event(*args, **kwargs):
    '''
    [ NOTE ]: Called when the fully-closed button gets pressed by the gate.
              Turns off relay responsible for closing the gate.
    '''
    log.debug('')
    # WARNING: System currently only supports 1 gate under control
    return gate_position_close('gate1-close', state=False)

def handle_gate_fully_opened_event(*args, **kwargs):
    '''
    [ NOTE ]: Called when the fully-opened button gets pressed by the gate.
              Turns off relay responsible for opening the gate.
    '''
    log.debug('')
    # WARNING: System currently only supports 1 gate under control
    return gate_position_open('gate1-open', state=False)

#@pysnooper.snoop()
def handle_actions(actions=[], *args, **kwargs):
    log.debug('')
    failure_count = 0
    handlers = {
        'start-watchdog': action_start_watchdog,
        'open-gates': action_open_gates,
        'close-gates': action_close_gates,
        'check-gates': action_check_gates,
        'setup': action_setup,
    }
    gpio_setup = setup_gpio()
    if not gpio_setup:
        warning_gpio_setup_failed()
    for action_label in actions:
        stdout_msg('[ INFO ]: Processing action... ({})'.format(action_label))
        if action_label not in handlers.keys():
            stdout_msg(
                '[ NOK ]: Invalid action label specified! ({})'.format(action_label)
            )
            continue
        handle = handlers[action_label](*args, **kwargs)
        if isinstance(handle, int) and handle != 0:
            stdout_msg(
                '[ NOK ]: Action ({}) failures detected! ({})'\
                .format(action_label, handle)
            )
            failure_count += 1
            continue
        stdout_msg(
            "[ OK ]: Action executed successfully! ({})".format(action_label)
        )
    return True if failure_count == 0 else failure_count

# FORMATTERS

# TODO - REFACTOR - start watchdog here
def format_cron_content():
    log.debug('TODO - REFACTOR')
    content = ''.join([
        '@reboot service ssh start',
#       '\n@reboot tmux new-session -A -s ',
#       GK_SCRIPT_NAME, ' \; send -t ', GK_SCRIPT_NAME, ' "bash" ENTER \; send -t ',
#       GK_SCRIPT_NAME, ' "gatekeeper" ENTER \; detach -s ', GK_SCRIPT_NAME, '\n'
    ])
    log.debug('Formatted Cron file content: (\n{})'.format(content))
    return content

def format_bashrc_content():
    log.debug('')
    content = ''.join([
        'trap \'logout &> /dev/null || exit &> /dev/null\' 1 2 3 4 5 6 7 8 9 ',
        '10 11 12 13 14 15', '\n',

        'cd ', GK_DEFAULT['project-path'], ' && ', GK_DEFAULT['project-path'],
        '/gate-keeper && cd - &> /dev/null', '\n',

        'logout &> /dev/null || exit &> /dev/null', '\n',
    ])
    log.debug('Formatted BashRC file content: (\n{})'.format(content))
    return content

def format_bash_aliases_content():
    log.debug('')
    content = ''.join([
        'alias gatekeeper="cd ', GK_DEFAULT['project-path'], ' && ',
        GK_DEFAULT['project-path'], '/gate-keeper && cd - &> /dev/null"','\n'
    ])
    log.debug('Content: ' + content)
    return content

def format_wpa_supplicant_conf_content():
    log.debug('')
    content = '''ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
country=us
update_config=1\n
network={
    ssid="''' + GK_DEFAULT['wifi-essid'] + '''"
    scan_ssid=1
    psk="''' + GK_DEFAULT['wifi-pass'] + '''"
    key_mgmt=WPA-PSK
}'''
    log.debug('Content: ' + content)
    return content

def format_header_string():
    header = '''
    ___________________________________________________________________________

     *            *            *   Gate Keeper   *             *             *
    ___________________________________________________________________________
                    Regards, the Alveare Solutions #!/Society -x
    '''
    return header

def format_usage_string():
    usage = '''
    -h | --help                    Display this message.

    -S | --setup                   Setup current machine as Gate Keeper HEAD -
       |                           Script designed for the Raspberry Pi Zero W.
       |                           Argument same as (--action setup).

    -s | --silence                 No STDOUT messages.

    -a | --action ACTIONS-CSV      Action to execute - Valid values include one
       |                           or more of the following labels given as a CSV
       |                           string: (open-gates | close-gates | check-gates
       |                           | start-watchdog | setup)

    -g | --gate GATE-CSV           Implies --action (open-gates | close-gates)
       |                           Head unit flood gate ID's given as a CSV string:
       |                           (1 | all)

    -l | --log-file FILE-PATH      Log file path... where it writes log messages to.

    -c | --config-file FILE-PATH   Config file path... where it reads configurations
       |                           from.

    -D | --debug                   Increases verbosity of log messages.
    '''
    return usage

# DISPLAY

def display_header():
    if GK_DEFAULT['silence']:
        return False
    print(format_header_string())
    return True

def display_usage():
    if GK_DEFAULT['silence']:
        return False
    display_header()
    print(format_usage_string())
    return True

# CREATORS

def create_system_user():
    log.debug('')
    stdout_msg(
        '[ INFO ]: Ensuring system user exists... ({})'
        .format(GK_DEFAULT['system-user'])
    )
    encoded_pass = crypt.crypt(GK_DEFAULT['system-pass'], "22")
    cmd_out, cmd_err, exit_code = shell_cmd(
        'useradd -p ' + encoded_pass + ' ' + GK_DEFAULT['system-user']
        + ' &> /dev/null'
    )
    if exit_code != 0:
        stdout_msg('[ NOK ]: Could not create new system user!')
    else:
        stdout_msg('[ OK ]: System user!')
    return False if exit_code != 0 else True

def create_command_line_parser():
    log.debug('')
    help_msg = format_header_string() + '''
    [ EXAMPLE ]: Setup gatekeeper HEAD unit -

        ~$ %prog \\
            -S  | --setup \\
            -c  | --config-file /etc/conf/gate-keeper.conf.json \\
            -l  | --log-file /etc/log/gate-keeper.log

    [ EXAMPLE ]: Open gates 1 and 2 with no STDOUT output -

        ~$ %prog \\
            -a  | --action open-gates \\
            -g  | --gate 1,2 \\
            -s  | --silence \\
            -c  | --config-file /etc/conf/gate-keeper.conf.json \\
            -l  | --log-file /etc/log/gate-keeper.log'''
    parser = optparse.OptionParser(help_msg)
    return parser

# PROCESSORS

#@pysnooper.snoop()
def process_config_file_argument(parser, options):
    global GK_DEFAULT
    log.debug('')
    file_path = options.config_file_path
    if file_path == None:
        log.warning(
            'No config file provided. Defaulting to ({}/{}).'\
            .format(GK_DEFAULT['conf-dir'], GK_DEFAULT['conf-file'])
        )
        return False
    GK_DEFAULT['conf-dir'] = filter_directory_from_path(file_path)
    GK_DEFAULT['conf-file'] = filter_file_name_from_path(file_path)
    load_config_file()
    stdout_msg(
        '[ + ]: Config file setup ({})'.format(GK_DEFAULT['conf-file'])
    )
    return True

def process_warning(warning):
    log.warning(warning['msg'])
    print('[ WARNING ]:', warning['msg'], 'Details:', warning['details'])
    return warning

def process_error(error):
    log.error(error['msg'])
    print('[ ERROR ]:', error['msg'], 'Details:', error['details'])
    return error

def process_command_line_options(parser):
    '''
    [ NOTE ]: In order to avoid a bad time in STDOUT land, please process the
            silence flag before all others.
    '''
    log.debug('')
    (options, args) = parser.parse_args()
    processed = {
        'silence_flag': process_silence_argument(parser, options),
        'config_file': process_config_file_argument(parser, options),
        'log_file': process_log_file_argument(parser, options),
        'setup_flag': process_setup_argument(parser, options),
        'action_csv': process_action_csv_argument(parser, options),
        'gate_csv': process_gate_csv_argument(parser, options),
        'debug_flag': process_debug_mode_argument(parser, options),
    }
    return processed

def process_silence_argument(parser, options):
    global GK_DEFAULT
    log.debug('')
    silence_flag = options.silence
    if silence_flag == None:
        return False
    GK_DEFAULT['silence'] = silence_flag
    stdout_msg(
        '[ + ]: Silence ({})'.format(silence_flag)
    )
    return True

def process_setup_argument(parser, options):
    global GK_ACTIONS_CSV
    log.debug('')
    setup_flag = options.setup
    if setup_flag == None:
        return False
    GK_ACTIONS_CSV = 'setup' if not GK_ACTIONS_CSV \
            else 'setup,{}'.format(GK_ACTIONS_CSV)
    stdout_msg(
        '[ + ]: Setup mode ({})'.format(setup_flag)
    )
    return True

def process_action_csv_argument(parser, options):
    global GK_ACTIONS_CSV
    log.debug('')
    action_csv = options.action_csv
    if action_csv == None:
        log.warning(
            'No actions provided. Defaulting to ({}).'\
            .format(GK_ACTIONS_CSV)
        )
        return False
    GK_ACTIONS_CSV = action_csv
    stdout_msg(
        '[ + ]: Actions setup ({})'.format(GK_ACTIONS_CSV)
    )
    return True

def process_gate_csv_argument(parser, options):
    global GK_GATES_CSV
    log.debug('')
    gate_csv = options.gate_csv
    if gate_csv == None:
        log.warning(
            'No gate ID\'s provided. Defaulting to ({}).'\
            .format(GK_GATES_CSV)
        )
        return False
    GK_GATES_CSV = gate_csv
    stdout_msg(
        '[ + ]: Gate ID\'s setup ({})'.format(GK_GATES_CSV)
    )
    return True

def process_debug_mode_argument(parser, options):
    global GK_DEFAULT
    log.debug('')
    debug_mode = options.debug_mode
    if debug_mode == None:
        log.warning(
            'Debug mode flag not specified. '
            'Defaulting to ({}).'.format(GK_DEFAULT['debug'])
        )
        return False
    GK_DEFAULT['debug'] = debug_mode
    stdout_msg(
        '[ + ]: Debug mode setup ({})'.format(GK_DEFAULT['debug'])
    )
    return True

def process_log_file_argument(parser, options):
    global GK_DEFAULT
    log.debug('')
    file_path = options.log_file_path
    if file_path == None:
        log.warning(
            'No log file provided. Defaulting to ({}/{}).'\
            .format(GK_DEFAULT['log-dir'], GK_DEFAULT['log-file'])
        )
        return False
    GK_DEFAULT['log-dir'] = filter_directory_from_path(file_path)
    GK_DEFAULT['log-file'] = filter_file_name_from_path(file_path)
    stdout_msg(
        '[ + ]: Log file setup ({})'.format(GK_DEFAULT['log-file'])
    )
    return True

# PARSERS

def add_command_line_parser_options(parser):
    log.debug('')
    parser.add_option(
        '-S', '--setup', dest='setup', action='store_true',
        help='Setup current machine as a Gate Keeper - script designed '
            'for the Raspberry Pi Zero W. Argument same as (--action=setup).'
    )
    parser.add_option(
        '-s', '--silence', dest='silence', action='store_true',
        help='Eliminates all STDOUT messages.'
    )
    parser.add_option(
        '-a', '--action', dest='action_csv', type='string', metavar='ACTION-CSV',
        help='Action to execute - valid values include one or more of the '
            'following labels given as a CSV string: (open-gates | close-gates | setup)'
    )
    parser.add_option(
        '-g', '--gate', dest='gate_csv', type='string', metavar='GATES-CSV',
        help='Implies (--action <open-gates | close-gates>) - Specify gate ID\'s '
            'for action as a CSV string'
    )
    parser.add_option(
        '-c', '--config-file', dest='config_file_path', type='string',
        help='Configuration file to load default values from.', metavar='FILE_PATH'
    )
    parser.add_option(
        '-D', '--debug-mode', dest='debug_mode', action='store_true',
        help='Display more verbose output and log messages.'
    )
    parser.add_option(
        '-l', '--log-file', dest='log_file_path', type='string',
        help='Path to the log file.', metavar='FILE_PATH'
    )

def parse_command_line_arguments():
    log.debug('')
    parser = create_command_line_parser()
    add_command_line_parser_options(parser)
    return process_command_line_options(parser)

# SETUP

def setup_machine_id(*args, **kwargs):
    log.debug('')
    stdout_msg('[ INFO ]: Setting machine ID...')
    machine_id = kwargs.get('machine-id', GK_DEFAULT['machine-id'])
    cmd_out, cmd_err, exit_code = shell_cmd(
        'hostname ' + machine_id + ' &> /dev/null'
    )
    if exit_code != 0:
        stdout_msg(
            '[ NOK ]: Could not set machine hostname to {}! ({})'\
            .format(machine_id, exit_code)
        )
        return exit_code
    stdout_msg('[ OK ]: Machine hostname! ({})'.format(machine_id))
    hostname = write2file(
        machine_id,
        file_path=kwargs.get('hostname-file', GK_DEFAULT['hostname-file']),
        mode='w'
    )
    if not hostname:
        stdout_msg('[ NOK ]: Could not update hostname file!')
    else:
        stdout_msg('[ OK ]: Hostname file updated!')
    hosts = write2file(
        GK_DEFAULT['machine-ip'] + '        ' + str(machine_id),
        file_path=kwargs.get('hosts-file', GK_DEFAULT['hosts-file']),
        mode='a'
    )
    if not hosts:
        stdout_msg('[ NOK ]: Could not update hosts file!')
    else:
        stdout_msg('[ OK ]: Hosts file updated!')
    failure_count = len([item for item in (hostname, hosts) if not item])
    return failure_count

#@pysnooper.snoop()
def setup_system_user_directory_structure():
    log.debug('')
    user_home = GK_DEFAULT['home-dir'] + '/' + GK_DEFAULT['system-user']
    if GK_DEFAULT['project-path']:
        user_project = GK_DEFAULT['project-path']
    else:
        user_project = user_home + '/' + GK_SCRIPT_NAME
    return ensure_directories_exist(
        user_home, user_project, GK_DEFAULT['cron-dir']
    )

#@pysnooper.snoop()
def setup_system_user_bashrc():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up ({})...'.format(GK_DEFAULT['bashrc-file']))
    stdout_msg('[ INFO ]: Formatting file content...')
    template, content = str(), format_bashrc_content()
    if not content:
        stdout_msg('[ NOK ]: Could not format file content!')
    else:
        stdout_msg('[ OK ]: File content!')
    with open(GK_DEFAULT['bashrc-template'], 'r', encoding='utf-8',
            errors='ignore') as bashrc:
        stdout_msg('[ INFO ]: Reading template file...')
        template = ''.join(bashrc.readlines())
        if not template:
            stdout_msg(
                '[ NOK ]: Could not read template file ({})!'\
                .format(GK_DEFAULT['bashrc-template'])
            )
        else:
            stdout_msg(
                '[ OK ]: Read template file ({})!'\
                .format(GK_DEFAULT['bashrc-template'])
            )
    ensure_bashrc = ensure_files_exist(GK_DEFAULT['bashrc-file'])
    content = template + '\n' + content
    with open(GK_DEFAULT['bashrc-file'], 'w', encoding='utf-8',
            errors='ignore') as bashrc:
        stdout_msg(
            '[ INFO ]: Updating file... ({})'.format(GK_DEFAULT['bashrc-file'])
        )
        write = bashrc.write(content)
        if not write:
            stdout_msg('[ NOK ]: Could not update file!')
        else:
            stdout_msg('[ OK ]: File updated successfuly!')
    return True

#@pysnooper.snoop()
def setup_gpio():
    log.debug('')
    log.info('Setting GPIO warnings to ({})'.format(GK_DEFAULT['pi-warnings']))
    GPIO.setwarnings(GK_DEFAULT['pi-warnings'])
    log.info('Setting GPIO mode to ({})'.format(GK_DEFAULT['gpio-mode']))
    GPIO.setmode(GK_DEFAULT['gpio-mode'])
    log.info('Setting up GPIO IN pins ({})'.format(list(GK_PINS['in'].values())))
    GPIO.setup(list(int(item) for item in GK_PINS['in'].values()), GPIO.IN)
    out_pins = list(GK_PINS['out'].values())
    log.info('Setting up GPIO OUT pins ({})'.format(out_pins))
    GPIO.setup(out_pins, GPIO.OUT)
    log.info('Setting up GPIO IN&OUT pins ({})'.format(
        list(GK_PINS['both'][data_set_key]['pin'] for data_set_key in GK_PINS['both']))
    )
    for data_set_key in GK_PINS['both']:
        data_set = GK_PINS['both'][data_set_key]
        pull_resistor = GPIO.PUD_UP if data_set['pull'] == 'up' else GPIO.PUD_DOWN
        GPIO.setup(data_set['pin'], GPIO.IN, pull_up_down=pull_resistor)
        GPIO.add_event_detect(
            data_set['pin'], GPIO.BOTH, callback=data_set['event-callback']
        )
    return True

#@pysnooper.snoop()
def setup_cron_jobs():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up cron jobs...')
    if not ensure_directories_exist(GK_DEFAULT['cron-dir']):
        stdout_msg(
            '[ WARNING ]: Could not ensure cron directory '
            + GK_DEFAULT['cron-dir'] + ' exists!'
        )
    stdout_msg('[ INFO ]: Formatting cron file content...')
    content = format_cron_content()
    if not content:
        stdout_msg(
            '[ NOK ]: Could not format cron file content! ({})'\
            .format(content)
        )
    else:
        stdout_msg('[ OK ]: File content!')
    with open(GK_DEFAULT['cron-file'], 'w', encoding='utf-8',
            errors='ignore') as cron:
        stdout_msg(
            '[ INFO ]: Updating file... ({})'\
            .format(GK_DEFAULT['cron-file'])
        )
        write = cron.write(content)
        if not write:
            stdout_msg(
                '[ NOK ]: Could not update file ({})!'\
                .format(GK_DEFAULT['cron-file'])
            )
        else:
            stdout_msg(
                '[ OK ]: File updated successfuly! ({})'\
                .format(GK_DEFAULT['cron-file'])
            )
    owner_out, owner_err, owner_exit = shell_cmd(
        'chown ' + GK_DEFAULT['system-user'] + ' ' + GK_DEFAULT['cron-dir']
        + ' &> /dev/null'
    )
    if owner_exit != 0:
        stdout_msg(
            '[ NOK ]: Could not set ({}) as owner of directory ({})!'\
            .format(GK_DEFAULT['system-user'], GK_DEFAULT['cron-dir'])
        )
    perms_out, perms_err, perms_exit = shell_cmd(
        'chmod -R ' + str(GK_DEFAULT['system-perms']) + ' '
        + GK_DEFAULT['cron-dir'] + ' &> /dev/null'
    )
    if perms_exit != 0:
        stdout_msg(
            '[ NOK ]: Could not set ({}) permissions to directory ({})!'\
            .format(GK_DEFAULT['system-perms'], GK_DEFAULT['cron-dir'])
        )
    return False if owner_exit != 0 or perms_exit != 0 else True

#@pysnooper.snoop()
def setup_system_user_permissions():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up user HOME permissions...')
    home_dir = GK_DEFAULT['home-dir'] + '/' + GK_DEFAULT['system-user']
    owner_out, owner_err, owner_exit = shell_cmd(
        'chown ' + GK_DEFAULT['system-user'] + ' ' + home_dir + ' &> /dev/null'
    )
    if owner_exit != 0:
        stdout_msg(
            '[ NOK ]: Could not set ({}) as owner of directory ({})!'\
            .format(GK_DEFAULT['system-user'], home_dir)
        )
    else:
        stdout_msg(
            '[ OK ]: System user HOME directory owner set! ({})'\
            .format(GK_DEFAULT['system-user'])
        )
    perms_out, perms_err, perms_exit = shell_cmd(
        'chmod -R ' + str(GK_DEFAULT['system-perms']) + ' ' + home_dir
        + ' &> /dev/null'
    )
    if perms_exit != 0:
        stdout_msg(
            '[ NOK ]: Could not set ({}) permissions to directory ({})!'\
            .format(GK_DEFAULT['system-perms'], home_dir)
        )
    else:
        stdout_msg(
            '[ OK ]: System user HOME directory permissions set! ({})'\
            .format(GK_DEFAULT['system-perms'])
        )
    return False if owner_exit != 0 or perms_exit != 0 else True

def setup_system_user_bash_aliases():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up ({})...'.format(GK_DEFAULT['bashaliases-file']))
    stdout_msg('[ INFO ]: Formatting file content...')
    content = format_bash_aliases_content()
    if not content:
        stdout_msg(
            '[ NOK ]: Could not format ({}) file content!'\
            .format(GK_DEFAULT['bashaliases-file'])
        )
        return False
    stdout_msg('[ OK ]: File content!')
    with open(GK_DEFAULT['bashaliases-file'], 'w', encoding='utf-8',
            errors='ignore') as aliases:
        stdout_msg(
            '[ INFO ]: Updating file... ({})'\
            .format(GK_DEFAULT['bashaliases-file'])
        )
        write = aliases.write(content)
        if not write:
            stdout_msg('[ NOK ]: Could not update file!')
            return False
        else:
            stdout_msg('[ OK ]: File updated successfuly!')
    return True

def setup_system_user():
    log.debug('')
    user_setup = {
        'directories': setup_system_user_directory_structure(),
        'bashrc': setup_system_user_bashrc(),
        'aliases': setup_system_user_bash_aliases(),
        'permissions': setup_system_user_permissions(),
        'groups': setup_system_user_groups(),
        'gate-index': ensure_files_exist(GK_DEFAULT['gate-index']),
    }
    return False if False in user_setup.values() else True

def setup_wifi():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up wifi...')
    content = format_wpa_supplicant_conf_content()
    if not content:
        stdout_msg('[ NOK ]: Could not format ' + GK_DEFAULT['wpa-file'] + 'content!')
        return False
    with open(GK_DEFAULT['wpa-file'], 'w', encoding='utf-8', errors='ignore') as conf_file:
        stdout_msg(
            '[ INFO ]: Updating file ({})'.format(GK_DEFAULT['wpa-file'])
        )
        write = conf_file.write(content)
        if not write:
            stdout_msg(
                '[ NOK ]: Could not update file! ({})'\
                .format(GK_DEFAULT['wpa-file'])
            )
        else:
            stdout_msg(
                '[ OK ]: File updated successfuly! ({})'\
                .format(GK_DEFAULT['wpa-file'])
            )
    return True

#@pysnooper.snoop()
def setup_root_password():
    log.debug('')
    stdout_msg('[ INFO ]: Setting up service password...')
    alphabet = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    salt = ''.join(random.choice(alphabet) for i in range(8))
    shadow_pass = crypt.crypt(GK_DEFAULT['service-pass'], '$1$' + salt + '$')
    log.debug('Alphabet used for password salt: ' + alphabet)
    log.debug('Random salt to be used for shadow password: ' + salt)
    log.debug('Clear service password: ' + GK_DEFAULT['service-pass'])
    log.debug('Shadow password: ' + shadow_pass)
    if not shadow_pass:
        stdout_msg('[ NOK ]: Could not create shadow password hash!')
        return False
    # WARNING: shell_cmd() did not properly handle this command - investigate
    setup_exit = subprocess.call(('usermod', '-p', shadow_pass, 'root'))
    if setup_exit != 0:
        stdout_msg('[ NOK ]: Could not set service password!')
    else:
        stdout_msg('[ OK ]: Service password updated successfuly!')
    return False if setup_exit != 0 else True

def setup_system_user_groups():
    log.debug('')
    stdout_msg('[ INFO ]: Adding system user to sudoers...')
    group_out, group_err, group_exit = shell_cmd(
        'adduser ' + GK_DEFAULT['system-user'] + ' sudo &> /dev/null'
    )
    if group_exit != 0:
        stdout_msg(
            '[ NOK ]: Could not add ({}) to (sudoers) group!'\
            .format(GK_DEFAULT['system-user'])
        )
    else:
        stdout_msg(
            '[ OK ]: System user added to sudoers group! ({})'\
            .format(GK_DEFAULT['system-user'])
        )
    return False if group_exit != 0 else True

# WARNINGS

def warning_action_not_handled_properly(warn_code=WARNING_CODES['action-fail'],
                                        *args, **kwargs):
    warning = {
        'msg': 'Action not handled properly, failures detected!',
        'code': warn_code,
        'details': (args, kwargs),
    }
    return process_warning(warning)

def warning_preconditions_check_failed(validation_dict,
                                    warn_code=WARNING_CODES['preconditions'],
                                    *args, **kwargs):
    warning = {
        'msg': 'Preconditions check failed! ({})'.format(validation_dict),
        'code': warn_code,
        'details': (args, kwargs),
    }
    for pre_label in validation_dict:
        if validation_dict[pre_label]:
            continue
        warning['code'] = WARNING_CODES[pre_label]
        break
    return process_warning(warning)

def warning_gpio_setup_failed(warn_code=WARNING_CODES['gpio-setup'],
                                        *args, **kwargs):
    warning = {
        'msg': 'Failures detected in GPIO setup! Some devices might not work properly.',
        'code': warn_code,
        'details': (args, kwargs),
    }
    return process_warning(warning)

def error_preconditions_not_met(err_code=ERROR_CODES['preconditions'],
                                *args, **kwargs):
    error = {
        'msg': 'Action preconditions not met!',
        'code': err_code,
        'details': (args, kwargs),
    }
    return process_error(error)

# INIT

#@pysnooper.snoop()
def init_gate_keeper():
    log.debug('')
    display_header()
    stdout_msg('[ INFO ]: Verifying action preconditions...')
    check = check_preconditions()
    if not isinstance(check, int) or check != 0:
        return error_preconditions_not_met(check)
    elif os.path.isfile(GK_DEFAULT['gate-index']):
        stdout_msg('[ OK ]: Action preconditions met!')
        stdout_msg(
            '[ INFO ]: Loading gate states from index file... ({})'\
            .format(GK_DEFAULT['gate-index'])
        )
        load = load_gate_index_from_file(GK_DEFAULT['gate-index'])
        if not load:
            stdout_msg('[ NOK ]: Could not load gate states from index file!')
        else:
            stdout_msg('[ OK ]: Gate states loaded from index!')
    stdout_msg('[ OK ]: Action preconditions met!')
    handle = handle_actions(
        GK_ACTIONS_CSV.split(','), *GK_GATES_CSV.split(','), **GK_DEFAULT
    )
    if not handle:
        warning_action_not_handled_properly(handle)
    return 0 if handle is True else handle

# MISCELLANEOUS

GK_PINS = {
    'in': {
        'gate1-open': 23,
        'gate1-close': 24,
    },
    'out': {
        'gate1-open': 20,
        'gate1-close': 26,
    },
    'both': {
        'fully-closed-button': {
            'pin': 19,
            'pull': 'up',
            'event-callback': handle_gate_fully_closed_event,
        },
        'fully-opened-button': {
            'pin': 16,
            'pull': 'up',
            'event-callback': handle_gate_fully_opened_event,
        },
    }
}

if __name__ == '__main__':
    parse_command_line_arguments()
    clear_screen(GK_DEFAULT['silence'])
    EXIT_CODE = init_gate_keeper()
    stdout_msg('[ DONE ]: Terminating! ({})'.format(EXIT_CODE))
    if isinstance(EXIT_CODE, int):
        exit(EXIT_CODE)
    exit(0)

# CODE DUMP

