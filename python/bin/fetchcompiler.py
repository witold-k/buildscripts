#!/usr/bin/python3

import os, sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import architecture, fileutils, gittools, jsonenvironment

environment_json = sys.argv[1]
jenv = jsonenvironment.JsonEnvironment.load(environment_json)
env = jenv.apply_env()

url    = env["COMPILER_GIT"]
dir    = env["COMPILER_ROOT"]
branch = env["COMPILER_VERSION"]


def mklink(dir, version):
    inner_dir = dir + '/' + version + '/' + version
    if os.path.isdir(inner_dir):
        native = architecture.Architecture.select_native_from_dir(inner_dir)
        # print("native: " + dir + " => " + native)
        if native != "":
            fileutils.rel_link(inner_dir + '/' + native, dir + '/native')
            fileutils.rel_link(inner_dir + '/' + native, inner_dir + '/native')


g = gittools.Git(url, dir)
g.cloneSingleBranch(branch)
mklink(dir, branch)

if "BUILDSYSTEMS_GIT" in env:
    url    = env["BUILDSYSTEMS_GIT"]
    dir    = env["BUILDSYSTEMS_ROOT"]
    branch = env["BUILDSYSTEMS_VERSION"]

    g = gittools.Git(url, dir)
    g.cloneSingleBranch(branch)
    mklink(dir, branch)

if "CIDE_GIT" in env:
    url    = env["CIDE_GIT"]
    dir    = env["CIDE_ROOT"]
    branch = env["CIDE_VERSION"]

    g = gittools.Git(url, dir)
    g.cloneSingleBranch(branch)
    mklink(dir, branch)
