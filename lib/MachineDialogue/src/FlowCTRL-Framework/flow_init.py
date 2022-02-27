#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# FlowCTRL - Procedure Automation Framework

import logging
import json
import os
import optparse
#import pysnooper

from src.procedure_handler import ProcedureHandler as Procedure
from src.backpack.bp_log import log_init
from src.backpack.bp_convertors import json2dict
from src.backpack.bp_general import write2file, clear_screen, stdout_msg
from src.backpack.bp_shell import shell_cmd as shell

CONFIG_FILE_PATH = os.path.dirname(os.path.realpath(__file__)) \
    + '/conf/flow-ctrl.conf.json'
CONFIG = json2dict(CONFIG_FILE_PATH)
PROCEDURE_HANDLER = Procedure()
PROCEDURE_SKETCH_FILES = list()
ACTION='' # start, stop, pause, purge, resume
log = logging.getLogger(CONFIG['log-name'])


# GENERAL

def add_action_to_queue(action_label):
    global ACTION
    log.debug('')
    if not ACTION:
        ACTION = str(action_label)
    else:
        action_labels = ACTION.split(',')
        action_labels.append(str(action_label))
        ACTION = ','.join(set(action_labels))
    return ACTION


def reload_config():
    log.debug('')
    global CONFIG
    CONFIG = json2dict(CONFIG_FILE_PATH)
    CONFIG['project-dir'] = os.path.dirname(os.path.realpath(__file__))
    return CONFIG

# FORMATTERS

def format_header_string():
    header = '''
    ___________________________________________________________________________

      *              *   Flow CTRL * Automation Framework   *               *
    ___________________________________________________________________________
                    Regards, the Alveare Solutions #!/Society -x
    '''
    return header

# ACTIONS

def action_stop():
    log.debug('')
    stdout_msg('...\n[ INFO ]: Action stop...')
    stop = PROCEDURE_HANDLER.stop()
    stdout_msg('Action stop.\n...', done=True)
    return 1 if not stop else 0


def action_pause():
    log.debug('')
    stdout_msg('...\n[ INFO ]: Action pause...')
    pause = PROCEDURE_HANDLER.pause()
    stdout_msg('Action pause.\n...', done=True)
    return 1 if not pause else 0


def action_resume():
    log.debug('')
    stdout_msg('..\n[ INFO ]: Action resume...')
    resume = PROCEDURE_HANDLER.cont()
    if resume is None:
        stdout_msg('Action resume.\n...', done=True)
        return
    cleanup = PROCEDURE_HANDLER.purge()
    stdout_msg('Action resume.\n...', done=True)
    return 1 if not resume else 0


def action_purge():
    log.debug('')
    stdout_msg('...\n[ INFO ]: Action purge...')
    purge = PROCEDURE_HANDLER.purge()
    log_file_path = CONFIG['project-dir'] + '/' + CONFIG['log-dir'] \
        + '/' + CONFIG['log-file']
    write2file('', file_path=log_file_path, mode='w')
    stdout_msg('Action purge...\n...', done=True)
    return 1 if not purge else 0


def action_start():
    log.debug('')
    stdout_msg('...\n[ INFO ]: Action start...')
    if not PROCEDURE_SKETCH_FILES:
        return 1
    procedures = process_procedure_sketch_files(PROCEDURE_SKETCH_FILES)
    stdout_msg('Action start.\n...', done=True)
    return 1 if not procedures else 0


#@pysnooper.snoop()
def process_procedure_sketch_files(sketch_files):
    log.debug('')
    failure_count = 0
    if not sketch_files:
        return False
    for file_path in sketch_files:
        if not PROCEDURE_HANDLER.load(file_path):
            stdout_msg(
                'Could not load sketch file! ({})'.format(file_path), warn=True
            )
            failure_count += 1
            continue
        execute = PROCEDURE_HANDLER.start()
        if not execute and execute is None:
            return
        elif not execute:
            stdout_msg(
                'Sketch terminated with errors! ({})'.format(file_path),
                nok=True
            )
            failure_count += 1
        else:
            stdout_msg('Sketch complete! ({})'.format(file_path), ok=True)
    cleanup = PROCEDURE_HANDLER.purge()
    if not cleanup:
        failure_count += 1
    return False if failure_count else True

# PROCESSORS

def process_log_file_argument(parser, options):
    global CONFIG
    log.debug('')
    CONFIG['conf-file-path'] = options.config_file
    return True


def process_config_file_argument(parser, options):
    global CONFIG
    log.debug('')
    CONFIG['log-file-path'] = options.log_file
    return True


def process_start_argument(parser, options):
    log.debug('')
    if not options.start_flag:
        return False
    return add_action_to_queue('start')


def process_stop_argument(parser, options):
    log.debug('')
    if not options.stop_flag:
        return False
    return add_action_to_queue('stop')


def process_pause_argument(parser, options):
    log.debug('')
    if not options.pause_flag:
        return False
    return add_action_to_queue('pause')


def process_resume_argument(parser, options):
    log.debug('')
    if not options.resume_flag:
        return False
    return add_action_to_queue('resume')


#@pysnooper.snoop()
def process_purge_argument(parser, options):
    log.debug('')
    if not options.purge_flag:
        return False
    return add_action_to_queue('purge')


def process_sketch_file_argument(parser, options):
    global PROCEDURE_SKETCH_FILES
    log.debug('')
    file_path = options.sketch_file
    if file_path == None:
        log.warning(
            'Sketch file for action not specified. '
            'Defaulting to ({}).'.format(PROCEDURE_SKETCH_FILES)
        )
        return False
    PROCEDURE_SKETCH_FILES.append(file_path)
    stdout_msg('[ + ]: Procedure sketch file loaded ({})'.format(file_path))
    return True


