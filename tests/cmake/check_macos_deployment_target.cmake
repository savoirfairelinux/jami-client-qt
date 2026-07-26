# Copyright (C) 2026 Savoir-faire Linux Inc.
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

# The daemon's contrib libraries are built with the macOS deployment target
# pinned in contrib/src/main.mak. libc++ selects a different std::mutex
# representation depending on that target, which changes the layout of
# header-only contrib types such as
# asio::detail::kqueue_reactor::descriptor_state. Building the client and
# jami-core against a different target therefore produces two incompatible
# layouts in a single binary, and the resulting out-of-bounds accesses corrupt
# the heap at runtime.

if(NOT DEFINED CONTRIB_MAIN_MAK)
    message(FATAL_ERROR "CONTRIB_MAIN_MAK must be defined")
endif()

if(NOT EXISTS "${CONTRIB_MAIN_MAK}")
    message(FATAL_ERROR "contrib makefile not found: ${CONTRIB_MAIN_MAK}")
endif()

file(STRINGS "${CONTRIB_MAIN_MAK}" MIN_OSX_LINES REGEX "^MIN_OSX_VERSION[ \t]*=")
if(NOT MIN_OSX_LINES)
    message(FATAL_ERROR "MIN_OSX_VERSION not found in ${CONTRIB_MAIN_MAK}")
endif()

list(GET MIN_OSX_LINES 0 MIN_OSX_LINE)
string(REGEX REPLACE "^MIN_OSX_VERSION[ \t]*=[ \t]*([0-9.]+).*$" "\\1"
       CONTRIB_TARGET "${MIN_OSX_LINE}")

if(NOT DEPLOYMENT_TARGET STREQUAL CONTRIB_TARGET)
    message(FATAL_ERROR
        "macOS deployment target mismatch: contrib libraries are built for "
        "${CONTRIB_TARGET} but the client and jami-core are built for "
        "'${DEPLOYMENT_TARGET}'. Mixing deployment targets changes the layout "
        "of libc++-backed types in header-only contribs and corrupts the heap "
        "at runtime.")
endif()

message(STATUS "macOS deployment target consistent with contrib: ${CONTRIB_TARGET}")
