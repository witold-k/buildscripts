inherit mesonproperties simpleninja test populate

# TOOLCHAIN is a directory here with files:
# BUILD and config.bzl
TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/bazel/${CURRENT_TARGET}"
#MESON_TOOLCHAIN = "${PROJECT_ROOT}/buildscripts/toolchains/meson/${CURRENT_TARGET}-toolchain.meson"

# Path to the Bazel workspace (source tree)
BAZEL_WORKSPACE ?= "/path/to/bazel/workspace"     # <-- DUMMY

# Bazel target to build
BAZEL_TARGET ?= "//:my_target"                    # <-- DUMMY

# Optional: Bazel configuration flags
BAZEL_FLAGS ?= "--compilation_mode=opt"           # <-- DUMMY

# Optional: Bazel output directory (BitBake local)
BAZEL_OUTDIR ?= "${B}/bazel-out"                  # <-- DUMMY

# ---------------------------------------------------------------------
# Toolchain selection (NEW)
# ---------------------------------------------------------------------

# Bazel platform to use (optional)
BAZEL_PLATFORM ?= "//platforms:dummy_platform"    # <-- DUMMY

# Combine into Bazel flags
TOOLCHAIN_FLAGS = "\
  --extra_toolchains=${TOOLCHAIN} \
  --platforms=${BAZEL_PLATFORM} \
"

# Append to global Bazel flags
BAZEL_FLAGS = "${BAZEL_FLAGS} ${TOOLCHAIN_FLAGS}"

# ---------------------------------------------------------------------
# Standard BitBake tasks
# ---------------------------------------------------------------------

python do_configure() {
    import os

    outdir = d.getVar("BAZEL_OUTDIR")
    os.makedirs(outdir, exist_ok=True)

    # Visible dummy marker
    with open(os.path.join(outdir, "CONFIGURE_MARKER.txt"), "w") as f:
        f.write("simplebazel.bbclass: configure step executed\n")
}

do_configure[dirs] = "${B}"


# ---------------------------------------------------------------------

python do_compile() {
    import os, subprocess

    bazel = d.getVar("BAZEL_BIN")
    workspace = d.getVar("BAZEL_WORKSPACE")
    target = d.getVar("BAZEL_TARGET")
    flags = d.getVar("BAZEL_FLAGS")

    cmd = [bazel, "build", target] + flags.split()

    print("=== simplebazel.bbclass: running Bazel build ===")
    print("Command:", " ".join(cmd))
    print("Workspace:", workspace)

    subprocess.check_call(cmd, cwd=workspace)
}

do_compile[dirs] = "${B}"


# ---------------------------------------------------------------------

python do_install() {
    import os, shutil

    outdir = d.getVar("BAZEL_OUTDIR")
    dest = os.path.join(d.getVar("D"), "usr/local/bin")
    os.makedirs(dest, exist_ok=True)

    dummy_output = os.path.join(outdir, "DUMMY_OUTPUT.txt")

    with open(dummy_output, "w") as f:
        f.write("simplebazel.bbclass: install step placeholder\n")

    shutil.copy(dummy_output, dest)
}

do_install[dirs] = "${D}"


# ---------------------------------------------------------------------
# Declare task order
# ---------------------------------------------------------------------

addtask configure before do_compile
addtask compile after do_configure
addtask install after do_compile

