inherit mesonproperties populate simpleautoconfigure

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"

DO_MAKE_COMPILE_WRITABLE ?= "False"

CONFIGURE_BUILD_DIR     ?= "${B}"
CONFIGURE_CONFIGURE_DIR ?= "${S}"
CONFIGURE_NPROC ?= "${NPROC}"

CONFIGURE_OPTIONS  ?= ""
CONFIGURE_NO_CC_SWITCHES ?= "False"
CONFIGURE_CROSS_OPTIONS ?= ""
CONFIGURE_CFLAGS   ?= ""
CONFIGURE_CXXFLAGS ?= ""
CONFIGURE_LDFLAGS  ?= ""
CONFIGURE_LIBS     ?= ""
CONFIGURE_COMMAND  ?= "configure"
CONFIGURE_MAKE_OPTIONS ?= ""
CONFIGURE_AUTOGEN_OPTIONS ?= ""
CONFIGURE_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${CURRENT_TARGET}"
CONFIGURE_NATIVE_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${NATIVE_TARGET}"
CONFIGURE_LD_LIBRARY_PATH ?= ""
CONFIGURE_IGNORE_HOST ?= "False"
CONFIGURE_NEED_COPY    = "True"
CONFIGURE_DEEPCOPY_SRC = "False"
CONFIGURE_INTERPRETER_BIN ?= ""

do_clean_automake() {
    cd ${S}
    find . -name 'Makefile.in' -delete
    find . -name 'aclocal.m4' -delete
    find . -name 'autom4te.cache' -exec rm -r {} +
    find . -name 'configure' -delete
}

addtask configure_copy
do_configure_copy[nostamp] = "1"
do_configure_copy[dirs] = "${S}"
python do_configure_copy() {
    import fileutils

    s = d.getVar('S')
    b = d.getVar('B')
    ccs = d.getVar('CONFIGURE_COPY_SRC')
    cds = d.getVar('CONFIGURE_DEEPCOPY_SRC')
    if (ccs == 'False') and (cds == False):
        return

    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    if not os.path.exists(ccd):
        os.makedirs(ccd, 0o750)

    if ccs == '1' or ccs == 'true' or ccs == True:
        fileutils.copy_no_vc_files(s, b)
        d.setVar('CONFIGURE_NEED_COPY', 'False')
    elif cds == '1' or cds == 'true' or cds == True:
        fileutils.copy_files(s, b)
        d.setVar('CONFIGURE_NEED_COPY', 'False')
}


