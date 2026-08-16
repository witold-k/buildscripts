class Buildswitches:

    @staticmethod
    def fromString(builddir: str, targetpostfix: str, lasttask: str, list: str):
        bs = Buildswitches(builddir, targetpostfix, lasttask)
        bs.modules = list.split()

    def __init__(self, builddir: str, targetpostfix: str, lasttask: str):
        self.builddir = builddir
        self.targetpostfix = targetpostfix
        self.lasttask = lasttask
        self.modules = []

    def getBBDependString(self):
        line = ""
        for module in self.modules:
            line += ' ' + module + self.targetpostfix + ':' + self.lasttask + '\n'
        return line

    def getIncludeString(self):
        line = ""
        for module in self.modules:
            line += ' -I' + self.builddir + '/' + module + self.targetpostfix + self.subdirs + '/include'
        return line

    def getLibraryString(self):
        line = ""
        for module in self.modules:
            subline = ' -L' + self.builddir + '/' + module + self.targetpostfix + self.subdirs + '/lib'
            line += subline
            line += subline + '64'
            line += subline + '/'
        return line

    def getPkgconfigString(self):
        line = ""
        for module in self.modules:
            line += ' -L' + self.builddir + '/' + module + self.targetpostfix + self.subdirs + '/pkgconfig'
        return line
