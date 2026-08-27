inherit test simpleninja mesonproperties populate

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"

PKG_CONFIG_PATH ?= ""
NATIVE_PKG_CONFIG_PATH ?= ""
MESON_PKG_CONFIG_PATH ?= "${PKG_CONFIG_PATH}:${TMPDIR}/moduleref/${CURRENT_TARGET}"
MESON_NATIVE_PKG_CONFIG_PATH ?= "${NATIVE_PKG_CONFIG_PATH}:${TMPDIR}/moduleref/${NATIVE_TARGET}"
MESON_PKG_CONFIG ?= "/usr/bin/pkg-config"
MESON_GENERATOR ?= "ninja"
MESON_MAKE_PROGRAM ?= "${NINJA_BIN}"
MESON_SRC_DIR ?= "${S}"
MESON_NPROC ?= "${NPROC}"
MESON_MAKE_OPTIONS ?= ""
MESON_LDFLAGS ?= ""

python do_configure() {
    import subprocess, sys, bbenv

    apply_meson_properties(d.getVar('TOOLCHAIN'), d)

    module = d.getVar('MODULE')
    if (module == None): raise Exception('CONFIGURE: MODULE NOT SET')

    rust = d.getVar('RUSTUP_HOME')
    if rust != None:
        os.environ['RUSTUP_HOME'] = rust


    s  = d.getVar('S')
    b  = d.getVar('B')

    is_native = d.getVar('IS_NATIVE')

    meson_bin = d.getVar('MESON_BIN')
    mmp = d.getVar('MESON_MAKE_PROGRAM')
    mo = d.getVar('MESON_MAKE_OPTIONS')
    mn = d.getVar('MESON_NPROC')

    mprp = d.getVar('MESON_PROGRAM_PATH')

    tc = d.getVar('TOOLCHAIN')
    ntc = d.getVar('NATIVE_TOOLCHAIN')

    csd  = d.getVar('MESON_SRC_DIR')
    pkgpath = d.getVar('MESON_PKG_CONFIG_PATH')
    pkgbin  = d.getVar('MESON_PKG_CONFIG')

    nw = ' ' + (d.getVar('NOWARN') or '') + ' '  + (d.getVar('DEPEND_INCLUDE_DIRS_SWITCH') or '')
    cbrp  = None

    ccf   = ' ' + (d.getVar('MESON_C_FLAGS') or '') + nw
    cxxf  = ' ' + (d.getVar('MESON_CXX_FLAGS') or '') + nw

    ldf = d.getVar('MESON_LDFLAGS')

    os.environ['LDFLAGS']         = ldf
    os.environ['NINJA']           = d.getVar("NINJA_BIN")
    env = os.environ.copy()

    bbenv.apply_localenv_keyvals(d, env, d.getVar('MESON_ENV'))

    env['PKG_CONFIG_PATH'] = pkgpath
    env['PKG_CONFIG'] = pkgbin
    env['TOOLCHAIN_VERSION'] = d.getVar('COMPILER_VERSION')

    nativepkgpath = d.getVar('MESON_NATIVE_PKG_CONFIG_PATH')
    if not is_native:
        env['PKG_CONFIG_PATH_FOR_BUILD'] = nativepkgpath

    mgen  = d.getVar('MESON_GENERATOR')
    tpd   = d.getVar('TARGET_PREFIX_DIR')
    bbtd  = d.getVar('TOPDIR')
    bbct  = d.getVar('CURRENT_TARGET')
    bbcts = d.getVar('CURRENT_TARGET_SUFFIX')
    bbwd  = d.getVar('TMPDIR') + '/work'
    copt  = d.getVar('MESON_OPTIONS') or ''
    bb.note('MODULE PATH: ' + (pkgpath or ''))
    bb.note('TOOLCHAIN:   ' + tc)
    bb.note("BUILD_DIR: " + b)
    os.makedirs(b, exist_ok=True)

    args = [meson_bin, "setup"]

    args += [f"-Dc_args='{ccf}'", f"-Dcpp_args='{cxxf}'"]
    if is_native:
        args += ["--native-file", tc]
    else:
        args += ["--native-file", ntc, "--cross-file", tc]
        args += ["-Dbuild.c_args=-w", "-Dbuild.cpp_args=-w"]
    if None != ldf:
        args += ["-Dc_link_args='" + ldf + "'", "-Dcpp_link_args='" + ldf + "'"]
    args.append(copt)

    args += ["--prefix", tpd]
    args += ["--libdir", tpd + '/lib']
    args += ["--backend", mgen]
    if nativepkgpath:
        args += ["--build.pkg-config-path", nativepkgpath]
    if pkgpath:
        args += ["--pkg-config-path", pkgpath]
    args += [b, s]

    cmd = " ".join(args)

    bb.note('')
    bb.note('cd ' + b + ' && ' + cmd)
    bb.note('')

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        env['LD_LIBRARY_PATH'] = ldlp
    if mprp is not None:
        path = env['PATH']
        # bb.warn("PATH1: " + path)
        path = mprp + ':' + path
        # bb.warn("PATH2: " + path)
        env['PATH'] = path

    # dump_env(bb, env)
    p = subprocess.Popen(cmd, shell=True, cwd=s, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())
        bb.error('CONFIGURE FAILED: ' + b)
        bb.warn('cd ' + s + ' && ' + cmd)
        sys.exit(retval)
}
