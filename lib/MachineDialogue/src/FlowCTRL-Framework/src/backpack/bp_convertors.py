import json
import logging
import os

log = logging.getLogger('FlowCTRL')

# CONVERTORS


def json2dict(file_path):
    if not file_path or not os.path.exists(file_path):
        log.warning('File not found! ({})'.format(file_path))
        return {}
    with open(file_path, 'r') as fl:
        converted = json.load(fl)
    log.debug('Converted JSON: ({})'.format(converted))
    return converted

def dict2json(dict_obj):
    if not dict_obj:
        log.warning('No data to convert! ({})'.format(dict_obj))
        return {}
    converted = json.dumps(dict_obj, indent=4)
    log.debug('Converted JSON: ({})'.format(converted))
    return converted

def file2list(file_path):
    if not file_path or not os.path.exists(file_path):
        log.warning('File not found! ({})'.format(file_path))
        return {}
    with open(file_path, 'r') as fl:
        converted = fl.readlines()
    log.debug('Lines read from file: ({})'.format(converted))
    return converted
