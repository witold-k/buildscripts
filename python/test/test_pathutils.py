#!/usr/bin/python3

import pathutils
import sys
from pathlib import Path


class PathUtilsTest:

    def remove_duplicates(self):
        path = ["123", "123", "456"]
        rpath = pathutils.remove_duplicates(path)
        if len(rpath) != 2:
            raise Exception("invalid length: " + str(len(rpath)))
        if rpath[0] != "123":
            raise Exception("invalid value: " + rpath[0])
        if rpath[1] != "456":
            raise Exception("invalid value: " + rpath[1])

        path = ["123", "123", "456", "456"]
        rpath = pathutils.remove_duplicates(path)
        if len(rpath) != 2:
            raise Exception("invalid length: " + str(len(rpath)))
        if rpath[0] != "123":
            raise Exception("invalid value: " + rpath[0])
        if rpath[1] != "456":
            raise Exception("invalid value: " + rpath[1])

    def files2path(self):
        files = ["abc/de/f.so", "abc/de/g.so", "abc/ef/c.so"]
        path  = pathutils.files2path(files)
        if len(path) != 2:
            raise Exception("invalid length: " + str(len(path)))
        if path[0] != "abc/de":
            raise Exception("invalid value: " + path[0])
        if path[1] != "abc/ef":
            raise Exception("invalid value: " + path[1])

    def path2str(self):
        import pathutils
        path = ["abc/de", "abc/ef"]
        pathstr = pathutils.path2str(path)
        if pathstr != "abc/de:abc/ef":
            raise Exception("invalid: " + pathstr)


if __name__ == "__main__":
    path = Path(__file__ + '/../../python').resolve()
    print("added python path: " + str(path))
    sys.path.insert(1, str(path))
    t = PathUtilsTest()
    t.remove_duplicates()
    t.files2path()
    t.path2str()
