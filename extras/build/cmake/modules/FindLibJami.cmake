# Copyright (C) 2015-2024 Savoir-faire Linux Inc.
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
#   LIBJAMI_INCLUDE_DIRS - libjami include directories
#   LIBJAMI_FOUND - whether it was able to find the include directories
#   LIBJAMI_LIB - path to libjami or libring library

set(LIBJAMI_FOUND true)

if(WITH_DAEMON_SUBMODULE)
  set(LIBJAMI_INCLUDE_DIRS ${DAEMON_DIR}/src/jami)
else()
  if(EXISTS ${LIBJAMI_INCLUDE_DIR}/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${LIBJAMI_INCLUDE_DIR})
  elseif(EXISTS ${LIBJAMI_BUILD_DIR}/jami/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${LIBJAMI_BUILD_DIR}/jami)
  elseif(EXISTS ${RING_INCLUDE_DIR}/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${RING_INCLUDE_DIR})
  elseif(EXISTS ${RING_BUILD_DIR}/jami/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${RING_BUILD_DIR}/jami)
  elseif(EXISTS ${CMAKE_INSTALL_PREFIX}/include/jami/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/include/jami)
  elseif(EXISTS ${CMAKE_INSTALL_PREFIX}/daemon/include/jami/jami.h)
    set(LIBJAMI_INCLUDE_DIRS ${CMAKE_INSTALL_PREFIX}/daemon/include/jami)
  else()
    message(STATUS "Jami daemon headers not found!
Set -DLIBJAMI_BUILD_DIR or -DCMAKE_INSTALL_PREFIX")
    set(LIBJAMI_FOUND false)
  endif()
endif()

# Save the current value of CMAKE_FIND_LIBRARY_SUFFIXES.
set(CMAKE_FIND_LIBRARY_SUFFIXES_orig ${CMAKE_FIND_LIBRARY_SUFFIXES})

set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib;.so;.dll")

set(LIBJAMI_NAMES
  jami-core
  jami
  ring
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

message(STATUS "Jami daemon headers are in " ${LIBJAMI_INCLUDE_DIRS})
message(STATUS "Jami daemon library is at " ${LIBJAMI_LIB})
