#!/usr/bin/python3

import sys
from pathlib import Path
path = Path(__file__ + '/../../lib').resolve()
sys.path.append(str(path))

import sys
import buildjobs, jsonenvironment

args            = None
task_name       = sys.argv[1]
bitbake_project = sys.argv[2]
task_dir        = None
if len(sys.argv) > 3:
    task_dir        = sys.argv[3]
build_task      = None
if len(sys.argv) > 4:
    build_task = sys.argv[4]

arch = 'x86_64-unknown-linux-gnu'

if task_name == 'build':
    db = buildjobs.DoBuild(bitbake_project, arch, task_dir)
    db.run()

if task_name == 'install':
    db = buildjobs.DoInstall(bitbake_project, arch, task_dir, '/usr/devel', 'native')
    db.run()

if task_name == 'test':
    db = buildjobs.DoTest(bitbake_project, arch, task_dir)
    db.run()

if task_name == 'clean':
    db = buildjobs.DoClean(bitbake_project, arch, task_dir)
    db.run()

if task_name == 'bbkbuild':
    args = ['-k']
    task_name = 'bbbuild'

if task_name == 'bbfbuild':
    args = ['--force']
    task_name = 'bbbuild'

if task_name == 'bbvbuild':
    args = ['-v']
    task_name = 'bbbuild'

if task_name == 'bbbuild':
    env_file = bitbake_project
    je = jsonenvironment.JsonEnvironment.load(env_file)
    env = je.apply_env()
    bitbake_exe     = env['BITBAKE_EXE']
    bb = buildjobs.DoBitbake(bitbake_exe=bitbake_exe, build_dir=task_dir, args=args, do_continue=False)
    bb.run(build_task)

if task_name == 'bbclean':
    env_file = bitbake_project
    je = jsonenvironment.JsonEnvironment.load(env_file)
    env = je.apply_env()
    bitbake_exe = env['BITBAKE_EXE']
    build_root  = env['BUILD_ROOT']
    bb = buildjobs.DoBitbakeClean(bitbake_exe=bitbake_exe, build_dir=build_root)
    bb.run(build_task)

if task_name == 'bbcleanlog':
    env_file = bitbake_project
    je = jsonenvironment.JsonEnvironment.load(env_file)
    env = je.apply_env()
    bitbake_exe = env['BITBAKE_EXE']
    bb = buildjobs.DoBitbakeClean(bitbake_exe=bitbake_exe, build_dir=task_dir)
    bb.run()

if task_name == 'create_env':
    if task_dir is None:
        print('create_env: task_dir not set')
        exit()
    else:
        dest_file = task_dir + '/scripts/env.sh'
        je = jsonenvironment.JsonEnvironment.load_upper_from(task_dir, 'config/environment.json')
        env = je.apply_env()
        bb = buildjobs.DoCreateEnv(env, dest_file=dest_file)
        bb.run()

if task_name == 'create_dockerimage':
    je = jsonenvironment.JsonEnvironment.load_upper_from(task_dir, 'config/environment.json')
    env = je.apply_env()
    di = env['DOCKER_IMAGE']
    cmd = ['podman', 'build', '-f', 'Dockerfile', '-t', di, '.']
    buildjobs.DoProcess(cmd=cmd, cwd=task_dir).run()
