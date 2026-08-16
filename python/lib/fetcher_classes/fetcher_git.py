import os, subprocess, buildjobs
import fileutils as fu, gittools
import fetcher_classes.fetcherentry as fe


class FetcherGit:
    def __init__(self, dir: str):
        self.dir = dir

    def fetch(self, entry: fe.FetcherEntry, doCleanUp=True, doUpdate=False):
        clonedir = self.dir + '/' + entry.dir
        basedir  = os.path.dirname(clonedir)
        git = gittools.Git(entry.url, clonedir, None, entry.branch)
        lines = []

        if not os.path.isdir(basedir):
            os.makedirs(basedir)

        if fu.removed_empty_dir(clonedir):
            git.clone()
            if entry.freeze:
                lines.append('## CHECKOUT')
                cmd = ['git', 'checkout', entry.commit]
                bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
                _, _, _ = bj.run_to_lines(lines, lines)
        else:
            lines.append("## FETCH: " + entry.branch + "@" + entry.url)

            cmd = ['git', 'fetch']
            bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
            _, _, _ = bj.run_to_lines(lines, lines)

            if doCleanUp:
                git.clean()

            cmd = ['git', 'checkout', entry.branch]
            bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
            _, _, _ = bj.run_to_lines(lines, lines)

            if not doUpdate and entry.freeze:
                cmd = ['git', 'checkout', entry.commit]
                bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
                _, _, _ = bj.run_to_lines(lines, lines)

            if doUpdate and not entry.freeze:
                if entry.recurse_submodules:
                    cmd = ['git', 'pull', '--recurse-submodules']
                else:
                    cmd = ['git', 'pull']

            bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
            _, _, _ = bj.run_to_lines(lines, lines)
        return lines

    def scan(self, clonedir, dir):
        ret = fe.FetcherEntry()
        ret.dir    = dir
        ret.tool   = fe.FetcherTool.GIT
        ret.freeze = False
        str = 'git ls-remote --get-url origin'
        p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ret.url = fu.get_line_from_process(p)
        str = "git rev-parse --abbrev-ref HEAD"
        p = subprocess.Popen(str, shell=True, cwd=clonedir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ret.branch = fu.get_line_from_process(p)
        str = "git rev-parse HEAD"
        cmd = ['git', 'rev-parse', "HEAD"]
        bj = buildjobs.DoProcess(cmd=cmd, cwd=clonedir)
        lines = []
        _, _, _ = bj.run_to_lines(lines, lines)
        ret.commit = lines[0]
        return ret
