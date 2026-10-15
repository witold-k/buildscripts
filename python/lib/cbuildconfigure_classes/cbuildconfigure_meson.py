"""Reusable Meson configuration object for CIDE."""
import os
import shlex
from pkgconfigsetup import CidePkgConfig
from cbuildconfigure_classes.common import BuildConfiguration, clean_linker_flags


class CBuildConfigureMeson(BuildConfiguration):
    def create_command(self):
        if not self.get('module'):
            raise ValueError('CONFIGURE: MODULE NOT SET')

        source, build = self.get('source_dir'), self.get('build_dir')
        native = self.get('native_build')
        toolchain = self.get('toolchain_file')
        build_toolchain = self.get('build_machine_toolchain_file')
        compiler = self.get('compiler_version')
        meson = self.get('executable')

        flags = clean_linker_flags(self.get('linker_flags', ''))
        for entry in self.get('install_rpath', '').split(':'):
            if entry:
                flag = '-Wl,-rpath=' + entry
                if flag not in flags:
                    flags.append(flag)

        env = self.environ.copy()
        env['LDFLAGS'] = shlex.join(flags)
        env['NINJA'] = self.get('ninja_executable')
        if self.get('rustup_home') is not None:
            env['RUSTUP_HOME'] = self.get('rustup_home')

        pc = CidePkgConfig(self.get('pkg_config_executable'),
                           self.get('pkg_config_path'))
        env.update(pc.environment())
        native_path = pc.path if native else self.get('build_pkg_config_path')
        pc_native = CidePkgConfig(self.get('pkg_config_executable'), native_path)
        env.update(pc_native.build_environment())
        env['TOOLCHAIN_VERSION'] = compiler

        warning_flags = self.get('warning_flags', '')
        argv = [
            meson, 'setup', '--debug',
            '-Dc_args=' + repr(shlex.split(self.get('c_flags', '') + ' ' + warning_flags)),
            '-Dcpp_args=' + repr(shlex.split(self.get('cxx_flags', '') + ' ' + warning_flags)),
        ]
        if native:
            argv += ['--native-file', toolchain]
        else:
            argv += ['--native-file', build_toolchain, '--cross-file', toolchain,
                     '-Dbuild.c_args=-w', '-Dbuild.cpp_args=-w',
                     '-Dpkg_config_path=' + pc.path,
                     '-Dbuild.pkg_config_path=' + pc_native.path]
        argv += ['-Dc_link_args=' + repr(flags), '-Dcpp_link_args=' + repr(flags)]
        argv += shlex.split(self.get('options', ''))
        prefix = self.get('install_prefix')
        argv += ['--prefix', prefix, '--libdir', prefix + '/lib',
                 '--backend', self.get('backend', 'ninja'), build, source]

        library_path = self.get('toolchain_library_path')
        if library_path is not None:
            env['LD_LIBRARY_PATH'] = library_path
        program_path = self.get('program_path')
        if program_path is not None:
            env['PATH'] = program_path + ':' + env['PATH']
        os.makedirs(build, exist_ok=True)
        return argv, source, env
