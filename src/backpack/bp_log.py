#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# LOGGING

import logging


#@pysnooper.snoop()
def log_init(file_path, log_format, timestamp_format, debug_mode, log_name=__name__):
    log = logging.getLogger(log_name)
    try:
        if debug_mode:
            log.setLevel(logging.DEBUG)
        else:
            log.setLevel(logging.INFO)
        file_handler = logging.FileHandler(file_path, 'a')
        formatter = logging.Formatter(log_format, timestamp_format)
        file_handler.setFormatter(formatter)
        log.addHandler(file_handler)
    finally:
        return log