#@pysnooper.snoop()
def process_command_line_options(parser):
    log.debug('')
    (options, args) = parser.parse_args()
    processed = {
        'sketch_file': process_sketch_file_argument(parser, options),
        'log_file': process_log_file_argument(parser, options),
        'config_file': process_config_file_argument(parser, options),
        'purge_flag': process_purge_argument(parser, options),
        'start_flag': process_start_argument(parser, options),
        'stop_flag': process_stop_argument(parser, options),
        'pause_flag': process_pause_argument(parser, options),
        'resume_flag': process_resume_argument(parser, options),
    }
    return False if not [item for item in processed.keys() if item] \
        else processed

# CREATORS

def create_command_line_parser():
    log.debug('')
    help_msg = format_header_string() + '''
    [ EXAMPLE ]:
        $ %prog --start --sketch-file automate_me.json
        $ %prog --purge --start --sketch-file automate_me.json
        $ %prog --pause
        $ %prog --resume
        $ %prog --stop

    [ EXAMPLE ]: Procedure sketch JSON format
{
    "Stage ID": [
        {
            "name"         : "Action ID",
            "time"         : "5(s|m|h|d) usual operation time aproximation",
            "timeout"      : "10(s|m|h|d) operation time allowed"
            "cmd"          : "(Shell CMD1 || Shell CMD 2) && Shell CMD3",
            "setup-cmd"    : "Shell CMD to execute before main (cmd)",
            "teardown-cmd" : "Shell CMD to execute after main (cmd)",
            "on-ok-cmd"    : "Shell CMD to execute if main (cmd) returned 0",
            "on-nok-cmd"   : "Shell CMD to execute if main (cmd) did not return 0'",
            "fatal-nok"    : (true | false) Terminate session after on-nok-cmd,
        }
    ]
}'''
    parser = optparse.OptionParser(help_msg)
    return parser

# PARSERS

def add_command_line_parser_options(parser):
    log.debug('')
    parser.add_option(
        '-f', '--sketch-file', dest='sketch_file', type='string', metavar='FILE_PATH',
        help='Specify path to JSON sketch file containing procedure to execute.'
    )
    parser.add_option(
        '-l', '--log-file', dest='log_file', type='string', metavar='FILE_PATH',
        help='Specify log file path.'
    )
    parser.add_option(
        '-c', '--config-file', dest='config_file', type='string', metavar='FILE_PATH',
        help='Specify JSON config file path.'
    )
    parser.add_option(
        '-P', '--purge', dest='purge_flag', action='store_true',
        help='Purge all data on previous or current action and cleanup files.'
    )
    parser.add_option(
        '-S', '--start', dest='start_flag', action='store_true',
        help='Start new automation process with new procedure sketch files.'
    )
    parser.add_option(
        '-s', '--stop', dest='stop_flag', action='store_true',
        help='Stop currently running automation process.'
    )
    parser.add_option(
        '-p', '--pause', dest='pause_flag', action='store_true',
        help='Pause currently running automation process. ' \
            + 'Procedure stage and action are cached and can be resumed from ' \
            + 'at any time.'
    )
    parser.add_option(
        '-R', '--resume', dest='resume_flag', action='store_true',
        help='Resume previously paused automation process. Executes only the ' \
            + 'last sketch file from the stage and action where it left off.'
    )


def parse_command_line_arguments():
    log.debug('')
    parser = create_command_line_parser()
    add_command_line_parser_options(parser)
    return process_command_line_options(parser)

# HANDLERS

def action_handler(*args, **kwargs):
    log.debug('')
    failures, handlers = 0, {
        'start': action_start,
        'stop': action_stop,
        'pause': action_pause,
        'resume': action_resume,
        'purge': action_purge,
    }
    if len(ACTION.split(',')) > 1:
        stdout_msg('Following orders... ({})'.format(ACTION), info=True)
    setup = PROCEDURE_HANDLER.setup(**CONFIG)
    if not setup:
        stdout_msg('Could not setup handler!', err=True)
        return 1
    for action_label in ACTION.split(','):
        if action_label not in handlers.keys():
            stdout_msg(
                'Invalid action label! Skipping ({})'.format(action_label),
                warn=True
            )
            continue
        stdout_msg('Processing action... ({})'.format(action_label), info=True)
        handle = handlers[action_label](*args, **kwargs)
        if handle is None:
            return 0
        if isinstance(handle, int) and handle != 0:
            stdout_msg(
                'Action ({}) failures detected! ({})'\
                .format(action_label, handle), nok=True
            )
            failures += 1; continue
        stdout_msg(
            "Action executed successfully! ({})".format(action_label), ok=True
        )
    return failures

# INIT

#@pysnooper.snoop()
def init_flowctrl(config={}, *args, **kwargs):
    log.debug('')
    if not CONFIG['silence']:
        clear_screen()
        print(format_header_string())
    if not ACTION:
        stdout_msg('No action specified!', warn=True)
        return 1
    return action_handler(*args, **kwargs)


if __name__ == '__main__':
    if parse_command_line_arguments():
        reload_config()
    if CONFIG:
        log = log_init(
            CONFIG['project-dir'] + '/' + CONFIG['log-dir'] + '/'
            + CONFIG['log-file'], CONFIG['log-format'],
            CONFIG['timestamp-format'], CONFIG['debug'],
            log_name=CONFIG['log-name']
        )
        PROCEDURE_HANDLER = Procedure(**{
            'state_file': CONFIG['state-file'],
            'report_file': CONFIG['report-file'],
        })
    exit(init_flowctrl(CONFIG))

