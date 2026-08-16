"""
build path detection
"""

import os


class Buildpaths:

    def __init__(self, file):
        # use __file__ to pass current file
        dir = Buildpaths.findRoot(file)
        self.dir = dir
        if dir is None:
            raise Exception("can not find root: " + file)
        self.home_index = Buildpaths.find_nth(dir, '/', 3)

    @staticmethod
    def findRoot(path):
        import pathlib
        p = pathlib.Path(path).resolve()

        while (len(p.parts) > 2):
            pa = p.parts
            if pa[-1] == "src" or pa[-1] == "main":
                return str(p.parent)
            isroot = p.joinpath("src").is_dir() or p.joinpath("main").is_dir() or \
                p.joinpath(".git").is_dir()
            if (isroot):
                return str(p)
            p = p.parent
        return None

    def isGitlab(self):
        if self.dir is not None:
            if "/gitlab/" in self.dir:
                return True
            else:
                return False
        else:
            return False

    def useBitbake(self):
        import os.path
        if self.dir is not None:
            if os.path.isdir(self.dir + '/bitbake'):
                return True
            else:
                return False
        else:
            return False

    def getUpperBitbakeProductDir(self, bitbake_project, arch):
        import pathutils
        work = pathutils.find_subdir(self.dir, bitbake_project + '/build/tmp/work')
        project_name = os.path.basename(self.dir)
        if arch is not None and arch != '':
            return work + '/' + project_name + '-' + arch + '-1.0-r0/build'
        else:
            return work + '/' + project_name + '-1.0-r0/build'

    def getBitbakeProductDir(self, bitbake_project):
        return self.dir + '/' + bitbake_project + '/build/tmp/rootfs'

    def getProductDir(self, bitbake_project):
        import os
        # fist bitbake, since the directory is the same in gitlab and local
        if self.useBitbake():
            return self.getBitbakeProductDir(bitbake_project)
        if self.isGitlab():
            return self.dir + '/build'
        else:
            use_dirty_repository_builddir = os.getenv('DIRTY_REPOSITORY_BUILDDIR')
            if use_dirty_repository_builddir is not None:
                return self.dir + '/build'
            else:
                home_dir = self.dir[0:self.home_index]
                rel_dir  = self.dir[self.home_index:len(self.dir)]
                return home_dir + '/.products' + rel_dir

    @staticmethod
    def find_nth(haystack, name, n):
        start = haystack.find(name)
        while start >= 0 and n > 1:
            start = haystack.find(name, start + len(name))
            n -= 1
        return start

    def __str__(self):
        return str(self.home_index) + "@" + self.dir
