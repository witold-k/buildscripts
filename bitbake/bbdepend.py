import os

class BBCCXXEntry:

    def __init__(self, d, target, ct, pb, nv):
        assert d      is not None, "id must not be None"
        assert target is not None, "target must not be None"
        assert ct     is not None, "ct must not be None"
        assert pb     is not None, "pb must not be None"
        assert nv     is not None, "nv must not be None"

        tpd = pb + '/' + nv + '/' + nv + '/' + ct
        t = d.getVar('TOPDIR')
        self.basedir = None
        self.relativeInclude = 'include'
        self.relativeLib     = 'lib'
        self.basedir = t + '/tmp/work/' + target + '-' + ct + '-1.0-r0/install/' + ct + '/' + tpd

    def __str__(self):
        return "{" + self.basedir + ", " + self.relativeInclude + ", " + self.relativeLib + "}"


class BBDepend:

    def __init__(self, target, list, task):
        # import buildpaths
        # import jsonenvironment
        self.target   = target
        self.list     = list
        self.task     = task
        self.bblist   = None
        self.ccxxlist = None
        self.includeFlags  = None
        self.libFlags      = None
        self.libPath       = None
        self.libMap        = None
        self.pkgConfigPath = None
        # datadir = os.getcwd()
        # root = buildpaths.Buildpaths.findRoot(datadir)
        # config_name = root + '/config/environment.json'
        # jenv = jsonenvironment.JsonEnvironment.load(config_name)
        # self.env = jenv.apply_env()
        # self.nv  = self.env['NEXT_VERSION']

    @staticmethod
    def depends(d, dep):
        ct  = d.getVar('CURRENT_TARGET')
        if dep is None or dep == '':
            return BBDepend(None, None, None)

        if ct is None or ct == 'invalid':
            d.setVar('DEPEND_LIST', '')
            d.setVar('DEPEND_TARGETS', '')
            d.setVar('DEPEND_INCLUDE_DIRS_SWITCH', '')
            d.setVar('DEPEND_LIB_DIRS_SWITCH', '')
            d.setVar('DEPEND_PKG_CONFIG_PATH', '')
            return BBDepend(None, None, None)
        else:
            bbd = BBDepend(ct, dep.split(), 'do_build')
            bbd.buildDepends()
            bbd.buildCxx(d)
            bbd.buildIncludeFlags()
            bbd.buildLibFlags()
            bbd.buildLibPath()
            bbd.buildPkgConfigPath()
            d.setVar('DEPEND_LIST', dep)
            d.setVar('DEPEND_TARGETS', bbd.bblist)
            d.setVar('DEPEND_INCLUDE_DIRS_SWITCH', bbd.includeFlags)
            d.setVar('DEPEND_LIB_DIRS_SWITCH', bbd.libFlags)
            d.setVar('DEPEND_PKG_CONFIG_PATH', bbd.pkgConfigPath)
            return bbd

    @staticmethod
    def native_depends(d, dep):
        ct  = d.getVar('CURRENT_TARGET')
        nt  = d.getVar('NATIVE_TARGET')
        if dep is None or dep == '':
            return BBDepend(None, None, None)

        if ct is None or ct == 'invalid':
            d.setVar('NATIVE_DEPEND_LIST', '')
            d.setVar('NATIVE_DEPEND_TARGETS', '')
            d.setVar('NATIVE_DEPEND_INCLUDE_DIRS_SWITCH', '')
            d.setVar('NATIVE_DEPEND_LIB_DIRS_SWITCH', '')
            d.setVar('NATIVE_DEPEND_PKG_CONFIG_PATH', '')
            return BBDepend(None, None, None)
        elif ct == nt:
            d.setVar('NATIVE_DEPEND_LIST', '')
            d.setVar('NATIVE_DEPEND_TARGETS', '')
            d.setVar('NATIVE_DEPEND_INCLUDE_DIRS_SWITCH', '')
            d.setVar('NATIVE_DEPEND_LIB_DIRS_SWITCH', '')
            d.setVar('NATIVE_DEPEND_PKG_CONFIG_PATH', '')
            return BBDepend(None, None, None)
        else:
            bbd = BBDepend(nt, dep.split(), 'do_build')
            bbd.buildDepends()
            bbd.buildCxx(d)
            bbd.buildIncludeFlags()
            bbd.buildLibFlags()
            bbd.buildLibPath()
            bbd.buildPkgConfigPath()
            d.setVar('NATIVE_DEPEND_LIST', dep)
            d.setVar('NATIVE_DEPEND_TARGETS', bbd.bblist)
            d.setVar('NATIVE_DEPEND_INCLUDE_DIRS_SWITCH', bbd.includeFlags)
            d.setVar('NATIVE_DEPEND_LIB_DIRS_SWITCH', bbd.libFlags)
            d.setVar('NATIVE_DEPEND_LIB_PATH', bbd.libPath)
            d.setVar('NATIVE_DEPEND_PKG_CONFIG_PATH', bbd.pkgConfigPath)
            return bbd

    @staticmethod
    def createAll(d, dep):
        ct  = d.getVar('CURRENT_TARGET')
        if ct is None or ct == 'invalid':
            return BBDepend(None, None, None)

        bbd = BBDepend(ct, dep.split(), 'do_build')
        bbd.buildDepends()
        bbd.buildCxx(d)
        bbd.buildIncludeFlags()
        bbd.buildLibFlags()
        bbd.buildLibPath()
        bbd.buildLibDictionary()
        bbd.buildPkgConfigPath()
        return bbd

    def buildDepends(self):
        bblist = ''
        for entry in self.list:
            bblist += ' ' + entry + '-' + self.target + ':' + self.task
        self.bblist = bblist

    def buildCxx(self, d):
        pb = d.getVar('PREFIX_BASE')
        nv = d.getVar('NEXT_VERSION')
        ccxxlist = []
        for entry in self.list:
            ccxxlist.append(BBCCXXEntry(d, entry, self.target, pb, nv))
        self.ccxxlist = ccxxlist

    def buildIncludeFlags(self):
        if self.ccxxlist:
            list = ""
            for entry in self.ccxxlist:
                list += ' -I' + entry.basedir + '/' + entry.relativeInclude
            self.includeFlags = list

    def buildLibFlags(self):
        if self.ccxxlist:
            list = ""
            for entry in self.ccxxlist:
                list += ' -L' + entry.basedir + '/' + entry.relativeLib \
                    + ' -Wl,-rpath=' + entry.basedir + '/' + entry.relativeLib \
                    + ' -Wl,-rpath-link=' + entry.basedir + '/' + entry.relativeLib
            self.libFlags = list

    def buildLibPath(self):
        if self.ccxxlist:
            entry0 = self.ccxxlist[0]
            list = entry0.basedir + '/' + entry0.relativeLib
            for entry in self.ccxxlist[1:]:
                list += ':' + entry.basedir + '/' + entry.relativeLib
            self.libPath = list

    def buildLibDictionary(self):
        if self.ccxxlist:
            self.libMap = {}
            for idx in range(0, len(self.list)):
                entry = self.ccxxlist[idx]
                self.libMap[self.list[idx]] = entry.basedir + '/' + entry.relativeLib

    def buildPkgConfigPath(self):
        if self.ccxxlist:
            entry0 = self.ccxxlist[0]
            list = entry0.basedir + '/' + entry0.relativeLib + '/pkgconfig'
            for entry in self.ccxxlist[1:]:
                list += ':' + entry.basedir + '/' + entry.relativeLib + '/pkgconfig'
            self.pkgConfigPath = list

    def getLibDir(self, name):
        if self.libMap:
            return self.libMap[name]
        else:
            return None

    def setEnvLib(self, env_name, module_name, lib_name):
        l = self.getLibDir(module_name) + '/' + lib_name
        os.environ[env_name] = l

    def __str__(self):
        return self.bblist + '\n' + self.includeFlags + '\n' + self.libFlags
