addtask showdata
do_showdata[nostamp] = "1"
python do_showdata() {
    import sys
    # emit variables and shell functions
    bb.data.emit_env(sys.__stdout__, d, True)
    # emit the metadata which isnt valid shell
    for e in bb.data.keys(d):
        if d.getVarFlag(e, 'python', False):
            bb.plain("\npython %s () {\n%s}" % (e, d.getVar(e, True)))
}

addtask listtasks
do_listtasks[nostamp] = "1"
python do_listtasks() {
    import sys
    for e in bb.data.keys(d):
        if d.getVarFlag(e, 'task', False):
            bb.plain("%s" % e)
}

addtask clean
do_clean[nostamp] = "1"
python do_clean() {
    import shutil
    b = d.getVar('B')
    if os.path.isdir(b):
        shutil.rmtree(b)
}

addtask mrproper
do_mrproper[nostamp] = "1"
python do_mrproper() {
    import shutil
    b = d.getVar('B')
    if os.path.isdir(b):
        shutil.rmtree(b)
    s = d.getVar('S')
    if os.path.isdir('s' + "/" + '.git'):
        call("git checkout .", cwd = s)
        call("git clean -xdf", cwd = s)
}

python () {
    d.setVar('NPROC', str(os.cpu_count()))

    origenv = d.getVar("BB_ORIGENV", False)
    compiler_dir = origenv.getVar("COMPILER_DIR", False)
    d.setVar("COMPILER_DIR", compiler_dir)
    compiler_version = origenv.getVar("COMPILER_VERSION", False)
    d.setVar("COMPILER_VERSION", compiler_version)

    exc = d.getVar('BBCLASSEXTENDCURR')
    if (exc != None):
        ct  = exc
        tt  = exc
    else:
        ct = 'invalid'
        tt  = ''

    nt = d.getVar('NATIVE_TARGET')
    is_n = exc != None and nt in exc
    d.setVar('IS_NATIVE', is_n)

    d.setVar('CURRENT_EXTEND', exc)
    d.setVar('CURRENT_TARGET', ct)
    d.setVar('CURRENT_TARGET_SUFFIX', ct + '-')
    d.setVar('CURRENT_TARGET_PREFIX', '-' + ct)
    if ct is not None:
        d.setVar('COMPILER_PREFIX', compiler_dir + '/' + compiler_version + '/x-tools/' + ct + '/bin/' + ct + '-')
    d.setVar('HOST_TARGET', tt)
    d.setVar('LD_LINUX_SO', 'ld-linux.so')

    rt = d.getVar('ROOT_DIR')
    if rt is not None:
        import sys
        from pathlib import Path
        path = d.getVar('ROOT_DIR') + '/buildscripts/python'
        # bb.warn('ADDPATH: ' + path)
        sys.path.insert(0, path)
}

# ------------------- check_need_build ---------------------

addtask check_need_build
do_check_need_build[dirs] = "${S}"
do_check_need_build[nostamp] = "1"
python do_check_need_build() {
    bb.note("do_check_need_build ishould be removed")
}

# -------------------------- build -------------------------

addtask setup
do_setup[dirs] = "${S}"
do_setup[nostamp] = "1"
python do_setup () {
    bb.note("do_setup not implemented")
}

addtask patch
do_patch[dirs] = "${S}"
do_patch[nostamp] = "1"
python do_patch () {
    bb.note("do_patch not implemented")
}

addtask configure
do_configure[dirs] = "${S}"
do_configure[nostamp] = "1"
python do_configure () {
    bb.note("do_configure not implemented")
}

addtask compile
do_compile[dirs] = "${B}"
do_compile[nostamp] = "1"
python do_compile () {
    bb.note("do_compile not implemented")
}

addtask test
do_test[dirs] = "${B}"
do_test[nostamp] = "1"
python do_test () {
    bb.note("do_test not implemented")
}

addtask install
do_install[dirs] = "${INSTALL_DIR}"
do_install[nostamp] = "1"
python do_install () {
    bb.note("do_install not implemented")
}

addtask finalize
do_finalize[dirs] = "${B}"
do_finalize[nostamp] = "1"
python do_finalize () {
    bb.note("do_finalize not implemented")
}

addtask populate
do_populate[dirs] = "${IMAGE_ROOTFS}"
do_populate[nostamp] = "1"
python do_populate () {
     bb.note("do_populate not impemented")
}

