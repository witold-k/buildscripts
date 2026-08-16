import json
from pathlib import Path
import keyvalue, pathutils


class JsonEnvironment:
    @staticmethod
    def from_json(basedir, json_data):
        private_env = JsonEnvironment.resolve_variables_self(basedir, json_data['private'])
        public_env_prepend = JsonEnvironment.resolve_variables_other(json_data, 'env:prepend', private_env)
        public_env_append  = JsonEnvironment.resolve_variables_other(json_data, 'env:append', private_env)
        public_env_set     = JsonEnvironment.resolve_variables_other(json_data, 'env:set', private_env)
        return JsonEnvironment(basedir, private_env, public_env_prepend, public_env_append, public_env_set)

    @staticmethod
    def new_empty():
        return JsonEnvironment('.', {}, {}, {}, {})

    @staticmethod
    def with_env(private_env, public_env_set):
        private_env    = JsonEnvironment.resolve_variables_self('.', private_env)
        public_env_set = JsonEnvironment.resolve_variables_other(public_env_set, private_env)
        return JsonEnvironment('.', private_env, {}, {}, public_env_set)

    @staticmethod
    def load(filename):
        basedir = str(Path(filename + '/..').resolve())
        with open(filename) as file:
            return JsonEnvironment.from_json(basedir, json.load(file))

    @staticmethod
    def load_upper_from(dirname, filename):
        envname = pathutils.find_subdir(dirname, filename)
        return JsonEnvironment.load(envname)

    @staticmethod
    def from_string(basedir, text):
        return JsonEnvironment.from_json(basedir, json.loads(text))

    @staticmethod
    def resolve_variables_self(basedir, data):
        decoded_data = {}
        dir_data = []
        for key, value in data.items():
            var_name_type = key.split(':')
            var_name = var_name_type[0]
            var_type = None
            if len(var_name_type) > 1:
                var_type = var_name_type[1]
            if var_type == "DIR" or var_type == "FILE":
                dir_data.append(var_name)
            decoded_data[var_name] = value

        replaced = True
        while replaced:
            replaced = False
            for key, value in decoded_data.items():
                kv = keyvalue.KeyValue(key, value, '=')
                if kv.has_var():
                    for var_key, var_value in decoded_data.items():
                        var_var_key = '${' + var_key + '}'
                        if var_var_key in value:
                            value = value.replace(var_var_key, var_value)
                            replaced = True
                            decoded_data[key] = value

            for dir_key in dir_data:
                dir_name = decoded_data[dir_key]
                if dir_name != "":
                    p = Path(dir_name)
                    if not p.is_absolute():
                        p = Path(basedir + '/' + str(p))
                    dir_name = str(p.resolve())
                    decoded_data[dir_key] = dir_name

        return decoded_data

    @staticmethod
    def resolve_variables_section(data, map_data):
        decoded_data = {}

        for key, value in data.items():
            if "${" in value:
                for var_key, var_value in map_data.items():
                    var_var_key = '${' + var_key + '}'
                    if var_var_key in value:
                        value = value.replace(var_var_key, var_value)
            decoded_data[key] = value
        return decoded_data

    @staticmethod
    def resolve_variables_other(data_all, key, map_data):
        return JsonEnvironment.resolve_variables_section(data_all[key], map_data)

    def __init__(self, basedir, private_env, public_env_prepend, public_env_append, public_env_set):
        self.basedir            = basedir
        self.private_env        = private_env
        self.public_env_prepend = public_env_prepend
        self.public_env_append  = public_env_append
        self.public_env_set     = public_env_set

    def apply_env(self):
        import os
        map = {}
        for name, val in self.private_env.items():
            map[name] = val
        for name, val in self.public_env_prepend.items():
            if name in os.environ:
                new_val = val + os.environ[name]
            else:
                new_val = val
            os.environ[name] = new_val
            map[name] = new_val

        for name, val in self.public_env_append.items():
            if name in os.environ:
                new_val = os.environ[name] + val
            else:
                new_val = val
                os.environ[name] = new_val
                map[name] = new_val
        for name, val in self.public_env_set.items():
            os.environ[name] = val
            map[name] = val
        return map

    @staticmethod
    def map_to_str(map):
        out = ""
        for key, value in map.items():
            out += '    { "' + key + '": "' + value + "'},\n"
        out = out[:-2]
        if len(out) == 0:
            return out
        else:
            return out + '\n'

    def __str__(self):
        return \
            '"private": {\n' + JsonEnvironment.map_to_str(self.private_env) + '},\n' + \
            '"env:prepend": {\n' + JsonEnvironment.map_to_str(self.public_env_prepend) + '},\n' + \
            '"env:append": {\n' + JsonEnvironment.map_to_str(self.public_env_append) + '},\n' + \
            '"env:set": {\n' + JsonEnvironment.map_to_str(self.public_env_set) + '}\n'
