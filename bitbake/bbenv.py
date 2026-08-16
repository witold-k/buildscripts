import os
import keyvalue


def apply_env_var(d, var):
    if var is None:
        return

    line = d.getVar(var)
    if line is None:
        return

    args = line.split()
    if args is None or len(args) == 0:
        return

    for arg in args:
        kv = keyvalue.KeyValue.fromAssignOrCharArray(arg)
        if kv.valid():
            os.environ[kv.key] = kv.value


def dump_env_var(d, bb, var):
    if var is None:
        bb.warn('no env set')
        return

    line = d.getVar(var)
    if line is None:
        bb.warn('no env set')
        return

    args = line.split()
    if args is None or len(args) == 0:
        bb.warn('no env set')
        return

    for arg in args:
        kv = keyvalue.KeyValue.fromAssignOrCharArray(arg)
        if kv.valid():
            bb.warn(str(kv))


def apply_localenv_keyvals(d, env, keyvals):
    if keyvals is None:
        # bb.warn('var is none')
        return

    keyvals = keyvals.strip()
    args = keyvals.split()
    if args is None or len(args) == 0:
        return

    for arg in args:
        kv = keyvalue.KeyValue.fromAssignOrCharArray(arg)
        if kv.valid():
            env[kv.key] = kv.value


def set_env_var(d, dest_env_var, src_bb_var):
    if src_bb_var is None:
        return

    var = d.getVar(src_bb_var)
    if var is None:
        return

    os.environ[dest_env_var] = var


def set_env_var2(d, dest_env_var, src_bb_var, suffix):
    if src_bb_var is None:
        return

    var = d.getVar(src_bb_var)
    if var is None:
        return

    os.environ[dest_env_var] = var + suffix


def dump_env(bb, env):
    import keyvalue

    for key, value in env.items():
        bb.warn(str(keyvalue.KeyValue(key, value)))


def dump_os_env(bb):
    import keyvalue
    for key, value in os.environ.items():
        bb.warn(str(keyvalue.KeyValue(key, value)))
