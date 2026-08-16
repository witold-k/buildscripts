#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
# print("added python path: " + str(path))
sys.path.insert(1, str(path))

import buildjobs


class BuildJobsTest:

    def doProcess(self):
        dp = buildjobs.DoProcess(["ls", "--color=auto"])
        dp.run_pty()
        dp.fork_pty()
        dp.run_pipe()
        dp.run()


test = BuildJobsTest()
test.doProcess()
