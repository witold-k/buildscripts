from enum import Enum

import pkgconfig_classes.pkgconfig_json as pjson
import pkgconfig_classes.pkgconfig_pc as ppc
import pkgconfig_classes.pkgconfig_none as pnone


class PkgConfigType(Enum):
    UNKNOWN = 0,  # UNKNOWN
    PC      = 1,  # regular .pc file
    JSON    = 2,  # json style .pc file

    @staticmethod
    def from_filename(filename: str):
        if filename.endswith('.pc'):
            return PkgConfigType.PC
        if filename.endswith('.pc.json'):
            return PkgConfigType.JSON
        return PkgConfigType.UNKNOWN

    def filesuffix(self):
        if self == PkgConfigType.PC:
            return '.pc'
        if self == PkgConfigType.JSON:
            return '.pc.json'
        return '(None)'


class PkgConfig:
    @staticmethod
    def can_replace_key(key):
        return key not in ["prefix,", "bindir", "datadir", "libdir"]

    @staticmethod
    def load(env, filename: str):
        type = PkgConfigType.from_filename(filename)
        if type == PkgConfigType.JSON:
            return pjson.PkgConfigJson.load(env, filename)
        if type == PkgConfigType.PC:
            return ppc.PkgConfigPc.load(env, filename)
        return pnone.PkgConfigNone.load(env, filename)

    @staticmethod
    def generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir):
        type = PkgConfigType.from_filename(src_file)
        match type:
            case PkgConfigType.JSON:
                return pjson.PkgConfigJson.generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir)
            case PkgConfigType.PC:
                return ppc.PkgConfigPc.generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir)
            case _:
                return pnone.PkgConfigNone.generate_pkgconfig(module_dir, local_prefix, src_file, dest_pc_dir)
