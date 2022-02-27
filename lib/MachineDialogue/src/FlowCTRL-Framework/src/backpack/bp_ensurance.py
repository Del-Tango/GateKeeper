import logging

from os import path, makedirs, mkfifo

log = logging.getLogger('FlowCTRL')

# ENSURANCE


def ensure_fifo_exists(*args):
    log.debug('')
    failures = 0
    for fifo_path in args:
        try:
            mkfifo(fifo_path)
        except OSError as e:
            log.error(e)
            failures += 1
    return False if failures else True


def ensure_files_exist(*args):
    log.debug('')
    for file_path in args:
        with open(file_path, 'w', encoding='utf-8', errors='ignore'):
            pass
    return True


def ensure_directories_exist(*args):
    log.debug('')
    failures = 0
    for dir_path in args:
        try:
            makedirs(dir_path)
        except OSError as e:
            log.error(e)
            failures += 1
    return False if failures else True



