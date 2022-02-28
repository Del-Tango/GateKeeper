#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# FILTERS

import os
import stat
import logging

log = logging.getLogger('GateKeeper')


def filter_file_name_from_path(file_path):
    log.debug('')
    return os.path.basename(file_path)


def filter_directory_from_path(file_path):
    log.debug('')
    return os.path.dirname(file_path)




