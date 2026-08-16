from enum import Enum
import shlex
import cbuildconfigure_classes.cbuildconfigure_none as bcnone
import cbuildconfigure_classes.cbuildconfigure_cmake as bccmake


class CBuildConfigureType(Enum):
    UNKNOWN   = 0,  # UNKNOWN
    AUTOTOOLS = 1,
    CMAKE     = 2,
    MESON     = 3

    @staticmethod
    def from_filename(filename: str):
        pass


class CBuildConfigureData:
    def __init__(
        self,
        tool_flags=None,
        pkg_config_path=None,
        module_path=None,
        generator=None,
        make_program=None,
        c_defines=None,
        c_flags=None, cxx_flags=None, common_flags=None, ld_flags=None,
        c_nowarn_flags=None, cxx_nowarn_flags=None, common_nowarn_flags=None,
        cross_toolchain=None, native_toolchain=None,
        use_have_flags=False
    ):
        self.tool_flags      = tool_flags
        self.pkg_config_path = pkg_config_path
        self.module_path     = module_path
        self.generator       = generator or 'Ninja'
        self.make_program    = make_program
        self.export_compile_commands = True
        self.c_defines       = c_defines
        self.c_flags         = c_flags
        self.cxx_flags       = cxx_flags
        self.common_flags    = common_flags
        self.ld_flags        = ld_flags
        self.c_nowarn_flags      = c_nowarn_flags
        self.cxx_nowarn_flags    = cxx_nowarn_flags
        self.common_nowarn_flags = common_nowarn_flags
        self.cross_toolchain     = cross_toolchain
        self.native_toolchain    = native_toolchain
        self.use_have_flags      = use_have_flags

    @staticmethod
    def from_key_values(d, prefix=None):
        ret = CBuildConfigureData()
        prefix = prefix or ''

        ret.pkg_config_path  = d.getVar(prefix + 'PKG_CONFIG_PATH')
        ret.module_path      = d.getVar(prefix + 'MODULE_PATH')
        ret.generator        = d.getVar(prefix + 'GENERATOR') or 'Ninja'
        ret.make_program     = d.getVar(prefix + 'MAKE_PROGRAM')
        ret.tool_flags       = d.getVar(prefix + 'OPTIONS')
        if isinstance(ret.tool_flags, str):
            ret.tool_flags = shlex.split(ret.tool_flags)
        ret.cross_toolchain  = d.getVar(prefix + 'CROSS_TOOLCHAIN')
        ret.native_toolchain = d.getVar(prefix + 'NATIVE_TOOLCHAIN')
        ret.common_nowarn_flags = d.getVar(prefix + 'NOWARN') or d.getVar('NOWARN')
        if isinstance(ret.common_nowarn_flags, str):
            ret.common_nowarn_flags = shlex.split(ret.common_nowarn_flags)

        return ret


class CBuildConfigureFactory:
    def __init__(self, filename):
        self.filename = filename

    def create(self):
        type = CBuildConfigureType.from_filename(self.filename)
        match type:
            case BuildConfigureType.AUTOTOOLS:
                return pjson.PkgConfigJson.generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir)
            case BuildConfigureType.CMAKE:
                return ppc.PkgConfigPc.generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir)
            case _:
                return bcnone.BuildConfigure()
