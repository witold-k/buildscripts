"""
Classes for (almost) unambiguous file and its content identification
"""

import os


class TimeFileId:
    def __init__(self):
        self.size    = 0
        self.time    = 0
        self.path    = ''

    @staticmethod
    def for_filename(name):
        fi = TimeFileId()
        fi.size = os.path.getsize(name)
        fi.time = os.path.getmtime(name)
        fi.path = os.path.realpath(name)
        return fi

    def __lt__(self, other):
        if self.size < other.size:
            return True
        elif self.size > other.size:
            return False
        else:
            if self.time < other.time:
                return True
            elif self.time > other.time:
                return False
            else:
                return self.path < other.path

    def __le__(self, other):
        if self.size < other.size:
            return True
        elif self.size > other.size:
            return False
        else:
            if self.time < other.time:
                return True
            elif self.time > other.time:
                return False
            else:
                return self.path <= other.path

    def __eq__(self, other):
        return (self.size == other.size) and (self.time == other.time) and (self.path == other.path)

    def __ne__(self, other):
        return (self.size != other.size) or (self.time != other.time) or (self.path != other.path)

    def __gt__(self, other):
        if self.size < other.size:
            return False
        elif self.size > other.size:
            return True
        else:
            if self.time < other.time:
                return False
            elif self.time > other.time:
                return True
            else:
                return self.path > other.path

    def __ge__(self, other):
        if self.size < other.size:
            return False
        elif self.size > other.size:
            return True
        else:
            if self.time < other.time:
                return False
            elif self.time > other.time:
                return True
            else:
                return self.path >= other.path

    def __str__(self) -> str:
        return '{:15d} {:f} {}'.format(self.size, self.time, self.path)

# -----------------------------------------------------------------------------


class TimeFileIdList:
    def __init__(self):
        self.entrylist = []

    @staticmethod
    def for_filearray(filearray):
        fil = TimeFileIdList()
        fil.entrylist = []
        while filearray:
            remainarray = []
            for name in filearray:
                if os.path.isfile(name):
                    e = TimeFileId.for_filename(name)
                    fil.entrylist.append(e)
                elif os.path.isdir(name):
                    entries = os.scandir(name)
                    for e in entries:
                        remainarray.append(name + '/' + e.name)
            filearray = remainarray
        fil.entrylist.sort()
        return fil

    def save(self, filename):
        with open(filename, 'w') as f:
            for e in self.entrylist:
                f.write(str(e) + '\n')
