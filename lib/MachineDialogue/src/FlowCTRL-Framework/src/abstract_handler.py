import logging
import os
import datetime
#import pysnooper

from abc import ABC

from .backpack.bp_convertors import json2dict
from .backpack.bp_general import write2file
from .backpack.bp_shell import shell_cmd as shell
from .backpack.bp_checkers import check_file_exists
from .validator import Validator

log = logging.getLogger('FlowCTRL')


class Handler(ABC):

    instruction_set = None
    state_flag = False
    state_file = str()
    validator = Validator()

    def __init__(self, *args, **kwargs):
        log.debug('')
        self.instruction_set = kwargs.get('instruction_set')

    def fetch_instruction(self):
        log.debug('')
        return self.instruction_set

#   @pysnooper.snoop()
    def set_instruction(self, instruction_set):
        log.debug('')
        if not self.validator.check_instruction(instruction_set):
            return False
        self.instruction_set = instruction_set
        return True

#   @pysnooper.snoop()
    def fetch_state(self, state='flag'):
        log.debug('')
        if not os.path.exists(self.state_file):
            return False if state != 'action' else str()
        content = []
        with open(self.state_file, 'r') as fl:
            content = [item.strip('\n') for item in fl.readlines()]
        if not len(content):
            return False if state != 'action' else str()
        segmented_record = content[0].split(',')
        return segmented_record[0] if state == 'action' else True

#   @pysnooper.snoop()
    def update_state_record(self, column_no, value):
        log.debug('')
        if not check_file_exists(self.state_file):
            record = [''] * 5
        else:
            with open(self.state_file, 'r') as fl:
                record = fl.readlines()
                if record:
                    record = record[0].split(',')
                else:
                    record = [''] * 5
        record[column_no] = value
        record[4] = str(datetime.datetime.now())
        return write2file(','.join(record), file_path=self.state_file, mode='w')

#   @pysnooper.snoop()
    def set_state(self, state_flag, action_label):
        log.debug('')
        self.state_flag = state_flag
        if not state_flag:
            shell('rm {}'.format(self.state_file))
            return True
        return self.update_state_record(0, action_label)

#   @pysnooper.snoop()
    def load(self, json_file):
        log.debug('')
        converted = json2dict(json_file)
        if not json_file or not converted:
            return False
        self.update_state_record(1, json_file)
        self.set_instruction(json2dict(json_file))
        return self.instruction_set

    def start(self):
        pass

    def stop(self):
        pass

    def cont(self):
        pass

    def purge(self):
        pass

    def setup(self):
        pass

# CODE DUMP

