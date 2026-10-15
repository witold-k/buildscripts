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
    import os, subprocess, shlex, bbdefaultvars
    from mesonproperties import apply_meson_properties
    from cbuildconfigure_classes.cbuildconfigure_cmake import CBuildConfigureCMake

    apply_meson_properties(d.getVar('MESON_TOOLCHAIN'), d)
    bbdefaultvars.bbdefaultvars(bb, d)
    keys = (
        'MODULE CURRENT_TARGET COMPILER_VERSION SDK_DIR PKG_CONFIG_PATH TMPDIR '
        'TOOLCHAIN TARGET_PREFIX_DIR CMAKE_INSTALL_RPATH NOWARN '
        'DEPEND_INCLUDE_DIRS_SWITCH CMAKE_EXE_LINKER_FLAGS CMAKE_BIN '
        'CMAKE_MODULE_PATH CMAKE_INSTALLED_PREFIX NATIVE_PREFIX_DIR '
        'PYTHON_BIN CMAKE_SYSTEM_PROGRAM_PATH CMAKE_PROGRAM_PATH '
        'CMAKE_PREFIX_PATH CMAKE_C_FLAGS CMAKE_CXX_FLAGS '
        'CURRENT_SYSNAME_SHORT USE_HAVE_FLAGS TOPDIR '
        'CURRENT_TARGET_SUFFIX CURRENT_TARGET_PREFIX NATIVE_TARGET '
        'NATIVE_TARGET_SUFFIX NATIVE_TARGET_PREFIX CMAKE_OPTIONS '
        'CMAKE_MAKE_PROGRAM CMAKE_GENERATOR CMAKE_SRC_DIR '
        'TOOLCHAIN_LD_LIBRARY_PATH B'
    ).split()
    config = {key: d.getVar(key) for key in keys}
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
