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
from backpack.bp_ensurance import ensure_files_exist, ensure_directories_exist
from backpack.bp_shell import shell_cmd
from backpack.bp_checkers import check_file_exists, check_superuser
from backpack.bp_threads import threadify
from backpack.bp_general import stdout_msg, clear_screen
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
    'bashrc-template': '/home/gate-keeper/GateKeeper/data/.bashrc',
    'log-format': '[ %(asctime)s ] %(name)s [ %(levelname)s ] %(thread)s - '\
                  '%(filename)s - %(lineno)d: %(funcName)s - %(message)s',
    'timestamp-format': '%d/%m/%Y-%H:%M:%S',
    'debug': True,
    'machine-id': 'GateKeeper01',
    'silence': False,
    'wifi-essid': 'GateKeeperService',
    'wifi-pass': 'gatekeeper',
    'gpio-mode': GPIO.BCM,
    'pi-warnings': False,
}
GK_CARGO = {
    'gate-keeper': __file__,
}
GK_ACTIONS_CSV = str() # (open-gate | close-gate | check-gate | help | setup | setup,open-gate)
GK_GATES_CSV = str()   # (1 | all ,etc) - [ NOTE ]: Makes no sense now, but it will, when you try controlling multiple gates

# Cold Parameters

ERROR_CODES = {
    'preconditions': 1,
}
WARNING_CODES = {
    'preconditions': 1,
    'action-fail': 2,
    'preconditions-privileges': 3,
    'preconditions-conf': 4,
    'preconditions-log': 5,
    'preconditions-servo': 6,
    'gpio-setup': 7,
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

# SETTERS

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

def action_setup(*args, **kwargs):
    log.debug('')
    setup_procedure = {
        'service-pass': setup_root_password(),
        'create-user': create_system_user(),
        'export': export_project(),
        'setup-user': setup_system_user(),
        'setup-cron': setup_cron_jobs(),
        'setup-wifi': setup_wifi(),
    }
    failure_count = len([item for item in setup_procedure.values() if not item])
    stdout_msg('[ INFO ]: Setup complete! Reboot required.')
    return failure_count

#@pysnooper.snoop()
def action_close_gates(*args, **kwargs):
    log.debug('')
    targets = ['all'] if 'all' in args else [int(item) for item in args]
    stdout_msg('[ INFO ]: Closing flood gates... ({})'.format(targets))
    action = close_gate(*targets)
    if not action:
        stdout_msg("[ NOK ]: Could not close HEAD flood gates! ({})".format(args))
        return 1
    stdout_msg("[ OK ]: Flood gates closed! ({})".format(args))
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
    stdout_msg("[ OK ]: Flood gates open! ({})".format(targets))
    return 1 if not write else 0

# GENERAL

# TODO
#@pysnooper.snoop()
def open_gate(*gate_ids):
    '''
    [ INPUT ]: 1, 2, 3, all, ALL
    '''
    log.debug('TODO - Under construction, building...')
    global SERVO_ANGLE_MAP
    threads = list()
    for gate_id in gate_ids:
        if gate_id == 'all' or gate_id == 'ALL':
            return open_all_flood_gates()
        elif gate_id < 1 or gate_id > SERVO_MOTORS:
            error_servo_index_out_of_range()
            continue
        t = threading.Thread(target=servo_position_open, args=(gate_id,))
        threads.append(t)
        SERVO_ANGLE_MAP[gate_id-1] = MAX_SERVO_ANGLE
    for thread in threads:
        thread.start()
        thread.join()
    return True
#@pysnooper.snoop()
def close_gate(*gate_ids):
    '''
    [ INPUT ]: 1, 2, 3, all, ALL
    '''
    log.debug('TODO - Under construction, building...')
    global SERVO_ANGLE_MAP
    threads = list()
    for gate_id in gate_ids:
        if gate_id == 'all' or gate_id == 'ALL':
            return close_all_flood_gates()
        elif not isinstance(gate_id, int) or gate_id < 1 or gate_id > SERVO_MOTORS:
            error_servo_index_out_of_range()
            continue
        t = threading.Thread(target=servo_position_closed, args=(gate_id,))
        threads.append(t)
        SERVO_ANGLE_MAP[gate_id-1] = MIN_SERVO_ANGLE
    for thread in threads:
        thread.start()
        thread.join()
    return True

#@pysnooper.snoop()
def export_project():
    log.debug('')
    stdout_msg('[ INFO ]: Exporting project...')
    project_dir = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
    new_dir = GK_DEFAULT['home-dir'] + '/' + GK_DEFAULT['system-user']
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
    return open_gate(*[item + 1 for item in range(SERVO_MOTORS)])

def close_all_flood_gates():
    log.debug('')
    return close_gate(*[item + 1 for item in range(SERVO_MOTORS)])

# HANDLERS

# TODO
def handle_gate_fully_closed_event(*args, **kwargs):
    log.debug('WARNING: Under construction, building...')
def handle_gate_fully_opened_event(*args, **kwargs):
    log.debug('WARNING: Under construction, building...')

#@pysnooper.snoop()
def handle_actions(actions=[], *args, **kwargs):
    log.debug('')
    failure_count = 0
    handlers = {
        'open-gates': action_open_gates,
        'close-gates': action_close_gates,
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

#   # FORMATTERS

# TODO - Check warning
def format_cron_content():
    log.debug('TODO - Rule out warning')
    content = ''.join([
        '@reboot service ssh start',
        '\n@reboot tmux new-session -A -s ',
        GK_SCRIPT_NAME, ' \; send -t ', GK_SCRIPT_NAME, ' "bash" ENTER \; send -t ',
        GK_SCRIPT_NAME, ' "gatekeeper" ENTER \; detach -s ', GK_SCRIPT_NAME, '\n'
    ])
    log.debug('Formatted Cron file content: (\n{})'.format(content))
    return content

def format_bashrc_content():
    log.debug('')
    content = ''.join([
        'trap \'logout &> /dev/null || exit &> /dev/null\' 1 2 3 4 5 6 7 8 9 ',
        '10 11 12 13 14 15\ntmux attach -t ', GK_SCRIPT_NAME,
        '\nlogout &> /dev/null || exit &> /dev/null',
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
       |                           string: (open-gates | close-gates | setup)

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

#@pysnooper.snoop()
def setup_gpio():
    log.debug('')
    log.info('Setting GPIO warnings to ({})'.format(GK_DEFAULT['pi-warnings']))
    GPIO.setwarnings(GK_DEFAULT['pi-warnings'])
    log.info('Setting GPIO mode to ({})'.format(GK_DEFAULT['gpio-mode']))
    GPIO.setmode(GK_DEFAULT['gpio-mode'])
    log.info('Setting up GPIO IN pins ({})'.format(list(GK_PINS['in'].values())))
    GPIO.setup(list(int(item) for item in GK_PINS['in'].values()), GPIO.IN)
    out_pins = list(item for item in GK_PINS['out']['spl-gate-lock'].values()) \
        + list(GK_PINS['out']['act-light'].values()) + [GK_PINS['out']['fluid-pump']]
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
    spl.setup_gpio_pins()
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

def setup_system_user():
    log.debug('')
    user_setup = {
        'bashrc': setup_system_user_bashrc(),
        'aliases': setup_system_user_bash_aliases(),
        'permissions': setup_system_user_permissions(),
        'groups': setup_system_user_groups(),
        'servo-index': ensure_files_exist(GK_DEFAULT['servo-index']),
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
    log.debug('TODO - Investigate warning')
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
    stdout_msg('[ OK ]: Action preconditions met!')
    handle = handle_actions(
        GK_ACTIONS_CSV.split(','), *GK_GATES_CSV.split(','), **GK_DEFAULT
    )
    if not handle:
        warning_action_not_handled_properly(handle)
    return 0 if handle is True else handle

# MISCELLANEOUS

GK_PINS = {
    'in': {},
    'out': {
        'gate1': 20,
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
    stdout_msg('DONE: Terminating! ({})'.format(EXIT_CODE))
    if isinstance(EXIT_CODE, int):
        exit(EXIT_CODE)
    exit(0)

# CODE DUMP

#   def format_temperature_sensor_boot_config_content():
#       log.debug('')
#       content = 'dtoverlay=w1-gpio\n'
#       log.debug('Content: ' + content)
#       return content

#   def warning_servo_setup_failed(warn_code=WARNING_CODES['servo-setup-fail'],
#                               *args, **kwargs):
#       warning = {
#           'msg': 'Servo setup failures detected!',
#           'code': warn_code,
#           'details': (args, kwargs),
#       }
#       return process_warning(warning)

#   # ERRORS

#   def error_servokit_not_found(err_code=ERROR_CODES['servokit-nok'],
#                                   *args, **kwargs):
#       error = {
#           'msg': 'Adafruit ServoKit not set up!',
#           'code': err_code,
#           'details': (args, kwargs),
#       }
#       return process_error(error)


#   def error_servo_index_out_of_range(err_code=ERROR_CODES['servo-oor'],
#                                   *args, **kwargs):
#       error = {
#           'msg': 'Servo motor index out of range! ({})'.format(args),
#           'code': err_code,
#           'details': (args, kwargs),
#       }
#       return process_error(error)


#   def setup_temperature_sensor():
#       log.debug('')
#       stdout_msg('INFO: Setting up temperature sensor...')
#       content, failure_count = format_temperature_sensor_boot_config_content(), 0
#       if not content:
#           failure_count += 1
#           stdout_msg(
#               '......NOK: Could not format cron file content! ({})'\
#               .format(content)
#           )
#       else:
#           stdout_msg(
#               '...INFO: Updating file... ({})'.format(GK_DEFAULT['boot-file'])
#           )
#           write = write_to_file(content, file_path=GK_DEFAULT['boot-file'], mode='a')
#           if not write:
#               failure_count += 1
#               stdout_msg(
#                   '......NOK: Could not update file ({})!'\
#                   .format(GK_DEFAULT['boot-file'])
#               )
#           else:
#               stdout_msg(
#                   '......OK: File updated successfuly! ({})'\
#                   .format(GK_DEFAULT['boot-file'])
#               )
#       modprobe_out, modprobe_err, modprobe_exit = shell_cmd(
#           'modprobe w1-gpio &> /dev/null'
#       )
#       if modprobe_out != 0:
#           failure_count += 1
#           stdout_msg(
#               '...NOK: Could not load 1Wire kernel module! (w1-gpio)'
#           )
#       else:
#           stdout_msg(
#               '...OK: Loaded 1Wire kernel module! (w1-gpio)'
#           )
#       return False if failure_count != 0 else True

#   def setup_sensors():
#       log.debug('')
#       sensor_setup = {
#           'temperature': setup_temperature_sensor(),
#       }
#       failure_count = len([item for item in sensor_setup.values() if not item])
#       return failure_count

#   def setup_servokit():
#       log.debug('')
#       global pca
#       pca = ServoKit(channels=16)
#       servo_setup = set_all_servo_pulse_width_range()
#       return False if not pca or not servo_setup else pca

#   def process_identity_argument(parser, options):
#       global GK_DEFAULT
#       log.debug('')
#       machine_id = options.identity
#       if machine_id == None:
#           log.warning(
#               'No HEAD machine identifier provided. Defaulting to ({}).'\
#               .format(GK_DEFAULT['machine-id'])
#           )
#           return False
#       GK_DEFAULT['machine-id'] = machine_id
#       stdout_msg(
#           '[ + ]: HEAD machine identifier setup ({})'\
#           .format(GK_DEFAULT['machine-id'])
#       )
#       return True


#   def process_flash_count_argument(parser, options):
#       global GK_FLASH_COUNT
#       log.debug('')
#       flash_count = options.flash_count
#       if flash_count == None:
#           log.warning(
#               'No ACT flash count provided. Defaulting to ({}).'\
#               .format(GK_FLASH_COUNT)
#           )
#           return False
#       GK_FLASH_COUNT = flash_count
#       stdout_msg(
#           '[ + ]: ACT flash count setup ({})'.format(GK_FLASH_COUNT)
#       )
#       return True

#   def process_light_csv_argument(parser, options):
#       global GK_LIGHTS_CSV
#       log.debug('')
#       light_csv = options.light_csv
#       if light_csv == None:
#           log.warning(
#               'No ACT light IDs provided. Defaulting to ({}).'\
#               .format(GK_LIGHTS_CSV)
#           )
#           return False
#       GK_LIGHTS_CSV = light_csv
#       stdout_msg(
#           '[ + ]: ACT lights setup ({})'.format(GK_LIGHTS_CSV)
#       )
#       return True


#   def process_id_count_argument(parser, options):
#       global GK_DEFAULT
#       log.debug('')
#       id_count = options.machine_id_count
#       if id_count == None:
#           log.warning(
#               'Number of machine ID\'s to generate not specified. '
#               'Defaulting to ({}).'.format(GK_DEFAULT['machine-ids'])
#           )
#           return False
#       GK_DEFAULT['machine-ids'] = id_count
#       stdout_msg(
#           '[ + ]: Number of machine ID\'s to generate setup ({})'\
#           .format(GK_DEFAULT['machine-ids'])
#       )
#       return True

#   def process_system_type_argument(parser, options):
#       global GK_DEFAULT
#       log.debug('')
#       sys_type = options.system_type
#       if sys_type == None:
#           log.warning(
#               'System type for action not specified. '
#               'Defaulting to ({}).'.format(GK_DEFAULT['system-type'])
#           )
#           return False
#       GK_DEFAULT['system-type'] = sys_type
#       stdout_msg(
#           '[ + ]: System type setup ({})'\
#           .format(GK_DEFAULT['system-type'])
#       )
#       return True

#   def load_servo_index_from_file(file_path):
#       log.debug('')
#       global SERVO_ANGLE_MAP
#       with open(file_path, 'r', encoding='utf-8', errors='ignore') \
#               as active_file:
#           angle_map = []
#           for line in active_file.readlines():
#               log.debug('Read servo index line: {}'.format(line.strip('\n')))
#               try:
#                   angle_map.append(int(line))
#               except Exception as e:
#                   log.error(e)
#           if len(angle_map) != SERVO_MOTORS:
#               log.warning(
#                   'Servo index file ({}) contains malformed data! ({})'.format(
#                       file_path, angle_map
#                   )
#               )
#               return False
#           else:
#               SERVO_ANGLE_MAP = angle_map
#       return True

#   #@pysnooper.snoop()
#   def write_to_file(*args, file_path=str(), mode='w', **kwargs):
#       log.debug('')
#       with open(file_path, mode, encoding='utf-8', errors='ignore') \
#               as active_file:
#           content = ''
#           for line in args:
#               content = content + str(line) + '\n'
#           for line_key in kwargs:
#               content = content + str(line_key) + '=' \
#                   + str(kwargs[line_key]) + '\n'
#           try:
#               active_file.write(content)
#           except UnicodeError as e:
#               log.error(e)
#               return False
#       log.debug('Wrote to file ({}):\n{}'. format(file_path, content))
#       return True

#   def clear_screen():
#       log.debug('')
#       if GK_DEFAULT['silence']:
#           return False
#       return os.system('cls' if os.name == 'nt' else 'clear')

#   def stdout_msg(message):
#       log.debug('')
#       log.info(message)
#       if not GK_DEFAULT['silence']:
#           print(message)
#           return True
#       return False

#   #@pysnooper.snoop()
#   def set_pump_state(state):
#       log.debug('')
#       # [ NOTE ]: Custom state - Module turns relay ON when pin driven LOW
#       gpio_state = GPIO.HIGH if not state else GPIO.LOW
#       try:
#           GPIO.output(GK_PINS['out']['fluid-pump'], gpio_state)
#       except Exception as e:
#           log.error(e)
#           return False
#       return True

#   #@pysnooper.snoop()
#   def set_servo_action_light_state(*args, state=True):
#       log.debug('')
#       global GK_SENSOR_SCAN
#       try:
#           if 'all' in args:
#               args = [
#                   item for item in GK_PINS['out']['act-light'].keys()
#                   if isinstance(item, int)
#               ]
#           for gate_id in args:
#               GPIO.output(
#                   GK_PINS['out']['act-light'][int(gate_id)], GK_PIN_STATES[state]
#               )
#               GK_SENSOR_SCAN['act-light'][int(gate_id)] = GPIO.input(
#                   GK_PINS['out']['act-light'][int(gate_id)]
#               )
#       except Exception as e:
#           log.error(e)
#           return False
#       return True

#   #@pysnooper.snoop()
#   def set_all_servo_pulse_width_range():
#       log.debug('')
#       stdout_msg('INFO: Setting up servo pulse width range...')
#       failure_count = 0
#       for i in range(SERVO_MOTORS):
#           servo_setup = pca.servo[i].set_pulse_width_range(
#               MIN_SERVO_IMPULSE, MAX_SERVO_IMPULSE
#           )
#           if servo_setup or servo_setup == None:
#               stdout_msg('...OK: Servo motor ({}) PW range set up!'.format(i))
#               continue
#           stdout_msg(
#               '...NOK: Failed to set up servo ({}) PW range! Details: ({})'\
#               .format(i, servo_setup)
#           )
#           failure_count += 1
#       return True if failure_count == 0 else False



#   def check_fluid_pump_off():
#       log.debug('')
#       return False if GPIO.input(GK_PINS['out']['fluid-pump']) != 1 else True

#   def check_superuser():
#       log.debug('')
#       return False if os.geteuid() != 0 else True


#   def check_servo_details():
#       log.debug('')
#       int_values = [
#           SERVO_MOTORS, MIN_SERVO_IMPULSE, MAX_SERVO_IMPULSE, MIN_SERVO_ANGLE,
#           MAX_SERVO_ANGLE
#       ]
#       for item in int_values:
#           if isinstance(item, int):
#               continue
#           return False
#       if not isinstance(SERVO_ANGLE_MAP, list) \
#               or len(SERVO_ANGLE_MAP) != SERVO_MOTORS:
#           return False
#       return True

#   # TODO
#   def monitor_reset_button():
#       log.debug('TODO - Under construction, building...')
#       stdout_msg('...INFO: Monitoring reset button...')
#       while True:
#           time.sleep(1)
#       return True
#   def monitor_spl_events():
#       log.debug('TODO - Under construction, building...')
#       # Check for SPL events - on cnx interogate neighbour over SPL and report to
#       # HEAD on paralel thread
#       stdout_msg('...INFO: Monitoring SPL events...')
#       while True:
#           time.sleep(1)
#       return True

#   #@pysnooper.snoop()
#   def scan_action_light_states(*args):
#       log.debug('')
#       global GK_SENSOR_SCAN
#       if not args or 'all' in args:
#           args = [
#               item for item in GK_PINS['out']['act-light'].keys()
#               if isinstance(item, int)
#           ]
#       try:
#           for gate_id in args:
#               GK_SENSOR_SCAN['act-light'][int(gate_id)] = GPIO.input(
#                   GK_PINS['out']['act-light'][int(gate_id)]
#               )
#       except Exception as e:
#           log.error(e)
#           return False
#       return GK_SENSOR_SCAN['act-light']

#   #@pysnooper.snoop()
#   def servo_position_closed(servo_id, min_pos=MIN_SERVO_ANGLE, max_pos=MAX_SERVO_ANGLE):
#       log.debug('')
#       if not pca:
#           return error_servokit_not_found(pca)
#       try:
#           pca.servo[GK_SERVO_ID_MAP[servo_id]].angle = min_pos
#       except IndexError as e:
#           log.error(e)
#           return False
#       set_servo_action_light_state(servo_id, state=False)
#       return True

#   #@pysnooper.snoop()
#   def servo_position_open(servo_id, min_pos=MIN_SERVO_ANGLE, max_pos=MAX_SERVO_ANGLE):
#       log.debug('')
#       if not pca:
#           return error_servokit_not_found(pca)
#       try:
#           pca.servo[GK_SERVO_ID_MAP[servo_id]].angle = max_pos
#       except IndexError as e:
#           log.error(e)
#           return False
#       set_servo_action_light_state(servo_id, state=True)
#       return True


#   #@pysnooper.snoop()
#   def action_set_id(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Setting machine ID...')
#       machine_id = kwargs.get('machine-id', GK_DEFAULT['machine-id'])
#       cmd_out, cmd_err, exit_code = shell_cmd(
#           'hostname ' + machine_id + ' &> /dev/null'
#       )
#       if exit_code != 0:
#           stdout_msg(
#               '...NOK: Could not set machine hostname to {}! ({})'\
#               .format(machine_id, exit_code)
#           )
#           return exit_code
#       stdout_msg('...OK: Machine hostname! ({})'.format(machine_id))
#       hostname = write_to_file(
#           machine_id,
#           file_path=kwargs.get('hostname-file', GK_DEFAULT['hostname-file']),
#           mode='w'
#       )
#       if not hostname:
#           stdout_msg('...NOK: Could not update hostname file!')
#       else:
#           stdout_msg('...OK: Hostname file updated!')
#       hosts = write_to_file(
#           GK_DEFAULT['machine-ip'] + '        ' + str(machine_id),
#           file_path=kwargs.get('hosts-file', GK_DEFAULT['hosts-file']),
#           mode='a'
#       )
#       if not hosts:
#           stdout_msg('...NOK: Could not update hosts file!')
#       else:
#           stdout_msg('...OK: Hosts file updated!')
#       failure_count = len([item for item in (hostname, hosts) if not item])
#       return failure_count

#   #@pysnooper.snoop()
#   def action_spl_scan(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Start SPL scan...')
#       spl_scan = spl.discovery()
#       if not spl_scan:
#           stdout_msg(
#               '...NOK: SPL scan failure! Index not updated ({})'
#               .format(GK_DEFAULT['spl-index'])
#           )
#       else:
#           stdout_msg(
#               '...OK: SPL scan! Index will be updated in a few seconds ({})'
#               .format(GK_DEFAULT['spl-index'])
#           )
#       return 1 if not spl_scan else 0

#   def action_start_sensor_watchdog(*args, **kwargs):
#       log.debug('')
#       failures = 0
#       stdout_msg('INFO: Starting sensor watchdog...')
#       reset_btn_thread = threadify(monitor_reset_button)
#       if not reset_btn_thread:
#           failures += 1
#           stdout_msg('...NOK: Could not start reset button monitor thread!')
#       else:
#           stdout_msg('...OK: Reset button monitor thread!')
#       spl_events_thread = threadify(monitor_spl_events, join=True)
#       if not spl_events_thread:
#           failures += 1
#           stdout_msg('...NOK: Could not start SPL event monitor thread!')
#       else:
#           stdout_msg('...OK: SPL event monitor thread!')
#       return failures

#   #@pysnooper.snoop()
#   def action_act_flash(*args, **kwargs):
#       log.debug('')
#       failures = 0
#       stdout_msg(
#           'INFO: Blinking gatekeeper ACT lights ({}) times...'
#           .format(GK_FLASH_COUNT)
#       )
#       original_act_states = dict(scan_action_light_states())
#       original_on = [
#           gate_id for gate_id in original_act_states
#           if original_act_states[gate_id]
#       ]
#       original_off = [
#           gate_id for gate_id in original_act_states
#           if not original_act_states[gate_id]
#       ]
#       if not original_on and not original_off:
#           failures += 1
#           stdout_msg('...WARNING: Could not scan initial ACT light states!')
#       for count in range(GK_FLASH_COUNT):
#           on = set_servo_action_light_state('all', state=True)
#           if not on:
#               failures += 1
#           time.sleep(GK_DEFAULT['flash-interval'])
#           off = set_servo_action_light_state('all', state=False)
#           if not off:
#               failures += 1
#           time.sleep(GK_DEFAULT['flash-interval'])
#       set_on = set_servo_action_light_state(*original_on, state=True)
#       set_off = set_servo_action_light_state(*original_off, state=False)
#       if not set_on and not set_off:
#           failures += 1
#       return failures

#   #@pysnooper.snoop()
#   def action_check_water_temperature(*args, **kwargs):
#       log.debug('')
#       if not temp_sensors:
#           stdout_msg('WARNING: No temperature sensors detected!')
#           return 1
#       temperature_readings = [ sensor.get_temperature() for sensor in temp_sensors ]
#       if not temperature_readings:
#           stdout_msg('WARNING: No temperature readings from sensor!')
#           return 2
#       # If multiple sensors attached, their readings will be averaged out
#       if len(temperature_readings) > 1:
#           temperature_readings = sum(temperature_readings)/len(temperature_readings)
#       stdout_msg('OK: Sensor readings!')
#       print('\n...Water Temperature: {}'.format(temperature_readings[0]))
#       return 0

#   def action_generate_machine_ids(*args, **kwargs):
#       log.debug('')
#       generated_machine_ids = []
#       for item in range(1, GK_DEFAULT['machine-ids'] + 1):
#           if len(str(item)) < 2:
#               machine_no = "0" + str(item)
#           else:
#               machine_no = str(item)
#           formatted_machine_id="FG." + str(GK_DEFAULT['system-type']) \
#               + "." + machine_no
#           generated_machine_ids.append(formatted_machine_id)
#       print('\n' + '\n'.join(generated_machine_ids) + '\n')
#       return 0 if generated_machine_ids else 1

#   def action_liquid_circuit_flush(*args, **kwargs):
#       log.debug('')
#       in_gate_servo_state = 1 if SERVO_ANGLE_MAP[0] == MAX_SERVO_ANGLE else 0
#       out_gate_servo_state = 2 if SERVO_ANGLE_MAP[1] == MAX_SERVO_ANGLE else 0
#       stdout_msg('INFO: Closing IN gate...')
#       close_gate(1)
#       stdout_msg('INFO: Openning AIR,OUT gates...')
#       open_gate(2,3)
#       action_pump_on()
#       time.sleep(GK_DEFAULT['pump-timeout'])
#       action_pump_off()
#       stdout_msg('INFO: Closing AIR gate...')
#       to_open = [item for item in (in_gate_servo_state, out_gate_servo_state) if item]
#       to_close = [item for item in GK_SERVO_ID_MAP.keys() if item not in to_open]
#       log.debug('Resetting gates - to_open: {}, to_close: {}'.format(to_open, to_close))
#       stdout_msg('INFO: Resetting gate states...')
#       close_gate(*to_close)
#       open_gate(*to_open)
#       return 0

#   def action_pump_on(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Turning ON fluid pump...')
#       if not check_fluid_pump_off():
#           stdout_msg('...OK: Fluid pump already ON!')
#           return True
#       set_state = set_pump_state(True)
#       if not set_state:
#           stdout_msg('...NOK: Could not turn ON fluid pump!')
#       else:
#           stdout_msg('...OK: Fluid pump turned ON!')
#       return 1 if not set_state else 0

#   def action_pump_off(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Turning OFF fluid pump...')
#       if check_fluid_pump_off():
#           stdout_msg('...OK: Fluid pump already OFF!')
#           return True
#       set_state = set_pump_state(False)
#       if not set_state:
#           stdout_msg('...NOK: Could not turn OFF fluid pump!')
#       else:
#           stdout_msg('...OK: Fluid pump turned OFF!')
#       return 1 if not set_state else 0

#   def action_spl_read2pipe(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Starting Serial Power Link Read2Pipe process...')
#       read2pipe = spl.read2pipe(GK_DEFAULT['spl-fifo'])
#       return 1 if not read2pipe else 0

#   def action_spl_monitor(*args, **kwargs):
#       log.debug('')
#       stdout_msg('INFO: Starting Serial Power Link Monitor process...')
#       monitor = spl.spl_monitor(GK_DEFAULT['spl-fifo'])
#       return 1 if not monitor else 0

#   #@pysnooper.snoop()
#   def action_lights_on(*args, **kwargs):
#       log.debug('')
#       stdout_msg(
#           'INFO: Turning ON specified flood gate ACT lights... {}'
#           .format(GK_LIGHTS_CSV)
#       )
#       light_state_update = set_servo_action_light_state(
#           *GK_LIGHTS_CSV.split(','), state=True
#       )
#       if not light_state_update:
#           stdout_msg('...NOK: Could not turn ON specified flood gate ACT lights!')
#       else:
#           stdout_msg('...OK: Specified flood gate ACT lights turned ON!')
#       return 1 if not light_state_update else 0

#   def action_lights_off(*args, **kwargs):
#       log.debug('')
#       stdout_msg(
#           'INFO: Turning OFF specified flood gate ACT lights... {}'
#           .format(GK_LIGHTS_CSV)
#       )
#       light_state_update = set_servo_action_light_state(
#           *GK_LIGHTS_CSV.split(','), state=False
#       )
#       if not light_state_update:
#           stdout_msg('...NOK: Could not turn OFF specified flood gate ACT lights!')
#       else:
#           stdout_msg('...OK: Specified flood gate ACT lights turned OFF!')
#       return 1 if not light_state_update else 0


