import buildjobs
from pathlib import Path


class RipGrep:
    def __init__(self, dir):
        self.dir    = str(Path(dir).resolve())

    def find(self, key):
        cmd = ["rg", "-l", "-F", key, self.dir]
        _, tags, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.dir).run_to_lines()
        found_files = [string for string in tags if string]
        return found_files
