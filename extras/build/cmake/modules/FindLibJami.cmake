# Copyright (C) 2015-2025 Savoir-faire Linux Inc.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA.

# Once done, this find module will set the LibJami::LibJami imported
# target, which references all what is needed (headers, libraries,
# dependencies).

set(LIBJAMI_FOUND true)

if(WITH_DAEMON_SUBMODULE)
  set(LIBJAMI_INCLUDE_DIR ${DAEMON_DIR}/src/jami)
else()
  # Preferably find libjami via pkg-config.
  find_package(PkgConfig QUIET)
  if(PKG_CONFIG_FOUND)
    pkg_check_modules(LIBJAMI QUIET IMPORTED_TARGET jami)
    if(LIBJAMI_FOUND)
      add_library(LibJami::LibJami ALIAS PkgConfig::LIBJAMI)
      message(STATUS "Found LibJami via pkg-config")
      return()
    endif()
  endif()

  find_path(LIBJAMI_INCLUDE_DIR jami.h PATH_SUFFIXES jami)
  if(NOT LIBJAMI_INCLUDE_DIR)
    message(STATUS "Jami daemon headers not found!
To build using the daemon git submodule, set -DWITH_DAEMON_SUBMODULE")
    set(LIBJAMI_FOUND false)
  endif()
endif()

# Save the current value of CMAKE_FIND_LIBRARY_SUFFIXES.
set(CMAKE_FIND_LIBRARY_SUFFIXES_orig ${CMAKE_FIND_LIBRARY_SUFFIXES})

set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib;.so;.dll")

set(LIBJAMI_NAMES
  jami-core
  jami
)

if(WITH_DAEMON_SUBMODULE)
  find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES}
    PATHS ${DAEMON_DIR}/src/.libs
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/libexec
    PATHS ${CMAKE_INSTALL_PREFIX}/bin
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/build/bin
    NO_DEFAULT_PATH)
else()
  # Search only in these given PATHS.
  find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES}
    PATHS ${LIBJAMI_BUILD_DIR}/.libs
    PATHS ${RING_BUILD_DIR}/.libs
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/libexec
    PATHS ${CMAKE_INSTALL_PREFIX}/bin
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/build/bin
    NO_DEFAULT_PATH)

  # Search elsewhere as well (e.g. system-wide).
  if(NOT LIBJAMI_LIB)
    find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES})
  endif()
endif()

# Try for a static version also.
if(NOT LIBJAMI_LIB)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".a;.lib")

  if(WITH_DAEMON_SUBMODULE)
    find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES}
      PATHS ${DAEMON_DIR}/src/.libs
      PATHS ${CMAKE_INSTALL_PREFIX}
      PATHS ${CMAKE_INSTALL_PREFIX}/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/libexec
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/build/lib
      NO_DEFAULT_PATH)
  else()
    # Search only in these given PATHS.
    find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES}
      PATHS ${LIBJAMI_BUILD_DIR}/.libs
      PATHS ${RING_BUILD_DIR}/.libs
      PATHS ${CMAKE_INSTALL_PREFIX}
      PATHS ${CMAKE_INSTALL_PREFIX}/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/libexec
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/build/lib
      NO_DEFAULT_PATH)

    # Search elsewhere as well (e.g. system-wide).
    if(NOT LIBJAMI_LIB)
      find_library(LIBJAMI_LIB NAMES ${LIBJAMI_NAMES})
    endif()

    if(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Windows")
      add_definitions(-fPIC)
    endif()
  endif()
endif()

# Restore the original value of CMAKE_FIND_LIBRARY_SUFFIXES.
set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_orig})

# Assemble a CMake imported target with the above information gathered
# by other means than pkg-config.
if(LIBJAMI_FOUND AND LIBJAMI_LIB AND LIBJAMI_INCLUDE_DIR)
  add_library(LibJami::LibJami UNKNOWN IMPORTED)
  set_target_properties(LibJami::LibJami PROPERTIES
    IMPORTED_LOCATION "${LIBJAMI_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${LIBJAMI_INCLUDE_DIR}"
  )
endif()

message(STATUS "Jami daemon headers are in " ${LIBJAMI_INCLUDE_DIR})
message(STATUS "Jami daemon library is at " ${LIBJAMI_LIB})
