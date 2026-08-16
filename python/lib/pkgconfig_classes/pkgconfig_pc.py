from pathlib import Path
import os
import patcher


class PkgConfigPc:
    @staticmethod
    def load(env, filename):
        basedir = str(Path(filename + '/..').resolve())
        p = patcher.Patcher(filename, None)
        for k, v in env.items():
            p.replace('${' + k + '}', v)
        return PkgConfigPc(basedir, p)

    @staticmethod
    def generate_pkgconfig(module_dir, local_prefix, src_pc_file, dest_pc_dir):
        os.makedirs(dest_pc_dir, exist_ok=True)
        filename = os.path.basename(src_pc_file)
        save_name = dest_pc_dir + '/' + filename
        if module_dir is not None and module_dir != '':
            prefix = module_dir + '/' + local_prefix
            env = {'PREFIX': prefix, 'SRCDIR': module_dir}
        else:
            prefix = local_prefix
            env = {'PREFIX': prefix, 'SRCDIR': '/'}
        pcdata = PkgConfigPc.load(env, src_pc_file)
        pcdata.pc.write_to(save_name)

    def __init__(self, basedir, patcher):
        self.basedir = basedir
        self.pc      = patcher

    def __str__(self):
        return str(self.pc)
