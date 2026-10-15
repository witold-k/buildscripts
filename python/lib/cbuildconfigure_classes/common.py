"""Reusable helpers for configuring CIDE build systems."""
import os
import shlex


def clean_linker_flags(flags):
    """Remove explicit staging runtime paths, retaining link-time search options."""
    return [arg for arg in shlex.split(flags or "")
            if not arg.startswith(("-Wl,-rpath=", "-Wl,-rpath,"))]


class BuildConfiguration:
    def __init__(self, config, environ=None):
        self.config = dict(config)
        self.environ = dict(os.environ if environ is None else environ)

    def get(self, key, default=None):
        value = self.config.get(key)
        return default if value is None else value

    def configure(self):
        """Return (argv, cwd, env), suitable for subprocess.run."""
        return self.create_command()
