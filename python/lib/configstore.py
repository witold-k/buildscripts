import os
import filecmp
import shutil


class ConfigStore:
    @staticmethod
    def fromBBVars(d, name, configured_storedfile, default_storedfile, workingfile):
        cs = ConfigStore(d.getVar(name), d.getVar(configured_storedfile), d.getVar(default_storedfile), d.getVar(workingfile))
        return cs

    def __init__(self, name, configured_storedfile, default_storedfile, workingfile):
        self.name                  = name
        self.configured_storedfile = configured_storedfile
        self.default_storedfile    = default_storedfile
        self.workingfile           = workingfile

    # copy stored file (defconfig) => default storedfile
    # make defconfig or make menuconfig will create .config
    def setup(self):
        # if there is no custom configured use the default stored one
        if not os.path.exists(self.configured_storedfile):
            shutil.copy(self.default_storedfile, self.configured_storedfile)
            return

        do_copy = False
        if not os.path.exists(self.default_storedfile):
            do_copy = True
        else:
            if not filecmp.cmp(self.configured_storedfile, self.default_storedfile, shallow=False):
                os.remove(self.default_storedfile)
                do_copy = True
        if do_copy:
            shutil.copy(self.configured_storedfile, self.default_storedfile)

    # save changes: copy workig (.config) => storedfile (defconfig)
    def save(self):
        if not os.path.exists(self.workingfile):
            return

        if not filecmp.cmp(self.workingfile, self.configured_storedfile, shallow=False):
            os.remove(self.default_storedfile)
            shutil.copy(self.workingfile, self.configured_storedfile)
