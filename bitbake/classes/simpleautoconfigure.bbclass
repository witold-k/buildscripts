TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NATIVE_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${NATIVE_TARGET}-toolchain.meson"

#
# autotool_autogen is not called automaticly
# in case it is needed, because of an ./autogen.sh script
# it should be called in:
#     do_patch
# of the according bitbake reciepe
#
addtask autotools_aclocal
do_autotools_aclocal[nostamp] = "1"
do_autotools_aclocal[dirs] = "${S}"
python do_autotools_aclocal() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    os.system('aclocal')
}

#
# autotool_autoconf is not called automaticly
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_autoconf
do_autotools_autoconf[nostamp] = "1"
do_autotools_autoconf[dirs] = "${S}"
python do_autotools_autoconf() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    if not os.path.isfile('configure'):
        bb.warn(ccd + ': autoconf')
        os.system('autoconf')

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}

#
# autotools_automake is not called automaticly
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_automake
do_autotools_automake[nostamp] = "1"
do_autotools_automake[dirs] = "${S}"
python do_autotools_automake() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    if not os.path.isfile('configure'):
        bb.warn(ccd + ': automake')
        os.system('automake --add-missing')
}

#
# autotools_automake_foreign is not called automaticly
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_automake
do_autotools_automake[nostamp] = "1"
do_autotools_automake[dirs] = "${S}"
python do_autotools_automake() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    if not os.path.isfile('Makefile.in'):
        bb.warn(ccd + ': automake')
        os.system('automake --add-missing --foreign')
}


#
# autotool_autoreconf is not called automaticly
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_autoreconf
do_autotools_autoreconf[nostamp] = "1"
do_autotools_autoreconf[dirs] = "${S}"
python do_autotools_autoreconf() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    if not os.path.isfile('configure'):
        bb.warn(ccd + ': autoreconf')
        os.system('autoreconf -i -f')

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}

#
# autotool_autoreconf is not called automaticly
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_full_autoreconf
do_autotools_full_autoreconf[nostamp] = "1"
do_autotools_full_autoreconf[dirs] = "${S}"
python do_autotools_full_autoreconf() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_clean_automake', d)
    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    if not os.path.isfile('configure'):
        bb.warn(ccd + ': full autoreconf')
        os.system('aclocal')
        os.system('autoconf')
        os.system('automake --add-missing --force-missing')
        os.system('autoreconf -i -f')

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}


#
# autotool_autogen is not called automaticly
# in case it is needed, because of an ./autogen.sh script
# it should be called in:
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_autogen
do_autotools_autogen[nostamp] = "1"
do_autotools_autogen[dirs] = "${S}"
python do_autotools_autogen() {
    import fileutils

    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    files = d.getVar('FILE_DIRNAME') + '/files'
    config = files + '/configure'
    if os.path.exists(config):
        bb.warn('use cached: ' + config)
        fileutils.copy_file(config, s + '/configure')
    else:
        ao = d.getVar('CONFIGURE_AUTOGEN_OPTIONS') or ''
        if not os.path.isfile('configure'):
            bb.warn(s + ': autogen ' + ao)
            os.system('./autogen.sh ' + ao)
        # fileutils.copy_file(s + '/configure', config)

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}

#
# autotool_autogen is not called automaticly
# in case it is needed, because of an ./autogen.sh script
# it should be called in:
# do_patch
#
# of the according bitbake reciepe
# do_patch, because it pollutes the source tree.
#
addtask autotools_autogen_reconf
do_autotools_autogen_reconf[nostamp] = "1"
do_autotools_autogen_reconf[dirs] = "${S}"
python do_autotools_autogen_reconf() {
    import fileutils

    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS')
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS')
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    bb.build.exec_func('do_configure_copy', d)
    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    os.chdir(ccd)

    files = d.getVar('FILE_DIRNAME') + '/files'
    config = files + '/configure'
    if os.path.exists(config):
        bb.warn('use cached: ' + config)
        fileutils.copy_file(config, s + '/configure')
    else:
        ao = d.getVar('CONFIGURE_AUTOGEN_OPTIONS') or ''
        if not os.path.isfile('configure'):
            bb.warn(s + ': autogen_reconf ' + ao)
            os.system('./autogen.sh ' + ao)
            os.system('autoreconf --install --force')
        # fileutils.copy_file(s + '/configure', config)

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}

