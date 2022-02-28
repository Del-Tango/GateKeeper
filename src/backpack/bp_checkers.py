#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# CHECKERS

import os
import stat
import logging

log = logging.getLogger('GateKeeper')


def check_superuser():
    log.debug('')
    return False if os.geteuid() != 0 else True


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


