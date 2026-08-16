set(CMAKE_SYSTEM_NAME Windows CACHE STRING "system type")
set(CMAKE_TARGET_SYSTEM_IS_WINDOWS 1 CACHE BOOL "is defined and true only on windows builds")
set(CMAKE_TARGET_DEFAULT_LINK_TYPE "SHARED" CACHE STRING "default link type")
set(CMAKE_SUPPORT_SHARED_LIBRARIES 1 CACHE BOOL "system supports shared libraries")
set(TARGET_ARCH "i686" CACHE STRING "target architecture")
set(CMAKE_SYSTEM_PROCESSOR "i686" CACHE STRING "system processor")
set(WIN32 "true" CACHE BOOL "os name")

# -----------------------------------------------------------------------------

set(TOOLCHAIN_PREFIX  "i686-w64-mingw32-")
set(TOOLCHAIN_POSTFIX "")
set(TOOLCHAIN_SYSROOT "/usr/i686-w64-mingw32")
set(TOOLCHAIN_DIR     "/usr/bin")
set(TOOLCHAIN_SHAREDLIB_SUFFIX ".dll.a")

# -----------------------------------------------------------------------------

#set(CMAKE_SYSROOT         ${TOOLCHAIN_SYSROOT})
set(CMAKE_FIND_ROOT_PATH  ${TOOLCHAIN_DIR})
# FIX: Explicitly register the cross-compiler target sysroot as the baseline search root
list(APPEND CMAKE_FIND_ROOT_PATH "${TOOLCHAIN_SYSROOT}")

# -----------------------------------------------------------------------------

# mendatory settings
set(CMAKE_C_COMPILER   ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}gcc${TOOLCHAIN_POSTFIX}        CACHE FILEPATH "c compiler")
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}g++${TOOLCHAIN_POSTFIX}        CACHE FILEPATH "c++ compiler")
set(CMAKE_Fortran_COMPILER ${TOOLCHAIN_DIR}/${TOOLCHAIN_PREFIX}sysroot_gfortran${TOOLCHAIN_POSTFIX} CACHE FILEPATH "fortran compiler")
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

set(GCC_COMMON_FLAGS "${TOOLCHAIN_SYSROOT_SWITCH} ${GCC_COMMON_FLAGS} -fstack-protector-strong -O2 -D_VARIANT_WINDOWS_ -D_OS_WINDOWS_ -D_COMP_MINGW_")
set(CMAKE_C_FLAGS_INIT    "${GCC_WARNING_FLAGS} ${CMAKE_C_FLAGS}   ${CMAKE_C_FLAGS_CMDL}   ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain c flags")
set(CMAKE_CXX_FLAGS_INIT  "${GCC_WARNING_FLAGS} ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_CMDL} ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain c++ flags")

#message("GCC_COMMON_FLAGS= ${GCC_COMMON_FLAGS}")
#message("CMAKE_C_FLAGS   = ${CMAKE_C_FLAGS_INIT}")
#message("CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS_INIT}")

# -----------------------------------------------------------------------------

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
