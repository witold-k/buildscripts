from enum import Enum
from pathlib import Path
import pathutils


class Buildcommand:
    def __init__(self, setup, build, lint, test):
        self.setup = setup
        self.build = build
        self.lint  = lint
        self.test  = test


class Buildsystem(Enum):
    NONE    = 1
    CARGO   = 2
    MESON   = 3
    CMAKE   = 4
    MAVEN   = 5
    JUST    = 6

    @staticmethod
    def from_name(name: str) -> "Buildsystem":
        ustr = name.upper()
        maxlen = 0
        hit    = Buildsystem.NONE
        for data in Buildsystem:
            if data.name in ustr:
                if (data.name != "NONE") and (len(data.name) > maxlen):
                    hit = data
                    maxlen = len(data.name)
        return hit

    @staticmethod
    def from_dir(path: str | Path) -> "Buildsystem":
        p = Path(path)

        if (p / "Cargo.toml").exists():
            return Buildsystem.CARGO

        if (p / "meson.build").exists():
            return Buildsystem.MESON

        if (p / "CMakeLists.txt").exists():
            return Buildsystem.CMAKE

        if (p / "pom.xml").exists():
            return Buildsystem.MAVEN

        if (p / "Justfile").exists():
            return Buildsystem.JUST

        return Buildsystem.NONE

    @staticmethod
    def from_versioned_project(path: str | Path) -> "Buildsystem":
        proj_path = Path(pathutils.from_versioned_project(path))
        return Buildsystem.from_dir(proj_path)

    def build_cmd(self, targetdir: Path | str | None = None) -> Buildcommand | None:
        # Normalize targetdir
        if targetdir is not None:
            targetdir = Path(targetdir)

        match self:
            case Buildsystem.CARGO:
                # Cargo supports --target-dir
                base = ["cargo"]
                tdir = ["--target-dir", str(targetdir)] if targetdir else []
                return Buildcommand(
                    None,
                    base + ["build"] + tdir,
                    base + ["clippy"] + tdir,
                    base + ["test"] + tdir,
                )

            case Buildsystem.MESON:
                # Meson build dir = targetdir (default: "build")
                builddir = str(targetdir or "build")
                return Buildcommand(
                    ["meson", "setup", builddir],
                    ["meson", "compile", "-C", builddir],
                    None,
                    None
                )

            case Buildsystem.CMAKE:
                # CMake build dir = targetdir (default: "build")
                builddir = str(targetdir or "build")
                return Buildcommand(
                    ["cmake", "-S", ".", "-B", builddir],
                    ["cmake", "--build", builddir],
                    None,
                    ["cmake", "test", "--build", builddir],
                )

            case Buildsystem.MAVEN:
                # Maven output dir can be overridden, but usually not needed
                if targetdir:
                    return Buildcommand(
                        None,
                        ["mvn", "clean", "install", f"-DoutputDirectory={targetdir}"],
                        None,
                        None,
                    )
                else:
                    return Buildcommand(
                        None,
                        ["mvn", "clean", "install"],
                        None,
                        None
                    )

            case Buildsystem.JUST:
                return Buildcommand(
                    None,
                    ["just", "build"],
                    None,
                    None
                )

            case _:
                return None

