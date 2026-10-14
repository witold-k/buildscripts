import os
import keyvalue

def apply_meson_properties(filename, d, ctar=None, set_environment=True, skip_sysroot=False):
    if not filename:
        raise ValueError("Meson toolchain file is not set")

    if not os.path.isfile(filename):
        raise FileNotFoundError(
            f"Meson toolchain file does not exist: {filename}"
        )

    with open(filename, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if ctar is None:
        ctar = d.getVar("CURRENT_TARGET")

    if not ctar:
        raise ValueError("CURRENT_TARGET not set")

    def required_var(name):
        value = d.getVar(name)
        if value is None or value == "":
            raise ValueError(f"Required BitBake variable {name} is not set")
        if not isinstance(value, str):
            raise TypeError(
                f"BitBake variable {name} must be a string, "
                f"got {type(value).__name__}"
            )
        return value.replace("'", "")

    cver = required_var("COMPILER_VERSION")
    cdir = required_var("COMPILER_DIR")

    cname = None
    cbase = None
    cbin = None
    cprefix = None

    def parse_line(parser, line, lineno):
        try:
            return parser(line)
        except Exception as exc:
            raise ValueError(
                f"Failed parsing {filename}:{lineno}: {line!r}"
            ) from exc

    def require_value(kv, lineno):
        if kv.value is None:
            raise ValueError(
                f"Missing value for {kv.key!r} "
                f"at {filename}:{lineno}"
            )

        if not isinstance(kv.value, str):
            raise TypeError(
                f"Invalid value for {kv.key!r} "
                f"at {filename}:{lineno}: "
                f"expected str, got {type(kv.value).__name__}"
            )

    def replace_reference(value, name, replacement):
        if replacement is None:
            return value

        value = value.replace(
            f"' + {name} + '", replacement
        )
        value = value.replace(
            f"{name} + '", "'" + replacement
        )
        value = value.replace(
            f"' + {name}", replacement + "'"
        )

        return value

    toolchain_keys = {
        "toolchain_name",
        "toolchain_version",
        "toolchain_prefix",
        "toolchain_base",
        "toolchain_dir",
        "toolchain_bin",
    }

    compiler_keys = {
        "c": "CC",
        "cpp": "CXX",
        "fc": "FC",
        "ar": "AR",
        "ld": "LD",
        "strip": "STRIP",
    }

    # First pass: toolchain properties and compiler commands.
    for lineno, line in enumerate(lines, 1):
        linestr = line.strip()

        if not linestr or linestr.startswith("#"):
            continue

        kv = parse_line(
            keyvalue.KeyValue.fromAssign,
            linestr,
            lineno,
        )

        if not kv.valid():
            continue

        require_value(kv, lineno)

        try:
            value = kv.value

            value = replace_reference(
                value, "toolchain_name", cname
            )
            value = replace_reference(
                value, "toolchain_version", cver
            )
            value = replace_reference(
                value, "toolchain_dir", cdir
            )
            value = replace_reference(
                value, "toolchain_base", cbase
            )
            value = replace_reference(
                value, "toolchain_bin", cbin
            )

            if cprefix is not None:
                value = value.replace(
                    "toolchain_prefix + '",
                    "'" + cprefix,
                )
                value = value.strip("'")

            if kv.key == "toolchain_name":
                cname = value.replace("'", "")
            elif kv.key == "toolchain_version":
                cver = value.replace("'", "")
            elif kv.key == "toolchain_prefix":
                cprefix = value.replace("'", "")
            elif kv.key == "toolchain_base":
                cbase = value.replace("'", "")
            elif kv.key == "toolchain_dir":
                cdir = value.replace("'", "")
            elif kv.key == "toolchain_bin":
                cbin = value.replace("'", "")

            d.setVar(kv.key, value)

            if kv.key in compiler_keys:
                d.setVar(compiler_keys[kv.key], value)

            if kv.key == "strip":
                d.setVar("STRIPPROG", value)

            elif kv.key == "toolchain_ld_library_path":
                d.setVar("TOOLCHAIN_LD_LIBRARY_PATH", value)

            elif kv.key == "sys_root":
                d.setVar("SYSROOT", value)
                d.setVar("SYSROOT_SWITCH", "--sysroot=" + value)

        except Exception as exc:
            raise RuntimeError(
                f"Failed processing Meson toolchain property "
                f"{kv.key!r} at {filename}:{lineno}: "
                f"{linestr!r}"
            ) from exc

    # Second pass: compiler and linker flags.
    for lineno, line in enumerate(lines, 1):
        linestr = line.strip()

        if not linestr or linestr.startswith("#"):
            continue

        kv = parse_line(
            keyvalue.KeyValue.fromAssignOrCharArray,
            linestr,
            lineno,
        )

        if not kv.valid():
            continue

        if kv.key in ("CFLAGS", "CXXFLAGS", "LDFLAGS"):
            require_value(kv, lineno)
            d.setVar(kv.key, kv.value)

    # Add sysroot flags.
    if not skip_sysroot:
        sr = d.getVar("SYSROOT_SWITCH")

        if sr is not None:
            if not isinstance(sr, str):
                raise TypeError(
                    f"SYSROOT_SWITCH must be a string, "
                    f"got {type(sr).__name__}"
                )

            for name in ("CFLAGS", "CXXFLAGS", "LDFLAGS"):
                current = d.getVar(name) or ""
                d.setVar(name, sr + " " + current)

    # Export toolchain settings to the process environment.
    if set_environment:
        env_vars = (
            "AR",
            "CC",
            "CXX",
            "FC",
            "LD",
            "STRIP",
            "LIBTOOL",
            "SYSROOT",
            "SYSROOT_SWITCH",
            "CFLAGS",
            "CXXFLAGS",
            "LDFLAGS",
            "TOOLCHAIN_LD_LIBRARY_PATH",
        )

        for name in env_vars:
            value = d.getVar(name)

            if value is None:
                continue

            if not isinstance(value, str):
                raise TypeError(
                    f"Environment variable {name} must be a string, "
                    f"got {type(value).__name__}"
                )

            os.environ[name] = value

        strip = d.getVar("STRIP")
        if strip is not None:
            os.environ["STRIPPROG"] = strip

