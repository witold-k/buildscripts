"""
misc file utilities
"""

import fnmatch
import os
import pathlib
import difflib


def is_empty_dir(dir):
    if not os.path.isdir(dir):
        return True

    entries = os.listdir(dir)
    if len(entries) == 0:
        return True
    else:
        return False


def removed_empty_dir(dir):
    if not os.path.isdir(dir):
        return True

    entries = os.listdir(dir)
    if len(entries) == 0:
        os.rmdir(dir)
        return True
    else:
        return False


def get_first_directory(path):
    with os.scandir(path) as it:
        for entry in it:
            if entry.is_dir():
                return entry.name
    return None

#
# src_file: the existing file
# dest_file: the link that should be created
#
def rel_link(src_file, dest_file, create_dirs=True):
    dest_dir = os.path.dirname(dest_file)
    if not os.path.exists(dest_dir):
        if create_dirs:
            os.makedirs(dest_dir, mode=0o700, exist_ok=True)
        else:
            raise Exception('no such directory: ' + dest_dir)

    if os.path.islink(dest_file):
        # to do: if links is same do not change anything
        os.remove(dest_file)

    else:
        if os.path.exists(dest_file):
            os.remove(dest_file)

    relative_source = os.path.relpath(src_file, os.path.dirname(dest_file))
    os.symlink(relative_source, dest_file)
    return relative_source


#
# src_file: the existing file
# dest_file: the link that should be created
#
def symlink(src_file, dest_file, create_dirs=True):
    dest_dir = os.path.dirname(dest_file)
    if not os.path.exists(dest_dir):
        if create_dirs:
            os.makedirs(dest_dir, mode=0o700, exist_ok=True)
        else:
            raise Exception('no such directory: ' + dest_dir)
    os.symlink(src_file, dest_file)


#
# src_dir: directory with existing files
# dest_dir directory where the links should be created
#
def create_symlinks(src_dir, dest_dir):
    if os.path.isdir(src_dir):
        if not os.path.isdir(dest_dir):
            os.makedirs(dest_dir, mode=0o700, exist_ok=True)
        with os.scandir(src_dir) as itr:
            entries = list(itr)
            for filename in entries:
                src_path = os.path.join(src_dir, filename.name)
                dest_path = os.path.join(dest_dir, filename.name)
                rel_link(src_path, dest_path)


def remove_file(name):
    if os.path.exists(name):
        os.remove(name)


def remove_files_ends(root_dir, suffix):
    for dirpath, _, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith(suffix):
                file_path = os.path.join(dirpath, filename)
                remove_file(file_path)


def finish_process(p):
    lines = p.stdout.readlines()
    retval = p.wait()
    p.stdout.close()
    if (retval):
        for line in lines:
            print(line.decode('utf-8').rstrip())
    else:
        for line in lines:
            print(line.decode('utf-8').rstrip())


def get_line_from_process(p):
    lines = p.stdout.readlines()
    retval = p.wait()
    p.stdout.close()
    if retval:
        for line in lines:
            raise Exception(retval)
    else:
        for line in lines:
            return line.decode('utf-8').rstrip()


def file_contains(filename, text):
    with open(filename) as f:
        if text in f.read():
            return True
        else:
            return False


def replace_in_file(filename, from_str, to_str):
    cmd = 'sed -i \'s|' + from_str + '|' + to_str + '|g\' ' + filename
    print(cmd)
    os.system(cmd)


def _copy_replace_in_files(src_dir, dest_dir, in_replace, pattern_list, from_str, to_str):
    entries = []
    with os.scandir(src_dir) as itr:
        entries = list(itr)
    os.makedirs(dest_dir, exist_ok=True)

    for srcentry in entries:
        srcname = os.path.join(src_dir, srcentry.name)
        dstname = os.path.join(dest_dir, srcentry.name)

        if srcentry.is_dir() and not srcentry.is_symlink():
            _copy_replace_in_files(srcname, dstname, in_replace, pattern_list, from_str, to_str)
        else:
            srcpath = srcentry.name.split('/')
            do_replace = False
            if in_replace:
                for pattern in pattern_list:
                    if fnmatch.fnmatch(srcpath[-1], pattern):
                        do_replace = True
                        break

