# Copyright (C) 2015-2024 Savoir-faire Linux Inc.
#
# Author: Emmanuel Lepage Vallee <emmanuel.lepage@savoirfairelinux.com>
# Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
# Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
# Author: Aline Gondim Santos <aline.gondimsantos@savoirfairelinux.com>
# Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
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

cmake_minimum_required(VERSION 3.16)

project(qtwrapper)

message(STATUS "Compiling with ${PROJECT_NAME}")

if(MUTE_DRING)
  # It makes debugging clients easier.
  message("Jami daemon/library logs are disabled")
  add_definitions(-DMUTE_DRING=true)
endif()

set(QTWRAPPER_SOURCES
  instancemanager.cpp
  videomanager_wrap.cpp)

if(ENABLE_PLUGIN)
  message("Adding pluginmanager.cpp")
  set(PLUGIN_SOURCES pluginmanager.cpp)
else()
  message("Adding pluginmanagerMock.cpp")
  set(PLUGIN_SOURCES pluginmanagerMock.cpp)
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${LIBJAMI_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../dbus)

add_library(${PROJECT_NAME} STATIC
  ${QTWRAPPER_SOURCES}
  ${PLUGIN_SOURCES})

target_link_libraries(${PROJECT_NAME}
  Qt::Core
  ${LIBJAMI_LIB})
