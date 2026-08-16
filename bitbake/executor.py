def execute(name, bb, dir, command, do_warn_dump=False):
    import subprocess
    import os
    import sys

    os.environ['TERM'] = 'screen-256color'

    p = subprocess.Popen(command, shell=True, cwd=dir, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines()
    retval = p.wait()
    p.stdout.close()

    if (retval):
        bb.warn('--------------------------------------------------------------')
        for line in lines:
            bb.warn(line.decode(encoding='utf-8', errors='ignore').rstrip())
        bb.error(name + ' FAILED: ' + dir)
        bb.warn('cd ' + dir + ' && ' + command)
        sys.exit(retval)

    if do_warn_dump:
        for line in lines:
            bb.warn(line.decode(encoding='utf-8', errors='ignore').rstrip())
    else:
        for line in lines:
            bb.note(line.decode(encoding='utf-8', errors='ignore').rstrip())
