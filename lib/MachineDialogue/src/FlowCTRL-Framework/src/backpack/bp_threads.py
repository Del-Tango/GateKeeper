#!/usr/bin/python3
#
# Regards, the Alveare Solutions #!/Society -x
#
# THREADZ

import threading
import logging

log = logging.getLogger('')


def threadify(function_obj, *args, join=False, **kwargs):
    log.info(
        'Threadifying function ({}) - Args: {}, Join: {}, Kwargs: {}'.format(
            function_obj, args, join, kwargs
        )
    )
    func_thread = threading.Thread(target=function_obj, args=args)
    try:
        func_thread.start()
        if join:
            func_thread.join()
    except Exception as e:
        log.error(e)
        return False
    log.info('Function threadified! ({})'.format(func_thread))
    return func_thread


