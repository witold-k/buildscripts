inherit mesonproperties populate

NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"
TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"

MAKE_SRC_DIR ?= "${B}"
MAKE_NPROC ?= "${NPROC}"

# -- environment

CC  = "gcc"
CXX = "g++"
CFLAGS   ?= ""
CXXFLAGS ?= ""
LDFLAGS  ?= ""
MAKE_CFLAGS   ?= ""
MAKE_CXXFLAGS ?= ""
MAKE_LDFLAGS  ?= ""
MAKE_LIBS     ?= ""
MAKE_MAKE_OPTIONS ?= ""
MAKE_PKG_CONFIG_PATH ?= ""
MAKE_LD_LIBRARY_PATH ?= ""

# --

python do_generate_make_env() {
    import os, subprocess, json

    # 1. Dummy-Meson-Projekt erstellen
    build_dir = os.path.join(d.getVar('B'), 'meson-introspect')
    os.makedirs(build_dir, exist_ok=True)

    with open(os.path.join(d.getVar('S'), 'meson.build'), 'w') as f:
        f.write("project('env-gen', 'c', 'cpp')")

    # 2. Meson Setup ausführen
    cmd = [
        'meson', 'setup', build_dir,
        '--native-file', d.getVar('NATIVE_TOOLCHAIN'),
        '--cross-file', d.getVar('TOOLCHAIN'),
        '--wipe'
    ]
    subprocess.check_call(cmd, cwd=d.getVar('S'))

    # 3. Introspection nutzen, um Flags zu extrahieren
    # Meson speichert die kompilierten Flags intern
    intro_cmd = ['meson', 'introspect', '--buildoptions', build_dir]
    options = json.loads(subprocess.check_output(intro_cmd))

    # Flags extrahieren
    env_flags = {}
    for opt in options:
        name = opt['name']
        value = opt['value']
        if isinstance(value, list):
            value = " ".join(value)

        # Mapping von Meson auf Make/Shell
        if name == 'c_args': env_flags['TARGET_CFLAGS'] = value
        elif name == 'build.c_args': env_flags['HOST_CFLAGS'] = value
        elif name == 'c_link_args': env_flags['TARGET_LDFLAGS'] = value
        elif name == 'build.c_link_args': env_flags['HOST_LDFLAGS'] = value

    # In d speichern für do_compile
    for k, v in env_flags.items():
        d.setVar(k, v)
        bb.warn(k + " = " + v)
        bb.note(f"Extracted {k}: {v}")
}

do_configure() {
    cd ${S}
    mkdir -p ${B}
    rsync -rv --links ${S}/* ${B}/

    TC=$(readlink -m ${TOOLCHAIN})
    SD=$(readlink -m ${MAKE_SRC_DIR})
    echo "toolchain      : ${TC}"
}

python do_compile() {
    import subprocess, sys
    apply_meson_properties(d.getVar('NATIVE_TOOLCHAIN'), d, d.getVar('NATIVE_TARGET'), skip_sysroot=True)
    hostcc       = d.getVar('CC')
    hostcxx      = d.getVar('CXX')
    os.environ['HOST_CC']  = hostcc
    os.environ['HOST_CXX'] = hostcxx

    apply_meson_properties(d.getVar('TOOLCHAIN'), d, skip_sysroot=True)

    nw = ' ' + (d.getVar('NOWARN') or '') + ' '  + (d.getVar('DEPEND_INCLUDE_DIRS_SWITCH') or '')

    mcf          = d.getVar('CFLAGS')   + ' ' + d.getVar('MAKE_CFLAGS') + ' ' + nw
    mcxxf        = d.getVar('CXXFLAGS') + ' ' + d.getVar('MAKE_CXXFLAGS') + ' ' + nw
    mldf         = d.getVar('LDFLAGS')  + ' ' + d.getVar('MAKE_LDFLAGS') + ' ' + nw
    cc           = d.getVar('CC')
    cxx          = d.getVar('CXX')
    ld           = d.getVar('LD')
    libtool      = d.getVar('LIBTOOL')
    tpd          = d.getVar('TARGET_PREFIX_DIR')

    os.environ['CC']              = cc
    os.environ['CXX']             = cxx
    os.environ['LIBTOOL']         = libtool
    os.environ['CFLAGS']          = mcf
    os.environ['CXXFLAGS']        = mcxxf
    os.environ['LDFLAGS']         = mldf
    os.environ['LIBS']            = d.getVar('MAKE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('MAKE_PKG_CONFIG_PATH')
    os.environ['LD_LIBRARY_PATH'] = d.getVar('MAKE_LD_LIBRARY_PATH')
    os.environ['CROSS'] = d.get('TOOLCHAIN_DIR') + '/' + d.getVar('TOOLCHAIN_PREFIX')
    os.environ['PATH']            = os.environ['PATH'] + ':' + d.get('TOOLCHAIN_DIR')

    b  = d.getVar('MAKE_SRC_DIR')
#    mo = "CC=" + cc + " " + "CFLAGS='" + mcf + "' " + d.getVar('MAKE_MAKE_OPTIONS')
    mo = 'HOST_CC=' + hostcc + ' CC=' + cc + ' PREFIX=' + tpd + ' ' + d.getVar('MAKE_MAKE_OPTIONS')
    mn = d.getVar('MAKE_NPROC')
    bb.note(mo)

    cmd = "make " + mo + " -j " + mn + " -C " + b
    print(cmd)
    bb.note(cmd)
    p = subprocess.Popen(cmd, shell=True, cwd=b, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode(encoding = 'utf-8', errors = 'ignore').rstrip())
        bb.error('BUILD FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + cmd)
        sys.exit(retval)
}

python do_install() {
    import bbtools

    s      = d.getVar('MAKE_SRC_DIR')
    prefix = d.getVar('TARGET_PREFIX_DIR')
    inst   = d.getVar('INSTALL_DIR')
    cmd = "make -C " + s + " DESTDIR=" + inst + " PREFIX=" + prefix + " install"
    bb.note(cmd)
    if os.system(cmd):
        raise Exception('INSTALL FAILED: ' + s)

    #bb.warn('installpkgconfig')
    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), prefix, s, inst)
}