python do_configure() {
    import subprocess, sys, fileutils, bbenv, stat
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')
    nw = ' ' + (d.getVar('NOWARN') or '') + ' '  + (d.getVar('DEPEND_INCLUDE_DIRS_SWITCH') or '')
    bbenv.set_env_var(d, 'PKG_CONFIG_PATH', 'CONFIGURE_PKG_CONFIG_PATH')
    bbenv.set_env_var(d, 'PKG_CONFIG_PATH_FOR_BUILD', 'CONFIGURE_NATIVE_PKG_CONFIG_PATH')
    bbenv.set_env_var(d, 'PKG_CONFIG'     , 'CONFIGURE_PKG_CONFIG')
    bbenv.set_env_var2(d, 'CFLAGS'        , 'CONFIGURE_CFLAGS', nw)
    bbenv.set_env_var2(d, 'CXXFLAGS'      , 'CONFIGURE_CXXFLAGS', nw)
    bbenv.set_env_var(d, 'LDFLAGS'        , 'CONFIGURE_LDFLAGS')
    bbenv.set_env_var(d, 'LIBS'           , 'CONFIGURE_LIBS')
    bbenv.set_env_var(d, 'LD_LIBRARY_PATH', 'CONFIGURE_LD_LIBRARY_PATH')
    bbenv.apply_env_var(d, 'CONFIGURE_ENV')
    bb.build.exec_func('do_configure_copy', d)
    os.chdir(d.getVar('CONFIGURE_CONFIGURE_DIR'))

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        os.environ['LD_LIBRARY_PATH'] = ldlp

    module = d.getVar('MODULE')
    if (module == None): raise Exception('CONFIGURE: MODULE NOT SET')

    b  = d.getVar('CONFIGURE_BUILD_DIR')
    mp = d.getVar('CONFIGURE_MAKE_PROGRAM')
    mo = d.getVar('CONFIGURE_MAKE_OPTIONS') or ''
    mn = d.getVar('CONFIGURE_NPROC')
    concmd = d.getVar('CONFIGURE_COMMAND')

    conint = d.getVar('CONFIGURE_INTERPRETER_BIN')
    consrc = d.getVar('CONFIGURE_CONFIGURE_DIR')

    tc = d.getVar('TOOLCHAIN')
    ntc = d.getVar('NATIVE_TOOLCHAIN')

    tpd   = d.getVar('TARGET_PREFIX_DIR')
    bbtd  = d.getVar('TOPDIR')
    bbct  = d.getVar('CURRENT_TARGET')
    bbnt  = d.getVar('NATIVE_TARGET')
    bbcts = d.getVar('CURRENT_TARGET_SUFFIX')
    bbwd  = d.getVar('TMPDIR') + '/work'
    copt  = d.getVar('CONFIGURE_OPTIONS') or ''
    pcp   = d.getVar('CONFIGURE_PKG_CONFIG_PATH') or ''
    npcp  = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH') or ''
    ih    = d.getVar('CONFIGURE_IGNORE_HOST') == 'True'
    is_native = d.getVar('IS_NATIVE')

    bb.note('PKG_CONFIG_PATH:' + pcp)
    bb.note('TOOLCHAIN:      ' + tc)
    bb.note('BUILD_DIR:      ' + b)
    bb.note('CURRENT_TARGET: ' + bbct)
    bb.note('NATIVE_TARGET:  ' + bbnt)

    os.makedirs(b, exist_ok=True)

    tcp = d.get('TOOLCHAIN_PREFIX')

    if conint != "" and conint != None:
        cmd = conint + " "
    else:
        cmd = ""

    conexe = concmd.strip().split(" ")[0]
    conpath = consrc + "/" + conexe
    current_stat = os.stat(consrc + "/" + conexe).st_mode
    executable_stat = current_stat | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH
    os.chmod(conpath, executable_stat)

    conpath = consrc + "/" + concmd
    cmd += conpath

    if not is_native:
        if not ih:
            noccsw = d.getVar('CONFIGURE_NO_CC_SWITCHES')
            if noccsw != 'True':
                cmd += " --build=" + bbnt
                cmd += " --host=" + bbct
            cmd += d.getVar('CONFIGURE_CROSS_OPTIONS')
    cmd += " --prefix=" + tpd
    cmd += " --libdir=" + tpd + '/lib'
    cmd += " " + copt

    p = subprocess.Popen(cmd, shell=True, cwd=b, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('CONFIGURE FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + str)
        sys.exit(retval)
}

python do_compile() {
    import subprocess, sys, bbenv
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)

    nw = ' ' + (d.getVar('NOWARN') or '') + ' '  + (d.getVar('DEPEND_INCLUDE_DIRS_SWITCH') or '')

    bbenv.set_env_var(d, 'CFLAGS'         , 'CONFIGURE_CFLAGS')
    bbenv.set_env_var(d, 'CXXFLAGS'       , 'CONFIGURE_CXXFLAGS')
    bbenv.set_env_var(d, 'LDFLAGS'        , 'CONFIGURE_LDFLAGS')
    bbenv.set_env_var(d, 'LIBS'           , 'CONFIGURE_LIBS')
    bbenv.set_env_var(d, 'PKG_CONFIG_PATH', 'CONFIGURE_PKG_CONFIG_PATH')
    bbenv.set_env_var(d, 'LD_LIBRARY_PATH', 'CONFIGURE_LD_LIBRARY_PATH')
    bbenv.apply_env_var(d, 'CONFIGURE_ENV')

    bbenv.buildtools   = d.getVar('TOOLCHAIN_BASE') + '/bin'

    os.environ['PATH'] = os.environ['PATH'] + ':' + d.get('TOOLCHAIN_DIR')

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        os.environ['LD_LIBRARY_PATH'] = ldlp

    b  = d.getVar('CONFIGURE_BUILD_DIR')
    mo = d.getVar('CONFIGURE_MAKE_OPTIONS')
    mn = d.getVar('CONFIGURE_NPROC')
    inst = d.getVar('INSTALL_DIR')
    bb.note(mo)

    cmd = "make " + mo + " DESTDIR=" + inst + " -j " + mn + " -C " + b
    bb.note(cmd)

    dw = d.getVar('DO_MAKE_COMPILE_WRITABLE')
    dwd = d.getVar('DO_MAKE_COMPILE_WRITABLE_DEBUG')
    if dw == 'True':
        for current_dir, subdirs, files in os.walk('.'):
            for filename in files:
                fn = os.path.join(current_dir, filename)
                if dwd == 'True':
                    bb.warn('make writable: ' + fn)
                os.chmod(fn, 0o740)

    p = subprocess.Popen(cmd, shell=True, cwd=b, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('BUILD FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + cmd)
        sys.exit(retval)
}

python do_install() {
    import subprocess, sys, fileutils, bbtools

    s  = d.getVar('S')
    b  = d.getVar('CONFIGURE_BUILD_DIR')
    tpd = d.getVar('TARGET_PREFIX_DIR')

    my_env = os.environ.copy()
    my_env["LD_LIBRARY_PATH"] = d.getVar('CONFIGURE_LD_LIBRARY_PATH')
    inst = d.getVar('INSTALL_DIR')

    dw = d.getVar('DO_MAKE_COMPILE_WRITABLE')
    if dw == 'True':
        for current_dir, subdirs, files in os.walk(inst):
            for filename in files:
                fn = os.path.join(current_dir, filename)
                os.chmod(fn, 0o740)

    cmd = "make -C " + b + " DESTDIR=" + inst + " install"
    bb.note(cmd)

    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=my_env)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    fileutils.rm_file_with_suffix(inst, '.la')

    if dw == 'True':
        for current_dir, subdirs, files in os.walk(inst):
            for filename in files:
                fn = os.path.join(current_dir, filename)
                os.chmod(fn, 0o740)


    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('INSTALL FAILED: ' + b)
        sys.exit(retval)

    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), tpd, s, inst)
}
