#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
print("added python path: " + str(path))
sys.path.insert(1, str(path))


class BuildpathsTest:

    def findRoot(self):
        import buildpaths
        root = buildpaths.Buildpaths.findRoot(__file__)
        if root is None:
            raise Exception("failed: root")

    def isGitlab(self):
        import buildpaths
        bp = buildpaths.Buildpaths("/home/xye/gitlab/project/src/test")
        gl = bp.isGitlab()
        if not gl:
            raise Exception("failed: should be gitlab")
        bp = buildpaths.Buildpaths("/home/xye/project/src/test")
        gl = bp.isGitlab()
        if gl:
            raise Exception("failed: should not be gitlab")

    def getProductDir(self):
        import buildpaths
        bp = buildpaths.Buildpaths("/home/xye/gitlab/project/src/test")
        pd = bp.getProductDir()
        if pd != "/home/xye/gitlab/project/build":
            raise Exception("failed: wrong gilab product path: " + pd)
        bp = buildpaths.Buildpaths("/home/xye/project/src/test")
        pd = bp.getProductDir()
        if pd != "/home/xye/.products/project":
            raise Exception("failed: wrong local product path: " + pd)


test = BuildpathsTest()
test.findRoot()
test.isGitlab()
test.getProductDir()
