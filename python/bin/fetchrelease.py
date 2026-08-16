#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import gittools

url    = sys.argv[1]
dir    = sys.argv[2]
branch = sys.argv[3]

g = gittools.Git(url, dir)
g.cloneSingleBranch(branch)
