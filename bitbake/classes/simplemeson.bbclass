inherit test simpleninja populate

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"

PKG_CONFIG_PATH ?= ""
NATIVE_PKG_CONFIG_PATH ?= ""
MESON_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${CURRENT_TARGET}:${PKG_CONFIG_PATH}"
MESON_NATIVE_PKG_CONFIG_PATH ?= "${TMPDIR}/moduleref/${NATIVE_TARGET}:${NATIVE_PKG_CONFIG_PATH}"
MESON_PKG_CONFIG ?= "/usr/bin/pkg-config"
MESON_GENERATOR ?= "ninja"
MESON_LDFLAGS ?= ""
MESON_INSTALL_RPATH ?= "$ORIGIN:$ORIGIN/../lib"
MESON_DEBUG ?= "False"

python do_configure() {
    import os, subprocess, shlex
    from mesonproperties import apply_meson_properties
    from cbuildconfigure_classes.cbuildconfigure_meson import CBuildConfigureMeson
    import bbpaths, bbenv

    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    keys = (
        'MODULE S B IS_NATIVE TOOLCHAIN NATIVE_TOOLCHAIN COMPILER_VERSION '
        'MESON_LDFLAGS MESON_INSTALL_RPATH NINJA_BIN RUSTUP_HOME '
        'MESON_PKG_CONFIG MESON_PKG_CONFIG_PATH MESON_NATIVE_PKG_CONFIG_PATH '
        'NOWARN MESON_C_FLAGS MESON_CXX_FLAGS MESON_OPTIONS '
        'TARGET_PREFIX_DIR MESON_GENERATOR TOOLCHAIN_LD_LIBRARY_PATH '
        'MESON_PROGRAM_PATH'
    ).split()
    config = {key: d.getVar(key) for key in keys}
    config['MESON_BIN'] = bbpaths.BBPaths.from_current(d, 'meson').install_dir + '/bin/meson'
    env = os.environ.copy()
    bbenv.apply_localenv_keyvals(d, env, d.getVar('MESON_ENV'))
    argv, cwd, env = CBuildConfigureMeson(config, env).configure()
    bb.note('CONFIGURE: ' + shlex.join(argv))
    result = subprocess.run(argv, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    if result.returncode:
        bb.plain(result.stdout)
        raise RuntimeError('MESON CONFIGURE FAILED: ' + str(result.returncode))
}
