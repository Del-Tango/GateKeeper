import string
import random
import logging

log = logging.getLogger('FlowCTRL')

# GENERATORS


def generate_msg_id(id_length, id_characters=list(string.ascii_letters + string.digits)):
    log.debug('')
    random.shuffle(id_characters)
    spl_msg_id = [random.choice(id_characters) for i in range(id_length)]
    random.shuffle(spl_msg_id)
    return ''.join(spl_msg_id)