#            print('copy: ' + srcname + ' => ' + dstname)
            copy_file(srcname, dstname, follow_symlinks=False)
            if do_replace and os.path.isfile(srcname):
                replace_in_file(dstname, from_str, to_str)


def copy_replace_in_files(src_dir, dest_dir, scan_dir_list, pattern_list, from_str, to_str):
    entries = []
    with os.scandir(src_dir) as itr:
        entries = list(itr)
    os.makedirs(dest_dir, exist_ok=True)

    in_replace = False
    for srcentry in entries:
        if srcentry.name in scan_dir_list:
            in_replace = True

        srcname = os.path.join(src_dir, srcentry.name)
        dstname = os.path.join(dest_dir, srcentry.name)

        _copy_replace_in_files(srcname, dstname, in_replace, pattern_list, from_str, to_str)


def copy_file(src_file, dest_file, follow_symlinks=False):
    import os
    import shutil
    import filecmp

    do_copy = False

    # copy symlink
    if os.path.islink(src_file):
        if os.path.exists(dest_file) and os.path.samefile(src_file, dest_file):
            if os.path.islink(dest_file):
                return

        # dest_file differs, do cleanup
        if os.path.isdir(dest_file):
            shutil.rmtree(dest_file, ignore_errors=True)

        if os.path.exists(dest_file) or os.path.islink(dest_file):
            os.remove(dest_file)

        shutil.copy(src_file, dest_file, follow_symlinks=False)
        return

    # copy file
    if not os.path.exists(src_file):
        raise Exception('file not found: ' + src_file)

    if not os.path.exists(dest_file):
        do_copy = True
    else:
        if not filecmp.cmp(src_file, dest_file, shallow=False):
            os.remove(dest_file)
            do_copy = True

    if do_copy:
        dirname = os.path.dirname(dest_file)
        if not os.path.exists(dirname):
            os.makedirs(dirname, mode=0o750)
        shutil.copy(src_file, dest_file, follow_symlinks=follow_symlinks)


def copy_file_to_dir(src_file, dest_file, follow_symlinks=False):
    filename = os.path.basename(src_file)
    copy_file(src_file, dest_file + '/' + filename, follow_symlinks=follow_symlinks)


def copy_files(src_dir, dest_dir, follow_symlinks=True):
    entries = []
    with os.scandir(src_dir) as itr:
        entries = list(itr)
    os.makedirs(dest_dir, exist_ok=True)

    for srcentry in entries:
        srcname = os.path.join(src_dir, srcentry.name)
        dstname = os.path.join(dest_dir, srcentry.name)

        if srcentry.is_dir() and not srcentry.is_symlink():
            copy_files(srcname, dstname, follow_symlinks)
        else:
            copy_file(srcname, dstname, follow_symlinks)


def copy_no_vc_files(src_dir, dest_dir, follow_symlinks=True):
    entries = []
    with os.scandir(src_dir) as itr:
        entries = list(itr)
    os.makedirs(dest_dir, exist_ok=True)

    for srcentry in entries:
        srcname = os.path.join(src_dir, srcentry.name)
        dstname = os.path.join(dest_dir, srcentry.name)

        if srcentry.is_dir() and not srcentry.is_symlink():
            s = srcentry.name
            if (s != '.git') and (s != '.svn') and (s != '.hg'):
                copy_files(srcname, dstname, follow_symlinks)
        else:
            copy_file(srcname, dstname, follow_symlinks)


def copy_files_except(src_dir, dest_dir, without, follow_symlinks=True):
    entries = []
    with os.scandir(src_dir) as itr:
        entries = list(itr)
    os.makedirs(dest_dir, exist_ok=True)

    for srcentry in entries:
        if srcentry.name not in without:
            srcname = os.path.join(src_dir, srcentry.name)
            dstname = os.path.join(dest_dir, srcentry.name)

            if srcentry.is_dir() and not srcentry.is_symlink():
                copy_files(srcname, dstname, follow_symlinks)
            else:
                copy_file(srcname, dstname, follow_symlinks)


