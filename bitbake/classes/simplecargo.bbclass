inherit test populate

TOOLCHAIN = "${TOPDIR}/../toolchains/cargo/${CURRENT_TARGET}-toolchain.cargo"

python do_compile() {
    os.environ['CARGO_TARGET_DIR'] = d.getVar('B')
    os.system("cargo build")
}

python do_install() {
    import bbtools

    s  = d.getVar('S')
    tpd = d.getVar('TARGET_PREFIX_DIR')

    inst = d.getVar('INSTALL_DIR')
    os.system("cargo install --root " + id)
    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), tpd, s, inst)
}

#  ENV
#  CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc
#  CC_aarch64_unknown_linux_gnu=aarch64-linux-gnu-gcc
#  CXX_aarch64_unknown_linux_gnu=aarch64-linux-gnu-g++


