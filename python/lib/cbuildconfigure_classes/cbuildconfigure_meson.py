"""Reusable Meson configuration object for CIDE."""
import os
import shlex
import subprocess
import bbenv
import bbpaths
from pkgconfigsetup import CidePkgConfig
from mesonproperties import apply_meson_properties
from cbuildconfigure_classes.common import BuildConfiguration, clean_linker_flags


class CBuildConfigureMeson(BuildConfiguration):
    def create_command(self):
        d = self.d
        apply_meson_properties(self.get('TOOLCHAIN'), d)
        if not self.get('MODULE'):
            raise ValueError('CONFIGURE: MODULE NOT SET')

        source, build = self.get('S'), self.get('B')
        native = self.get('IS_NATIVE')
        toolchain = self.get('TOOLCHAIN')
        build_toolchain = self.get('NATIVE_TOOLCHAIN')
        compiler = self.get('COMPILER_VERSION')
        meson = bbpaths.BBPaths.from_current(d, 'meson').install_dir + '/bin/meson'

        flags = clean_linker_flags(self.get('MESON_LDFLAGS', ''))
        for entry in self.get('MESON_INSTALL_RPATH', '').split(':'):
            if entry:
                flag = '-Wl,-rpath=' + entry
                if flag not in flags:
                    flags.append(flag)

        env = os.environ.copy()
        env['LDFLAGS'] = shlex.join(flags)
        env['NINJA'] = self.get('NINJA_BIN')
        if self.get('RUSTUP_HOME') is not None:
            env['RUSTUP_HOME'] = self.get('RUSTUP_HOME')
        bbenv.apply_localenv_keyvals(d, env, self.get('MESON_ENV'))

        pc = CidePkgConfig(self.get('MESON_PKG_CONFIG'),
                           self.get('MESON_PKG_CONFIG_PATH'))
        env.update(pc.environment())
        native_path = pc.path if native else self.get('MESON_NATIVE_PKG_CONFIG_PATH')
        pc_native = CidePkgConfig(self.get('MESON_PKG_CONFIG'), native_path)
        env.update(pc_native.build_environment())
        env['TOOLCHAIN_VERSION'] = compiler

        warning_flags = self.get('NOWARN', '')
        argv = [
            meson, 'setup', '--debug',
            '-Dc_args=' + repr(shlex.split(self.get('MESON_C_FLAGS', '') + ' ' + warning_flags)),
            '-Dcpp_args=' + repr(shlex.split(self.get('MESON_CXX_FLAGS', '') + ' ' + warning_flags)),
        ]
        if native:
            argv += ['--native-file', toolchain]
        else:
            argv += ['--native-file', build_toolchain, '--cross-file', toolchain,
                     '-Dbuild.c_args=-w', '-Dbuild.cpp_args=-w',
                     '-Dpkg_config_path=' + pc.path,
                     '-Dbuild.pkg_config_path=' + pc_native.path]
        argv += ['-Dc_link_args=' + repr(flags), '-Dcpp_link_args=' + repr(flags)]
        argv += shlex.split(self.get('MESON_OPTIONS', ''))
        prefix = self.get('TARGET_PREFIX_DIR')
        argv += ['--prefix', prefix, '--libdir', prefix + '/lib',
                 '--backend', self.get('MESON_GENERATOR', 'ninja'), build, source]

        library_path = self.get('TOOLCHAIN_LD_LIBRARY_PATH')
        if library_path is not None:
            env['LD_LIBRARY_PATH'] = library_path
        program_path = self.get('MESON_PROGRAM_PATH')
        if program_path is not None:
            env['PATH'] = program_path + ':' + env['PATH']
        os.makedirs(build, exist_ok=True)
        return argv, source, env

    def configure(self, bb):
        argv, cwd, env = self.create_command()
        self.run(argv, cwd, env, bb)