def ls_dirs_to(dirs, ignore_dirs, files):
    if dirs is None:
        return

    entries = []
    for dir in dirs:
        if dir is not None:
            with os.scandir(dir) as itr:
                entries = list(itr)

            new_dirs = []
            for srcentry in entries:
                if srcentry is not None:
                    if srcentry.name is not None and srcentry.name not in ignore_dirs:
                        srcname = os.path.join(dir, srcentry.name)
                        if os.path.isdir(srcname) and not os.path.islink(srcname):
                            new_dirs.append(srcname)
                        elif os.path.isfile(srcname):
                            files.append(srcname)
            ls_dirs_to(new_dirs, ignore_dirs, files)


def ls_dirs(dirs):
    if dirs is None:
        return []

    ignore_dirs = [".", "..", ".git", ".hg", ".svn", ".cvs"]
    files = []
    ls_dirs_to(dirs, ignore_dirs, files)
    return files


def save(filename, text):
    data = None
    if (os.path.exists(filename)):
        with open(filename, 'rb') as file:
            data = file.read()

    enc = text.encode('utf-8')
    if data is None or enc != data:
        with open(filename, 'wb') as file:
            file.write(enc)


def find_upper_side(p: pathlib.Path, name: str):
    while (len(p.parts) > 2):
        pj = p.joinpath(name)
        found = pj.is_dir()
        if (found):
            return pj
        p = p.parent
    return None


def find_file(search_path, filename):
    for root, _, files in os.walk(search_path):
        if filename in files:
            return os.path.join(root, filename)
    return None


def find_file_prefix(search_path, file_prefix):
    for root, _, files in os.walk(search_path):
        for filename in files:
            if filename.startswith(file_prefix):
                return os.path.join(root, filename)
    return None


def find_file_suffix(search_path, file_suffix):
    for root, _, files in os.walk(search_path):
        for filename in files:
            if filename.endswith(file_suffix):
                return os.path.join(root, filename)
    return None


def rm_file_with_suffix(search_path, file_suffix):
    for root, _, files in os.walk(search_path):
        for filename in files:
            if filename.endswith(file_suffix):
                os.remove(os.path.join(root, filename))


def filefinder_find_best(search_root, query, suffixes=None, cutoff=0.8):
    # search fuzzy for files which name match a patter 'query'
    # if suffixes is that then the file must contain one suffix of suffixes
    # the interal fuzzy compare is done only on the file without the suffix
    # and without the dirname

    if suffixes is None:
        suffixes = []

    # Split query into name + suffix
    query_name, query_suffix = os.path.splitext(query)
    query_name = query_name.lower()

    candidates = []  # list of (full_path, name_no_suffix, suffix)
    search_root = os.path.normpath(search_root) + '/'
    srl = len(search_root)
    for root, _, files in os.walk(search_root):
        for f in files:
            tail = root[srl - len(root):]
            rel_path = os.path.join(tail, f)
            name_no_suffix, suf = os.path.splitext(f)

            # If query contains a suffix → enforce exact suffix match
            if query_suffix:
                if suf != query_suffix:
                    continue

            # If query has no suffix → apply suffix filtering rules
            else:
                if suffixes:
                    if not any(f.endswith(s) for s in suffixes):
                        continue

            candidates.append((rel_path, name_no_suffix, suf))

    if not candidates:
        return None

    # Compute similarity scores manually
    scored = []
    for rel_path, name_no_suffix, _ in candidates:
        score = difflib.SequenceMatcher(None, query_name, name_no_suffix.lower()).ratio()
        if score >= cutoff:
            scored.append((score, rel_path))

    if not scored:
        return None

    # Sort by best score (descending)
    scored.sort(key=lambda x: x[0], reverse=True)

    # Return only the best match
    return scored[0][1]
