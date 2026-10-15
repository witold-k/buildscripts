# Reusable build configuration objects

`cbuildconfigure_classes` contains **ordinary Python classes**, not BitBake tasks.
The `simplemeson.bbclass` and `simplecmake.bbclass` files are adapters.

## Boundary rule

**Never call `d.getVar(...)`, `bb.note(...)`, `bb.error(...)`, `bbdefaultvars`,
`bbpaths`, or other BitBake-specific APIs from `cbuildconfigure_*.py`.**
Do not pass BitBake's `d` datastore or `bb` module to these objects.

The BitBake adapter must expand variables, perform BitBake-specific setup,
resolve tool paths, and translate BitBake names into generic configuration fields and pass a plain
`dict[str, str | None]` plus an optional
environment mapping. The configuration object constructs the command and
environment; the adapter executes it and handles BitBake logging/errors.

## Standalone usage

```python
import subprocess
from cbuildconfigure_classes.cbuildconfigure_meson import CBuildConfigureMeson

settings = {
    "module": "example",
    "executable": "/usr/bin/meson",
    "source_dir": "/tmp/example/src",
    "build_dir": "/tmp/example/build",
    "native_build": True,
    "toolchain_file": "/tmp/example/native.ini",
    "pkg_config_executable": "/usr/bin/pkg-config",
    "pkg_config_path": "/tmp/example/pkgconfig",
    "install_rpath": "$ORIGIN:$ORIGIN/../lib",
    "install_prefix": "/opt/example",
    "backend": "ninja",
    "ninja_executable": "/usr/bin/ninja",
    "compiler_version": "system",
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

## Naming convention

Configuration fields use generic Python names such as `source_dir`, `build_dir`,
`executable`, `toolchain_file`, `install_prefix`, `linker_flags`, and
`install_rpath`. **Never use BitBake variable identifiers as configuration
member names.** Mapping from `MESON_*`, `CMAKE_*`, `S`, `B`, etc. belongs
exclusively in the `.bbclass` adapters. CMake/Meson command-line option names
are necessarily tool-specific and are not configuration member names.
