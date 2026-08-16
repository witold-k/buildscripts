from enum import Enum
from pathlib import Path
import subprocess


class Architecture(Enum):
    DEFAULT = 1
    UNKNOWN = 2
    ALPHA   = 3
    AMD64   = 4
    ARM     = 5
    AARCH64 = 6
    AVR32   = 7
    BFIN    = 8
    CRIS    = 9
    FRV     = 10
    IA64    = 11
    M32R    = 12
    M68K    = 13
    METAG   = 14
    MICORBLAZE = 15
    MIPS    = 16
    MIPS64  = 17
    MOXIE   = 18
    PA      = 19
    POWERPC = 20
    S390    = 21
    SH      = 22
    SH64    = 23
    SPARC   = 24
    TILE    = 25
    X86     = 26
    X86_32  = 27
    X86_64  = 28
    XTENSA  = 29

    @staticmethod
    def from_name(name: str):
        ustr = name.upper()
        maxlen = 0
        hit    = Architecture.UNKNOWN
        for data in Architecture:
            if data.name in ustr:
                if (data.name != "UNKNOWN") and (len(data.name) > maxlen):
                    hit = data
                    maxlen = len(data.name)
        return hit

    @staticmethod
    def from_native():
        p = subprocess.Popen(["/usr/bin/uname", "-m"], stdout=subprocess.PIPE, shell=False)
        lines = None
        if p.stdout is not None:
            lines = p.stdout.readlines()
        _ = p.wait()
        if lines is not None:
            for line in lines:
                linestr = line.decode('utf-8').strip()
                return Architecture.from_name(linestr)
        return Architecture.UNKNOWN

    @staticmethod
    def select_native_from_dir(path: str) -> str:
        native = Architecture.from_native()
        for d in Path(path).iterdir():
            if d.is_dir():
                arch = Architecture.from_name(d.name)
                if arch == native:
                    return d.name
        return ""
