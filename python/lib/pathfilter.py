from pathlib import Path
import pathutils

class Pathfilter:

    @staticmethod
    def from_current_dir() -> "Pathfilter":
        cwd = Path.cwd().resolve()
        return Pathfilter([cwd])

    @staticmethod
    def from_versioned_project() -> "Pathfilter":
        current = Path.cwd().resolve()
        return Pathfilter([pathutils.from_versioned_project(current)])

    def __init__(self, paths):
        if paths is None or len(paths) == 0:
            self.paths = None
        else:
            self.paths = [Path(p).resolve() for p in paths]

    def contains(self, name):
        if self.paths is None:
            return True
        else:
            # canonicalize input path
            name = Path(name).resolve()
            name_str = str(name)
            if 'buildscripts' in name_str or '.git' in name_str or '.svn' in name_str or '.hg' in name_str:
                return False

            for base in self.paths:
                try:
                    # name is inside base if name.relative_to(base) works
                    name.relative_to(base)
                    return True
                except ValueError:
                    pass

            return False

    def __str__(self):
        return str(self.paths)

    def __repr__(self):
        return str(self)
