load(":config.bzl", "make_toolchain_config")

cc_toolchain_config(
    name = "aarch64_config",
    toolchain_version = "DUMMY_VERSION",  # replace dynamically
)

cc_toolchain(
    name = "aarch64_toolchain",
    toolchain_identifier = "aarch64-linux-gnu",
    toolchain_config = ":aarch64_config",
)

toolchain(
    name = "registered",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    toolchain = ":aarch64_toolchain",
)

