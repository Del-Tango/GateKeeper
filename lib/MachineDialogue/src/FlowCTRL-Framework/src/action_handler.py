import logging
import time
import datetime
#import pysnooper

from threading import Thread
from timeit import default_timer as timer

from .backpack.bp_shell import shell_cmd as shell
from .backpack.bp_general import stdout_msg
from .backpack.bp_checkers import check_file_exists
from .backpack.bp_threads import ThreadWithReturnValue
from .abstract_handler import Handler

log = logging.getLogger('FlowCTRL')


class ActionHandler(Handler):

    def __init__(self, *args, **kwargs):
        self.action = kwargs.get('action', dict())
        self.state_file = kwargs.get('state_file', '/tmp/.flow-ctrl.state.tmp')
        self.report_file = kwargs.get('report_file', '/tmp/.flow-ctrl.report.tmp')

    def __print__(self, *args, **kwargs):
        return 'Action Handler: {}'.format(self.action)

    # CONVERTORS

    def convert_action_time_to_seconds(self, action_timeout):
        log.debug('')
        if not action_timeout:
            return
        unit_of_measure = list(action_timeout)[-1]
        timeout = int(action_timeout[:-1])
        if unit_of_measure in ('m', 'M'):
            timeout = timeout * 60
        elif unit_of_measure in ('h', 'H'):
            timeout = timeout * 3600
        elif unit_of_measure in ('d', 'D'):
            timeout = timeout * 3600 * 24
        return timeout

    # GENERAL

#   @pysnooper.snoop()
    def detached_shell(self, command, return_values, user=None):
        '''
        [ NOTE ]: Wrapper for backpack.shell_cmd() that runs in it's own thread
        '''
        log.debug('')
        stdout, stderr, exit_code = shell(command, user=user)
        for item in (stdout, stderr, exit_code):
            return_values.append(item)
        return return_values

    # HANDLERS

    def handle_cmd(self, action_dict):
        log.debug('')
        stdout_msg('[ EXEC ]: Action ({})... ({})'.format(
            action_dict.get('name'), action_dict['cmd']
        ))
        cmd_out, err, exit_code = self.handle_shell_cmd(
            str(action_dict['cmd']), action_dict
        )
        return False if exit_code != 0 else True

    def handle_on_ok_cmd(self, action_dict):
        log.debug('')
        stdout_msg('[ EXEC ]: Action ({}) on OK... ({})'.format(
            action_dict.get('name'), action_dict['on-ok-cmd']
        ))
        on_ok_out, err, exit_code = self.handle_shell_cmd(
            str(action_dict['on-ok-cmd']), action_dict
        )
        return False if exit_code != 0 else True

    def handle_on_nok_cmd(self, action_dict):
        log.debug('')
        stdout_msg('[ EXEC ]: Action ({}) on NOK... ({})'.format(
            action_dict.get('name'), action_dict['on-nok-cmd']
        ))
        on_nok_out, err, exit_code = self.handle_shell_cmd(
            str(action_dict['on-nok-cmd']), action_dict
        )
        return False if exit_code != 0 else True

    def handle_teardown_cmd(self, action_dict):
        log.debug('')
        stdout_msg('[ EXEC ]: Action ({}) teardown... ({})\n...'.format(
            action_dict.get('name'), action_dict['teardown-cmd']
        ))
        teardown_out, err, exit_code = self.handle_shell_cmd(
            str(action_dict['teardown-cmd']), action_dict
        )
        return False if exit_code != 0 else True

    def handle_setup_cmd(self, action_dict):
        log.debug('')
        stdout_msg('...\n[ EXEC ]: Action ({}) setup... ({})'.format(
            action_dict.get('name'), action_dict['setup-cmd']
        ))
        setup_out, err, exit_code = self.handle_shell_cmd(
            str(action_dict['setup-cmd']), action_dict
        )
        return False if exit_code != 0 else True

    def handle_shell_cmd_timeout(self, start_time, timeout, return_values):
        log.debug('')
        if not timeout:
            stdout_msg('No timeout specified for action!', warn=True)
            return False
        while True:
            now = timer()
            time_passed = now - start_time
            if return_values:
                break
            elif time_passed > timeout:
                stdout_msg(
                    'Process timed out! ({})'.format(action_dict['timeout']),
                    warn=True
                )
                return True
        return False

#   @pysnooper.snoop()
    def handle_shell_cmd(self, command, action_dict):
        log.debug('')
        if not command:
            return False
        return_values, timeout = [], self.convert_action_time_to_seconds(
            action_dict.get('timeout')
        )
        thread = Thread(
            target=self.detached_shell,
            args=(command, return_values, action_dict.get('user'))
        )
        start_time = timer()
        thread.start()
        timeout = self.handle_shell_cmd_timeout(
            start_time, timeout, return_values
        )
        if timeout:
            stdout_msg(
                'Command timed out! ({})'.format(action_dict.get('timeout')),
                nok=True
            )
            return None, None, 1
        thread.join()
        if not return_values:
            stdout_msg('Could not fetch process return values!', err=True)
            return None, None, 2
        exit_code = return_values[2]
        if exit_code != 0:
            stdout_msg(return_values[1], err=True)
            stdout_msg(
                'Command terminated with errors! Exit Code ({})'
                .format(exit_code), nok=True
            )
        else:
            stdout_msg(
                'Command terminated Successfully! Exit Code ({})'
                .format(exit_code), ok=True
            )
        return return_values[0], return_values[1], return_values[2]

#   @pysnooper.snoop()
    def action_handler(self, action_dict):
        log.debug('')
        if not action_dict.get('cmd'):
            stdout_msg(
                'No command specified in action! ({})'.format(action_dict['name']),
                warn=True
            )
            return False
        stdout_msg(
            '...\n[ INFO ]: Processing action ({}) Should take around ({})'
            .format(action_dict['name'], action_dict['time'])
        )
        failures = 0
        if action_dict.get('setup-cmd'):
            setup = self.handle_setup_cmd(action_dict)
            if not setup: failures += 1
        main_cmd = self.handle_cmd(action_dict)
        if main_cmd and action_dict['on-ok-cmd']:
            on_ok = self.handle_on_ok_cmd(action_dict)
            if not on_ok: failures += 1
        if not main_cmd:
            if action_dict['on-nok-cmd']:
                on_nok = self.handle_on_nok_cmd(action_dict)
                if not on_nok: failures += 1
            if action_dict['fatal-nok']:
                stdout_msg('Fatal! Terminating session.')
                return
        if action_dict.get('teardown'):
            teardown = self.handle_teardown_cmd(action_dict)
            if not teardown: failures += 1
        if failures:
            stdout_msg(
                'Failures detected when processing action! ({})'
                .format(failures), warn=True
            )
        return False if failures else True

    # ACTIONS

#   @pysnooper.snoop()
    def start(self):
        log.debug('')
        action_dict = self.fetch_instruction()
        if not self.validator.check_instruction(action_dict) or \
                not check_file_exists(self.state_file):
            return False
        handle = self.action_handler(action_dict)
        return False if not handle else True

# CODE DUMP


