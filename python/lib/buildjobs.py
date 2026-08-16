"""
build jobs
"""

import os, subprocess, sys, multiprocessing, fileutils
from pathlib import Path
import buildpaths


class DoProcess:
    def __init__(self, cmd, cwd=None, env=None):
        self.cmd = cmd
        self.cwd = cwd
        if env is None:
            env = os.environ.copy()
            self.env = env
        else:
            self.env = env

    @staticmethod
    def is_posix() -> bool:
        return os.name == 'posix'

    # Function to set terminal to raw mode
    @staticmethod
    def set_terminal_raw(fd):
        import termios
        attrs = termios.tcgetattr(fd)
        attrs[0] &= ~(termios.IXON | termios.IXOFF | termios.ICRNL | termios.INLCR | termios.IGNCR)
        termios.tcsetattr(fd, termios.TCSANOW, attrs)

    @staticmethod
    def read_pty(fd) -> bytes:
        data = os.read(fd, 4096)
        return data

    def run_pty(self):
        import pty
        master_fd, slave_fd = pty.openpty()

        p = subprocess.Popen(
            self.cmd, cwd=self.cwd, env=self.env,
            stdin=slave_fd,
            # stdout=subprocess.PIPE,
            # stderr=subprocess.PIPE,
            stdout=slave_fd, stderr=slave_fd,
            shell=False, text=False)
        os.close(slave_fd)
        # DoProcess.set_terminal_raw(master_fd)

        try:
            while True:
                data = os.read(master_fd, 4096)
                if not data:
                    break
                sys.stdout.buffer.write(data)
                sys.stdout.flush()
        except IOError:
            pass
        finally:
            os.close(master_fd)
        return p.wait()

    def fork_pty(self):
        import pty
        pid, fd = pty.fork()
        result = 0
        if pid == 0:
            if self.cwd is not None:
                os.chdir(self.cwd)
            result = os.execvpe(self.cmd[0], self.cmd, self.env)
        else:
            try:
                while True:
                    data = os.read(fd, 4096)
                    if not data:
                        break
                    sys.stdout.buffer.write(data)
                    sys.stdout.flush()
            except IOError:
                pass
            finally:
                os.close(fd)
        return result

    def run_fork_pty(self):
        import pty
        master_fd, slave_fd = pty.openpty()
        pid = os.fork()
        result = 0
        if pid == 0:
            if self.cwd is not None:
                os.chdir(self.cwd)
            os.close(master_fd)
            os.dup2(slave_fd, 1)
            os.dup2(slave_fd, 2)
            result = os.execvpe(self.cmd[0], self.cmd, self.env)
        else:
            os.close(slave_fd)
            try:
                while True:
                    data = os.read(master_fd, 4096)
                    if not data:
                        break
                    sys.stdout.buffer.write(data)
                    sys.stdout.flush()
            except IOError:
                pass
            finally:
                os.close(master_fd)
        return result

    def spawn_pty(self):
        import pty
        if self.cwd is not None:
            os.chdir(self.cwd)
        pty.spawn(self.cmd, DoProcess.read_pty)

    def run_pipe(self):
        p = subprocess.Popen(
            self.cmd, cwd=self.cwd, env=self.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=False
        )
        if p.stdout is not None:
            for line in p.stdout:
                # linestr = line.decode('utf-8').rstrip()
                sys.stdout.buffer.write(line)
        return p.wait()

    def run(self):
        if DoProcess.is_posix():
            return self.run_pty()
        else:
            return self.run_pipe()

    def run_to_lines(self, collect_outlines=None, collect_errlines=None):
        p = subprocess.Popen(
            self.cmd, cwd=self.cwd, env=self.env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=False,
            text=True
        )
        output, errinfo = p.communicate()
        outlines = output.splitlines()
        errlines = errinfo.splitlines()
        res = p.wait()
        if collect_outlines is not None and outlines:
            collect_outlines.extend(outlines)
        if collect_errlines is not None and errlines:
            collect_errlines.extend(errlines)
        return res, outlines, errlines


