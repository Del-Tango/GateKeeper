#import pysnooper
import time
import pytest

from threading import Thread

from src.backpack.bp_shell import shell_cmd as shell
from src.backpack.bp_general import write2file
from src.backpack.bp_convertors import dict2json, json2dict, file2list
from src.backpack.bp_checkers import check_file_exists


class TestFlowCtrlCLI():

    init_file = 'flow-init'
    sketch_dir = 'dump'
    log_dir = 'log'
    conf_dir = 'conf'
    sketch_file = sketch_dir + '/test-procedure.sketch'
    log_file = log_dir + '/flow-ctrl.log'
    conf_file = conf_dir + '/flow-ctrl.conf.json'
    config = json2dict(conf_file)

    # ACTIONS

    def action_start(self, daemon=False):
        command = './' + self.init_file + ' --purge --start --sketch-file ' \
            + self.sketch_file + ' --log-file ' + self.log_file \
            + ' --config-file ' + self.conf_file
        if daemon:
            t = Thread(target=self.handle_shell_cmd,
                       name='TestCLI FlowCTRL Start', args=(command, daemon))
            t.daemon = True
            t.start()
            return '', '', 0
        return self.handle_shell_cmd(command, daemon)

    def action_pause(self):
        command = './' + self.init_file + ' --pause --log-file ' \
            + self.log_file + ' --config-file ' + self.conf_file
        return self.handle_shell_cmd(command)

    def action_resume(self):
        command = './' + self.init_file + ' --resume --log-file ' \
            + self.log_file + ' --config-file ' + self.conf_file
        return self.handle_shell_cmd(command)

    def action_stop(self):
        command = './' + self.init_file + ' --stop --log-file ' \
            + self.log_file + ' --config-file ' + self.conf_file
        return self.handle_shell_cmd(command)

    def action_purge(self):
        command = './' + self.init_file + ' --purge'
        return self.handle_shell_cmd(command)

    # PYTESTS

    def test_flow_init_cli_start(self):
        start_out, start_err, start_exit = self.action_start()
        print('[ START ]: ' + start_out)
        assert start_out
        assert start_exit == 0

    def test_flow_init_cli_pause(self):
        self.update_sketch_file(self.sketch_file)

        start_action, err, exit_code = self.action_start(daemon=True)
        print('[ START ]: (Exit {}) '.format(exit_code) + start_action)

        state = file2list(self.config['state-file'])
        print('[ STATE ]: ({}) {}'.format(self.config['state-file'], state))

        pause_out, pause_err, pause_exit = self.action_pause()
        print('[ PAUSE ]: (Exit {}) '.format(pause_exit) + pause_out)
        print('[ ERROR ]: {}'.format(pause_err))

        if state:
            assert pause_exit == 0
        assert pause_out

    def test_flow_init_cli_resume(self):
        self.update_sketch_file(self.sketch_file)

        start_action, err, exit_code = self.action_start(daemon=True)
        print('[ START ]: (Exit {})'.format(exit_code) + start_action)
        time.sleep(1)

        state = file2list(self.config['state-file'])
        print('[ STATE ]: ({}) {}'.format(self.config['state-file'], state))

        pause_session, err, exit_code = self.action_pause()
        print('[ PAUSE ]: (Exit {})'.format(exit_code) + pause_session)

        state = file2list(self.config['state-file'])
        print('[ STATE ]: ({}) {}'.format(self.config['state-file'], state))

        resume_out, resume_err, resume_exit = self.action_resume()
        print('[ RESUME ]: (Exit {})'.format(resume_exit) + resume_out)

        if state:
            assert resume_exit == 0
        assert resume_out

    def test_flow_init_cli_stop(self):
        self.update_sketch_file(self.sketch_file)

        start_action, err, exit_code = self.action_start(daemon=True)
        print('[ START ]: (Exit {})'.format(exit_code) + start_action)

        state = file2list(self.config['state-file'])
        print('[ STATE ]: ({}) {}'.format(self.config['state-file'], state))

        stop_out, stop_err, stop_exit = self.action_stop()
        print('[ STOP ]: ' + stop_out)

        if state:
            assert stop_exit == 0
        assert stop_out

    def test_flow_init_cli_purge(self):
        purge_out, purge_err, purge_exit = self.action_purge()
        print('[ PURGE ]: ' + purge_out)
        assert purge_out
        assert purge_exit == 0

    # FORMATTERS

    @classmethod
    def format_test_procedure_json_file_content(cls):
        sketch_content = {
            "Stage 1": [
                {
                    "name": "Test Action 1",
                    "time": "5m",
                    "cmd": "ls -la && echo 'Hey, this worked!' || echo 'What? Why?!!'; sleep 10",
                    "setup-cmd": "echo 'Preparing to execute payload...'",
                    "teardown-cmd": "echo 'Payload executed!'",
                    "on-ok-cmd": "echo 'Well, this went well.'",
                    "on-nok-cmd": "echo 'This did not go well man! Fix it!'",
                    "fatal-nok": False,
                    "timeout": "10m"
                },
                {
                    "name": "Test Action 2",
                    "time": "3m",
                    "cmd": "ls -la && echo 'Hey, this worked!' || echo 'What? Why?!!'; sleep 10",
                    "setup-cmd": "echo 'Preparing to execute payload...'",
                    "teardown-cmd": "echo 'Payload executed!'",
                    "on-ok-cmd": "echo 'Well, this went well.'",
                    "on-nok-cmd": "echo 'This did not go well man! Fix it!'",
                    "fatal-nok": False,
                    "timeout": "5m"
                },
            ],
        }
        return dict2json(sketch_content)

    # HANDLERS

    @classmethod
    def handle_shell_cmd(cls, command, daemon=False):
        cmd = command
        if daemon:
            cmd = str(cmd) + ' &'
        print('[ EXECUTING ]: ' + cmd)
        return shell(cmd)

    # UPDATERS

    @classmethod
    def update_sketch_file(cls, file_path):
        print('[ + ]: Updating procedure sketch file ~')
        if not check_file_exists(file_path):
            stdout, stderr, exit_code = shell('touch ' + str(file_path))
            assert exit_code == 0
        sketch_content = cls.format_test_procedure_json_file_content()
        print('[...]: Updating test procedure sketch file...\n' + sketch_content)
        write2file(sketch_content, file_path=file_path, mode='w')


if __name__ == '__main__':
    pytest.main()

