#!/usr/bin/python3

import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib').resolve()
sys.path.append(str(path))

import gittools

if len(sys.argv) < 2:
    git = gittools.Git.for_dir('.')
else:
    git = gittools.Git.for_dir(sys.argv[1])
print(str(git.has_new_tag()))
