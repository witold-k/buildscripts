inherit simpleninja test populate

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/cmake/${CURRENT_TARGET}-toolchain.cmake"
MESON_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"

DO_MAKE_COMPILE_WRITABLE ?= "False"
PKG_CONFIG_PATH ?= ""
CMAKE_MODULE_PATH ?= "${PROJECT_ROOT}/modulerefs/cmake"
CMAKE_SRC_DIR ?= "${S}"
CMAKE_GENERATOR ?= "Ninja"
CMAKE_MAKE_PROGRAM ?= "${NINJA_BIN}"
CMAKE_MAKE_OPTIONS ?= ""
CMAKE_NPROC ?= "${NPROC}"

python do_configure() {
    import shlex, subprocess
    import bbdefaultvars
    from mesonproperties import apply_meson_properties
    from cbuildconfigure_classes.cbuildconfigure_cmake import CBuildConfigureCMake

    apply_meson_properties(d.getVar('MESON_TOOLCHAIN'), d)
    bbdefaultvars.bbdefaultvars(bb, d)
    # Translate BitBake variable names at the boundary.
    variables = {
        'module': 'MODULE',
        'target': 'CURRENT_TARGET',
        'compiler_version': 'COMPILER_VERSION',
        'sdk_dir': 'SDK_DIR',
        'pkg_config_path': 'PKG_CONFIG_PATH',
        'temp_dir': 'TMPDIR',
        'toolchain_file': 'TOOLCHAIN',
        'install_prefix': 'TARGET_PREFIX_DIR',
        'install_rpath': 'CMAKE_INSTALL_RPATH',
        'warning_flags': 'NOWARN',
        'dependency_include_flags': 'DEPEND_INCLUDE_DIRS_SWITCH',
        'linker_flags': 'CMAKE_EXE_LINKER_FLAGS',
        'executable': 'CMAKE_BIN',
        'module_path': 'CMAKE_MODULE_PATH',
        'installed_prefix': 'CMAKE_INSTALLED_PREFIX',
        'native_install_prefix': 'NATIVE_PREFIX_DIR',
        'python_executable': 'PYTHON_BIN',
        'system_program_path': 'CMAKE_SYSTEM_PROGRAM_PATH',
        'program_path': 'CMAKE_PROGRAM_PATH',
        'prefix_path': 'CMAKE_PREFIX_PATH',
        'c_flags': 'CMAKE_C_FLAGS',
        'cxx_flags': 'CMAKE_CXX_FLAGS',
        'system_name': 'CURRENT_SYSNAME_SHORT',
        'use_have_flags': 'USE_HAVE_FLAGS',
        'top_dir': 'TOPDIR',
        'target_suffix': 'CURRENT_TARGET_SUFFIX',
        'target_prefix': 'CURRENT_TARGET_PREFIX',
        'native_target': 'NATIVE_TARGET',
        'native_target_suffix': 'NATIVE_TARGET_SUFFIX',
        'native_target_prefix': 'NATIVE_TARGET_PREFIX',
        'options': 'CMAKE_OPTIONS',
        'make_program': 'CMAKE_MAKE_PROGRAM',
        'generator': 'CMAKE_GENERATOR',
        'source_dir': 'CMAKE_SRC_DIR',
        'toolchain_library_path': 'TOOLCHAIN_LD_LIBRARY_PATH',
        'build_dir': 'B',
    }
    config = {name: d.getVar(variable) for name, variable in variables.items()}
    argv, cwd, env = CBuildConfigureCMake(config).configure()
    bb.note('CONFIGURE: ' + shlex.join(argv))
    result = subprocess.run(argv, cwd=cwd, env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True)
    if result.returncode:
        bb.plain(result.stdout)
        raise RuntimeError('CMAKE CONFIGURE FAILED: ' + str(result.returncode))
    for line in result.stdout.splitlines():
        bb.note(line)
}
