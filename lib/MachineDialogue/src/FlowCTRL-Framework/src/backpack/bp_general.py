import os
import logging

from .bp_shell import shell_cmd as shell

log = logging.getLogger('FlowCTRL')

# GENERAL


#@pysnooper.snoop()
def write2file(*args, file_path=str(), mode='w', **kwargs):
    log.debug('')
    if not os.path.exists(file_path):
        shell('touch {}'.format(file_path))
    with open(file_path, mode, encoding='utf-8', errors='ignore') \
            as active_file:
        content = ''
        for line in args:
            content = content + str(line) + '\n'
        for line_key in kwargs:
            content = content + str(line_key) + '=' + str(kwargs[line_key]) + '\n'
        try:
            active_file.write(content)
        except UnicodeError as e:
            log.error(e)
            return False
    log.debug('Wrote to file ({}):\n\n{}'. format(file_path, content))
    return True


def clear_screen(silence=False):
    log.debug('')
    if silence:
        return False
    return os.system('cls' if os.name == 'nt' else 'clear')


def stdout_msg(message, silence=False, red=False, info=False, warn=False,
               err=False, done=False, bold=False, green=False, ok=False, nok=False):
    if red:
        display_line = '\033[91m' + str(message) + '\033[0m'
    elif green:
        display_line = '\033[1;32m' + str(message) + '\033[0m'
    elif ok:
        log.info(message)
        display_line = '[ ' + '\033[1;32m' + 'OK' + '\033[0m' + ' ]: ' \
            + '\033[92m' + str(message) + '\033[0m'
    elif nok:
        log.warning(message)
        display_line = '[ ' + '\033[91m' + 'NOK' + '\033[0m' + ' ]: ' \
            + '\033[91m' + str(message) + '\033[0m'
    elif info:
        log.info(message)
        display_line = '[ INFO ]: ' + str(message)
    elif warn:
        log.warning(message)
        display_line = '[ ' + '\033[91m' + 'WARNING' + '\033[0m' + ' ]: ' \
            + '\033[91m' + str(message) + '\x1b[0m'
    elif err:
        log.error(message)
        display_line = '[ ' + '\033[91m' + 'ERROR' + '\033[0m' + ' ]: ' \
            + '\033[91m' + str(message) + '\033[0m'
    elif done:
        log.info(message)
        display_line = '[ ' + '\x1b[1;34m' + 'DONE' + '\033[0m' + ' ]: ' \
            + str(message)
    elif bold:
        log.info(message)
        display_line = '\x1b[1;37m' + str(message) + '\x1b[0m'
    else:
        log.info(message)
        display_line = message
    if silence:
        return False
    print(display_line)
    return True

