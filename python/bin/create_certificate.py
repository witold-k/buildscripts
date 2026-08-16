#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import certificatehelper

cert = certificatehelper.Certificate()
cert.generate_root()
cert.generate_child()
