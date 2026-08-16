import json, os
from pathlib import Path
import keyvalue, fileutils
import pkgconfig


class PkgConfigJson:
    @staticmethod
    def from_json(env, basedir, json_data):
        vars  = PkgConfigJson.resolve_variables_self(env, basedir, json_data['vars'])
        meta  = json_data['meta']
        build = json_data['build']
        return PkgConfigJson(basedir, meta, vars, build, json_data)

    @staticmethod
    def load(env, filename):
        basedir = str(Path(filename + '/..').resolve())
        with open(filename) as file:
            return PkgConfigJson.from_json(env, basedir, json.load(file))

    @staticmethod
    def from_string(env, basedir, text):
        return PkgConfigJson.from_json(env, basedir, json.loads(text))

    @staticmethod
    def resolve_variables_self(env, basedir, data):
        decoded_data = {}
        dir_data = []
        for key, value in env.items():
            decoded_data[key] = value
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
                        if var_var_key in value and pkgconfig.PkgConfig.can_replace_key(var_key):
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
    def resolve_variables_other(data_all, key, map_data):
        data = data_all[key]
        decoded_data = {}

        for key, value in data.items():
            if "${" in value:
                for var_key, var_value in map_data.items():
                    var_var_key = '${' + var_key + '}'
                    if var_var_key in value and pkgconfig.PkgConfig.can_replace_key(var_key):
                        value = value.replace(var_var_key, var_value)
            decoded_data[key] = value
        return decoded_data

    def __init__(self, basedir, meta, vars, build, raw):
        self.basedir = basedir
        self.meta    = meta
        self.vars    = vars
        self.build   = build
        self.raw     = raw

    @staticmethod
    def map_to_jsonstr(map):
        out = ""
        for key, value in map.items():
            out += '    { "' + key + '": "' + value + "'},\n"
        out = out[:-2]
        if len(out) == 0:
            return out
        else:
            return out + '\n'

    @staticmethod
    def map_to_str(map, delim):
        out = ""
        for key, value in map.items():
            out += key + delim + value + "\n"
        return out

    @staticmethod
    def generate_pkgconfig(module_dir, local_prefix, src_json_file, dest_pc_dir):
        os.makedirs(dest_pc_dir, exist_ok=True)
        filename = os.path.basename(src_json_file)
        # cut .pc.json
        new_filename = filename[:-8] + '.pc'
        save_name = dest_pc_dir + '/' + new_filename
        if module_dir is not None and module_dir != '':
            prefix = module_dir + '/' + local_prefix
            env = {'PREFIX': prefix, 'SRCDIR': module_dir}
        else:
            prefix = local_prefix
            env = {'PREFIX': prefix, 'SRCDIR': '/'}
        jsdata = PkgConfigJson.load(env, src_json_file)
        fileutils.save(save_name, jsdata.export_pkgconfig())

    def export_pkgconfig(self):
        return \
            PkgConfigJson.map_to_str(self.vars, '=') + '\n' + \
            PkgConfigJson.map_to_str(self.meta, ': ') + '\n' + \
            PkgConfigJson.map_to_str(self.build, ': ') + '\n'

    def __str__(self):
        return \
            '"meta": {\n' + PkgConfigJson.map_to_jsonstr(self.meta) + '},\n' + \
            '"vars": {\n' + PkgConfigJson.map_to_jsonstr(self.vars) + '},\n' + \
            '"build": {\n' + PkgConfigJson.map_to_jsonstr(self.build) + '}\n'
