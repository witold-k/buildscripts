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
    from cbuildconfigure_classes.cbuildconfigure_meson import CBuildConfigureMeson
    CBuildConfigureMeson(d).configure(bb)
}
