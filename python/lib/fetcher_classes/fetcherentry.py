import os
from enum import Enum


class FetcherTool(Enum):
    UNKNOWN = 0,  # UNKNOWN
    DIR     = 1,  # DIRECTORY
    GIT     = 2,  # GIT
    SVN     = 3,  # SUBVERSION
    HG      = 4,  # MERCURIAL
    WGET    = 5,  # wget
    RSYNC   = 6,  # rsync

    @staticmethod
    def from_cmd(cmd):
        if cmd == '.':
            return FetcherTool.DIR
        if cmd == 'git':
            return FetcherTool.GIT
        if cmd == 'hg':
            return FetcherTool.HG
        if cmd == 'svn':
            return FetcherTool.SVN
        if cmd == 'wget':
            return FetcherTool.WGET
        if cmd == 'rsync':
            return FetcherTool.RSYNC
        return FetcherTool.UNKNOWN

    @staticmethod
    def from_dir(dir):
        if os.path.isdir(dir + '/.git'):
            return FetcherTool.GIT
        if os.path.isfile(dir + '/.git'):
            return FetcherTool.GIT
        if os.path.isdir(dir + '/.hg'):
            return FetcherTool.HG
        if os.path.isdir(dir + '/.svn'):
            return FetcherTool.SVN
        return FetcherTool.UNKNOWN

    def cmd(self):
        if self == FetcherTool.DIR:
            return '.'
        if self == FetcherTool.GIT:
            return 'git'
        if self == FetcherTool.SVN:
            return 'svn'
        if self == FetcherTool.HG:
            return 'hg'
        if self == FetcherTool.WGET:
            return 'wget'
        if self == FetcherTool.RSYNC:
            return 'rsync'
        return '(None)'


class FetcherToolSubType(Enum):
    NONE          = 0,  # UNKNOWN
    HAS_SUBMODULE = 1,  # git submodules
    BZ            = 2,  # .tar.bz
    BZ2           = 3,  # .tar.bz2
    GZ            = 4,  # .tar.gz
    XZ            = 5,  # .tar.xz

    @staticmethod
    def from_filename(cmd):
        if '.tar.bz2' in cmd:
            return FetcherToolSubType.BZ2
        if '.tar.bz' in cmd:
            return FetcherToolSubType.BZ
        if '.tar.gz' in cmd:
            return FetcherToolSubType.GZ
        if '.tar.xz' in cmd:
            return FetcherToolSubType.XZ
        return FetcherToolSubType.NONE

    def cmd(self):
        if self == FetcherToolSubType.NONE:
            return '(None)'
        if self == FetcherToolSubType.HAS_SUBMODULE:
            return 'has submodules'
        if self == FetcherToolSubType.BZ:
            return 'tar.bz'
        if self == FetcherToolSubType.BZ2:
            return 'tar.bz2'
        if self == FetcherToolSubType.GZ:
            return 'tar.gz'
        if self == FetcherToolSubType.XZ:
            return 'tar.xz'
        return '(None)'


class FetcherEntry:
    def __init__(self):
        self.url     = ''
        self.tool    = FetcherTool.GIT
        self.branch  = ''
        self.commit  = ''
        self.dir     = ''
        self.freeze  = False
        self.recurse_submodules = False

    def __str__(self):
        return self.toJson()

    def __lt__(self, other):
        if self.dir < other.dir:
            return True
        elif self.dir > other.dir:
            return False
        else:
            if self.url < other.url:
                return True
            elif self.url > other.url:
                return False
            else:
                if self.branch < other.branch:
                    return True
                elif self.branch > other.branch:
                    return False
                else:
                    return self.commit < other.commit

    def __le__(self, other):
        if self.dir < other.dir:
            return True
        elif self.dir > other.dir:
            return False
        else:
            if self.url < other.url:
                return True
            elif self.url > other.url:
                return False
            else:
                if self.branch < other.branch:
                    return True
                elif self.branch > other.branch:
                    return False
                else:
                    return self.commit <= other.commit

    def __eq__(self, other):
        return (self.dir == other.dir) and (self.url == other.url) and (self.branch == other.branch) and (self.commit == other.commit)

    def __ne__(self, other):
        return (self.dir != other.dir) or (self.url != other.url) or (self.branch != other.branch) or (self.commit != other.commit)

    def __gt__(self, other):
        if self.dir < other.dir:
            return False
        elif self.dir > other.dir:
            return True
        else:
            if self.url < other.url:
                return False
            elif self.url > other.url:
                return True
            else:
                if self.branch < other.branch:
                    return False
                elif self.branch > other.branch:
                    return True
                else:
                    return self.commit > other.commit

    def __ge__(self, other):
        if self.dir < other.dir:
            return False
        elif self.dir > other.dir:
            return True
        else:
            if self.url < other.url:
                return False
            elif self.url > other.url:
                return True
            else:
                if self.branch < other.branch:
                    return False
                elif self.branch > other.branch:
                    return True
                else:
                    return self.commit >= other.commit

    @staticmethod
    def fromJson(js):
        ret = FetcherEntry()
        ret.url     = js['url']
        ret.tool    = FetcherTool.from_cmd(js['tool'])
        ret.branch  = js['branch']
        ret.commit  = js['commit']
        ret.dir     = js['dir']
        ret.freeze  = js['freeze']
        ret.recurse_submodules = False
        if 'sm' in js:
            key = js['sm']
            ret.recurse_submodules = (key == 'true')
        return ret

    def toJson(self):
        return '{' \
            '"dir": "' + (self.dir if self.dir is not None else '(None)') + \
            '", "url": "' + (self.url if self.url is not None else '(None)') + \
            '", "tool": "' + self.tool.cmd() + \
            '", "branch": "' + (self.branch if self.branch is not None else '(None)') + \
            '", "commit": "' + (self.commit if self.commit is not None else '(None)') + \
            '", "freeze": ' + ('true' if self.freeze else 'false') + \
            ', "sm": ' + ('true' if self.recurse_submodules else 'false') + \
            '}'
