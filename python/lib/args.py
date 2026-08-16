"""
args tools
"""


class Args:
    def __init__(self, args):
        self.args = args

    def remove_all(self, text):
        if self.args is None:
            return 0
        alen = len(self.args)
        tmp = [v for v in self.args if v != text]
        del self.args[:]
        self.args.extend(tmp)
        return alen - len(self.args)

    def remove_start(self, index):
        if (len(self.args) <= index):
            return None
        val = self.args[index]
        del self.args[index]
        return val
