"""Reusable helpers for configuring CIDE build systems."""
import os
import shlex
import subprocess


def clean_linker_flags(flags):
    """Remove explicit staging runtime paths, retaining link-time search options."""
    return [arg for arg in shlex.split(flags or "")
            if not arg.startswith(("-Wl,-rpath=", "-Wl,-rpath,"))]


class BuildConfiguration:
    def __init__(self, d):
        self.d = d

    def get(self, key, default=None):
        value = self.d.getVar(key)
        return default if value is None else value

    def run(self, argv, cwd, env, bb):
        bb.note("CONFIGURE: " + shlex.join(argv))
        result = subprocess.run(argv, cwd=cwd, env=env,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT, text=True)
        if result.returncode:
            bb.plain(result.stdout)
            raise RuntimeError("Configuration failed: " + shlex.join(argv))
        for line in result.stdout.splitlines():
            bb.note(line)
