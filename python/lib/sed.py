import os
from pathlib import Path


class Sed:
    def __init__(self, filename):
        self.filename  = str(Path(filename).resolve())

    def replace(self, from_str, to_str):
        cmd = 'sed -i \'s|' + from_str + '|' + to_str + '|g\' ' + self.filename
        print(cmd)
        os.system(cmd)
