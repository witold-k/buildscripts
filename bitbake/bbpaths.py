class BBPaths:

    def __init__(self, native: bool, target, root_dir, install_dir, build_dir):
        self.target      = target
        self.root_dir    = root_dir
        self.install_dir = install_dir
        self.build_dir   = build_dir
        self.native      = native
        self.include_dir = install_dir + '/include'
        self.include_dir_switch = '-I' + self.include_dir
        self.lib_dir     = install_dir + '/lib'
        self.lib_dir_switch     = '-L' + self.lib_dir

    @staticmethod
    def from_current(d, target):
        wd   = d.getVar('TMPDIR') + '/work'
        tp   = d.getVar('CURRENT_TARGET_PREFIX')
        ct   = d.getVar('CURRENT_TARGET')
        pb   = d.getVar('PREFIX_BASE')
        nv   = d.getVar('NEXT_VERSION')
        tpd  = pb + '/' + nv + '/' + nv + '/' + ct
        root_dir = wd + '/' + target + tp + '-1.0-r0'
        install_dir  = root_dir + '/install/' + ct + '/' + tpd
        build_dir    = root_dir + '/build/' + ct
        return BBPaths(False, target, root_dir, install_dir, build_dir)

    @staticmethod
    def from_native(d, target):
        wd   = d.getVar('TMPDIR') + '/work'
        tp   = d.getVar('NATIVE_TARGET_PREFIX')
        ct   = d.getVar('NATIVE_TARGET')
        pb   = d.getVar('PREFIX_BASE')
        nv   = d.getVar('NEXT_VERSION')
        tpd  = pb + '/' + nv + '/' + nv + '/' + ct
        root_dir = wd + '/' + target + tp + '-1.0-r0'
        install_dir  = root_dir + '/install/' + ct + '/' + tpd
        build_dir    = root_dir + '/build/' + ct
        return BBPaths(True, target, root_dir, install_dir, build_dir)

    def is_native(self):
        return self.native

    def set_vars(self, d):
        up = self.target.upper()
        if self.native:
            d.setVar('NATIVE_' + up + '_ROOT_DIR',       self.root_dir)
            d.setVar('NATIVE_' + up + '_BUILD_DIR',      self.build_dir)
            d.setVar('NATIVE_' + up + '_INSTALL_DIR',    self.install_dir)
            d.setVar('NATIVE_' + up + '_PREFIX',         self.install_dir)
            d.setVar('NATIVE_' + up + '_INCLUDE_DIR',    self.include_dir)
            d.setVar('NATIVE_' + up + '_INCLUDE_DIR_SWITCH', self.include_dir_switch)
            d.setVar('NATIVE_' + up + '_LIB_DIR',        self.lib_dir)
            d.setVar('NATIVE_' + up + '_LIB_DIR_SWITCH', self.lib_dir_switch)
        else:
            d.setVar(up + '_ROOT_DIR',    self.root_dir)
            d.setVar(up + '_BUILD_DIR',   self.build_dir)
            d.setVar(up + '_INSTALL_DIR', self.install_dir)
            d.setVar(up + '_PREFIX',      self.install_dir)
            d.setVar(up + '_INCLUDE_DIR', self.include_dir)
            d.setVar(up + '_INCLUDE_DIR_SWITCH', self.include_dir_switch)
            d.setVar(up + '_LIB_DIR',     self.lib_dir)
            d.setVar(up + '_LIB_DIR_SWITCH', self.lib_dir_switch)

    def __str__(self):
        return self.target + ': ' + self.root_dir
