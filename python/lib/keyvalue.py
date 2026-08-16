"""
data tools
"""


class KeyValue:

    def __init__(self, key, value, delimitter=None, keystring=None):
        self.key        = key
        self.value      = value
        if keystring is None:
            if key is None:
                self.keystring = None
            else:
                if delimitter is None:
                    self.keystring = key + ' '
                else:
                    self.keystring = key + ' ' + delimitter + ' '
        else:
            self.keystring = keystring

    def valid(self):
        return self.key is not None

    def has_var(self):
        return "${" in self.value

    @staticmethod
    def fromAssign(linestr, delimitter='='):
        keyval = linestr.split(delimitter, 1)
        if len(keyval) > 1:
            key   = keyval[0].strip()
            value = keyval[1].strip()
            return KeyValue(key, value, delimitter)
        else:
            return KeyValue(None, None)

    @staticmethod
    def fromAssignString(linestr, delimitter='='):
        keyval = linestr.split(delimitter, 1)
        if len(keyval) > 1:
            key    = keyval[0].strip()
            text   = keyval[1].strip().split('"', 2)
            value  = text[1]
            return KeyValue(key, value, delimitter)
        else:
            return KeyValue(None, None)

    @staticmethod
    def fromAssignCharArray(linestr, delimitter='='):
        keyval = linestr.split(delimitter, 1)
        if len(keyval) > 1:
            key    = keyval[0].strip()
            text   = keyval[1].strip().split("'", 2)
            value  = text[1]
            return KeyValue(key, value, delimitter)
        else:
            return KeyValue(None, None)

    @staticmethod
    def fromAssignOrCharArray(linestr, delimitter='='):
        keyval = linestr.split(delimitter, 1)
        if len(keyval) > 1:
            key    = keyval[0].strip()
            text   = keyval[1].strip().split("'", 2)
            if len(text) >= 2:
                value = text[1]
            else:
                value = text[0]
            return KeyValue(key, value, delimitter)
        else:
            return KeyValue(None, None)

    @staticmethod
    def append(list, key, value):
        if value is not None:
            list.append(key + value)

    def __str__(self):
        return self.keystring + self.value


class KeyValueMap:
    def __init__(self, delimitter='='):
        self.map = {}
        self.delimitter = delimitter

    def readAssign(self, filename):
        with open(filename, 'r') as fp:
            for line in fp:
                kv = KeyValue.fromAssign(line, self.delimitter)
                self.map[kv.key] = kv

    def readAssignString(self, filename):
        with open(filename, 'r') as fp:
            for line in fp:
                kv = KeyValue.fromAssignString(line, self.delimitter)
                self.map[kv.key] = kv

    def readStringArray(self, string_array):
        for part in string_array:
            kv = KeyValue.fromAssign(part, self.delimitter)
            self.map[kv.key] = kv

    def __getitem__(self, key):
        val = self.map.get(key)
        return val.value if val is not None else None

    def __str__(self):
        return str(self.map)

    def __repr__(self):
        return str(self)
