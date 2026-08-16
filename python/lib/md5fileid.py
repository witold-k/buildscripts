"""
Classes for (almost) unambiguous file content identification
"""

import hashlib, os


class MD5FileId:

    def __init__(self):
        self.size   = 0
        self.md5int = 0
        self.md5    = hashlib.md5(b'')
        self.path   = ''

    @staticmethod
    def for_filename(name):
        fi = MD5FileId()
        fi.size = os.path.getsize(name)
        with open(name, 'rb') as file_to_check:
            data     = file_to_check.read()
            fi.md5 = hashlib.md5(data)
        hd = fi.md5.hexdigest()
        fi.md5int = int(hd, 16)
        fi.path   = os.path.realpath(name)
        return fi

    def __eq__(self, other):
        return (self.size == other.size) and (self.md5int == other.md5int) and (self.path == other.path)

    def __ne__(self, other):
        return (self.size != other.size) or (self.md5int != other.md5int) or (self.path != other.path)

    def __lt__(self, other):
        if self.size < other.size:
            return True
        elif self.size > other.size:
            return False
        else:
            if self.md5int < other.md5int:
                return True
            elif self.md5int > other.md5int:
                return False
            else:
                return self.path < other.path

    def __le__(self, other):
        if self.size < other.size:
            return True
        elif self.size > other.size:
            return False
        else:
            if self.md5int < other.md5int:
                return True
            elif self.md5int > other.md5int:
                return False
            else:
                return self.path <= other.path

    def __gt__(self, other):
        if self.size < other.size:
            return False
        elif self.size > other.size:
            return True
        else:
            if self.md5int < other.md5int:
                return False
            elif self.md5int > other.md5int:
                return True
            else:
                return self.path > other.path

    def __ge__(self, other):
        if self.size < other.size:
            return False
        elif self.size > other.size:
            return True
        else:
            if self.md5int < other.md5int:
                return False
            elif self.md5int > other.md5int:
                return True
            else:
                return self.path >= other.path

    def __str__(self) -> str:
        return '{:15d} {} {}'.format(self.size, self.md5.hexdigest(), self.path)


class MD5FileIdList:
    def __init__(self):
        self.entrylist = []

    @staticmethod
    def for_filearray(filearray):
        fil = MD5FileIdList()
        fil.entrylist = []
        while filearray:
            remainarray = []
            for name in filearray:
                if os.path.isfile(name):
                    e = MD5FileId.for_filename(name)
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
