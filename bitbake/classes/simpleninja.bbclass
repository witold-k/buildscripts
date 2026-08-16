inherit test populate

MESON_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NINJA_NINJA_BIN ?= "${NINJA_BIN}"
NINJA_MAKE_BIN  ?= "${MAKE_BIN}"
NINJA_NPROC ?= "${NPROC}"

python do_compile() {
    import subprocess, sys, os
    apply_meson_properties(d.getVar('MESON_TOOLCHAIN'), d)

    b  = d.getVar('B')
    mn = d.getVar('NINJA_NPROC')
    no = d.getVar('NINJA_OPTIONS') or ''

    if os.path.exists(b + '/build.ninja'):
        mp  = d.getVar('NINJA_NINJA_BIN')
        cmd = mp + ' ' + no + " -j " + mn + " -C " + b

    elif os.path.exists(b + '/Makefile'):
        mp  = d.getVar('NINJA_MAKE_BIN')
        cmd = mp + " -j " + mn + " -C " + b

    bb.note("BUILD_DIR: " + b)
    bb.note(cmd)

    env = os.environ.copy()

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        env['LD_LIBRARY_PATH'] = ldlp
    p = subprocess.Popen(cmd, shell=True, cwd=b, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    dw = d.getVar('DO_MAKE_COMPILE_WRITABLE')
    if dw == 'True':
        for current_dir, subdirs, files in os.walk('.'):
            for filename in files:
                fn = os.path.join(current_dir, filename)
                os.chmod(fn, 0o740)
    if (retval):
        for line in lines:
            bb.plain(line.decode(encoding = 'utf-8', errors = 'ignore').rstrip())
        bb.error('BUILD FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + cmd)
        sys.exit(retval)
}

python do_install() {
    import subprocess, sys, bbtools, os

    s   = d.getVar('S')
    b   = d.getVar('B')
    tpd = d.getVar('TARGET_PREFIX_DIR')

    inst = d.getVar('INSTALL_DIR')
    env  = os.environ.copy()
    env['DESTDIR'] = inst

    if os.path.exists(b + '/build.ninja'):
        mp = d.getVar('NINJA_NINJA_BIN')
        cmd = "DESTDIR=" + inst + " " + mp + " -C " + b + " install"

    elif os.path.exists(b + '/Makefile'):
        mp = d.getVar('NINJA_MAKE_BIN')
        cmd = "DESTDIR=" + inst + " " + mp + " -C " + b + " install"

    os.makedirs(inst, exist_ok=True)

    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('INSTALL FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + cmd)
        sys.exit(retval)

    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), tpd, s, inst)
}

