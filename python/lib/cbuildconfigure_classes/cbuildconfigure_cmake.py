"""Reusable CMake configuration object for CIDE."""
import os
import shlex
import bbdefaultvars
from mesonproperties import apply_meson_properties
from cbuildconfigure_classes.common import BuildConfiguration, clean_linker_flags


class CBuildConfigureCMake(BuildConfiguration):
    def create_command(self, bb):
        d = self.d
        apply_meson_properties(self.get('MESON_TOOLCHAIN'), d)
        bbdefaultvars.bbdefaultvars(bb, d)
        if not self.get('MODULE'):
            raise ValueError('CONFIGURE: MODULE NOT SET')

        env = os.environ.copy()
        target = self.get('CURRENT_TARGET')
        version = self.get('COMPILER_VERSION')
        sdk = self.get('SDK_DIR')
        if sdk:
            env['SDK_DIR'] = sdk + '/' + target
        roots = []
        pkgpath = self.get('PKG_CONFIG_PATH', '').strip().strip(';').strip()
        if pkgpath:
            roots.append(pkgpath)
        roots.append(self.get('TMPDIR') + '/moduleref/' + target)
        env['PKG_CONFIG_PATH'] = ';'.join(roots)
        env['PKG_CONFIG_LIBDIR'] = ''
        env['PKG_CONFIG_SYSROOT_DIR'] = ''
        env['PKG_CONFIG_ALLOW_SYSTEM_LIBS'] = '0'
        env['PKG_CONFIG_ALLOW_SYSTEM_CFLAGS'] = '0'
        if version:
            roots.append('/opt/compiler/' + version + '/' + version +
                         '/x-tools/' + target + '/' + target + '/sysroot')

        tc = self.get('TOOLCHAIN')
        prefix = self.get('TARGET_PREFIX_DIR')
        install_rpath = self.get('CMAKE_INSTALL_RPATH', '$ORIGIN;$ORIGIN/../lib')
        warning = ' ' + self.get('NOWARN', '') + ' ' + self.get('DEPEND_INCLUDE_DIRS_SWITCH', '')
        linker = shlex.join(clean_linker_flags(self.get('CMAKE_EXE_LINKER_FLAGS', '')))

        argv = [
            self.get('CMAKE_BIN'),
            '-DCMAKE_TOOLCHAIN_FILE=' + tc,
            '-DPKG_CONFIG_ARGUMENTS= --define-prefix ',
            '-DCMAKE_FIND_ROOT_PATH=' + ';'.join(roots),
            '-DCMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH=OFF',
            '-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=OFF',
            '-DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF',
            '-DCMAKE_FIND_USE_CMAKE_PACKAGE_REGISTRY=OFF',
            '-DCMAKE_FIND_USE_CMAKE_PATH=OFF',
            '-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER',
            '-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY',
            '-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY',
            '-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY',
            '-DCMAKE_MODULE_PATH:STRING=' + self.get('CMAKE_MODULE_PATH'),
            '-DCMAKE_INSTALL_PREFIX:PATH=' + prefix,
            '-DCMAKE_INSTALLED_PREFIX:PATH=' + str(self.get('CMAKE_INSTALLED_PREFIX')),
            '-DCMAKE_INSTALL_NATIVE_PREFIX:PATH=' + str(self.get('NATIVE_PREFIX_DIR')),
            '-DCMAKE_EXPORT_COMPILE_COMMANDS=1',
            '-DTOOLCHAIN_VERSION=' + (version or ''),
            '-DPython3_EXECUTABLE=' + str(self.get('PYTHON_BIN')),
            '-DCMAKE_POLICY_VERSION_MINIMUM=3.30',
            '-DCMAKE_SKIP_BUILD_RPATH=OFF',
            '-DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF',
            '-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF',
            '-DCMAKE_INSTALL_RPATH:STRING=' + install_rpath,
        ]
        optional = {
            'CMAKE_SYSTEM_PROGRAM_PATH:PATH': self.get('CMAKE_SYSTEM_PROGRAM_PATH'),
            'CMAKE_PROGRAM_PATH:PATH': self.get('CMAKE_PROGRAM_PATH'),
            'CMAKE_BUILD_RPATH:STRING': None,
            'CMAKE_PREFIX_PATH:PATH': self.get('CMAKE_PREFIX_PATH'),
            'CMAKE_C_FLAGS_CMDL': self.get('CMAKE_C_FLAGS', '') + warning,
            'CMAKE_CXX_FLAGS_CMDL': self.get('CMAKE_CXX_FLAGS', '') + warning,
            'CURRENT_SYSNAME_SHORT': self.get('CURRENT_SYSNAME_SHORT'),
            'CMAKE_EXE_LINKER_FLAGS': linker,
            'USE_HAVE_FLAGS:BOOL': self.get('USE_HAVE_FLAGS'),
        }
        argv += ['-D' + key + '=' + value for key, value in optional.items()
                 if value is not None]
        for key in ('BB_TOP_DIR', 'BB_TARGET', 'BB_TARGET_SUFFIX',
                    'BB_TARGET_PREFIX', 'BB_NATIVE_TARGET',
                    'BB_NATIVE_TARGET_SUFFIX', 'BB_NATIVE_TARGET_PREFIX',
                    'BB_WORK_DIR'):
            value = (self.get('TOPDIR') if key == 'BB_TOP_DIR' else
                     self.get('TMPDIR') + '/work' if key == 'BB_WORK_DIR' else
                     self.get({'BB_TARGET': 'CURRENT_TARGET',
                               'BB_TARGET_SUFFIX': 'CURRENT_TARGET_SUFFIX',
                               'BB_TARGET_PREFIX': 'CURRENT_TARGET_PREFIX',
                               'BB_NATIVE_TARGET': 'NATIVE_TARGET',
                               'BB_NATIVE_TARGET_SUFFIX': 'NATIVE_TARGET_SUFFIX',
                               'BB_NATIVE_TARGET_PREFIX': 'NATIVE_TARGET_PREFIX'}[key]))
            argv.append('-D' + key + '=' + str(value))
        argv += shlex.split(self.get('CMAKE_OPTIONS', ''))
        argv += ['-DCMAKE_MAKE_PROGRAM=' + self.get('CMAKE_MAKE_PROGRAM'),
                 '-G', self.get('CMAKE_GENERATOR', 'Ninja'),
                 self.get('CMAKE_SRC_DIR')]

        library_path = self.get('TOOLCHAIN_LD_LIBRARY_PATH')
        if library_path is not None:
            env['LD_LIBRARY_PATH'] = library_path
        build = self.get('B')
        os.makedirs(build, exist_ok=True)
        return argv, build, env

    def configure(self, bb):
        argv, cwd, env = self.create_command(bb)
        self.run(argv, cwd, env, bb)
