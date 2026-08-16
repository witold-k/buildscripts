"""
exec tools
"""


class CMakeCacheLibraries:
    def __init__(self, path):
        self.path   = path
        self.suffix = ".so"

    def fetchLibs(self):
        import keyvalue
        file = open(self.path, 'r')
        lines = file.readlines()
        file.close()

        path = []
        for line in lines:
            linestr = line.rstrip()
            if "_LIBRARIES" in linestr and self.suffix in linestr:
                kv = keyvalue.KeyValue.fromAssign(linestr)
                if kv.valid():
                    parts = kv.value.split(';')
                    for part in parts:
                        path.append(part)
        return path

    def fetchPath(self):
        import pathutils
        return pathutils.files2path(self.fetchLibs())
