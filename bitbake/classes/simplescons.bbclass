inherit populate

TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/scons/${CURRENT_TARGET}-toolchain.scons"
SCONS_SRC_DIR ?= "${S}"
SCONS_GENERATOR ?= "Ninja"
SCONS_MAKE_PROGRAM ?= "/usr/bin/ninja"
SCONS_MAKE_OPTIONS ?= ""
SCONS_NPROC ?= "${NPROC}"

do_configure() {
    TC=$(readlink -m ${TOOLCHAIN})
    SD=$(readlink -m ${SCONS_SRC_DIR})
    echo "toolchain      : ${TC}"
    echo "module path    : ${TOPDIR}/../cmake;${SCONS_MODULE_PATH}"
    echo "framework path : ${SCONS_FRAMEWORK_PATH}"
    echo "prefix path    : ${SCONS_PREFIX_PATH}"
    scons \
          --destdir=${INSTALL_DIR} \
          --prefix=${TARGET_PREFIX_DIR} \
          ${SCONS_OPTIONS} ${SD}
}

python do_compile() {
    b  = d.getVar('B')
    mp = d.getVar('SCONS_MAKE_PROGRAM')
    mo = d.getVar('SCONS_MAKE_OPTIONS')
    mn = d.getVar('SCONS_NPROC')
    str = "" + mp + " " + mo + " -j " + mn + " -C " + b
    bb.note("TOOLCHAIN: " + d.getVar("TOOLCHAIN"))
    bb.note(str)
    if os.system(str): raise Exception('BUILD FAILED: ' + b)
}

python do_install() {
    import bbtools

    s   = d.getVar('S')
    b  = d.getVar('B')
    tpd = d.getVar('TARGET_PREFIX_DIR')
    inst = d.getVar('INSTALL_DIR')

    mp = d.getVar('SCONS_MAKE_PROGRAM')
    mo = d.getVar('SCONS_MAKE_OPTIONS')
    mn = d.getVar('SCONS_NPROC')
    str = "" + mp + " " + mo + " -j " + mn + " -C " + b + " install"
    bb.note(str)
    if os.system(str): raise Exception('INSTALL FAILED: ' + b)

    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), tpd, s, inst)
}
