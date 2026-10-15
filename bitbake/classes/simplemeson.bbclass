inherit test simpleninja populate

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"

PKG_CONFIG_PATH ?= ""
NATIVE_PKG_CONFIG_PATH ?= ""

#
# Build-time pkg-config directories.
#
# These contain .pc files from the dependency staging area.
#
MESON_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${CURRENT_TARGET}:${PKG_CONFIG_PATH}"
MESON_NATIVE_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${NATIVE_TARGET}:${NATIVE_PKG_CONFIG_PATH}"

MESON_PKG_CONFIG ?= "/usr/bin/pkg-config"
MESON_GENERATOR ?= "ninja"
MESON_LDFLAGS ?= ""
MESON_INSTALL_RPATH ?= "$ORIGIN:$ORIGIN/../lib"
MESON_DEBUG ?= "False"

python do_configure() {
    import subprocess, sys, shlex, bbenv, bbpaths
    from pkgconfigsetup import CidePkgConfig
    from mesonproperties import apply_meson_properties

    ct = d.getVar('CURRENT_TARGET')
    tc = d.getVar('TOOLCHAIN')
    apply_meson_properties(tc, d)

    module = d.getVar('MODULE')
    if module is None:
        raise Exception('CONFIGURE: MODULE NOT SET')

    rust = d.getVar('RUSTUP_HOME')

    s = d.getVar('S')
    b = d.getVar('B')
    is_native = d.getVar('IS_NATIVE')
    is_debug  = d.getVar('MESON_DEBUG') == "True"

    meson_bin = bbpaths.BBPaths.from_current(d, 'meson').install_dir + '/bin/meson'
    mprp = d.getVar('MESON_PROGRAM_PATH')
    tc = d.getVar('TOOLCHAIN')
    ntc = d.getVar('NATIVE_TOOLCHAIN')

    pkgbin = d.getVar('MESON_PKG_CONFIG')

    nw = ' ' + (d.getVar('NOWARN') or '')
    ccf = ' ' + (d.getVar('MESON_C_FLAGS') or '') + nw
    cxxf = ' ' + (d.getVar('MESON_CXX_FLAGS') or '') + nw

    # Staging libraries are located by -L and -rpath-link at link time.
    # Absolute -rpath entries must not enter installed ELF binaries.
    ldf = d.getVar('MESON_LDFLAGS') or ''
    linker_args = [
        flag for flag in shlex.split(ldf)
        if not (flag.startswith('-Wl,-rpath=')
                or flag.startswith('-Wl,-rpath,'))
    ]
    # Meson has no project-wide install_rpath option. Supply only
    # relocatable runtime paths here; absolute staging RPATHs are excluded.
    install_rpath = d.getVar('MESON_INSTALL_RPATH') or ''
    for entry in install_rpath.split(':'):
        if entry:
            flag = '-Wl,-rpath=' + entry
            if flag not in linker_args:
                linker_args.append(flag)
    env = os.environ.copy()
    env['LDFLAGS'] = shlex.join(linker_args)
    env['NINJA'] = d.getVar('NINJA_BIN')
    if rust is not None:
        env['RUSTUP_HOME'] = rust
    bbenv.apply_localenv_keyvals(d, env, d.getVar('MESON_ENV'))

    #
    # Configure the target/host pkg-config universe.
    #
    host_pkgconfig = CidePkgConfig(pkgbin, d.getVar('MESON_PKG_CONFIG_PATH'))
    env.update(host_pkgconfig.environment())

    #
    # Configure the build-machine pkg-config universe.
    #
    build_path = host_pkgconfig.path if is_native else d.getVar('MESON_NATIVE_PKG_CONFIG_PATH')
    build_pkgconfig = CidePkgConfig(pkgbin, build_path)
    env.update(build_pkgconfig.build_environment())

    env['TOOLCHAIN_VERSION'] = d.getVar('COMPILER_VERSION')

    mgen = d.getVar('MESON_GENERATOR')
    tpd = d.getVar('TARGET_PREFIX_DIR')
    copt = d.getVar('MESON_OPTIONS') or ''

    bb.note('PKG:        ' + str(host_pkgconfig))
    bb.note('NATIVE PKG: ' + str(build_pkgconfig))
    bb.note('TOOLCHAIN: ' + tc)
    bb.note('BUILD_DIR: ' + b)

    os.makedirs(b, exist_ok=True)

    # Pass argv directly instead of joining a shell command.
    # Meson compiler/linker options are arrays, not shell-quoted strings.
    args = [
        meson_bin, 'setup', '--debug',
        f"-Dc_args={shlex.split(ccf)!r}",
        f"-Dcpp_args={shlex.split(cxxf)!r}",
    ]

    if is_native:
        args.extend(['--native-file', tc])
    else:
        args.extend([
            '--native-file', ntc,
            '--cross-file', tc,
            '-Dbuild.c_args=-w',
            '-Dbuild.cpp_args=-w',
            '-Dpkg_config_path=' + host_pkgconfig.path,
            '-Dbuild.pkg_config_path=' + build_pkgconfig.path,
        ])

    args.extend([
        f"-Dc_link_args={linker_args!r}",
        f"-Dcpp_link_args={linker_args!r}",
    ])

    if copt:
        args.extend(shlex.split(copt))

    args.extend([
        '--prefix', tpd,
        '--libdir', tpd + '/lib',
        '--backend', mgen,
        b, s,
    ])

    bb.note('')
    bb.note('cd ' + shlex.quote(s) + ' && ' + shlex.join(args))
    bb.note('')

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        env['LD_LIBRARY_PATH'] = ldlp

    if mprp is not None:
        env['PATH'] = mprp + ':' + env['PATH']

    if is_debug:
        for key in sorted(env):
            if key.startswith("PKG_CONFIG"):
                bb.note("MESON ENV {}={!r}".format(key, env[key]))

        for pc_machine in (
            ("target", env["PKG_CONFIG"], env["PKG_CONFIG_LIBDIR"]),
            ("build", env["PKG_CONFIG_FOR_BUILD"],
             env["PKG_CONFIG_LIBDIR_FOR_BUILD"]),
        ):
            name, binary, libdir = pc_machine

            bb.note(
                "PKG-CONFIG TEST {}: {} --modversion wayland-scanner "
                "(LIBDIR={})".format(name, binary, libdir)
            )

            testenv = env.copy()
            testenv["PKG_CONFIG_LIBDIR"] = libdir
            testenv["PKG_CONFIG_PATH"] = ""

            result = subprocess.run(
                [binary, "--modversion", "wayland-scanner"],
                env=testenv,
                capture_output=True,
                text=True,
            )

            bb.note(
                "PKG-CONFIG TEST {}: rc={} stdout={!r} stderr={!r}".format(
                    name,
                    result.returncode,
                    result.stdout,
                    result.stderr,
                )
            )

    #
    # Meson executes pkg-config using this environment.
    #
    p = subprocess.Popen(
        args,
        cwd=s,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT
    )

    lines = p.stdout.readlines()
    retval = p.wait()
    p.stdout.close()

    if retval:
        for line in lines:
            bb.plain(line.decode('utf-8').rstrip())

        bb.error('CONFIGURE FAILED: ' + b)
        bb.warn('cd ' + shlex.quote(s) + ' && ' + shlex.join(args))
        sys.exit(retval)
}

