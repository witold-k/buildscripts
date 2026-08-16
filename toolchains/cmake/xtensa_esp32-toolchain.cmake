# please check:
# https://www.espressif.com/
# https://docs.espressif.com/projects/esp-idf/en/latest/esp32/get-started/linux-macos-setup.html
# https://docs.platformio.org/en/stable/frameworks/espidf.html#framework-espidf


set(CMAKE_SYSTEM_NAME FreeRtos CACHE STRING "system type")
set(CMAKE_TARGET_SYSTEM_IS_FREERTOS 1 CACHE BOOL "is defined and true only on rtos builds")
set(CMAKE_TARGET_SYSTEM_IS_ESP32 1 CACHE BOOL "is defined and true only on esp32 builds")
set(CMAKE_TARGET_DEFAULT_LINK_TYPE "STATIC" CACHE STRING "default link type")
set(TARGET_ARCH "arm" CACHE STRING "target architecture")
set(UNIX "true" CACHE BOOL "os name")

# -----------------------------------------------------------------------------

set(TOOLCHAIN_PREFIX  "xtensa-unknown-elf-")
set(TOOLCHAIN_POSTFIX "")
set(TOOLCHAIN_BASE    "/opt/compiler/${TOOLCHAIN_VERSION}/${TOOLCHAIN_VERSION}/x-tools/xtensa-unknown-elf")
set(TOOLCHAIN_SYSROOT "${TOOLCHAIN_BASE}/xtensa-unknown-elf")
set(TOOLCHAIN_DIR     "${TOOLCHAIN_BASE}/bin")
set(TOOLCHAIN_SHAREDLIB_SUFFIX ".so")

# -----------------------------------------------------------------------------

#set(CMAKE_SYSROOT         ${TOOLCHAIN_SYSROOT} CACHE FILEPATH "sysroot")
#set(CMAKE_FIND_ROOT_PATH  ${TOOLCHAIN_DIR})

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
# set(SIZEOF_FLAGS "-DSIZEOF_INT=4 -DSIZEOF_LONG=8 -DSIZEOF_OFF_T=8 -DSIZEOF_SIZE_T=8 -DSIZEOF_TIME_T=8")

set(GCC_COMMON_FLAGS "${GCC_COMMON_FLAGS} ${SIZEOF_FLAGS} -O2 ${GCC_COVERAGE_COMPILE_FLAGS} -D_COMP_GCC_ -D_VARIANT_FREERTOS_ -D_OS_FREERTOS_ -D_COMP_GCC_")
set(CMAKE_C_FLAGS_INIT    "${GCC_WARNING_FLAGS} ${CMAKE_C_FLAGS}   ${CMAKE_C_FLAGS_CMDL}   ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain initial c flags")
set(CMAKE_CXX_FLAGS_INIT  "${GCC_WARNING_FLAGS} ${CMAKE_CXX_FLAGS} ${CMAKE_CXX_FLAGS_CMDL} ${GCC_COMMON_FLAGS}" CACHE STRING "toolchain initial c++ flags")

set(CMAKE_C_FLAGS    "${CMAKE_C_FLAGS_INIT}" CACHE STRING "toolchain c flags")
set(CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS_INIT}" CACHE STRING "toolchain c++ flags")

set (TOOLCHAIN_HAVE_MEMORY_MAP false)

#message("GCC_COMMON_FLAGS= ${GCC_COMMON_FLAGS}")
#message("CMAKE_C_FLAGS   = ${CMAKE_C_FLAGS_INIT}")
#message("CMAKE_CXX_FLAGS = ${CMAKE_CXX_FLAGS_INIT}")

# -----------------------------------------------------------------------------

set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

# adjust the default behaviour of the FIND_XXX() commands:
# search headers and libraries in the target environment, search
# programs in the host environment
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
