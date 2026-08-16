import os, buildpaths, jsonenvironment, fileutils, subprocess

def get_cmake_version(bb, cmake_bin):
    result = subprocess.run(
        [cmake_bin, '--version'],
        capture_output=True,
        text=True,
        check=True
    )

    # 2. Die erste Zeile nehmen und splitten
    first_line = result.stdout.splitlines()[0]
    # Teile bei Leerzeichen und nimm das letzte Element (die Versionsnummer)
    full_version = first_line.split()[-1]

    # 3. Major.Minor extrahieren (aus 3.22.1 wird 3.22)
    version_parts = full_version.split('.')
    major_minor = f"{version_parts[0]}.{version_parts[1]}"
    return major_minor


def get_cmake_root(bb, cmake_bin, cmake_version):
    base_dir = os.path.dirname(os.path.dirname(cmake_bin))
    cmake_root = os.path.join(base_dir, 'share', f'cmake-{cmake_version}')
    return cmake_root


def bbdefaultvars(bb, d, ct=None):
    root = d.getVar('PROJECT_ROOT')
    if root is None:
        datadir = os.getcwd()
        root = buildpaths.Buildpaths.findRoot(datadir)
        if root is None:
            raise Exception("ROOT IS NONE")
        d.setVar('PROJECT_ROOT', root)

    ct = d.getVar('CURRENT_TARGET')
    nt = 'x86_64-unknown-linux-gnu'
    d.setVar('NATIVE_TARGET', nt)
    d.setVar('NATIVE_TARGET_SUFFIX', nt + '-')
    d.setVar('NATIVE_TARGET_PREFIX', '-' + nt)

    mlr = root + '/meta-layer'
    d.setVar('META_LAYERS_ROOT', mlr)

    config_name = root + '/config/environment.json'
    jenv = jsonenvironment.JsonEnvironment.load(config_name)
    env = jenv.apply_env()
    d.setVar('PROJECT_CONFIG', env)

    d.setVar('NEXT_VERSION', env['NEXT_VERSION'])

    ver = env['COMPILER_VERSION']
    d.setVar('COMPILER_VERSION', ver)
    croot = env['COMPILER_ROOT']
    d.setVar('COMPILER_ROOT', croot)
    comp = env['COMPILER_DIR']
    d.setVar('COMPILER_DIR', comp + '/' + ver)
    xt = comp + '/' + ver + '/x-tools/'
    if ct is None:
        ct = d.getVar('CURRENT_TARGET')
    if os.path.exists(xt):
        d.setVar('MAKE_BIN', xt + nt + '/bin/make')
        if ct is not None:
            d.setVar('GCC_BIN', xt + ct + '/bin/'  + ct + '-sysroot_gcc')
    else:
        if ct is not None:
            comp_bin = fileutils.find_file(comp, ct + "-sysroot_gcc")
            if comp_bin is not None:
                d.setVar('GCC_BIN', comp_bin)
            else:
                comp_bin = fileutils.find_file(comp, ct + "-gcc")
                if comp_bin is not None:
                    d.setVar('GCC_BIN', comp_bin)

    if 'BUILDSYSTEMS_VERSION' in env:
        ver = env['BUILDSYSTEMS_VERSION']
        d.setVar('BUILDSYSTEMS_VERSION', ver)
        comp = env['BUILDSYSTEMS_DIR']
        basedir = comp + '/' + ver + '/' + nt
        d.setVar('BUILDSYSTEMS_DIR', basedir)
        d.setVar('BUILDSYSTEMS_BIN', basedir + '/wrapper/bin')

        d.setVar('BAZEL_BIN',  basedir + '/wrapper/bin/bazel')
        cmake_bin = basedir + '/wrapper/bin/cmake'
        cmake_version =  get_cmake_version(bb, cmake_bin)
        d.setVar('CMAKE_BIN',  cmake_bin)
        d.setVar('CMAKE_VERSION', cmake_version)
        d.setVar('CMAKE_ROOT', get_cmake_root(bb, cmake_bin, cmake_version))
        d.setVar('LUA_BIN',    basedir + '/wrapper/bin/lua')
        d.setVar('MESON_BIN',  basedir + '/wrapper/bin/meson')
        d.setVar('NINJA_BIN',  basedir + '/wrapper/bin/ninja')
        d.setVar('CMAKE_INSTALLED_PREFIX', basedir)
    else:
        d.setVar('BAZEL_BIN',  '/usr/bin/bazel')
        cmake_bin = "/usr/bin/cmake"
        cmake_version =  get_cmake_version(bb, cmake_bin)
        d.setVar('CMAKE_BIN',  '/usr/bin/cmake')
        d.setVar('CMAKE_VERSION', cmake_version)
        d.setVar('CMAKE_ROOT', get_cmake_root(bb, '/usr/bin/cmake', cmake_version))
        d.setVar('LUA_BIN',    '/usr/bin/lua')
        d.setVar('MESON_BIN',  '/usr/bin/meson')
        d.setVar('NINJA_BIN',  '/usr/bin/ninja')
        d.setVar('CMAKE_INSTALLED_PREFIX', '/usr/')

    d.setVar('JAVAC_BIN',  '/usr/bin/javac')
    d.setVar('JAVA_BIN',   '/usr/bin/java')
    d.setVar('PYTHON_BIN', '/usr/bin/python3')

    if 'CUDA_HOME' in env:
        cuda = env['CUDA_HOME']
        d.setVar('CUDA_HOME', cuda)

    if 'RUSTUP_HOME' in env:
        rust = env['RUSTUP_HOME']
        d.setVar('RUSTUP_HOME', rust)
