inherit test populate

MESON_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"
NINJA_NINJA_BIN ?= "${NINJA_BIN}"
NINJA_MAKE_BIN  ?= "${MAKE_BIN}"
NINJA_NPROC ?= "${NPROC}"

python do_compile() {
    import subprocess, sys, os
    from mesonproperties import apply_meson_properties

    apply_meson_properties(d.getVar('MESON_TOOLCHAIN'), d)

    b  = d.getVar('B')
    mn = d.getVar('NINJA_NPROC')
    no = d.getVar('NINJA_OPTIONS') or ''

    if os.path.exists(b + '/build.ninja'):
        mp  = d.getVar('NINJA_NINJA_BIN')
        cmd = mp + ' ' + no + " -j " + mn + " -C " + b

    elif os.path.exists(b + '/Makefile'):
        mp  = d.getVar('NINJA_MAKE_BIN')
        cmd = mp + " -j " + mn + " -C " + b

    else:
        raise Exception('No build.ninja or Makefile found in ' + b)

    bb.note("BUILD_DIR: " + b)
    bb.note(cmd)

    env = os.environ.copy()

    ldlp = d.getVar('TOOLCHAIN_LD_LIBRARY_PATH')
    if ldlp is not None:
        env['LD_LIBRARY_PATH'] = ldlp
    p = subprocess.Popen(cmd, shell=True, cwd=b, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = p.stdout.readlines();
    retval = p.wait()
    p.stdout.close()

    dw = d.getVar('DO_MAKE_COMPILE_WRITABLE')
    if dw == 'True':
        for current_dir, subdirs, files in os.walk('.'):
            for filename in files:
                fn = os.path.join(current_dir, filename)
                os.chmod(fn, 0o740)
    if (retval):
        for line in lines:
            bb.plain(line.decode(encoding = 'utf-8', errors = 'ignore').rstrip())
        bb.error('BUILD FAILED: ' + b)
        bb.warn('cd ' + b + ' && ' + cmd)
        sys.exit(retval)
}

python do_install() {
    import subprocess, sys, bbtools, os, shutil, struct

    s   = d.getVar('S')
    b   = d.getVar('B')
    tpd = d.getVar('TARGET_PREFIX_DIR')

    inst = d.getVar('INSTALL_DIR')
    env  = os.environ.copy()
    env['DESTDIR'] = inst

    if os.path.exists(b + '/build.ninja'):
        mp = d.getVar('NINJA_NINJA_BIN')
    elif os.path.exists(b + '/Makefile'):
        mp = d.getVar('NINJA_MAKE_BIN')
    else:
        raise Exception('No build.ninja or Makefile found in ' + b)

    os.makedirs(inst, exist_ok=True)
    cmd = [mp, '-C', b, 'install']
    p = subprocess.Popen(
        cmd, cwd=b, env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT
    )
    lines = p.stdout.readlines()
    retval = p.wait()
    p.stdout.close()

    if retval:
        for line in lines:
            bb.plain(line.decode('utf-8', errors='replace').rstrip())
        bb.error('INSTALL FAILED: ' + b)
        sys.exit(retval)

    # Explicit -Wl,-rpath flags in CIDE's build linker arguments are
    # not managed by Meson/CMake and survive their install-time RPATH
    # rewriting. Keep those paths during compilation and tests; strip
    # only CIDE work-directory entries from installed ELF files.
    work_root = os.path.abspath(os.path.join(d.getVar('TMPDIR'), 'work'))
    work_prefix = work_root + os.sep
    patchelf = shutil.which(d.getVar('PATCHELF_BIN') or 'patchelf')
    readelf = shutil.which(d.getVar('READELF_BIN') or 'readelf')
    changed = 0

    for root, dirs, files in os.walk(inst):
        for name in files:
            filename = os.path.join(root, name)
            if os.path.islink(filename):
                continue

            with open(filename, 'rb') as elf:
                header = elf.read(18)
            if len(header) < 18 or header[:4] != b'\x7fELF':
                continue

            # ET_EXEC / ET_DYN only; do not attempt to patch object files.
            endian = '<' if header[5] == 1 else '>' if header[5] == 2 else None
            if endian is None:
                continue
            elf_type = struct.unpack(endian + 'H', header[16:18])[0]
            if elf_type not in (2, 3):
                continue

            if not readelf:
                raise RuntimeError('readelf is required for RPATH inspection')
            dynamic = subprocess.run(
                [readelf, '-d', filename],
                capture_output=True, text=True, check=True
            ).stdout
            if work_prefix not in dynamic:
                continue
            if not patchelf:
                raise RuntimeError(
                    'patchelf is required for CIDE install RPATH cleanup'
                )
            old = subprocess.run(
                [patchelf, '--print-rpath', filename],
                capture_output=True, text=True, check=True
            ).stdout.strip()
            paths = old.split(':') if old else []
            retained = [
                entry for entry in paths
                if not (entry == work_root or entry.startswith(work_prefix))
            ]
            if len(retained) == len(paths):
                continue

            # Preserve existing non-staging entries, and add paths that
            # work for both installed executables and shared libraries.
            for relative in ('$ORIGIN', '$ORIGIN/../lib', '$ORIGIN/../lib64'):
                if relative not in retained:
                    retained.append(relative)

            # Preserve DT_RPATH versus DT_RUNPATH semantics.
            args = [patchelf]
            if '(RPATH)' in dynamic:
                args.append('--force-rpath')
            args.extend(['--set-rpath', ':'.join(retained), filename])
            subprocess.run(args, check=True)

            verified = subprocess.run(
                [patchelf, '--print-rpath', filename],
                capture_output=True, text=True, check=True
            ).stdout.strip()
            if any(
                item == work_root or item.startswith(work_prefix)
                for item in verified.split(':')
            ):
                raise RuntimeError('Staging RPATH survived fixup: ' + filename)
            changed += 1

    bb.note('INSTALL RPATH: cleaned {} ELF files in {}'.format(changed, inst))

    bbtools.installpkgconfig(bb, d, d.getVar('FILE_DIRNAME'), tpd, s, inst)
}

