#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import jsonenvironment

env_file = sys.argv[1]

je = jsonenvironment.JsonEnvironment.load(env_file)
env = je.apply_env()

res = ""
for key, val in env.items():
    res += "export " + str(key) + "='" + str(val) + "';"

print(res)
