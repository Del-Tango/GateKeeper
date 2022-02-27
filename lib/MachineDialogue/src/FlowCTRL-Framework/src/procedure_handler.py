import logging
import os
#import pysnooper

from .backpack.bp_shell import shell_cmd as shell
from .backpack.bp_checkers import check_file_exists
from .backpack.bp_general import write2file, clear_screen, stdout_msg
from .abstract_handler import Handler
from .stage_handler import StageHandler as Stage
from .validator import Validator

log = logging.getLogger('FlowCTRL')


class ProcedureHandler(Handler):
    '''
    [ NOTE ]: Interprets the content of a JSON procedure sketch file.
    '''

    def __init__(self, *args, **kwargs):
        self.state_file = kwargs.get('state_file', '/tmp/.flow-ctrl.state.tmp')
        self.report_file = kwargs.get('report_file', '/tmp/.flow-ctrl.report.tmp')
        self.stage_handler = kwargs.get(
            'stage_handler',
            Stage(report_file=self.report_file, state_file=self.state_file)
        )
        self.instruction_set = kwargs.get('sketch_file', str())

    def __print__(self, *args, **kwargs):
        return "Procedure Handler Instruction: {}, State: {}, Stage Handler: {}"\
            .format(self.instruction_set, self.state_flag, self.stage_handler)

    # FETCHERS

    def fetch_instruction(self):
        log.debug('')
        return self.instruction_set or []

    # PROCESSORS

#   @pysnooper.snoop()
    def process_sketch_stages(self, stages_dict, skip_to=None):
        log.debug('')
        failures, skip_to_stage = 0, None if not skip_to else skip_to[0]
        for stage_id in stages_dict:
            if skip_to_stage and stage_id == skip_to_stage:
                skip_to_stage = None
            elif skip_to_stage and stage_id != skip_to_stage:
                continue
            if not self.stage_handler.set_instruction(
                    {stage_id: stages_dict[stage_id]}):
                failures += 1
                stdout_msg(
                    'Could not load procedure stage ({}) to handler! '
                    'Skipping ({})'.format(stage_id, stages_dict[stage_id]),
                    warn=True
                )
                continue
            self.update_state_record(2, stage_id)
            stage = self.stage_handler.start(skip_to=skip_to)
            skip_to = None
            if not stage and stage == False:
                failures += 1
            elif not stage and stage == None:
                return
        if failures:
            stdout_msg(
                'Failures detected when processing ({}) sketch stages! ({})'
                .format(len(stages_dict.keys()), failures), warn=True
            )
        return False if failures else True

    # ACTIONS

    def stop(self):
        log.debug('')
        if not self.validator.check_state(
                self.fetch_state(), self.fetch_state('action'), 'stop'):
            stdout_msg('Invalid state for action stop!', warn=True)
            stdout_msg(
                'To force action execute with --purge beforehand.', info=True
            )
            return False
        state_details = []
        if check_file_exists(self.state_file):
            with open(self.state_file, 'r') as fl:
                state_details = [line.strip('\n') for line in fl.readlines()]
        failures, state = 0, self.set_state(False, 'stopped')
        if not state:
            failures += 1
            stdout_msg(
                'Could not stop running session! ({})'
                .format(state_details), nok=True
            )
        else:
            stdout_msg('Session terminated! ({})'
                       .format(state_details), ok=True)
        if failures:
            stdout_msg(
                'Failures detected when processing ({}) sketch stages! ({})'
                .format(len(stages_dict.keys()), failures), warn=True
            )
        return False if failures else True

#   @pysnooper.snoop()
    def cont(self):
        log.debug('')
        if not self.validator.check_state(
                self.fetch_state(), self.fetch_state('action'), 'resume'):
            stdout_msg('Invalid state for action resume!', warn=True)
            stdout_msg(
                'To force action execute with --purge beforehand.', info=True
            )
            return False
        failures, state = 0, self.set_state(True, 'resumed')
        with open(self.state_file, 'r') as fl:
            state_details = [line.strip('\n') for line in fl.readlines()]
        if not state:
            failures += 1
            stdout_msg(
                'Could not resume session! ({})'.format(state_details), nok=True
            )
        else:
            segmented_record = state_details[0].split(',')
            previous_action = segmented_record[0]
            sketch_file_path = segmented_record[1]
            stage_id, action_id = segmented_record[2], segmented_record[3]
            reload_sketch = self.load(sketch_file_path)
            if not reload_sketch:
                stdout_msg(
                    'Could not reload sketch file from previous session! ({})'
                    .format(sketch_file_path), err=True
                )
                failures += 1
            else:
                with open(self.state_file, 'r') as fl:
                    state_details = [line.strip('\n') for line in fl.readlines()]
                stdout_msg('Session resumed! ({})'.format(state_details), ok=True)
                process = self.process_sketch_stages(
                    self.fetch_instruction(), skip_to=[stage_id, action_id]
                )
        if failures:
            stdout_msg(
                'Failures detected when reviving paused session! ({})'
                .format(failures), warn=True
            )
        return False if failures else True

#   @pysnooper.snoop()
    def pause(self):
        log.debug('')
        if not self.validator.check_state(
                self.fetch_state(), self.fetch_state('action'), 'pause'):
            stdout_msg('Invalid state for action pause!', warn=True)
            stdout_msg('To force action execute with --purge beforehand.', info=True)
            return False
        failures, state = 0, self.set_state(True, 'paused')
        with open(self.state_file, 'r') as fl:
            state_details = [line.strip('\n') for line in fl.readlines()]
        if not state:
            failures += 1
            stdout_msg(
                'Could not pause session! ({})'.format(state_details), nok=True
            )
        else:
            stdout_msg('Session on hold! ({})'.format(state_details), ok=True)
        if failures:
            stdout_msg(
                'Failures detected when processing ({}) sketch stages! ({})'
                .format(len(stages_dict.keys()), failures), warn=True
            )
        return False if failures else True

#   @pysnooper.snoop()
    def start(self):
        log.debug('')
        if not self.validator.check_state(
                self.fetch_state(), self.fetch_state('action'), 'start'):
            stdout_msg('Invalid state for action start!', warn=True)
            stdout_msg(
                'To force action execute with --purge beforehand.', info=True
            )
            return False
        self.set_state(True, 'started')
        process = self.process_sketch_stages(self.fetch_instruction())
        if process is None:
            return
        return False if not process else True

    def purge(self):
        log.debug('')
        failures = 0
        files_to_clean = [
            str(file_path) for file_path in (self.state_file, self.report_file)
            if file_path
        ]
        if not files_to_clean:
            failures += 1
        else:
            cleanup = shell('rm {}'.format(' '.join(files_to_clean)))
            if not cleanup:
                failures += 1
                stdout_msg(
                    'Could not cleanup files! ({})'.format(files_to_clean),
                    nok=True
                )
            else:
                stdout_msg('Purged all handler files!', ok=True)
        return False if failures else True

    def setup(self, *args, **kwargs):
        log.debug('')
        create_tmp_files = shell(
            'touch {} {} &> /dev/null'.format(self.state_file, self.report_file)
        )
        return create_tmp_files

# CODE DUMP


