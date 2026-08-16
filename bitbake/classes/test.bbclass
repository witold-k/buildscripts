python do_test() {
    import subprocess, sys

    b = d.getVar('B')
    str = 'ctest --output-on-failure --test-dir ' + b

    env = os.environ.copy()

    tp = d.getVar('TEST_PATH')
    if tp is not None:
        path = env['PATH']
        path = tp + ':' + path
        env['PATH'] = path

    p = subprocess.Popen(str, shell=True, env=env, cwd=b, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('TEST FAILED: ' + b)
        bb.warn(str)
        sys.exit(retval)
}
