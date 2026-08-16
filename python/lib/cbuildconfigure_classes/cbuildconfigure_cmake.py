import os, buildjobs, cbuildconfigure
import keyvalue.KeyValue as KV


class CBuildConfigureCMake:
    def __init__(self, filename):
        self.filename = filename
        self.env      = None

    def create_command(self, d, ccd: cbuildconfigure.CBuildConfigureData):
        env = os.environ.copy()

        cmd = [d.getVar('CMAKE_BIN')]

        env['PKG_CONFIG_PATH'] = d.getVar('CMAKE_PKG_CONFIG_PATH')
        KV.append(cmd, '-DCMAKE_TOOLCHAIN_FILE=', ccd.cross_toolchain)
        KV.append(cmd, '-DCMAKE_MODULE_PATH=', ccd.module_path)
        KV.append(cmd, '-DCMAKE_INSTALL_PREFIX:PATH', ccd.install_prefix)
        KV.append(cmd, '-DCMAKE_INSTALL_NATIVE_PREFIX:PATH', ccd.install_native_prefix)
        KV.append(cmd, '-DCMAKE_INSTALLED_PREFIX:PATH', ccd.installed_prefix)
        KV.append(cmd, '-DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL', ccd.installed_prefix)
        KV.append(cmd, '-DPython3_EXECUTABLE=', d.getVar('PYTHON_BIN'))
        KV.append(cmd, '-DTOOLCHAIN_VERSION=', d.getVar('COMPILER_VERSION'))
        KV.append(cmd, '-DCMAKE_INSTALL_RPATH:PATH=', ccd.install_rpath)
        KV.append(cmd, '-DCMAKE_BUILD_RPATH:PATH=', ccd.build_rpath)
        KV.append(cmd, '-DCMAKE_EXE_LINKER_FLAGS:PATH=', ccd.ld_flags)
        KV.append(cmd, '-DCMAKE_EXE_LINKER_FLAGS:PATH=', ccd.ld_flags)
        KV.append(cmd, '-DUSE_HAVE_FLAGS:BOOL=', ccd.use_have_flags)

        if None != cspp:
            str += " -DCMAKE_SYSTEM_PROGRAM_PATH:PATH=" + cspp
        if None != cprp:
            str += " -DCMAKE_PROGRAM_PATH:PATH=" +cprp
        if None != cpp:
            str += " -DCMAKE_PREFIX_PATH:PATH=" + cpp
        if None != copt:
            str += " " + copt
        str += " -DCMAKE_MAKE_PROGRAM=" + mp
        str += " -G \"" + cgen + "\" " + csd

        return env, str

    def configure(self, d, ccd: cbuildconfigure.CBuildConfigureData):
        env, cmd = self.create_command(d, ccd)
        dp = buildjobs.DoProcess(cmd=cmd, env=env)
        _, _, _ = dp.run_to_lines()
