import cbuildconfigure


class CBuildConfigureNone:
    def __init__(self):
        pass

    def create_command(self, d, ccd: cbuildconfigure.CBuildConfigureData):
        return None, None

    def configure(self, d, ccd: cbuildconfigure.CBuildConfigureData):
        pass
