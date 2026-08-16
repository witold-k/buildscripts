load("@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
     "feature",
     "flag_group",
     "flag_set",
     "tool_path",
     "cc_toolchain_config")

def make_toolchain_config(ctx):
    tc_prefix = "aarch64-unknown-linux-gnu-"
    tc_base = "/opt/compiler/{v}/{v}/x-tools/aarch64-unknown-linux-gnu".format(
        v = ctx.attr.toolchain_version,
    )
    tc_bin = tc_base + "/bin"
    sysroot = tc_base + "/aarch64-unknown-linux-gnu/sysroot"

    return cc_toolchain_config(
        name = "config",

        toolchain_identifier = "aarch64-linux-gnu",
        host_system_name = "local",
        target_system_name = "linux",
        target_cpu = "aarch64",
        target_libc = "glibc",
        compiler = "gcc",

        cxx_builtin_include_directories = [
            sysroot + "/usr/include",
            sysroot + "/include",
        ],

        tool_paths = [
            tool_path(name = "gcc",      path = tc_bin + "/" + tc_prefix + "sysroot_gcc"),
            tool_path(name = "gxx",      path = tc_bin + "/" + tc_prefix + "sysroot_g++"),
            tool_path(name = "ld",       path = tc_bin + "/" + tc_prefix + "sysroot_gcc"),
            tool_path(name = "ar",       path = tc_bin + "/" + tc_prefix + "gcc-ar"),
            tool_path(name = "nm",       path = tc_bin + "/" + tc_prefix + "gcc-nm"),
            tool_path(name = "ranlib",   path = tc_bin + "/" + tc_prefix + "gcc-ranlib"),
            tool_path(name = "strip",    path = tc_bin + "/" + tc_prefix + "strip"),
            tool_path(name = "objcopy",  path = tc_bin + "/" + tc_prefix + "objcopy"),
            tool_path(name = "objdump",  path = tc_bin + "/" + tc_prefix + "objdump"),
            tool_path(name = "readelf",  path = tc_bin + "/" + tc_prefix + "readelf"),
        ],

        features = [
            feature(
                name = "sysroot",
                enabled = True,
                flag_sets = [
                    flag_set(
                        flag_groups = [
                            flag_group(
                                flags = ["--sysroot=" + sysroot],
                            ),
                        ],
                    ),
                ],
            ),

            feature(
                name = "warnings",
                enabled = True,
                flag_sets = [
                    flag_set(
                        flag_groups = [
                            flag_group(
                                flags = ["-Wall", "-Wextra", "-Werror"],
                            ),
                        ],
                    ),
                ],
            ),

            feature(
                name = "common_defines",
                enabled = True,
                flag_sets = [
                    flag_set(
                        flag_groups = [
                            flag_group(
                                flags = [
                                    "-DSIZEOF_INT=4",
                                    "-DSIZEOF_LONG=8",
                                    "-DSIZEOF_OFF_T=8",
                                    "-DSIZEOF_SIZE_T=8",
                                    "-DSIZEOF_TIME_T=8",
                                    "-D_VARIANT_LINUX_",
                                    "-D_VARIANT_POSIX_",
                                    "-D_OS_LINUX_",
                                    "-D_COMP_GCC_",
                                    "-D_ARCH_AARCH64_",
                                ],
                            ),
                        ],
                    ),
                ],
            ),

            feature(
                name = "linker_flags",
                enabled = True,
                flag_sets = [
                    flag_set(
                        flag_groups = [
                            flag_group(
                                flags = ["-lm"],
                            ),
                        ],
                    ),
                ],
            ),
        ],
    )

