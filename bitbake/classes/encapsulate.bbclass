INSTALL_DIR      = "${WORKDIR}/install/${CURRENT_TARGET}"


python do_virtualize() {
    import encapsulate, bbdefaultvars
    ct     = d.getVar('CURRENT_TARGET')
    root   = d.getVar('IMAGE_ROOTFS')
    wsd    = root + '/wrapper/src'
    wbd    = root + '/wrapper/bin'
    instd  = d.getVar('INSTALL_DIR')
    tpd    = d.getVar('TARGET_PREFIX_DIR')
    ldso   = d.getVar('LD_LINUX_SO')
    bindir = instd + '/' + tpd + '/bin'
    bbdefaultvars.bbdefaultvars(bb, d, ct)
    compiler = d.getVar('GCC_BIN')
    encapsulate.encapsulate_compile(compiler, wsd, wbd, bindir, ldso)
}
