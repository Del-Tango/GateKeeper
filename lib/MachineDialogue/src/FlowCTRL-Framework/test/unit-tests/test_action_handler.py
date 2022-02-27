import pysnooper
import pytest

from src.backpack.bp_general import write2file
from src.backpack.bp_convertors import dict2json, json2dict
from src.backpack.bp_checkers import check_file_exists
from src.action_handler import ActionHandler


class TestActionHandler():

    conf_dir = 'conf'
    sketch_dir = 'dump'
    init_file = 'flow-init'
    sketch_file = sketch_dir + '/test-procedure.sketch'
    conf_file = conf_dir + '/flow-ctrl.conf.json'
    config = json2dict(conf_file)
    handler = ActionHandler(state_file=config.get('state-file'))

# TESTS

    def test_action_handler(self):
        mock_stages = self.generate_mock_stages_dict()
        action_dict = mock_stages['Stage 1'][0]
        handle_action = self.handler.action_handler(action_dict)
        if handle_action != None:
            assert handle_action

    def test_shell_handler(self):
        mock_stages = self.generate_mock_stages_dict()
        command = './' + self.init_file + ' --help'
        action_dict = mock_stages['Stage 1'][0]
        stdout, stderr, exit_code = self.handler.handle_shell_cmd(
            command, action_dict
        )
        assert stdout
        assert exit_code == 0

    def test_action_time_convertor(self):
        seconds = self.handler.convert_action_time_to_seconds('3s')
        assert seconds == 3
        minutes = self.handler.convert_action_time_to_seconds('1m')
        assert minutes == 60
        hours = self.handler.convert_action_time_to_seconds('1h')
        assert hours == 3600
        days = self.handler.convert_action_time_to_seconds('1d')
        assert days == (3600 * 24)

    def test_action_start(self):
        mock_stages = self.generate_mock_stages_dict()
        mock_state = self.handler.update_state_record(0, '')
        set_instruction = self.handler.set_instruction(
            mock_stages['Stage 1'][0]
        )
        start = self.handler.start()
        assert set_instruction
        assert mock_state
        if start != None:
            assert start

    # GENERATORS

    @classmethod
    def generate_mock_stages_dict(cls):
        return {
            "Stage 1": [
                {
                    "name": "Test Action 1",
                    "time": "5m",
                    "cmd": "ls -la && echo 'Hey, this worked!' || echo 'What? Why?!!'",
                    "setup-cmd": "echo 'Preparing to execute payload...'",
                    "teardown-cmd": "echo 'Payload executed!'",
                    "on-ok-cmd": "echo 'Well, this went well.'",
                    "on-nok-cmd": "echo 'This did not go well man! Fix it!'",
                    "fatal-nok": False,
                    "timeout": "10m"
                },
            ]
        }


if __name__ == '__main__':
    pytest.main()

# CODE DUMP

