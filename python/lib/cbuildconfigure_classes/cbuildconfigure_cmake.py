"""Reusable CMake configuration object for CIDE."""
import os
import shlex
from cbuildconfigure_classes.common import BuildConfiguration, clean_linker_flags


class CBuildConfigureCMake(BuildConfiguration):
    def create_command(self):
        if not self.get('module'):
            raise ValueError('CONFIGURE: MODULE NOT SET')

        env = self.environ.copy()
        target = self.get('target')
        version = self.get('compiler_version')
        sdk = self.get('sdk_dir')
        if sdk:
            env['SDK_DIR'] = sdk + '/' + target
        roots = []
        pkgpath = self.get('pkg_config_path', '').strip().strip(';').strip()
        if pkgpath:
            roots.append(pkgpath)
        roots.append(self.get('temp_dir') + '/moduleref/' + target)
        env['PKG_CONFIG_PATH'] = ';'.join(roots)
        env['PKG_CONFIG_LIBDIR'] = ''
        env['PKG_CONFIG_SYSROOT_DIR'] = ''
        env['PKG_CONFIG_ALLOW_SYSTEM_LIBS'] = '0'
        env['PKG_CONFIG_ALLOW_SYSTEM_CFLAGS'] = '0'
        if version:
            roots.append('/opt/compiler/' + version + '/' + version +
                         '/x-tools/' + target + '/' + target + '/sysroot')

        tc = self.get('toolchain_file')
        prefix = self.get('install_prefix')
        install_rpath = self.get('install_rpath', '$ORIGIN;$ORIGIN/../lib')
        warning = ' ' + self.get('warning_flags', '') + ' ' + self.get('dependency_include_flags', '')
        linker = shlex.join(clean_linker_flags(self.get('linker_flags', '')))

        argv = [
            self.get('executable'),
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
            '-DCMAKE_MODULE_PATH:STRING=' + self.get('module_path'),
            '-DCMAKE_INSTALL_PREFIX:PATH=' + prefix,
            '-DCMAKE_INSTALLED_PREFIX:PATH=' + str(self.get('installed_prefix')),
            '-DCMAKE_INSTALL_NATIVE_PREFIX:PATH=' + str(self.get('native_install_prefix')),
            '-DCMAKE_EXPORT_COMPILE_COMMANDS=1',
            '-DTOOLCHAIN_VERSION=' + (version or ''),
            '-DPython3_EXECUTABLE=' + str(self.get('python_executable')),
            '-DCMAKE_POLICY_VERSION_MINIMUM=3.30',
            '-DCMAKE_SKIP_BUILD_RPATH=OFF',
            '-DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF',
            '-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=OFF',
            '-DCMAKE_INSTALL_RPATH:STRING=' + install_rpath,
        ]
        optional = {
            'CMAKE_SYSTEM_PROGRAM_PATH:PATH': self.get('system_program_path'),
            'CMAKE_PROGRAM_PATH:PATH': self.get('program_path'),
            'CMAKE_BUILD_RPATH:STRING': None,
            'CMAKE_PREFIX_PATH:PATH': self.get('prefix_path'),
            'CMAKE_C_FLAGS_CMDL': self.get('c_flags', '') + warning,
            'CMAKE_CXX_FLAGS_CMDL': self.get('cxx_flags', '') + warning,
            'CURRENT_SYSNAME_SHORT': self.get('system_name'),
            'CMAKE_EXE_LINKER_FLAGS': linker,
            'USE_HAVE_FLAGS:BOOL': self.get('use_have_flags'),
        }
        argv += ['-D' + key + '=' + value for key, value in optional.items()
                 if value is not None]
        for key in ('BB_TOP_DIR', 'BB_TARGET', 'BB_TARGET_SUFFIX',
                    'BB_TARGET_PREFIX', 'BB_NATIVE_TARGET',
                    'BB_NATIVE_TARGET_SUFFIX', 'BB_NATIVE_TARGET_PREFIX',
                    'BB_WORK_DIR'):
            value = (self.get('top_dir') if key == 'BB_TOP_DIR' else
                     self.get('temp_dir') + '/work' if key == 'BB_WORK_DIR' else
                     self.get({'BB_TARGET': 'target',
                               'BB_TARGET_SUFFIX': 'target_suffix',
                               'BB_TARGET_PREFIX': 'target_prefix',
                               'BB_NATIVE_TARGET': 'native_target',
                               'BB_NATIVE_TARGET_SUFFIX': 'native_target_suffix',
                               'BB_NATIVE_TARGET_PREFIX': 'native_target_prefix'}[key]))
            argv.append('-D' + key + '=' + str(value))
        argv += shlex.split(self.get('options', ''))
        argv += ['-DCMAKE_MAKE_PROGRAM=' + self.get('make_program'),
                 '-G', self.get('generator', 'Ninja'),
                 self.get('source_dir')]

        library_path = self.get('toolchain_library_path')
        if library_path is not None:
            env['LD_LIBRARY_PATH'] = library_path
        build = self.get('build_dir')
        os.makedirs(build, exist_ok=True)
        return argv, build, env
