#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import fetcher

cmd = sys.argv[1]
for dir in sys.argv[2:]:
    if cmd == 'fetch':
        fetcher.FetcherCommand.sync(dir, '')
    if cmd == 'save':
        fetcher.FetcherCommand.save_to(dir)
    if cmd == 'update':
        fetcher.FetcherCommand.sync(dir, 'update')
