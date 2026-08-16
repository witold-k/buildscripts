#!/usr/bin/python3

class KeyValueTest:

    def fromAssign(self):
        import keyvalue
        keyval = ' data = 123 '
        kv = keyvalue.KeyValue.fromAssign(keyval)
        if kv.key != "data":
            raise Exception("key is not data: " + kv.key)
        if kv.value != "123":
            raise Exception("value is not 123: " + kv.value)

    def fromAssignString(self):
        import keyvalue
        keyval = ' data = "123" '
        kv = keyvalue.KeyValue.fromAssignString(keyval)
        if kv.key != "data":
            raise Exception("key is not data: " + kv.key)
        if kv.value != "123":
            raise Exception("value is not 123: " + kv.value)

    def fromAssignFile(self, root):
        import keyvalue
        map = keyvalue.KeyValueMap()
        map.readAssign(root + '/test/config')
        url = map['url']
        if url is None:
            raise Exception("url fails: is none")
        else:
            if url != "svnuser@naspi.fritz.box:svn/buildscripts":
                raise Exception("url fails: " + url)


if __name__ == "__main__":
    import sys
    from pathlib import Path
    root = str(Path(__file__ + '/../..').resolve())
    path = root + '/python'
    print("added python path: " + str(path))
    sys.path.insert(1, str(path))
    t = KeyValueTest()
    t.fromAssign()
    t.fromAssignString()
    t.fromAssignFile(root)

