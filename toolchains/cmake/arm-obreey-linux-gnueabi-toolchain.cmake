#
# Pocketbook
# Tested with INKPAD 4
#

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_TARGET_SYSTEM_IS_LINUX 1 BOOL "is defined and true only on linux builds")
set(CMAKE_TARGET_DEFAULT_LINK_TYPE "SHARED" CACHE STRING "default link type")
set(CMAKE_SUPPORT_SHARED_LIBRARIES 1 CACHE BOOL "system supports shared libraries")
set(TARGET_ARCH "arm" CACHE STRING "target architecture")
set(CMAKE_SYSTEM_PROCESSOR "arm" CACHE STRING "system processor")
set(UNIX "true" CACHE BOOL "os name")

# -----------------------------------------------------------------------------

set(TOOLCHAIN_PREFIX  "arm-obreey-linux-gnueabi-")
set(TOOLCHAIN_POSTFIX "")
set(TOOLCHAIN_BASE    "/opt/pocketbook_sdk/${TOOLCHAIN_VERSION}/SDK-B288")
set(TOOLCHAIN_SYSROOT "${TOOLCHAIN_BASE}/usr/arm-obreey-linux-gnueabi/sysroot" CACHE STRING "toolchain sysroot")
set(TOOLCHAIN_DIR     "${TOOLCHAIN_BASE}/usr/bin")
set(TOOLCHAIN_SHAREDLIB_SUFFIX ".so")

set(CMAKE_SYSROOT     "${TOOLCHAIN_SYSROOT}" CACHE FILEPATH "cmake sysroot")
# FIX: Explicitly register the cross-compiler target sysroot as the baseline search root
list(APPEND CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_SYSROOT}")

# -----------------------------------------------------------------------------

# mendatory settings
set(CMAKE_C_COMPILER   ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_POSTFIX}        CACHE FILEPATH "c compiler")
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_POSTFIX}        CACHE FILEPATH "c++ compiler")
set(CMAKE_Fortran_COMPILER ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gfortran${TOOLCHAIN_POSTFIX} CACHE FILEPATH "fortran compiler")
set(CMAKE_RANLIB       ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ranlib${TOOLCHAIN_POSTFIX} CACHE FILEPATH "ranlib")
# optional settings
set(CMAKE_AR           ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-ar${TOOLCHAIN_POSTFIX}     CACHE FILEPATH "ar archiver")
set(CMAKE_GDB          ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gdb                            CACHE FILEPATH "gdb")
set(CMAKE_NM           ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc-nm${TOOLCHAIN_POSTFIX}     CACHE FILEPATH "nm")
set(CMAKE_OBJCOPY      ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objcopy                        CACHE FILEPATH "objcopy")
set(CMAKE_OBJDUMP      ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}objdump                        CACHE FILEPATH "objdump")
set(CMAKE_RC_COMPILER  ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}windres                        CACHE FILEPATH "resource compiler")
set(CMAKE_READELF      ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}readelf                        CACHE FILEPATH "readelf")
set(CMAKE_SIZE_UTIL    ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}size                           CACHE FILEPATH "size util")
set(CMAKE_STRIP        ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}strip                          CACHE FILEPATH "strip")

# -----------------------------------------------------------------------------
set(GCC_WARNING_FLAGS "-Wall -Wextra -Werror") #  -fsanitize=address -pedantic

set(SIZEOF_FLAGS "")
if (USE_HAVE_FLAGS)
    set(HAVE_H_FLAGS "-DHAVE_STDATOMIC_H=1 -DHAVE_STDBOOL_H=1 -DHAVE_STDINT_H=1 -DHAVE_STRING_H -DHAVE_STRINGS_H -DHAVE_STDLIB_H=1 -DHAVE_UNISTD_H=1 -DHAVE_NETINET_IN_H=1 -DHAVE_ARPA_INET_H=1 -DHAVE_NETDB_H=1 -DHAVE_NET_IF_H=1 -DHAVE_SYS_IOCTL_H=1 -DHAVE_FCNTL_H=1 -DHAVE_SYS_PARAM_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_SYS_SELECT_H=1 -DHAVE_SYS_UN_H")
    set(HAVE_T_FLAGS "-DHAVE_BOOL_T=1")
    set(HAVE_FLAGS "-DHAVE_SOCKET=1 -DHAVE_SELECT=1 -DHAVE_ATOMIC=1 -DHAVE_STRUCT_TIMEVAL=1 -DHAVE_FNCTL=1 -DHAVE_STRERROR_R=1 -DHAVE_RECV=1 -DHAVE_SEND=1 -DHAVE_FCNTL_O_NONBLOCK=1 -DHAVE_SETSOCKOPT_SO_NONBLOCK=1 -DHAVE_POSIX_STRERROR_R=1 -DHAVE_GETADDRINFO=1")
endif()

set(GCC_COMMON_FLAGS "--sysroot=${TOOLCHAIN_SYSROOT} ${SIZEOF_FLAGS} ${HAVE_H_FLAGS} ${HAVE_T_FLAGS} ${HAVE_FLAGS} ${GCC_COMMON_FLAGS} -mfloat-abi=softfp -fPIC -fstack-protector-strong -O2 -D_VARIANT_LINUX_ -D_VARIANT_POSIX_ -D_OS_LINUX_ -D_COMP_GCC_")

set(CMAKE_C_FLAGS_INIT    "${GCC_WARNING_FLAGS} ${CMAKE_C_FLAGS}   ${CMAKE_C_FLAGS_CMDL}   ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain initial c flags")
set(CMAKE_CXX_FLAGS_INIT  "${GCC_WARNING_FLAGS} ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_CMDL} ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain initial c++ flags")

set(CMAKE_C_FLAGS    "${CMAKE_C_FLAGS_INIT}" CACHE STRING "toolchain c flags")
set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS_INIT}" CACHE STRING "toolchain c++ flags")

# toolchain.cmake

set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} -lm")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -lm")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} -lm")

# -----------------------------------------------------------------------------

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)


set(CMAKE_C_COMPILER_WORKS TRUE CACHE INTERNAL   "C Compiler works")
set(CMAKE_CXX_COMPILER_WORKS TRUE CACHE INTERNAL "C++ Compiler works")
set(CMAKE_FIND_ROOT_PATH ${SDK_PATH}/usr/arm-obreey-linux-gnueabi/sysroot)

