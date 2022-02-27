import os
import stat
import logging

log = logging.getLogger('FlowCTRL')

# CHECKERS


def check_is_fifo(fifo_path):
    log.debug('')
    try:
        return stat.S_ISFIFO(os.stat(fifo_path).st_mode)
    except Exception as e:
        log.error(e)
        return None


def check_file_exists(file_path):
    log.debug('')
    try:
        return os.path.exists(file_path)
    except Exception as e:
        log.error(e)
        return None


