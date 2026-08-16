import os


class Patcher:

    def __init__(self, path, delimitter):
        self.path  = path
        self.delimitter = delimitter
        self.lines = None
        self.touched = False
        if not os.path.exists(path):
            raise Exception('no such file: ' + path)

    @staticmethod
    def is_sep_char(ch) -> bool:
        return \
            ch == ' '  or ch == '\t' or \
            ch == '='  or ch == '{'  or ch == '}' or \
            ch == '('  or ch == ')'  or ch == '"' or \
            ch == '\'' or ch == ','  or ch == ';'

    @staticmethod
    def is_word(line, text, pos):
        if (pos < 0):
            return False
        if pos != 0:
            ch = line[pos - 1]
            if ch != ' ' and ch != '\t' and ch != '=' and ch != '{' and ch != '}' and ch != '(' and ch != ')' and ch != '"' and ch != '\'':
                return False

        tlen = len(text)
        if pos + tlen < len(line):
            ch = line[pos + tlen]
            if not Patcher.is_sep_char(ch):
                return False

        return True

    def read(self):
        file = open(self.path, 'r')
        self.lines = file.readlines()
        file.close()
        self.touched = False

    def write(self):
        if self.touched:
            cf = None
            if os.path.exists(self.path):
                cf = Patcher(self.path, self.delimitter)
                cf.read()
            if self != cf:
                file = open(self.path, 'w')
                file.writelines(self.lines)
                file.close()
            self.touched = False

    def write_to(self, path):
        import os
        cf = None
        if os.path.exists(path):
            cf = Patcher(path, self.delimitter)
            cf.read()
        if self != cf:
            dir = os.path.dirname(path)
            if not os.path.exists(dir):
                os.makedirs(dir, 0o750)
            file = open(path, 'w')
            file.writelines(self.lines)
            file.close()

    def writeTo(self, path):
        self.write_to(path)

    # returns sorted list of indizies
    def find_first(self, key):
        if self.lines is None:
            self.read()
        if self.lines is not None:
            index = 0
            for line in self.lines:
                linestr = line.rstrip()
                pos = linestr.find(key)
                if Patcher.is_word(linestr, key, pos):
                    return index
        return -1

    # returns sorted list of indizies
    def find_all_text(self, key):
        if self.lines is None:
            self.read()
        index_list = []
        if self.lines is not None:
            index = 0
            for line in self.lines:
                linestr = line.rstrip()
                pos = linestr.find(key)
                if pos >= 0:
                    index_list.append(index)
                index = index + 1
        return index_list

    # returns sorted list of indizies
    def find_all(self, key):
        if self.lines is None:
            self.read()
        index_list = []
        if self.lines is not None:
            index = 0
            for line in self.lines:
                linestr = line.rstrip()
                pos = linestr.find(key)
                if Patcher.is_word(linestr, key, pos):
                    index_list.append(index)
                index = index + 1
        return index_list

    # returns sorted list of indizies
    def find_all_in(self, lines, key):
        if self.lines is None:
            self.read()
        index_list = []
        if self.lines is not None:
            index = 0
            for index in lines:
                line = self.lines[index]
                linestr = line.rstrip()
                pos = linestr.find(key)
                if Patcher.is_word(linestr, key, pos):
                    index_list.append(index)
        return index_list

    @staticmethod
    def valid_key_begin(pos, linestr) -> bool:
        if pos < 0:
            return False
        elif 0 == pos:
            return True
        else:
            ch = linestr[pos - 1]
            return ch == ' ' or ch == '\t'

    def valid_key_delim(self, pos, linestr) -> bool:
        return linestr[pos] == ' ' or linestr[pos:].startswith(self.delimitter)

    def set(self, key, value):
        if self.lines is None:
            self.read()
        if self.lines is not None:
            index = 0
            update = False
            for line in self.lines:
                linestr = line.rstrip()
                pos = linestr.find(key)
                if Patcher.valid_key_begin(pos, linestr) and self.valid_key_delim(pos + len(key), linestr):
                    if self.delimitter is not None:
                        update  = linestr[0:pos + len(key)] + self.delimitter + value
                    else:
                        update  = linestr[0:pos + len(key)] + ' '  + value
                    self.lines[index] = (update + '\n')
                    update = True
                    break
                index = index + 1

            if not update:
                return
            self.touched = True

    def replace(self, key, value):
        if self.lines is None:
            self.read()
        if self.lines is not None:
            index = 0
            updated = False
            for line in self.lines:
                linestr = line.rstrip()
                pos = linestr.find(key)
                if pos >= 0:
                    update  = linestr.replace(key, value)
                    self.lines[index] = (update + '\n')
                    updated = True
                index = index + 1

            if not updated:
                return
            self.touched = True

    def insert_after(self, key, value):
        if self.lines is None:
            self.read()
        if self.lines is not None:
            out = []
            updated = False
            index = 1
            for line in self.lines:
                out.append(line)
                linestr = line.rstrip()
                pos = linestr.find(key)
                if pos >= 0:
                    if len(self.lines) < (index + 1) or self.lines[index].find(value) < 0:
                        if (pos > 0):
                            out.append((linestr[0] * pos) + value + '\n')
                        else:
                            out.append(value + '\n')
                        updated = True
                index = index + 1
            if updated:
                self.touched = True
                self.lines = out

    def insert_lines_after(self, key, lines):
        if self.lines is None:
            self.read()
        if self.lines is not None and lines is not None and len(lines) != 0:
            out = []
            updated = False
            index = 1
            for line in self.lines:
                out.append(line)
                linestr = line.rstrip()
                pos = linestr.find(key)
                if pos >= 0:
                    if len(self.lines) > (pos + 1) and self.lines[index].find(lines[0]) < 0:
                        if (pos > 0):
                            for value in lines:
                                out.append((linestr[0] * pos) + value + '\n')
                        else:
                            for value in lines:
                                out.append(value + '\n')
                        updated = True
                index = index + 1
            if updated:
                self.touched = True
                self.lines = out

    def replace_all(self, lines, key, value):
        if lines is None or len(lines) == 0:
            return
        if self.lines is None:
            self.read()
        if self.lines is not None:
            updated = False
            for index in lines:
                line = self.lines[index]
                linestr = line.rstrip()
                pos = linestr.find(key)
                if pos >= 0:
                    update  = linestr.replace(key, value)
                    self.lines[index] = (update + '\n')
                    updated = True

            if not updated:
                return
            self.touched = True

    def replace_all_leading_in(self, lines, leading, begin, end, key, value):
        if lines is None or len(lines) == 0:
            return
        if self.lines is None:
            self.read()
        if self.lines is not None:
            updated = False
            for index in lines:
                line = self.lines[index]
                linestr = line.rstrip()
                lpos = linestr.find(leading)
                if lpos >= 0:
                    bpos = linestr.find(begin, lpos)
                    if bpos >= 0:
                        epos = linestr.find(end, bpos)
                        pos = linestr.find(key, bpos)
                        if pos >= 0 and pos < epos:
                            update = linestr[0:bpos + len(begin)] + value + linestr[epos:]
                            self.lines[index] = (update + '\n')
                            updated = True

            if not updated:
                return
            self.touched = True

    def delete_all(self, lines):
        if lines is None or len(lines) == 0:
            return
        if self.lines is None:
            self.read()
        if self.lines is not None:
            out = []
            current_index = 0
            for index in lines:
                while current_index < index:
                    out.append(self.lines[current_index])
                    current_index = current_index + 1
                current_index = current_index + 1
            while current_index < len(self.lines):
                out.append(self.lines[current_index])
                current_index = current_index + 1

            self.lines = out
            self.touched = True

    def delete_lines(self, text):
        list = self.find_all(text)
        self.delete_all(list)

    def delete_lines_contain(self, text):
        list = self.find_all_text(text)
        self.delete_all(list)

    def __eq__(self, other):
        if other is None:
            return False
        if self.lines is None:
            return other.lines is None
        if other.lines is None:
            return self.lines is None

        l1 = len(self.lines)
        l2 = len(other.lines)
        if l1 != l2:
            return False
        for i in range(0, l1):
            if self.lines[i] != other.lines[i]:
                return False
        return True

    def __ne__(self, other):
        return not (self == other)

    def __str__(self) -> str:
        if self.lines is None:
            return '(None)'
        else:
            return ''.join(self.lines)


class MultiPatcher:
    def __init__(self, paths, delimitter):
        self.patchers = []
        for path in paths:
            self.patchers.append(Patcher(path, delimitter))

    def replace(self, key, value):
        for patcher in self.patchers:
            patcher.replace(key, value)

    def write(self):
        for patcher in self.patchers:
            patcher.write()
