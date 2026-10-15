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
    # Translate BitBake variable names at the boundary.
    variables = {
        'module': 'MODULE',
        'source_dir': 'S',
        'build_dir': 'B',
        'native_build': 'IS_NATIVE',
        'toolchain_file': 'TOOLCHAIN',
        'build_machine_toolchain_file': 'NATIVE_TOOLCHAIN',
        'compiler_version': 'COMPILER_VERSION',
        'linker_flags': 'MESON_LDFLAGS',
        'install_rpath': 'MESON_INSTALL_RPATH',
        'ninja_executable': 'NINJA_BIN',
        'rustup_home': 'RUSTUP_HOME',
        'pkg_config_executable': 'MESON_PKG_CONFIG',
        'pkg_config_path': 'MESON_PKG_CONFIG_PATH',
        'build_pkg_config_path': 'MESON_NATIVE_PKG_CONFIG_PATH',
        'warning_flags': 'NOWARN',
        'c_flags': 'MESON_C_FLAGS',
        'cxx_flags': 'MESON_CXX_FLAGS',
        'options': 'MESON_OPTIONS',
        'install_prefix': 'TARGET_PREFIX_DIR',
        'backend': 'MESON_GENERATOR',
        'toolchain_library_path': 'TOOLCHAIN_LD_LIBRARY_PATH',
        'program_path': 'MESON_PROGRAM_PATH',
    }
    config = {name: d.getVar(variable) for name, variable in variables.items()}
    config['executable'] = bbpaths.BBPaths.from_current(d, 'meson').install_dir + '/bin/meson'
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
