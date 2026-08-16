def apply_meson_properties(file, d, ctar=None, set_environment=True, skip_sysroot=False):
    import keyvalue

    file = open(file, 'r')
    lines = file.readlines()
    file.close()

    if ctar is None:
        ctar = d.getVar('CURRENT_TARGET')
    if ctar is None:
        raise Exception('CURRENT_TARGET not set')
    cver = d.getVar('COMPILER_VERSION')
    if cver is None:
        raise Exception('COMPILER_VERSION not set')
    cver = cver.replace("'", '')
    cdir = d.getVar('COMPILER_DIR')
    if cdir is None:
        raise Exception('COMPILER_DIR not set')
    cdir = cdir.replace("'", '')
    cname = None
    cbase = None
    cbin  = None
    cprefix = None

    for line in lines:
        linestr = line.strip()
        kv = keyvalue.KeyValue.fromAssign(linestr)
        if kv.valid():
            if kv.value != None:
                if cname is not None:
                    kv.value = kv.value.replace("' + toolchain_name + '", cname)
                    kv.value = kv.value.replace("toolchain_name + '", "'" + cname)
                    kv.value = kv.value.replace("' + toolchain_name", cname + "'")
                if cver is not None:
                    kv.value = kv.value.replace("' + toolchain_version + '", cver)
                    kv.value = kv.value.replace("toolchain_version + '", "'" + cver)
                    kv.value = kv.value.replace("' + toolchain_version", cver + "'")
                if cdir is not None:
                    kv.value = kv.value.replace("' + toolchain_dir + '", cdir)
                    kv.value = kv.value.replace("toolchain_dir + '", "'" + cdir)
                    kv.value = kv.value.replace("toolchain_dir", cdir)
                if cbase is not None:
                    kv.value = kv.value.replace("' + toolchain_base + '", cbase)
                    kv.value = kv.value.replace("toolchain_base + '", "'" + cbase)
                    kv.value = kv.value.replace("toolchain_base", cbase)
                if cbin is not None:
                    kv.value = kv.value.replace("' + toolchain_bin + '", cbin)
                    kv.value = kv.value.replace("toolchain_bin + '", "'" + cbin)
                    kv.value = kv.value.replace("toolchain_bin", cbin)
                if cprefix is not None:
                    kv.value = kv.value.replace("toolchain_prefix + '", "'" + cprefix)
                    kv.value = kv.value.strip("'")

            if kv.key == 'toolchain_name':
                cname = kv.value.replace("'", "")
            if kv.key == 'toolchain_version':
                cver = kv.value.replace("'", "")
            if kv.key == 'toolchain_prefix':
                cprefix = kv.value.replace("'", "")
            if kv.key == 'toolchain_base':
                cbase = kv.value.replace("'", "")
            if kv.key == 'toolchain_dir':
                cdir = kv.value.replace("'", "")
            if kv.key == 'toolchain_bin':
                cbin = kv.value.replace("'", "")

            d.setVar(kv.key, kv.value)
            if (kv.key == 'c'):
                d.setVar('CC', kv.value)
            if (kv.key == 'cpp'):
                d.setVar('CXX', kv.value)
            if (kv.key == 'fc'):
                d.setVar('FC', kv.value)
            if (kv.key == 'ar'):
                d.setVar('AR', kv.value)
            if (kv.key == 'ld'):
                d.setVar('LD', kv.value)
            if (kv.key == 'strip'):
                d.setVar('STRIP', kv.value)
                d.setVar('STRIPPROG', kv.value)
            if (kv.key == 'toolchain_ld_library_path'):
                d.setVar('TOOLCHAIN_LD_LIBRARY_PATH', kv.value)
            if (kv.key == 'sys_root'):
                d.setVar('SYSROOT', kv.value)
                d.setVar('SYSROOT_SWITCH', '--sysroot=' + kv.value)

    for line in lines:
        linestr = line.strip()
        kv = keyvalue.KeyValue.fromAssignOrCharArray(linestr)
        if kv.valid():
            if (kv.key == 'CFLAGS'):
                d.setVar('CFLAGS', kv.value)
            if (kv == 'CXXFLAGS'):
                d.setVar('CXXFLAGS', kv.value)
            if (kv.key == 'LDFLAGS'):
                d.setVar('LDFLAGS', kv.value)

    if not skip_sysroot:
        sr = d.getVar('SYSROOT_SWITCH')
        if sr != None:
            d.setVar('CFLAGS',   sr + ' ' + (d.getVar('CFLAGS') or ''))
            d.setVar('CXXFLAGS', sr + ' ' + (d.getVar('CXXFLAGS') or ''))
            d.setVar('LDFLAGS',  sr + ' ' + (d.getVar('LDFLAGS') or ''))

    if set_environment:
        import os
        e = d.getVar('AR')
        if e != None: os.environ['AR'] = e
        e = d.getVar('CC')
        if e != None: os.environ['CC'] = e
        e = d.getVar('CXX')
        if e != None: os.environ['CXX'] = e
        e = d.getVar('FC')
        if e != None: os.environ['FC'] = e
        e = d.getVar('LD')
        if e != None: os.environ['LD'] = e
        e = d.getVar('STRIP')
        if e != None:
            os.environ['STRIP'] = e
            os.environ['STRIPPROG'] = e
        e = d.getVar('LIBTOOL')
        if e != None: os.environ['LIBTOOL'] = e
        e = d.getVar('SYSROOT')
        if e != None: os.environ['SYSROOT'] = e
        e = d.getVar('SYSROOT_SWITCH')
        if e != None: os.environ['SYSROOT_SWITCH'] = e
        e = d.getVar('CFLAGS')
        if e != None: os.environ['CFLAGS'] = e
        e = d.getVar('CXXFLAGS')
        if e != None: os.environ['CXXFLAGS'] = e
        e = d.getVar('LDFLAGS')
        if e != None: os.environ['LDFLAGS'] = e
        e = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
        if e != None: os.environ['TOOLCHAIN_LD_LIBRARY_PATH'] = e

