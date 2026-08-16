import subprocess
import fileutils as fu
import fetcher_classes.fetcherentry as fe


class FetcherHg:
    def __init__(self, dir: str):
        self.dir = dir

    def fetch(self, entry, doCleanUp=True, doUpdate=False):
        p = None
        clonedir = self.dir + '/' + entry.dir
        if fu.removed_empty_dir(clonedir):
            str = 'hg clone ' + entry.url + ' ' + clonedir
            p = subprocess.Popen(str, shell=True, cwd=self.dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            fu.finish_process(p)
            if entry.freeze:
                str = 'hg update ' + entry.commit
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                fu.finish_process(p)
        else:
            if doCleanUp:
                str = 'hg purge --all'
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                fu.finish_process(p)
                str = 'hg up -C'
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                fu.finish_process(p)
            str = 'hg update '  + entry.branch
            p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            fu.finish_process(p)
            str = 'hg fetch'
            p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            fu.finish_process(p)
            if not doUpdate and entry.freeze:
                str = 'hg update ' + entry.commit
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                fu.finish_process(p)
            if doUpdate and not entry.freeze:
                str = 'hg pull'
                p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                fu.finish_process(p)

    def scan(self, clonedir, dir):
        ret = fe.FetcherEntry()
        ret.dir    = dir
        ret.tool   = fe.FetcherTool.HG
        ret.freeze = False
        str = 'hg paths default'
        p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ret.url = fu.get_line_from_process(p)
        str = "hg branch"
        p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ret.branch = fu.get_line_from_process(p)
        str = "hg parent --template '{node}'"
        p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ret.commit = fu.get_line_from_process(p)
        return ret
