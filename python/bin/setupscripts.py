#!/usr/bin/python3

# standalone scripts for clone/copy setup this buildscripts repository
# this scripts should not use any external python modules or modules
import os
import shutil


class SetupScripts:

    def __init__(self):
        self.root   = SetupScripts.findRoot(__file__)
        self.branch = "master"
        self.url    = "svnuser@naspi:svn/buildscripts"
        self.subdir = "buildscripts"

    @staticmethod
    def findRoot(path):
        import pathlib
        p = pathlib.Path(path).resolve()

        while (len(p.parts) > 2):
            pa = p.parts
            if pa[-1] == "src" or pa[-1] == "main":
                return str(p.parent)
            isroot = p.joinpath("src").is_dir() or p.joinpath("main").is_dir() or p.joinpath(".git").is_dir()
            if (isroot):
                return str(p)
            p = p.parent
        return None

    def findBuildScripts(self):
        import pathlib
        p = pathlib.Path(self.root).resolve().parent

        while (len(p.parts) > 2):
            pb = p.joinpath("buildscripts")
            if pb.is_dir():
                return str(pb)
            p = p.parent
        return None

    @staticmethod
    def removed_empty_dir(dir):
        import os
        if not os.path.isdir(dir):
            return True

        entries = os.listdir(dir)
        if len(entries) == 0:
            os.rmdir(dir)
            return True
        else:
            return False

    @staticmethod
    def finish_process(p):
        lines = p.stdout.readlines()
        retval = p.wait()
        p.stdout.close()
        if (retval):
            for line in lines:
                print(line.decode('utf-8').rstrip())
        else:
            for line in lines:
                print(line.decode('utf-8').rstrip())

    def updategit(self, doCleanUp=False):
        import subprocess
        clonedir = self.root + '/' + self.subdir
        if SetupScripts.removed_empty_dir(clonedir):
            str = 'git clone -b ' + self.branch + ' ' + self.url + ' ' + clonedir
            p = subprocess.Popen(str, shell=True, cwd=self.root, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            SetupScripts.finish_process(p)
            str = 'git checkout ' + self.branch
            p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            SetupScripts.finish_process(p)
        else:
            if doCleanUp:
                str = 'git clean -xdf'
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                SetupScripts.finish_process(p)
                str = 'git checkout .'
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                SetupScripts.finish_process(p)
            str = 'git checkout '  + self.branch
            p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            SetupScripts.finish_process(p)
            str = 'git pull'
            p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            SetupScripts.finish_process(p)

    def createlink(self):
        scriptdir = self.root + '/' + self.subdir
        if not os.path.islink(scriptdir):
            dir = self.findBuildScripts()
            if dir is not None:
                if os.path.isdir(scriptdir):
                    shutil.rmtree(scriptdir)
                os.symlink(dir, scriptdir)

    def setup(self):
        self.createlink()
        self.updategit()


SetupScripts().setup()
