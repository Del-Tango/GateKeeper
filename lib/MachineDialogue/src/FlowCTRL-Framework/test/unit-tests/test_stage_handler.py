import pysnooper
import pytest

from src.backpack.bp_general import write2file
from src.backpack.bp_convertors import dict2json, json2dict
from src.backpack.bp_checkers import check_file_exists
from src.stage_handler import StageHandler


class TestStageHandler():

    conf_dir = 'conf'
    sketch_dir = 'dump'
    sketch_file = sketch_dir + '/test-procedure.sketch'
    conf_file = conf_dir + '/flow-ctrl.conf.json'
    config = json2dict(conf_file)
    handler = StageHandler(state_file=config.get('state-file'))

    # TESTS

    def test_procedure_start(self):
        update_sketch = self.update_sketch_file(self.sketch_file)
        mock_stages = self.generate_mock_stages_dict()
        mock_state = self.handler.update_state_record(0, '')
        set_instruction = self.handler.set_instruction(mock_stages)
        start = self.handler.start()
        assert mock_state
        if start != None:
            assert start

    def test_process_stage_actions(self):
        update_sketch = self.update_sketch_file(self.sketch_file)
        mock_stages = self.generate_mock_stages_dict()
        actions_list = mock_stages['Stage 1']
        set_instruction = self.handler.set_instruction(mock_stages)
        run_no_skip = self.handler.process_stage_actions(actions_list)
        print('(Run(No Skip) {}) {}'.format(run_no_skip, actions_list))
        if run_no_skip != None:
            assert run_no_skip
        run_skip = self.handler.process_stage_actions(
            actions_list, skip_to=('Stage 1', 'Test Action 2')
        )
        print('(Run(Skip) {}) {}'.format(run_skip, mock_stages))
        if run_skip != None:
            assert run_skip

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
                {
                    "name": "Test Action 2",
                    "time": "3m",
                    "cmd": "ls -la && echo 'Hey, this worked!' || echo 'What? Why?!!'",
                    "setup-cmd": "echo 'Preparing to execute payload...'",
                    "teardown-cmd": "echo 'Payload executed!'",
                    "on-ok-cmd": "echo 'Well, this went well.'",
                    "on-nok-cmd": "echo 'This did not go well man! Fix it!'",
                    "fatal-nok": False,
                    "timeout": "5m"
                }
            ]
        }

    # FORMATTERS

    @classmethod
    def format_test_procedure_json_file_content(cls):
        sketch_content = cls.generate_mock_stages_dict()
        return dict2json(sketch_content)

    # UPDATERS

    @classmethod
    def update_sketch_file(cls, file_path):
        print('[ + ]: Updating procedure sketch file ~')
        if not check_file_exists(file_path):
            stdout, stderr, exit_code = shell('touch ' + str(file_path))
            assert exit_code == 0
        sketch_content = cls.format_test_procedure_json_file_content()
        print('[...]: Updating test procedure sketch file...\n'
              + str(sketch_content))
        write2file(sketch_content, file_path=file_path, mode='w')


if __name__ == '__main__':
    pytest.main()

# CODE DUMP

