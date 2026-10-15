# Reusable build configuration objects

`cbuildconfigure_classes` contains **ordinary Python classes**, not BitBake tasks.
The `simplemeson.bbclass` and `simplecmake.bbclass` files are adapters.

## Boundary rule

**Never call `d.getVar(...)`, `bb.note(...)`, `bb.error(...)`, `bbdefaultvars`,
`bbpaths`, or other BitBake-specific APIs from `cbuildconfigure_*.py`.**
Do not pass BitBake's `d` datastore or `bb` module to these objects.

The BitBake adapter must expand variables, perform BitBake-specific setup,
resolve tool paths, and pass a plain `dict[str, str | None]` plus an optional
environment mapping. The configuration object constructs the command and
environment; the adapter executes it and handles BitBake logging/errors.

## Standalone usage

```python
import subprocess
from cbuildconfigure_classes.cbuildconfigure_meson import CBuildConfigureMeson

settings = {
    "MODULE": "example",
    "MESON_BIN": "/usr/bin/meson",
    "S": "/tmp/example/src",
    "B": "/tmp/example/build",
    "IS_NATIVE": True,
    "TOOLCHAIN": "/tmp/example/native.ini",
    "MESON_PKG_CONFIG": "/usr/bin/pkg-config",
    "MESON_PKG_CONFIG_PATH": "/tmp/example/pkgconfig",
    "MESON_INSTALL_RPATH": "$ORIGIN:$ORIGIN/../lib",
    "TARGET_PREFIX_DIR": "/opt/example",
    "MESON_GENERATOR": "ninja",
    "NINJA_BIN": "/usr/bin/ninja",
    "COMPILER_VERSION": "system",
}
argv, cwd, env = CBuildConfigureMeson(settings).configure()
subprocess.run(argv, cwd=cwd, env=env, check=True)
```

CMake follows the same API: `CBuildConfigureCMake(settings).configure()`
returns `(argv, cwd, env)`. Provide the required CMake settings and paths
in the dictionary. Neither class imports BitBake.

`clean_linker_flags` removes explicit staging `-Wl,-rpath` flags while
retaining link-time `-L` and `-rpath-link` options. Install RPATH settings
remain caller-configurable.

The existing `cbuildconfigure.py` and older helpers are not part of this
adapter contract yet; future changes should follow the same boundary.
