import os
import buildjobs
from pathlib import Path


class Rsync:
    def __init__(self, src_dir, dest_dir):
        self.src_dir  = str(Path(src_dir).resolve())
        self.dest_dir = str(Path(dest_dir).resolve())

    def copy(self):
        if not os.path.isdir(self.dest_dir):
            os.makedirs(self.dest_dir, mode=0o700, exist_ok=True)
        cmd = ["rsync", "-avc", "--delete", "--ignore-times", self.src_dir, self.dest_dir]
        _, _, _ = buildjobs.DoProcess(cmd=cmd, cwd=self.src_dir).run_to_lines()
