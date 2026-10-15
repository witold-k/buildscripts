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
    from cbuildconfigure_classes.cbuildconfigure_cmake import CBuildConfigureCMake
    CBuildConfigureCMake(d).configure(bb)
}
