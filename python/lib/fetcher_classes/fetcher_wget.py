import subprocess
import fileutils as fu
import fetcher_classes.fetcherentry as fe


class FetcherWget:
    def __init__(self, dir: str):
        self.dir = dir

    def fetch(self, entry, doCleanUp=True, doUpdate=False):
        print('not implemented')

    def scan(self, clonedir, dir):
        print('not implemented')
