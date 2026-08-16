#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import buildpaths

print(buildpaths.Buildpaths.findRoot(__file__))
