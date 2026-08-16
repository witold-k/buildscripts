from pathlib import Path

def from_versioned_project(current: Path | str | None) -> Path:
    vcs_dirs = {
        ".git",
        ".svn",
        ".hg",
        ".cvs",
        ".bzr",
        "_darcs",
        "_MTN",
        "BitKeeper",
        "BK",
        ".fslckout",
        "_FOSSIL_",
        ".fossil-settings",
    }

    if current is None:
        current = Path.cwd()
    else:
        current = Path(current).resolve()
    for parent in [current] + list(current.parents):
        for vcs in vcs_dirs:
            if (parent / vcs).exists():
                return parent

    return current

def remove_duplicates(arr):
    if not arr:
        return 0  # Empty array case
    cut = 0
    for all in range(1, len(arr)):
        if arr[all] != arr[cut]:
            cut += 1
            arr[cut] = arr[all]
    cut += 1
    return arr[:cut]


def files2path(files):
    if (not files):
        return None
    import os
    path = []
    for entry in files:
        path.append(str(os.path.dirname(entry)))
    sorted(path)
    return remove_duplicates(path)


def path2str(path):
    if path is None or len(path) == 0:
        return ""
    if len(path) == 1:
        return path[0]

    pathstr = path[0]
    for idx in range(1, len(path)):
        pathstr += ':'
        pathstr += path[idx]
    return str(pathstr)


def find_subdir(base, subdir):
    import pathlib, os

    bp = pathlib.Path(base)
    while len(bp.parts) > 1:
        p = str(bp) + '/' + subdir
        if os.path.exists(p):
            return str(p)
        bp = bp.parent

    # not found, dump search
    bp = pathlib.Path(base)
    print("BASE:" + str(bp))
    while len(bp.parts) > 1:
        print("SEARCH:" + str(bp))
        p = str(bp) + '/' + subdir
        print("CHECK:" + str(p))
        if os.path.exists(p):
            return str(p)
        bp = bp.parent

    raise Exception('subdir ' + subdir + ' not found in ' + base)
