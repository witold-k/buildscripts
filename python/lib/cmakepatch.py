class CMakePatch:

    def __init__(self, path):
        import patcher
        self.patcher = patcher.Patcher(path, None)

    def read(self):
        self.patcher.read()

    def write(self):
        self.patcher.write()

    def insert_after(self, key, value):
        self.patcher.insert_after(key, value)

    def insert_lines_after(self, key, value):
        self.patcher.insert_lines_after(key, value)

    def replace(self, key, value):
        self.patcher.replace(key, value)

    def delete_lines(self, text):
        list = self.patcher.find_all(text)
        self.patcher.delete_all(list)

    def replace_find_module(self, frm, to):
        list = self.patcher.find_all("find_module")
        if len(list) == 0:
            return
        self.patcher.replace_all(list, frm, to)

    def replace_find_library_as_package(self, frm, to):
        list = self.patcher.find_all("find_library")
        list = self.patcher.find_all_in(list, frm)
        self.patcher.replace_all_leading_in(list, "find_library", '(', ')', frm, to)
        self.patcher.replace_all(list, "find_library", "find_package")

    def delete_find_path(self, text):
        list = self.patcher.find_all("find_path")
        list = self.patcher.find_all_in(list, text)
        self.patcher.delete_all(list)

    def __eq__(self, other):
        return self.patcher == other.pather

    def __ne__(self, other):
        return not (self == other)

    def __str__(self) -> str:
        return str(self.patcher)
