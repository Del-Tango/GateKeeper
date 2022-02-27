import pysnooper
import pytest

from src.backpack.bp_general import write2file
from src.backpack.bp_convertors import dict2json, json2dict
from src.backpack.bp_checkers import check_file_exists
from src.validator import Validator


class TestValidator():

    conf_dir = 'conf'
    sketch_dir = 'dump'
    init_file = 'flow-init'
    sketch_file = sketch_dir + '/test-procedure.sketch'
    conf_file = conf_dir + '/flow-ctrl.conf.json'
    config = json2dict(conf_file)
    validator = Validator()

    # TESTS

    def test_validate_instruction_set(self):
        mock_stages = self.generate_mock_stages_dict()
        stage_dict = mock_stages['Stage 1']
        action_dict = stage_dict[0]
        ah_instruction = self.validator.check_instruction(action_dict)
        assert ah_instruction
        sh_instruction = self.validator.check_instruction(mock_stages)
        assert sh_instruction
        ph_instruction = self.validator.check_instruction([self.sketch_file])
        assert ph_instruction

    def test_validate_session_state(self):
        start_from_scratch = self.validator.check_state(False, '', 'start')
        assert start_from_scratch
        start_from_purged = self.validator.check_state(True, 'purged', 'start')
        assert start_from_purged
        pause = self.validator.check_state(True, 'started', 'pause')
        assert pause
        resume = self.validator.check_state(True, 'paused', 'resume')
        assert resume
        stop = self.validator.check_state(True, 'resumed', 'stop')
        assert stop

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

