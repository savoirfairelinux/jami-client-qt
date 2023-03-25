# Copyright (C) 2015-2023 Savoir-faire Linux Inc.
#
# Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
# Author: Emmanuel Lepage Vallee <emmanuel.lepage@savoirfairelinux.com>
# Author: Amin Bandali <amin.bandali@savoirfairelinux.com>
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

# Once done, this find module will set:
#
#   LIBJAMI_INCLUDE_DIR - libjami include directory
#   LIBJAMI_FOUND - whether it was able to find the include directories
#   LIBJAMI_LIB - path to libjami or libring library

set(LIBJAMI_FOUND true)

if(WITH_DAEMON_SUBMODULE)
  set(LIBJAMI_INCLUDE_DIR ${DAEMON_DIR}/src/jami)
else()
  find_path(LIBJAMI_INCLUDE_DIR jami.h PATH_SUFFIXES jami)
  if(NOT LIBJAMI_INCLUDE_DIR)
    message(STATUS "Jami daemon headers not found!
Set -DCMAKE_INSTALL_PREFIX or use -DWITH_DAEMON_SUBMODULE")
    set(LIBJAMI_FOUND false)
  endif()
endif()

# Save the current value of CMAKE_FIND_LIBRARY_SUFFIXES.
set(CMAKE_FIND_LIBRARY_SUFFIXES_orig ${CMAKE_FIND_LIBRARY_SUFFIXES})

set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib;.so;.dll")

if(WITH_DAEMON_SUBMODULE)
  find_library(LIBJAMI_LIB NAMES jami ring
    PATHS ${DAEMON_DIR}/src/.libs
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/libexec
    PATHS ${CMAKE_INSTALL_PREFIX}/bin
    NO_DEFAULT_PATH)
else()
  # Search only in these given PATHS.
  find_library(LIBJAMI_LIB NAMES jami ring
    PATHS ${LIBJAMI_BUILD_DIR}/.libs
    PATHS ${RING_BUILD_DIR}/.libs
    PATHS ${CMAKE_INSTALL_PREFIX}/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
    PATHS ${CMAKE_INSTALL_PREFIX}/libexec
    PATHS ${CMAKE_INSTALL_PREFIX}/bin
    NO_DEFAULT_PATH)

  # Search elsewhere as well (e.g. system-wide).
  if(NOT LIBJAMI_LIB)
    find_library(LIBJAMI_LIB NAMES jami ring)
  endif()
endif()

# Try for a static version also.
if(NOT LIBJAMI_LIB)
  set(CMAKE_FIND_LIBRARY_SUFFIXES ".a;.lib")

  if(WITH_DAEMON_SUBMODULE)
    find_library(LIBJAMI_LIB NAMES jami ring
      PATHS ${DAEMON_DIR}/src/.libs
      PATHS ${CMAKE_INSTALL_PREFIX}
      PATHS ${CMAKE_INSTALL_PREFIX}/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/libexec
      NO_DEFAULT_PATH)
  else()
    # Search only in these given PATHS.
    find_library(LIBJAMI_LIB NAMES jami ring
      PATHS ${LIBJAMI_BUILD_DIR}/.libs
      PATHS ${RING_BUILD_DIR}/.libs
      PATHS ${CMAKE_INSTALL_PREFIX}
      PATHS ${CMAKE_INSTALL_PREFIX}/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/daemon/lib
      PATHS ${CMAKE_INSTALL_PREFIX}/libexec
      NO_DEFAULT_PATH)

    # Search elsewhere as well (e.g. system-wide).
    if(NOT LIBJAMI_LIB)
      find_library(LIBJAMI_LIB NAMES jami ring)
    endif()

    if(NOT ${CMAKE_SYSTEM_NAME} MATCHES "Windows")
      add_definitions(-fPIC)
    endif()
  endif()
endif()

# Restore the original value of CMAKE_FIND_LIBRARY_SUFFIXES.
set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_orig})

message(STATUS "Jami daemon headers are in " ${LIBJAMI_INCLUDE_DIR})
message(STATUS "Jami daemon library is at " ${LIBJAMI_LIB})
