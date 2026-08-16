from pathlib import Path


class PkgConfigNone:
    @staticmethod
    def load(env, filename):
        basedir = str(Path(filename + '/..').resolve())
        return PkgConfigNone(basedir, None, None, None, None)

    @staticmethod
    def from_string(env, basedir, text):
        return PkgConfigNone(basedir, None, None, None, None)

    @staticmethod
    def generate_pkgconfig(module_dir, local_prefix, src_json_file, dest_pc_dir):
        return PkgConfigNone(module_dir, None, None, None, None)

    def __init__(self, basedir, meta, vars, build, raw):
        self.basedir = basedir
        self.meta    = meta
        self.vars    = vars
        self.build   = build
        self.raw     = raw

    def export_pkgconfig(self):
        return ""

    def __str__(self):
        return "(PkgConfigNone)"
