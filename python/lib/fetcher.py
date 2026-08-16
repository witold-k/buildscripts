import os, json
import fetcher_classes.fetcherentry as fe
import fetcher_classes.fetcher_dir as fdir
import fetcher_classes.fetcher_git as fgit
import fetcher_classes.fetcher_hg as fhg
import fetcher_classes.fetcher_none as fnone
import fetcher_classes.fetcher_rsync as frsync
import fetcher_classes.fetcher_svn as fsvn
import fetcher_classes.fetcher_wget as fwget
from concurrent.futures import ThreadPoolExecutor, as_completed


class FetcherList:
    def __init__(self):
        self.repos = []

    def __iter__(self):
        return self.repos.__iter__()

    def __len__(self):
        return len(self.repos)

    def __delitem__(self, key):
        self.repos.__delattr__(key)

    def __getitem__(self, key):
        return self.repos.__getattribute__(key)

    def __setitem__(self, key, value):
        self.repos.__setattr__(key, value)

    def __str__(self) -> str:
        val = self.toJson() if self.repos is not None else ''
        return val

    @staticmethod
    def fromJson(js):
        ret = FetcherList()
        for entry in js:
            ret.repos.append(fe.FetcherEntry.fromJson(entry))
        return ret

    def toJson(self):
        size = len(self.repos)
        str = '[\n'
        if size > 0:
            str += self.repos[0].toJson()
        it = iter(self.repos)
        next(it)
        for entry in it:
            str += ',\n' + entry.toJson()
        str += '\n]'
        return str


class FetcherCommand:
    def __init__(self, directory):
        import os
        self.dir      = directory
        self.jsonfile = os.path.dirname(directory) + '/' + os.path.basename(directory) + '.modules'

    def create_fetcher(self, tool: fe.FetcherTool):
        if tool == fe.FetcherTool.DIR:
            return fdir.FetcherDir(self.dir)
        if tool == fe.FetcherTool.GIT:
            return fgit.FetcherGit(self.dir)
        if tool == fe.FetcherTool.HG:
            return fhg.FetcherHg(self.dir)
        if tool == fe.FetcherTool.SVN:
            return fsvn.FetcherSvn(self.dir)
        if tool == fe.FetcherTool.WGET:
            return fwget.FetcherWget(self.dir)
        if tool == fe.FetcherTool.RSYNC:
            return frsync.FetcherRsync(self.dir)
        return fnone.FetcherNone(self.dir)

    def scan(self):
        list = FetcherList()
        if not os.path.exists(self.dir):
            os.makedirs(self.dir, 0o750, exist_ok=True)
        dirs = os.listdir(self.dir)
        for dir in dirs:
            clonedir = self.dir + '/' + dir
            tool = fe.FetcherTool.from_dir(clonedir)
            e = self.create_fetcher(tool).scan(clonedir, dir)
            if e is not None:
                list.repos.append(e)
        list.repos = sorted(list.repos)
        return list

    def save(self):
        list = self.scan()
        js   = list.toJson()
        with open(self.jsonfile, 'w') as f:
            f.write(js)

    def fetch(self, doCleanUp=True, doUpdate=False, max_workers=0):
        """
        Fetch entries concurrently with a configurable number of threads.
        Default max_workers = number of CPUs.
        """
        current_entry = ''
        try:
            with open(self.jsonfile, 'r') as f:
                js = json.load(f)
            entries = FetcherList.fromJson(js)

            # Default number of workers = CPU count
            if max_workers == 0:
                max_workers = os.cpu_count() or 8  # fallback to 4 if detection fails
                if max_workers < 8:
                    max_workers = 8

            def process_entry(entry):
                return self.create_fetcher(entry.tool).fetch(entry, doCleanUp=doCleanUp, doUpdate=doUpdate)

            # Run with ThreadPoolExecutor
            ignore = [
                'nothing to commit', 'Already on', 'is up to date', 'Already up to date',
                'fatal: There is no merge to abort', 'fatal: no rebase in progress'
            ]
            with ThreadPoolExecutor(max_workers=max_workers) as executor:
                futures = {executor.submit(process_entry, entry): entry for entry in entries}
                for future in as_completed(futures):
                    entry = futures[future]
                    try:
                        lines = future.result()
                        if lines:
                            for line in lines:
                                if not any(ig in line for ig in ignore):
                                    print(line)
                    except Exception as e:
                        raise Exception(
                            f"can not execute: {self.jsonfile}\nentry: {entry}\nerror: {e}"
                        )

        except Exception as e:
            raise Exception(
                f"can not parse: {self.jsonfile}\nentry: {current_entry}\nerror: {e}"
            )

    @staticmethod
    def sync(moduledir, command):
        cmd = FetcherCommand(moduledir)
        keep_switch   = 'keep' in command
        update_switch = 'update' in command
        cmd.fetch(doCleanUp=not keep_switch, doUpdate=update_switch)

    @staticmethod
    def save_to(moduledir):
        print("[fetcher] save " + moduledir)
        cmd = FetcherCommand(moduledir)
        cmd.save()