class DoExec:
    def __init__(self, cwd, cmd, do_dump=False):
        self.cwd = cwd
        self.cmd = cmd
        self.do_dump = do_dump

    def run(self, do_dump=False):
        import subprocess
        p = subprocess.Popen(self.cmd, cwd=self.cwd, stdout=subprocess.PIPE, shell=True, executable='/bin/bash')
        lines = None
        if p.stdout is not None:
            lines = p.stdout.readlines()
        _ = p.wait()
        if (do_dump and lines is not None):
            for line in lines:
                linestr = line.decode('utf-8').rstrip()
                print(linestr)
                break
        return lines


class DoBuild:
    def __init__(self, bitbake_project, arch, file):
        bp = buildpaths.Buildpaths(file)
        if bp.dir is None:
            raise Exception('dir not set')
        self.dir     = bp.dir
        self.product = bp.getUpperBitbakeProductDir(bitbake_project, arch)
        self.nproc   = multiprocessing.cpu_count()

    def run(self) -> bool:
        build_was_processed = False
        entries = []
        with os.scandir(self.product) as itr:
            entries = list(itr)

        current_dir = None
        for dir in entries:
            if os.path.isfile(dir.path + '/Cargo.toml'):
                current_dir = dir
                build_was_processed = True
                cmd = ["cargo", "build", "-C", dir.path]
                dp = DoProcess(cmd)
                retval = dp.run()
                if retval != 0:
                    print("FAILED: " + str(cmd))
            if os.path.isfile(dir.path + '/build.ninja'):
                current_dir = dir
                build_was_processed = True
                cmd = ["ninja", "-C", dir.path, "-j", str(self.nproc)]
                dp = DoProcess(cmd)
                retval = dp.run()
                if retval != 0:
                    print("FAILED: " + str(cmd))
            elif os.path.isfile(dir.path + '/Makefile'):
                current_dir = dir
                build_was_processed = True
                cmd = ["make", "-C", dir.path, "-j", str(self.nproc)]
                dp = DoProcess(cmd)
                retval = dp.run()
                if retval != 0:
                    print("FAILED: " + str(cmd))

        if None is not current_dir:
            tccp = self.dir         + '/compile_commands.json'
            sccp = current_dir.path + '/compile_commands.json'
            if os.path.exists(sccp):
                fileutils.rel_link(sccp, tccp)
        return build_was_processed


class DoTest:
    def __init__(self, bitbake_project, arch, file):
        bp = buildpaths.Buildpaths(file)
        self.dir     = bp.dir
        self.product = bp.getUpperBitbakeProductDir(bitbake_project, arch)
        self.nproc   = multiprocessing.cpu_count()

    def run(self):
        entries = []
        with os.scandir(self.product) as itr:
            entries = list(itr)

        for dir in entries:
            if (os.path.isdir(dir.path)):
                cmd = ["ctest", "--output-on-failure"]
                dp = DoProcess(cmd, cwd=dir.path)
                dp.run()


class DoInstall:
    def __init__(self, bitbake_project, arch, file, prefix, target):
        bp = buildpaths.Buildpaths(file)
        self.dir     = bp.dir
        self.product = bp.getUpperBitbakeProductDir(bitbake_project, arch)
        self.install = os.path.realpath(self.product + '../install/' + target + '/' + prefix)
        self.nproc   = multiprocessing.cpu_count()

    def run(self) -> bool:
        build_was_processed = False
        entries = []
        with os.scandir(self.product) as itr:
            entries = list(itr)

        for dir in entries:
            if os.path.isfile(dir.path + '/build.ninja'):
                # build first
                build_was_processed = True
                cmd = ["ninja", "-C", dir.path, "-j", str(self.nproc)]
                dp = DoProcess(cmd)
                retval = dp.run()
                if retval != 0:
                    print("FAILED: " + str(cmd))
                else:
                    cmd = ["ninja", "-C", dir.path, "install"]
                    env = {"DESTDIR": self.install}
                    dp = DoProcess(cmd, env=env)
                    retval = dp.run()
                    if retval != 0:
                        print("FAILED: " + str(cmd))
        return build_was_processed


