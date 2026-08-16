CONFIGURE_SYSTEM_NAME="Linux"
CONFIGURE_TARGET_SYSTEM_IS_LINUX="1"
CONFIGURE_TARGET_DEFAULT_LINK_TYPE="SHARED"
CONFIGURE_SUPPORT_SHARED_LIBRARIES="1"

# -----------------------------------------------------------------------------

TOOLCHAIN_VERSION="v1.1-2024-09-30"
TOOLCHAIN_PREFIX="x86_64-unknown-linux-gnu-"
TOOLCHAIN_POSTFIX=""
TOOLCHAIN_BASE="/opt/compiler/$TOOLCHAIN_VERSION/x86_64-unknown-linux-gnu"
TOOLCHAIN_SYSROOT="${TOOLCHAIN_BASE}/x86_64-unknown-linux-gnu/sysroot"
TOOLCHAIN_DIR="${TOOLCHAIN_BASE}/bin"
TOOLCHAIN_SHAREDLIB_SUFFIX=".so"

# -----------------------------------------------------------------------------

SYSROOT=${TOOLCHAIN_SYSROOT}
SYSROOT_SWITCH="--sysroot=${TOOLCHAIN_SYSROOT}"

# -----------------------------------------------------------------------------

# mendatory settings
          CC="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_POSTFIX}"
         CXX="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_POSTFIX}"
      RANLIB="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ranlib${TOOLCHAIN_POSTFIX}"
          AR="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ar${TOOLCHAIN_POSTFIX}"
         GDB="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gdb"
          NM="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-nm${TOOLCHAIN_POSTFIX}"
     OBJCOPY="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objcopy"
     OBJDUMP="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objdump"
 RC_COMPILER="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}windres"
     READELF="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}readelf"
   SIZE_UTIL="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}size"
       STRIP="${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}strip"

# -----------------------------------------------------------------------------

GCC_COMMON_FLAGS="${SYSROOT_SWITCH} ${GCC_COMMON_FLAGS} -Wall -Werror -fstack-protector-strong -O2 -D_VARIANT_LINUX_ -D_VARIANT_POSIX_ -D_OS_LINUX_ -D_COMP_GCC_"
  CFLAGS="${GCC_COMMON_FLAGS} ${CFLAGS}"
CXXFLAGS="${GCC_COMMON_FLAGS} ${CXXFLAGS}"
LDFLAGS="${SYSROOT_SWITCH} ${LDFLAGS}"

TOOLCHAIN_CROSS_COMPILE_SWITCH="--cross-compile-prefix=${TOOLCHAIN_PREFIX}"