#
# autotools_bootstrap is not called automaticly
# in case it is needed, because of an bootstrap or .bootstrap script
# it should be called in:
#     do_patch
# of the according bitbake reciepe
#
# do_patch, because it pollutes the source tree.
#
addtask autotools_fake_bootstrap
do_autotools_fake_bootstrap[nostamp] = "1"
do_autotools_fake_bootstrap[dirs] = "${S}"
python do_autotools_fake_bootstrap() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    nw = d.getVar('NOWARN') or ''

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS') + ' ' + nw
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS') + ' ' + nw
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    bb.build.exec_func('do_configure_copy', d)
    os.chdir(ccd)

    ao = d.getVar('CONFIGURE_BOOTSTRAP_OPTIONS') or ''
    if not os.path.isfile('configure'):
        if os.path.isfile('.bootstrap') or os.path.islink('.bootstrap'):
            bb.warn('execute .bootstrap ' + ao)
            os.system('./.bootstrap ' + ao)
        elif os.path.isfile('bootstrap') or os.path.islink('bootstrap'):
            bb.warn('execute bootstrap ' + ao)
            os.system('./bootstrap ' + ao)
        elif os.path.isfile('Bootstrap') or os.path.islink('Bootstrap'):
            bb.warn('execute Bootstrap ' + ao)
            os.system('./Bootstrap ' + ao)
        else:
            raise Exception('no bootstrap found')

    if os.path.isfile('configure'):
       os.remove('configure')

}


#
# autotools_bootstrap is not called automaticly
# in case it is needed, because of an bootstrap or .bootstrap script
# it should be called in:
#     do_patch
# of the according bitbake reciepe
#
# do_patch, because it pollutes the source tree.
#
addtask autotools_bootstrap
do_autotools_bootstrap[nostamp] = "1"
do_autotools_bootstrap[dirs] = "${S}"
python do_autotools_bootstrap() {
    apply_meson_properties(d.getVar('TOOLCHAIN'), d)
    s = d.getVar('S')
    b = d.getVar('B')

    nw = d.getVar('NOWARN') or ''

    os.environ['CFLAGS']          = d.getVar('CONFIGURE_CFLAGS') + ' ' + nw
    os.environ['CXXFLAGS']        = d.getVar('CONFIGURE_CXXFLAGS') + ' ' + nw
    os.environ['LDFLAGS']         = d.getVar('CONFIGURE_LDFLAGS')
    os.environ['LIBS']            = d.getVar('CONFIGURE_LIBS')
    os.environ['PKG_CONFIG_PATH'] = d.getVar('CONFIGURE_PKG_CONFIG_PATH')
    os.environ['PKG_CONFIG_PATH_FOR_BUILD'] = d.getVar('CONFIGURE_NATIVE_PKG_CONFIG_PATH')

    ccd = d.getVar('CONFIGURE_CONFIGURE_DIR')
    bb.build.exec_func('do_configure_copy', d)
    os.chdir(ccd)

    ao = d.getVar('CONFIGURE_BOOTSTRAP_OPTIONS') or ''
    if not os.path.isfile('configure'):
        if os.path.isfile('.bootstrap') or os.path.islink('.bootstrap'):
            bb.warn('execute .bootstrap ' + ao)
            os.system('./.bootstrap ' + ao)
        elif os.path.isfile('bootstrap') or os.path.islink('bootstrap'):
            bb.warn('execute bootstrap ' + ao)
            os.system('./bootstrap ' + ao)
        elif os.path.isfile('Bootstrap') or  os.path.islink('Bootstrap'):
            bb.warn('execute Bootstrap ' + ao)
            os.system('./Bootstrap ' + ao)
        else:
            raise Exception('no bootstrap found')

    if not os.path.isfile('configure'):
        raise Exception('no configuration file generated in: ' + ccd)
}


