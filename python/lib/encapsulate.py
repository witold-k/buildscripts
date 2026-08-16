import os


def encapsulate(path, ld_exe):
    base_dir = os.path.dirname(__file__)
    with open(base_dir + '/encapsulate.c') as f:
        ccode = f.read()

    data = ccode.replace('${LD_LINUX_SO}', ld_exe)
    with open(path, "w") as f:
        f.write(data)


def encapsulate_compile(c_compiler: str, wsd: str, wbd: str, bindir: str, ldso: str):
    import buildjobs
    if not os.path.exists(c_compiler):
        raise Exception('Compiler not found: ' + c_compiler)
    lines = []
    os.makedirs(wsd, exist_ok=True)

    if os.path.exists(bindir):
        bins = os.listdir(bindir)
        os.makedirs(wbd, 0o750, exist_ok=True)
        for bin in bins:
            wsrc = wsd + '/' + bin + '.c'
            encapsulate(wsrc, ldso)
            wdest = wbd + '/' + bin
            cmd = [c_compiler, '-O3', wsrc, '-o', wdest]
            bj = buildjobs.DoProcess(cmd=cmd)
            _, _, _ = bj.run_to_lines(lines, lines)
