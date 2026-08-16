#!/usr/bin/python3

import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib').resolve()
sys.path.append(str(path))

import gittools

git = gittools.Git.for_dir(sys.argv[1])
git.recreate()
