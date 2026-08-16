#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import buildpaths
import librarypathparser
import pathutils

bp = buildpaths.Buildpaths(__file__)
proddir = bp.getUpperBitbakeProductDir()
cmcl = librarypathparser.CMakeCacheLibraries(proddir + "/native/CMakeCache.txt")
print(pathutils.path2str(cmcl.fetchPath()))