class DoClean:
    def __init__(self, bitbake_project, arch, file):
        import buildpaths
        bp = buildpaths.Buildpaths(file)
        self.dir     = bp.dir
        self.product = bp.getUpperBitbakeProductDir(bitbake_project, arch)

    def run(self):
        import shutil
        if (os.path.isdir(self.product)):
            shutil.rmtree(self.product)


class DoBitbake:
    def __init__(self, bitbake_exe, build_dir, args=None, do_continue=False):
        self.bitbake_lib = str(Path(bitbake_exe + '../../../lib').resolve())
        self.bitbake_exe = str(Path(bitbake_exe).resolve())
        self.build_dir   = str(Path(build_dir).resolve())
        self.args        = args
        self.do_continue = do_continue
        self.nproc       = multiprocessing.cpu_count()

    def run(self, target) -> bool:
        print("BUILD: " + self.build_dir)
        # print("BB:    " + self.bitbake_lib)
        sys.path.insert(0, self.bitbake_lib)
        try:
            import bb
        except RuntimeError as exc:
            sys.exit(str(exc))

        from bb import cookerdata
        from bb.main import bitbake_main, BitBakeConfigParameters, BBMainException

        bb.utils.check_system_locale()

        os.chdir(self.build_dir)
        cmd = [self.bitbake_exe]
        if self.do_continue:
            cmd.append("--continue")
        if self.args is not None:
            cmd += self.args
        if target is not None:
            cmd.append(target)
        try:
            sys.exit(bitbake_main(BitBakeConfigParameters(cmd),
                                  cookerdata.CookerConfiguration()))
        except BBMainException as err:
            sys.exit(err)
        except bb.BBHandledException:
            sys.exit(1)
        except Exception:
            import traceback
            traceback.print_exc()
            sys.exit(1)

#            dp = DoProcess(cmd, cwd = self.build_dir)
#            retval = dp.run()
#
#            if retval != 0:
#                print("FAILED: " + str(cmd))
#            return retval == 0


class DoBitbakeClean:
    def __init__(self, bitbake_exe, build_dir):
        self.bitbake_root = str(Path(bitbake_exe + '../../..').resolve())
        self.build_dir   = str(Path(build_dir).resolve())

    def run(self, target=None):
        import shutil
        if target is None:
            print("CLEAN: " + self.build_dir)
            if os.path.exists(self.build_dir + '/tmp'):
                shutil.rmtree(self.build_dir + '/tmp')
            if os.path.exists(self.build_dir + '/cache'):
                shutil.rmtree(self.build_dir + '/cache')
        else:
            print("CLEAN: " + self.build_dir + ", TARGET: " + target)

        if os.path.exists(self.build_dir + '/bitbake-cookerdaemon.log'):
            os.remove(self.build_dir + '/bitbake-cookerdaemon.log')


class DoCreateEnv:
    def __init__(self, env, dest_file):
        self.env       = env
        self.dest_file = str(Path(dest_file).resolve())

    def run(self):
        import fileutils
        # print(str(self.env))
        os.makedirs(os.path.dirname(self.dest_file), 0o750, exist_ok=True)
        target = "native"
        data = "#!/bin/bash\n\n"
        data += "export COMPILER_VERSION=" + self.env['COMPILER_VERSION'] + "\n"
        data += "export COMPILER_DIR=" + self.env['COMPILER_DIR'] + "\n"
        data += "export COMPILER_GIT=" + self.env['COMPILER_GIT'] + "\n"

        data += "export DOCKER_IMAGE=" + self.env['DOCKER_IMAGE'] + "\n"

        data += "export BB_WORK_DIR=" + self.env['BUILD_WORK'] + "\n"
        if target != 'native':
            data += "export BB_TARGET_SUFFIX=" + target + "-\n"
            data += "export BB_TARGET=" + target + "\n"
        else:
            data += "export BB_TARGET_SUFFIX=\n"
            data += "export BB_TARGET=native\n"

        fileutils.save(self.dest_file, data)
