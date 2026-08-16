import os


class DirtyCheck:

    def __init__(self, src_dirs, save_check_dir, prefix):
        self.src_dirs       = src_dirs
        self.save_check_dir = save_check_dir
        self.prefix         = prefix

    def check_dirty(self):
        import fileutils
        import filecmp
        import md5fileid

        cd = self.save_check_dir
        cp = None
        cc = None
        if self.prefix is not None:
            cp = cd + '/' + self.prefix + 'checksum_previous.txt'
            cc = cd + '/' + self.prefix + 'checksum_current.txt'
        else:
            cp = cd + '/checksum_previous.txt'
            cc = cd + '/checksum_current.txt'

        needs_build = False
        if not os.path.isdir(cd) and not os.path.islink(cd):
            os.makedirs(cd, 0o750, exist_ok=True)
            needs_build = True

        flist = md5fileid.MD5FileIdList.for_filearray(fileutils.ls_dirs(self.src_dirs))
        flist.save(cc)

        if not os.path.isfile(cp) or not filecmp.cmp(cp, cc, shallow=False):
            needs_build = True
        else:
            if os.path.isfile('build.ninja'):
                cmd = ["ninja", "-n", "-C", b]
                out = os.popen(cmd).read()
                if 'no work to do' not in out:
                    needs_build = True

        if needs_build:
            if os.path.isfile(cp):
                os.remove(cp)

        return needs_build

    def apply(self):
        import fileutils

        cd = self.save_check_dir
        cp = None
        cc = None
        if self.prefix is not None:
            cp = cd + '/' + self.prefix + 'checksum_previous.txt'
            cc = cd + '/' + self.prefix + 'checksum_current.txt'
        else:
            cp = cd + '/checksum_previous.txt'
            cc = cd + '/checksum_current.txt'

        fileutils.copy_file(cc, cp)
