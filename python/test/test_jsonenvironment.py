#!/usr/bin/python3

import sys, os
from pathlib import Path
root = Path(__file__ + '/../..').resolve()
path = str(root) + '/lib'
print("added python path: " + str(path))
sys.path.insert(1, str(path))


class JsonEnvironmentTest:

    def load(self):
        import jsonenvironment
        jenv = jsonenvironment.JsonEnvironment.load(str(root) + '/test/environment.json')
        if jenv is None:
            raise Exception("failed:")
        jenv.apply_env()
        pl_is = os.environ['PYTHONLIB']
        pl_should = str(root) + '/modules/bitbake/lib'
        if pl_is != pl_should:
            print(str(jenv))
            raise Exception("failed: " + pl_is + " != " + pl_should)


test = JsonEnvironmentTest()
test.load()
