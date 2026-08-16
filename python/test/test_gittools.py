#!/usr/bin/python3

import sys
from pathlib import Path
root = str(Path(__file__ + '/../../').resolve())
path = root + '/bin'
print("added python path: " + str(path))
sys.path.insert(1, str(path))

import gittools


class GitToolsTest:
    def __init__(self, root):
        self.root = root
        self.git = gittools.Git.for_dir(self.root)

    def inittest(self):
        url = self.git.url
        if url is None:
            raise Exception("invalid url: (none)")
        else:
            if 'buildscripts' not in url:
                raise Exception("invalid url: " + url)

    def show_tags(self):
        print('TAGS: ' + str(self.git.get_taglist()))

    def show_origin_url(self):
        print('ORIGIN: ' + str(self.git.get_origin_url()))

    def show_origin_name(self):
        print('ORIGIN: ' + str(self.git.get_origin_name()))

    def show_ahead_count(self):
        print('COUNT: ' + str(self.git.get_ahead_count()))

    def __str__(self):
        return str(self.git)


t = GitToolsTest(root)
print(t)
t.inittest()
t.show_tags()
t.show_origin_url()
t.show_origin_name()
t.show_ahead_count()
