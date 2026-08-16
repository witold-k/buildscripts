python do_populate() {
    import fileutils

    inst = d.getVar('INSTALL_DIR') + '/' + d.getVar('TARGET_PREFIX_DIR')
    if os.path.isdir(inst):
        dest = d.getVar('IMAGE_ROOTFS')
        if not os.path.isdir(dest):
            os.makedirs(dest, 0o755, exist_ok = True)
        fileutils.copy_files(inst, dest, follow_symlinks = False)
}
