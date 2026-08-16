"""
git tools
"""

import os, shutil, fileutils, buildjobs, keyvalue, subprocess


class GitConfig:
    def __init__(self, dirname):
        self.dir          = None
        self.filename     = None
        self.is_submodule = False
        self.read_from_dir(dirname)

    def read_from_dir(self, dirname):
        from pathlib import Path
        self.dir = str(Path(dirname).resolve())
        path = self.dir + '/.git'
        if os.path.isfile(path):
            kv = keyvalue.KeyValueMap(':')
            kv.readAssign(path)
            self.config_link = kv['gitdir']
            self.filename = str(Path(dirname + '/' + self.config_link + '/config').resolve())
            self.is_submodule = True
        else:
            self.config_link = None
            self.filename = path + '/config'
            self.is_submodule = False

    def write_link(self):
        if self.dir is not None and self.config_link is not None:
            filename = self.dir + '/.git'
            entry = 'gitdir: ' + self.config_link
            with open(filename, 'w') as file:
                file.write(entry + '\n')


class Git:
    @staticmethod
    def for_url(url):
        dir = Git.strip_git(os.path.basename(url))
        g = Git(url, dir, GitConfig(dir))
        return g

    @staticmethod
    def for_first_dir_in_with_name(dir, name):
        with os.scandir(dir) as it:
            for entry in it:
                if entry.is_dir():
                    other = Git.for_dir(entry.name)
                    url = os.path.dirname(other.url) + name + '.git'
                    return Git(url, name)
        return None

    @staticmethod
    def for_dir(dir):
        gitconfig = GitConfig(dir)
        url = None
        # in case it is an empty / new created directory
        if os.path.isfile(gitconfig.filename):
            map = keyvalue.KeyValueMap(delimitter='=')
            map.readAssign(gitconfig.filename)
            url = map['url']
        g = Git(url, dir, gitconfig)
        return g

    def __init__(self, url, dir, config=None, branch=None):
        from pathlib import Path
        self.url    = url
        self.dir    = str(Path(dir).resolve())
        self.config = config
        self.branch = branch

    def create(self):
        destdir = self.dir
        if os.path.isdir(destdir):
            if not fileutils.is_empty_dir(destdir):
                raise Exception('dir exists: - can not create ' + destdir)
        else:
            os.makedirs(destdir)

        cmd = ["git", "init", "--bare"]
        buildjobs.DoProcess(cmd, destdir).run()

    @staticmethod
    def strip_git(dirname):
        if dirname.endswith('.git') or dirname.endswith('.GIT'):
            return dirname[:-4]
        else:
            return dirname

    def clone(self, is_bare=False):
        destdir = self.dir
        if os.path.isdir(destdir):
            if fileutils.is_empty_dir(destdir):
                shutil.rmtree(destdir)
            else:
                raise Exception('dir exists: - can not clone ' + destdir)

        if self.branch is not None:
            cmd = ['git', 'clone', '-b', self.branch, self.url, os.path.basename(destdir)]
        else:
            if is_bare:
                cmd = ['git', 'clone', '--bare', self.url, os.path.basename(destdir)]
            else:
                cmd = ['git', 'clone', self.url, os.path.basename(destdir)]
        buildjobs.DoProcess(cmd=cmd, cwd=os.path.dirname(destdir)).run()
        if self.config is not None and self.config.is_submodule:
            config_dir = self.dir + '/.git'
            shutil.rmtree(config_dir)
            self.config.write_link()
            buildjobs.DoProcess(cmd='git checkout master', cwd=destdir).run()

    def get_taglist(self):
        cmd = ["git", "tag", "-l"]
        _, tags, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        filtered_tags = [string for string in tags if string]
        return filtered_tags

    def get_origin_url(self):
        cmd = ["git", "ls-remote", "--get-url", "origin"]
        _, origin, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        return origin[0]

    def get_origin_name(self):
        cmd = ["git", "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"]
        _, origin, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        return origin[0]

    def get_ahead_count(self):
        origin = self.get_origin_name()
        cmd = ["git", "rev-list", "--count", origin + '..HEAD']
        _, count, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        return int(count[0])

    def delete_local_tags(self):
        list = self.get_taglist()
        cmd = ["git", "tag", "-d", " ".join(list)]
        buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run()

    def fetch_tags(self):
        cmd = ["git", "fetch", "--tags", "--all"]
        buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run()

    def revision_of_tag(self, tag):
        cmd = ["git", "rev-parse", tag]
        buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run()

    def checkout(self):
        cmd = ['git', 'checkout', '.']
        buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run()

    def clean(self):
        lines = []
        cmd = ['git', 'rebase', '--abort']
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)

        cmd = ['git', 'merge', '--abort']
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)

        if self.branch is not None:
            cmd = ['git', 'reset', self.branch]
        else:
            cmd = ['git', 'reset', '.']
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)

        cmd = ['git', 'clean', '-xdf']
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)

        if self.branch is not None:
            cmd = ['git', 'checkout', self.branch]
            _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)
        cmd = ['git', 'checkout', '.']
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines(lines, lines)
        return lines

    def cloneSingleBranch(self, branch):
        destdir = self.dir + '/' + branch
        if not fileutils.is_empty_dir(destdir):
            return
        else:
            os.makedirs(destdir)

        cmd = ['git', 'clone', self.url, '--branch', branch, '--single-branch', destdir]
        buildjobs.DoProcess(cmd=cmd, cwd=destdir).run()

    def getRemoteCommit(self, branch):
        cmd = 'git ls-remote ' + self.url + ' ' + branch
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True, executable='/bin/bash')
        lines = p.stdout.readlines()
        _ = p.wait()
        commit = None
        for line in lines:
            linestr = line.decode('utf-8').rstrip()
            keyval  = linestr.split('\t', 1)
            commit  = keyval[0]
            break
        return commit

    def applyIf(self, checkfile, content, pathfile):
        if not fileutils.file_contains(checkfile, content):
            return

        self.apply(pathfile)

    def applyIfNot(self, checkfile, content, pathfile):
        if fileutils.file_contains(checkfile, content):
            return

        self.apply(pathfile)

    def apply(self, pathfile):
        cmd = 'git apply ' + pathfile
        p = subprocess.Popen(cmd, cwd=self.dir, stdout=subprocess.PIPE, shell=True, executable='/bin/bash')
        _ = p.stdout.readlines()
        retval = p.wait()
        if retval != 0:
            print("FAILED: " + cmd)

    def save(self, message):
        cmd = 'git add -A'
        buildjobs.DoExec(self.dir, cmd).run(True)
        cmd = 'git commit -m "' + message + '"'
        buildjobs.DoExec(self.dir, cmd).run(True)
        cmd = 'git push'
        buildjobs.DoExec(self.dir, cmd).run(True)

    def recreate(self):
        new_dir      = self.dir + '_new'
        new_bare_dir = self.dir + '_bare.git'
        save_dir     = self.dir + '_save'

        if (os.path.isdir(new_dir)):
            shutil.rmtree(new_dir)
        if (os.path.isdir(new_bare_dir)):
            shutil.rmtree(new_bare_dir)

        bare_git = Git(None, new_bare_dir, None)
        new_git  = Git('file://' + new_bare_dir, new_dir)
        bare_git.create()
        new_git.clone()
        self.copy_to(new_git)
        new_git.save('initial commit - recreated repository')
        shutil.rmtree(new_dir)
        cmd = 'rsync --ignore-times --delete -r ' + new_bare_dir + '/ ' + self.url + '/'
        buildjobs.DoExec(self.dir, cmd).run(True)

        shutil.rmtree(new_bare_dir)
        os.rename(self.dir, save_dir)
        self.clone()
        shutil.rmtree(save_dir)

    def has_new_tag(self):
        cmd = ['git', 'fetch', '--tag', '--all']
        buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run()

        cmd = ['git', 'rev-list', '--tags', '--max-count=1']
        _, latest, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()

        cmd = ['git', 'rev-parse', 'HEAD']
        _, current, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        return latest[0] == current[0]

    def copy_to(self, destination):
        fileutils.copy_files_except(self.dir, destination.dir, ['.git'], follow_symlinks=False)

    def __str__(self):
        if self.branch is None:
            return self.dir + ": " + self.url
        else:
            return self.dir + ": " + self.url + "&branch=" + self.branch