addtask deploy
do_deploy[dirs] = "${DEPLOY_DIR}"
do_deploy[nostamp] = "1"
python do_deploy () {
    import fileutils
    #bb.warn('DEPLOY')
    df = d.getVar("DEPLOY_FILES")
    if df == None:
        return

    install = d.getVar("INSTALL_DIR")
    deploy_target = d.getVar('DEPLOY_TARGET')
    deploy  = d.getVar("DEPLOY_DIR") + '/' + deploy_target

    if not os.path.isdir(deploy):
        os.makedirs(deploy, 0o750, exist_ok = True)

    list = df.split()
    for filename in list:
        link = deploy + '/' + filename
        if not os.path.islink(link):
            src = install + '/' + filename
            dst = deploy + '/' + filename
            dir = os.path.dirname(dst)
            src = os.path.relpath(src, dir)
            fileutils.rel_link(src, dst)
}

addtask virtualize
do_virtualize[dirs] = "${B}"
do_virtualize[nostamp] = "1"
python do_virtualize () {
    bb.note("do_populate not impemented")
}


# ------------------------- build ------------------------

addtask build after do_check_need_build
do_build[dirs] = "${S}"
do_build[nostamp] = "1"
python base_do_build () {
    import bbdepend, dirtycheck

    dl = d.getVar('DEPEND_LIST')
    if dl != None:
        bbd = bbdepend.BBDepend.createAll(d, dl)
        d.setVar('TARGET_INCLUDE_DIR_FLAGS', bbd.includeFlags)
        d.setVar('TARGET_LIB_DIR_FLAGS', bbd.libFlags)

    ct = d.getVar('CURRENT_TARGET')
    nt = d.getVar('NATIVE_TARGET')
    if ct == None or ct == 'invalid':
        return None

    ca_list = ct.split('-', 1)
    if ca_list != None:
        ca = ca_list[0]
        d.setVar('CURRENT_ARCH', ca)

    can_build = True
    if d.getVar('SKIP_BUILD') != 'True':
        sc = d.getVar('SKIP_CROSS')     == 'True'
        sn = d.getVar('SKIP_NATIVE')    == 'True'
        isn = d.getVar('IS_NATIVE')

        can_build = True
        if isn:
            can_build = not sn
        else:
            can_build = not sc
    else:
        can_build = False

    if not can_build:
        return None

    pkgbase = d.getVar('PKG_BASE')
    if pkgbase != None:
        pkgpath = ""
        if len(pkgbase) > 0:
            entry = pkgbase[0]
            pkgpath += entry + '/' + ct + '/lib/pkgconfig'
            pkgpath += ':' + entry + '/' + ct + '/share/pkgconfig'
        for entry in pkgbase[1:]:
            pkgpath += ':' + entry + '/' + ct + '/lib/pkgconfig'
            pkgpath += ':' + entry + '/' + ct + '/share/pkgconfig'
        d.setVar('PKG_CONFIG_PATH', pkgpath)

    module = d.getVar('MODULE')
    if module == None:
        bb.error('check_compule: MODULE NOT SET - abort')
        return None

    pb = d.getVar('PREFIX_BASE')
    nv = d.getVar('NEXT_VERSION')
    d.setVar('TARGET_PREFIX_DIR', pb + '/' + nv + '/' + nv + '/' + ct)
    d.setVar('NATIVE_PREFIX_DIR', pb + '/' + nv + '/' + nv + '/' + nt)

    ab = d.getVar('BBALLOWBUILD')
    if ab != None:
        if not ct in ab:
            return None

    dc = dirtycheck.DirtyCheck( \
        src_dirs = [ \
            d.getVar('CHECK_DIR'),
            d.getVar('FILE_DIRNAME') \
        ], \
        save_check_dir = d.getVar('B'), prefix = ct + '-' \
    )

    if dc.check_dirty():
        st = d.getVar('SKIP_TEST')
        bb.warn('do build')
        bb.build.exec_func('do_setup', d)
        bb.build.exec_func('do_patch', d)
        bb.build.exec_func('do_configure', d)
        bb.build.exec_func('do_compile', d)
        if ct == 'native' and st != 'True':
            bb.build.exec_func('do_test', d)
        bb.build.exec_func('do_install', d)
        bb.build.exec_func('do_finalize', d)
        bb.build.exec_func('do_populate', d)
        bb.build.exec_func('do_deploy', d)
        bb.build.exec_func('do_virtualize', d)
        dc.apply()
}

EXPORT_FUNCTIONS do_clean do_mrproper \
    do_check_need_build \
    do_patch       \
    do_configure   \
    do_compile     \
    do_install     \
    do_populate    \
    do_deploy      \
    do_virtualize  \
    do_finalize    \
    do_build

