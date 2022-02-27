#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# FETCHERS

import time
import logging

log = logging.getLogger('FloodGateHEAD')


def fetch_time():
    log.debug('')
    return time.strftime('%H:%M:%S')


def fetch_full_time():
    log.debug('')
    return time.strftime('%H:%M:%S, %A %b %Y')
