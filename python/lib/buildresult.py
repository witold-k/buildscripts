from pathlib import Path
import copy

class Buildresult:

    def __init__(
        self,
        result,
        projectpath: Path, executionpath: Path,
        output: list[str]
    ):
        self.result = result
        self.projectpath = projectpath
        self.executionpath = executionpath
        self.output = output


    @staticmethod
    def new_need_build() -> "Buildresult":
        return Buildresult(1, Path(), Path(), [""])

    @staticmethod
    def new_no_build() -> "Buildresult":
        return Buildresult(0, Path(), Path(), [""])

    def has_error(self) -> bool:
        return self.result != 0

    def limit_lines(self, line_count: int) -> "Buildresult":
        br = copy.copy(self)
        br.output = self.output[:line_count]
        return br

    def __str__(self):
        dump = "in:  " + str(self.projectpath) + "\n" + \
            "out: " + str(self.executionpath)  + "\n"
        for line in self.output:
            dump += line + "\n"
        return dump

    def __repr__(self):
        return str(self)
