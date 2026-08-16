inherit mesonproperties simpleninja test populate

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
    import subprocess, sys, bbdefaultvars
    apply_meson_properties(d.getVar('MESON_TOOLCHAIN'), d)
    bbdefaultvars.bbdefaultvars(bb, d)

    module = d.getVar('MODULE')
    if (module == None): raise Exception('CONFIGURE: MODULE NOT SET')

    env = os.environ.copy()

    bbct  = d.getVar('CURRENT_TARGET')
    sdk_dir = d.getVar('SDK_DIR')
    if sdk_dir != None:
        env['SDK_DIR'] = sdk_dir + '/' + bbct

    # =========================================================================
    # PRISTINE PYTHON PKG_CONFIG & FIND_ROOT BUILDER (NO STRING REPLACEMENTS)
    # =========================================================================
    find_roots = []

    # Safe extraction of the primary PKG_CONFIG_PATH variable
    base_pc = d.getVar('PKG_CONFIG_PATH')
    if base_pc is not None:
        # Strip structural delimiters and spaces strictly from edge boundaries
        base_pc_clean = base_pc.strip().strip(';').strip()
        if base_pc_clean:
            find_roots.append(base_pc_clean)

    # Dynamically build and verify your workspace modular references path
    tmp_dir = d.getVar('TMPDIR')
    if tmp_dir is not None and bbct is not None:
        moduleref_path = f"{tmp_dir}/moduleref/{bbct}"
        find_roots.append(moduleref_path)

    # Re-join clean items with a single semicolon for PkgConfig environment routing
    custom_pkg_config = ";".join(find_roots)
    env['PKG_CONFIG_PATH'] = custom_pkg_config

    # =========================================================================
    # PKG-CONFIG SAFE CROSS-ISOLATION FIREWALL
    # =========================================================================
    env['PKG_CONFIG_LIBDIR'] = ""
    env['PKG_CONFIG_SYSROOT_DIR'] = ""
    env['PKG_CONFIG_ALLOW_SYSTEM_LIBS'] = "0"
    env['PKG_CONFIG_ALLOW_SYSTEM_CFLAGS'] = "0"
    str_pkg_options = " --define-prefix "
    # =========================================================================

    b  = d.getVar('B')
    nw = ' ' + (d.getVar('NOWARN') or '') + ' '  + (d.getVar('DEPEND_INCLUDE_DIRS_SWITCH') or '')

    cmake_bin = d.getVar('CMAKE_BIN')
    mp = d.getVar('CMAKE_MAKE_PROGRAM')
    mo = d.getVar('CMAKE_MAKE_OPTIONS')
    mn = d.getVar('NPROC') or d.getVar('CMAKE_NPROC')

    tc = d.getVar('TOOLCHAIN')
    csns = d.getVar('CURRENT_SYSNAME_SHORT')
    csd = d.getVar('CMAKE_SRC_DIR')
    cspp = d.getVar('CMAKE_SYSTEM_PROGRAM_PATH')
    cprp = d.getVar('CMAKE_PROGRAM_PATH')

    cmp   = d.getVar('CMAKE_MODULE_PATH')
    cirp  = d.getVar('CMAKE_INSTALL_RPATH')
    cpp   = d.getVar('CMAKE_PREFIX_PATH')
    cbrp  = None
    ccf   = None
    cxxf  = None
    crbp  = ''
    ccf   = (d.getVar('CMAKE_C_FLAGS') or '') + nw
    cxxf  = (d.getVar('CMAKE_CXX_FLAGS') or '') + nw

    celf  = (d.getVar('CMAKE_EXE_LINKER_FLAGS') or '')

    cgen  = d.getVar('CMAKE_GENERATOR')
    tpd   = d.getVar('TARGET_PREFIX_DIR')
    npd   = d.getVar('NATIVE_PREFIX_DIR')
    bbtd  = d.getVar('TOPDIR')
    bbwd  = d.getVar('TMPDIR') + '/work'
    copt  = d.getVar('CMAKE_OPTIONS')
    uhf   = d.getVar('USE_HAVE_FLAGS')

    bb.note('MODULE PATH: ' + cmp)
    bb.note('TOOLCHAIN:   ' + tc)
    bb.note("BUILD_DIR: " + b)
    bb.note('CMAKE_MAKE_PROGRAM: ' + mp)
    bb.note('NOTE GENERATOR: ' + cgen)

    os.makedirs(b, exist_ok=True)
    str  = cmake_bin + " -DCMAKE_TOOLCHAIN_FILE=" + tc
    str += " -DPKG_CONFIG_ARGUMENTS=\"" + str_pkg_options + "\""

    # =========================================================================
    # SAFE SEMICOLON SPLITTING FOR RE-ROUTING FIND DIRECTORIES INDEX
    # =========================================================================
    # Append the absolute targeted cross-compiler root sysroot directory to the list
    tc_ver = d.getVar('COMPILER_VERSION')
    if tc_ver is not None and bbct is not None:
        compiler_sysroot = f"/opt/compiler/{tc_ver}/{tc_ver}/x-tools/{bbct}/{bbct}/sysroot"
        find_roots.append(compiler_sysroot)

    # Re-join into a perfectly formed semicolon string for CMake's parser (No empty leading items)
    unified_find_root = ";".join(find_roots)

    str += " -DCMAKE_FIND_ROOT_PATH=\"" + unified_find_root + "\""

    # Strictly lock down search modes to prevent fallback scanning inside the host buildsystems directory
    str += " -DCMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH=OFF"
    str += " -DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF"
    str += " -DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF"
    str += " -DCMAKE_FIND_USE_CMAKE_PACKAGE_REGISTRY=OFF"
    str += " -DCMAKE_FIND_USE_CMAKE_PATH=OFF"
    str += " -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER"
    str += " -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY"
    str += " -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY"
    str += " -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY"
    # =========================================================================

    str += " -DCMAKE_MODULE_PATH:PATH=\"" + cmp + "\\;\""
    str += " -DCMAKE_INSTALL_PREFIX:PATH=" + tpd
    str += " -DCMAKE_INSTALLED_PREFIX:PATH=" + d.getVar('CMAKE_INSTALLED_PREFIX')
    str += " -DCMAKE_INSTALL_NATIVE_PREFIX:PATH=" + npd
    str += " -DCMAKE_EXPORT_COMPILE_COMMANDS=1"
    str += " -DTOOLCHAIN_VERSION=" + (tc_ver or '')
    str += " -DPython3_EXECUTABLE=" + d.getVar('PYTHON_BIN')
    str += " -DCMAKE_POLICY_VERSION_MINIMUM=3.30 "
    if None != cirp:
        str += " -DCMAKE_INSTALL_RPATH:PATH=" + cirp
    if None != cspp:
        str += " -DCMAKE_SYSTEM_PROGRAM_PATH:PATH=" + cspp
    if None != cprp:
        str += " -DCMAKE_PROGRAM_PATH:PATH=" +cprp
    if None != cbrp:
        str += " -DCMAKE_BUILD_RPATH:PATH=" + cbrp
    if None != cpp:
        str += " -DCMAKE_PREFIX_PATH:PATH=" + cpp
    if None != ccf:
        str += " -DCMAKE_C_FLAGS_CMDL=\"" + ccf + "\""
    if None != cxxf:
        str += " -DCMAKE_CXX_FLAGS_CMDL=\"" + cxxf + "\""
    if None != csns:
        str += " -DCURRENT_SYSNAME_SHORT=" + csns
    if None != celf:
        str += " -DCMAKE_EXE_LINKER_FLAGS=\"" + celf + "\""
    if None != uhf:
        str += " -DUSE_HAVE_FLAGS:BOOL=\"" + uhf + "\""
    str += " -DBB_TOP_DIR=" + bbtd
    str += " -DBB_TARGET=" + bbct
    str += " -DBB_TARGET_SUFFIX=" + d.getVar('CURRENT_TARGET_SUFFIX')
    str += " -DBB_TARGET_PREFIX=" + d.getVar('CURRENT_TARGET_PREFIX')
    str += " -DBB_NATIVE_TARGET=" + d.getVar('NATIVE_TARGET')
    str += " -DBB_NATIVE_TARGET_SUFFIX=" + d.getVar('NATIVE_TARGET_SUFFIX')
    str += " -DBB_NATIVE_TARGET_PREFIX=" + d.getVar('NATIVE_TARGET_PREFIX')
    str += " -DBB_WORK_DIR=" + bbwd
    if None != copt:
        str += " " + copt
    str += " -DCMAKE_MAKE_PROGRAM=" + mp
    str += " -G \"" + cgen + "\" " + csd

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        env['LD_LIBRARY_PATH'] = ldlp
    p = subprocess.Popen(str, shell=True, cwd=b, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    if (retval):
        for line in lines:
            bb.plain(line.decode(encoding = 'utf-8', errors = 'ignore').rstrip())
        bb.error('CONFIGURE FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + str)
        sys.exit(retval)
    else:
        for line in lines:
            bb.note(line.decode(encoding = 'utf-8', errors = 'ignore').rstrip())
}

