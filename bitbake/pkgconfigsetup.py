# classes/pkgconfig.py

import os
import subprocess
import sys


class CidePkgConfig:
    """
    Configuration-only interface for pkg-config/pkgconf.

    This class does not execute pkg-config, depend on Meson or BitBake,
    modify os.environ, or inspect the process environment.

    It only constructs the environment required for an isolated
    pkg-config package universe.
    """

    def __init__(self, pkg_config: str = "/usr/bin/pkg-config", paths=None):
        self.pkg_config = pkg_config
        self.paths = self._split_paths(paths)

    @staticmethod
    def _split_paths(paths):
        if not paths:
            return []

        return [path for path in paths.split(":") if path]

    @property
    def path(self) -> str:
        return ":".join(self.paths)

    def environment(self):
        """Environment for target/host dependencies."""
        return {
            "PKG_CONFIG": self.pkg_config,
            "PKG_CONFIG_PATH": "",
            "PKG_CONFIG_LIBDIR": self.path,
            "PKG_CONFIG_DONT_DEFINE_PREFIX": "1",
            "PKG_CONFIG_DONT_RELOCATE_PATHS": "1",
            "PKG_CONFIG_ALLOW_SYSTEM_CFLAGS": "1",
            "PKG_CONFIG_ALLOW_SYSTEM_LIBS": "1",
        }

    def build_environment(self):
        """Environment for build-machine dependencies."""
        return {
            "PKG_CONFIG_FOR_BUILD": self.pkg_config,
            "PKG_CONFIG_PATH_FOR_BUILD": "",
            "PKG_CONFIG_LIBDIR_FOR_BUILD": self.path,
            "PKG_CONFIG_DONT_DEFINE_PREFIX_FOR_BUILD": "1",
            "PKG_CONFIG_DONT_RELOCATE_PATHS_FOR_BUILD": "1",
            "PKG_CONFIG_ALLOW_SYSTEM_CFLAGS_FOR_BUILD": "1",
            "PKG_CONFIG_ALLOW_SYSTEM_LIBS_FOR_BUILD": "1",
        }

    def diagnostic(self, package):
        """Run pkg-config for a package and dump its result."""
        env = self.environment()

        print("PKG_CONFIG: " + self.pkg_config)
        print("PKG_CONFIG_LIBDIR: " + self.path)
        print("PACKAGE: " + package)
        print()

        for args in (
            ["--path", package],
            ["--exists", package],
            ["--cflags", package],
            ["--libs", package],
            ["--variable=prefix", package],
            ["--variable=includedir", package],
        ):
            cmd = [self.pkg_config] + args

            print("$ " + " ".join(cmd))

            result = subprocess.run(
                cmd,
                env=env,
                capture_output=True,
                text=True,
            )

            print("returncode: " + str(result.returncode))

            if result.stdout:
                print("stdout:")
                print(result.stdout.rstrip())

            if result.stderr:
                print("stderr:")
                print(result.stderr.rstrip())

            print()

    def __str__(self):
        return "BIN: " + self.pkg_config + ", PATHS: " + self.path

def _run_test(pkg_config, paths, package):
    pc = CidePkgConfig(pkg_config, paths)

    env = os.environ.copy()
    env.update(pc.environment())

    print("PKG_CONFIG: {}".format(env["PKG_CONFIG"]))
    print("PKG_CONFIG_PATH: {!r}".format(env["PKG_CONFIG_PATH"]))
    print("PKG_CONFIG_LIBDIR: {}".format(env["PKG_CONFIG_LIBDIR"]))
    print("PKG_CONFIG_DONT_DEFINE_PREFIX: {}".format(
        env["PKG_CONFIG_DONT_DEFINE_PREFIX"]
    ))
    print("PKG_CONFIG_DONT_RELOCATE_PATHS: {}".format(
        env["PKG_CONFIG_DONT_RELOCATE_PATHS"]
    ))
    print("PKG_CONFIG_ALLOW_SYSTEM_CFLAGS: {}".format(
        env["PKG_CONFIG_ALLOW_SYSTEM_CFLAGS"]
    ))
    print("PKG_CONFIG_ALLOW_SYSTEM_LIBS: {}".format(
        env["PKG_CONFIG_ALLOW_SYSTEM_LIBS"]
    ))
    print()
    print(f"PACKAGE: {package}")
    print()

    tests = [
        ("exists", ["--exists", package]),
        ("cflags", ["--cflags", package]),
        ("libs", ["--libs", package]),
        ("prefix", ["--variable=prefix", package]),
        ("includedir", ["--variable=includedir", package]),
    ]

    for name, args in tests:
        command = [pkg_config] + args

        result = subprocess.run(
            command,
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False,
        )

        print("===== {} =====".format(name))
        print("$ {}".format(" ".join(command)))
        print("returncode: {}".format(result.returncode))

        if result.stdout:
            print("stdout:")
            print(result.stdout.rstrip())

        if result.stderr:
            print("stderr:")
            print(result.stderr.rstrip())

        print()

    print("===== environment =====")
    for key in sorted(env):
        if key.startswith("PKG_CONFIG"):
            print("{}: {!r}".format(key, env[key]))
    print()


def main():
    pkg_config = "/usr/bin/pkg-config"
    package = "libxml-2.0"

    if len(sys.argv) == 2:
        root = os.path.abspath(os.path.join(
            sys.argv[1], "..", ".."
        ))
        print("PWD: " + sys.argv[1])
        print("ROOT: " + root)
        paths = os.path.join(
            root,
            "meta-layer",
            "build",
            "tmp",
            "moduleref",
            "x86_64-unknown-linux-gnu",
        )

        _run_test(pkg_config, paths, package)
        return 0

    if len(sys.argv) != 4:
        print(
            "usage: {} [<pkg-config> <pc-path> <package>]".format(
                sys.argv[0]
            ),
            file=sys.stderr,
        )
        return 2

    _run_test(sys.argv[1], sys.argv[2], sys.argv[3])
    return 0


if __name__ == "__main__":
    sys.exit(main())

