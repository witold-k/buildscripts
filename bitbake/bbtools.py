import os, pkgconfig, fileutils, buildjobs


def list_dir_as_warn(bb, dir):
    bb.warn("DIR: " + dir)
    items = os.listdir(dir)
    bb.warn(str(items))


def do_autogen(bb, dir=None):
    cmd = ["bash", "autogen.sh"]
    dp = buildjobs.DoProcess(cmd, cwd=dir)
    retval = dp.run()
    if retval != 0:
        bb.warn("FAILED: " + str(cmd))


def installpkgconfig(bb, d, bbdir, target_prefix, src_dir, dest_dir):
    dest_pc_dir = d.getVar('TMPDIR') + '/moduleref/' + d.getVar('CURRENT_TARGET')
    prefix = d.getVar('TARGET_PREFIX_DIR')
    install_pc_dir = d.getVar('INSTALL_DIR') + '/' + prefix + '/lib/pkgconfig'

    for root, _, files in os.walk(bbdir):
        for filename in files:
            pkgconfig.PkgConfig.generate_pkgconfig(dest_dir, target_prefix, root + '/' + filename, dest_pc_dir)
            pkgconfig.PkgConfig.generate_pkgconfig(None, target_prefix, root + '/' + filename, install_pc_dir)


def link_lib64(d):
    prefix = d.getVar('TARGET_PREFIX_DIR')
    install_dir = d.getVar('INSTALL_DIR') + '/' + prefix
    lib_dir   = install_dir + '/lib'
    lib64_dir = install_dir + '/lib64'
    fileutils.create_symlinks(lib64_dir, lib_dir)
