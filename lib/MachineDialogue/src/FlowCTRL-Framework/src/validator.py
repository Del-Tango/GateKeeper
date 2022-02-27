import logging
import os
#import pysnooper

log = logging.getLogger('FlowCTRL')


class Validator():

    def __print__(self, *args, **kwargs):
        return 'Validator: {}'.format(self.__dict__)

#   @pysnooper.snoop()
    def check_instruction(self, instruction_set):
        log.debug('')
        valid_flag = False
        # List containing procedure sketch file paths received via CLI args
        if isinstance(instruction_set, list):
            valid_files = [
                file_path for file_path in instruction_set
                if isinstance(file_path, str) and os.path.exists(file_path)
            ]
            if valid_files:
                valid_flag = True
        # Stage or action dictionary loaded from JSON sketch file
        elif isinstance(instruction_set, dict):
            if instruction_set:
                valid_flag = True
        return valid_flag

#   @pysnooper.snoop()
    def check_state(self, state, previous_action_label, action_label):
        log.debug('')
        action_labels = {
            'start': self.validate_state_action_start,
            'stop': self.validate_state_action_stop,
            'pause': self.validate_state_action_pause,
            'resume': self.validate_state_action_resume,
        }
        if action_label not in action_labels.keys():
            return False
        return action_labels[action_label](
            state, previous_action_label, action_label
        )

#   @pysnooper.snoop()
    def validate_state_action_start(self, state, previous_action_label,
                                    action_label):
        log.debug('')
        if not state and not previous_action_label:
            return True
        return False if previous_action_label not in ('purged', '') else True

#   @pysnooper.snoop()
    def validate_state_action_stop(self, state, previous_action_label,
                                   action_label):
        log.debug('')
        return False if previous_action_label \
            not in ('started', 'resumed') else True

#   @pysnooper.snoop()
    def validate_state_action_pause(self, state, previous_action_label,
                                    action_label):
        log.debug('')
        return self.validate_state_action_stop(
            state, previous_action_label, action_label
        )

#   @pysnooper.snoop()
    def validate_state_action_resume(self, state, previous_action_label,
                                     action_label):
        log.debug('')
        return False if previous_action_label != 'paused' else True

