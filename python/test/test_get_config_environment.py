#!/usr/bin/python3

import sys
from pathlib import Path
root = str(Path(__file__ + '/../..').resolve())
path = root + '/lib'
print("added python path: " + path)
sys.path.insert(1, path)
sys.path.insert(1, root + '/python/bin')


class GetConfigEnvironmentTest:

    def load(self):
        import jsonenvironment

        jenv = jsonenvironment.JsonEnvironment.load(root + '/test/environment.json')
        env = jenv.apply_env()

        for key, val in env.items():
            print(key + " => " + val)


test = GetConfigEnvironmentTest()
test.load()
