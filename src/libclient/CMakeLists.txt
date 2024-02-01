# Copyright (C) 2015-2024 Savoir-faire Linux Inc.
#
# Author: Emmanuel Lepage Vallee <emmanuel.lepage@savoirfairelinux.com>
# Author: Alexandre Lision <alexandre.lision@savoirfairelinux.com>
# Author: Guillaume Roguez <guillaume.roguez@savoirfairelinux.com>
# Author: Stepan Salenikovich <stepan.salenikovich@savoirfairelinux.com>
# Author: Alexandre Viau <alexandre.viau@savoirfairelinux.com>
# Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
# Author: Nicolas Jager <nicolas.jager@savoirfairelinux.com>
# Author: Hugo Lefeuvre <hugo.lefeuvre@savoirfairelinux.com>
# Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
# Author: Albert Babí <albert.babi@savoirfairelinux.com>
# Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
# Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
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

project(jami-libclient)

# First, check if the compiler is new enough.  Most versions of Clang
# are fine until specific problems arise.  Checking for GCC is enough.
if(CMAKE_COMPILER_IS_GNUCC)
  if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 8.0)
    message(STATUS
      "Found GCC version >= 8.0: " ${CMAKE_CXX_COMPILER_VERSION})
  else()
    message(FATAL_ERROR "Your version of GCC is too old, \
please install GCC 8.0 or newer")
  endif()
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS_DEBUG "-Og -ggdb")

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH true)

# libjami (daemon)
if(NOT DEFINED EXTRAS_DIR)
  set(EXTRAS_DIR ${PROJECT_SOURCE_DIR}/../../extras)
endif()
set(CMAKE_MODULE_PATH
  ${CMAKE_MODULE_PATH} "${EXTRAS_DIR}/build/cmake/modules")
find_package(LibJami REQUIRED)
if(LIBJAMI_FOUND)
  include_directories(${LIBJAMI_INCLUDE_DIRS})
endif()

string(SUBSTRING ${CMAKE_GENERATOR} 0 14 CMAKE_GENERATOR_SHORT)
if(CMAKE_GENERATOR_SHORT MATCHES "Visual Studio ")
  message(STATUS "Generating VS project")
  set(CMAKE_CXX_COMPILER_ID "MSVC")
  set(ENABLE_TEST false)
  add_definitions(-DUNICODE -D_UNICODE)
  remove_definitions(-D_MBCS)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zi /W0 /MP /EHsc")
endif()

if (NOT (CMAKE_CXX_COMPILER_ID MATCHES "MSVC"))
  add_definitions(
    ${QT_DEFINITIONS}
    -fexceptions
    -O2
    # Enable some useful warnings
    -Wall
    -pedantic
    -Wextra
    -Wmissing-declarations
    -Wmissing-noreturn
    -Wpointer-arith
    -Wcast-align
    -Wwrite-strings
    -Wformat-nonliteral
    -Wformat-security
    -Wmissing-include-dirs
    -Wundef
    -Wmissing-format-attribute
    -Wno-reorder
    -Wunused
    -Woverloaded-virtual
    -Wvarargs
    -Wno-gnu-zero-variadic-macro-arguments
)
endif()

# Add more warnings for compilers that support it.
# I used pipelines like the following:
#   curl https://gcc.gnu.org/onlinedocs/gcc-4.8.5/gcc/Warning-Options.html | \
#     grep -E "^[\t ]+<br><dt><code>-W[a-zA-Z=-]*" -o | \
#     grep -E "\-W[a-zA-Z=-]*" -o > /tmp/48;
#   curl https://gcc.gnu.org/onlinedocs/gcc-4.9.2/gcc/Warning-Options.html | \
#     grep -E "^[\t ]+<br><dt><code>-W[a-zA-Z=-]*" -o | \
#     grep -E "\-W[a-zA-Z=-]*" -o > /tmp/49;
#   sort /tmp/48 /tmp/49 | uniq -u
if(CMAKE_COMPILER_IS_GNUCC)
  add_definitions(
    # GCC 4.9
    -Wconditionally-supported
    -Wno-cpp
    -Wdouble-promotion
    -Wdate-time
    -Wfloat-conversion
    # GCC 5.1
    -Wformat-signedness
    -Wnormalized
    -Wshift-count-negative
    -Wshift-count-overflow
    -Wsized-deallocation
    -Wsizeof-array-argument
    # GCC 6.0
    -Wnull-dereference
    -Wshift-negative-value
    -Wshift-overflow
    -Wduplicated-cond)
endif()

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_definitions(
    -Wno-c++98-compat
    -Wno-c++98-compat-pedantic
    -Wno-unknown-pragmas
    -Wno-documentation-unknown-command
    -Wno-padded
    -Wno-old-style-cast
    -Wno-sign-conversion
    -Wno-exit-time-destructors
    -Wno-global-constructors
    -Wno-shorten-64-to-32
    # -Weverything
  )
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
  set(CMAKE_MACOSX_RPATH on)
  set(CMAKE_SKIP_BUILD_RPATH false)
  set(CMAKE_BUILD_WITH_INSTALL_RPATH false)
  set(CMAKE_INSTALL_RPATH "${CMAKE_CURRENT_SOURCE_DIR}")
endif()

if(NOT ENABLE_TEST)
  set(ENABLE_TEST false)
endif()

if(NOT (${ENABLE_VIDEO} MATCHES false))
  message(STATUS "VIDEO enabled")
  set(ENABLE_VIDEO 1 CACHE BOOL "Enable video")
  add_definitions(-DENABLE_VIDEO=true)
endif()

if(NOT (${ENABLE_PLUGIN} MATCHES false))
  message(STATUS "PLUGIN enabled")
  set(ENABLE_PLUGIN 1 CACHE BOOL "Enable plugin")
  add_definitions(-DENABLE_PLUGIN=true)
endif()

include_directories(SYSTEM ${QT_INCLUDES})
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})

# Here we let find_package(<PackageName>...) try to find Qt 6.
# If it is found, find_package will succeed, and the CMake variable
# QT_VERSION_MAJOR will be set to 6.

if(QT6_VER AND QT6_PATH)
  find_package(QT NAMES Qt6 REQUIRED
    PATHS ${QT6_PATH} NO_DEFAULT_PATH)
else()
  find_package(QT NAMES Qt6 REQUIRED)
endif()
if (${QT_VERSION_MAJOR} STRLESS 6)
  if (${QT_VERSION_MINOR} STRLESS 6)
    message(FATAL_ERROR "Qt 6.6 or higher is required.")
  endif()
endif()

set(QT_MODULES Core Gui Sql)
if(NOT ENABLE_LIBWRAP)
  list(APPEND QT_MODULES DBus)
endif()

if(QT6_VER AND QT6_PATH)
  message(STATUS "Using custom Qt version")
  find_package(Qt${QT_VERSION_MAJOR}
    REQUIRED COMPONENTS ${QT_MODULES}
    OPTIONAL_COMPONENTS LinguistTools
    PATHS ${QT6_PATH} NO_DEFAULT_PATH)
else()
  find_package(Qt${QT_VERSION_MAJOR}
    REQUIRED COMPONENTS ${QT_MODULES}
    OPTIONAL_COMPONENTS LinguistTools)
endif()

if(ENABLE_LIBWRAP)
  # The daemon is only required for when using direct linking
  if(NOT LIBJAMI_LIB)
    message(FATAL_ERROR "Jami daemon library is required when \
building with ENABLE_LIBWRAP")
  endif()

  # Use native calls (no DBus)
  add_definitions(-DENABLE_LIBWRAP=true)
  if (NOT (CMAKE_CXX_COMPILER_ID MATCHES "MSVC"))
    add_definitions(-Wno-unknown-pragmas)
  endif()
  message(STATUS "Compiling with qtwrapper enabled, \
Qt${QT_VERSION_MAJOR} enabled.")

  add_subdirectory(qtwrapper)
  include_directories(qtwrapper)

  if(JAMICORE_AS_SUBDIR)
    add_dependencies(qtwrapper jami-core)
  endif()

  if(${VERBOSE_IPC} MATCHES true)
    message(STATUS "Adding more debug output")
    add_definitions(-DVERBOSE_IPC=true)
  endif()
endif()

set(LIBCLIENT_SOURCES
  # data objects
  uri.cpp
  vcard.cpp

  # models
  contactmodel.cpp
  callparticipantsmodel.cpp
  callmodel.cpp
  devicemodel.cpp
  codecmodel.cpp
  conversationmodel.cpp
  database.cpp
  authority/daemon.cpp
  authority/storagehelper.cpp
  lrc.cpp
  accountmodel.cpp
  peerdiscoverymodel.cpp
  callbackshandler.cpp
  behaviorcontroller.cpp
  datatransfermodel.cpp
  messagelistmodel.cpp
  callInformationListModel.cpp
  rendererinformationlistmodel.cpp

  # communication
  dbus/configurationmanager.cpp
  dbus/callmanager.cpp
  dbus/instancemanager.cpp
  dbus/videomanager.cpp
  dbus/presencemanager.cpp
  dbus/pluginmanager.cpp

  # default interface implementations
  globalinstances.cpp
  pixmapmanipulatordefault.cpp
  dbuserrorhandlerdefault.cpp

  # other
  avmodel.cpp
  pluginmodel.cpp
  namedirectory.cpp
  renderer.cpp)

set(LIBCLIENT_HEADERS
  uri.h
  globalinstances.h
  pixmapmanipulatordefault.h
  dbuserrorhandlerdefault.h
  vcard.h
  namedirectory.h
  messagelistmodel.h
  callInformationListModel.h
  rendererinformationlistmodel.h

  # interfaces
  interfaces/pixmapmanipulatori.h
  interfaces/dbuserrorhandleri.h

  # extra
  typedefs.h
  containerview.h
  renderer.h)

set(LIBCLIENT_HEADERS_API
  api/account.h
  api/avmodel.h
  api/behaviorcontroller.h
  api/call.h
  api/contact.h
  api/conversation.h
  api/contactmodel.h
  api/conversationmodel.h
  api/datatransfermodel.h
  api/messagelistmodel.h
  api/datatransfer.h
  api/interaction.h
  api/lrc.h
  api/member.h
  api/accountmodel.h
  api/callmodel.h
  api/callparticipantsmodel.h
  api/codecmodel.h
  api/devicemodel.h
  api/pluginmodel.h
  api/peerdiscoverymodel.h
  api/profile.h
  api/video.h)

# For libavutil/avframe.
set(LIBJAMI_CONTRIB_DIR
  "${DAEMON_DIR}/contrib")
find_path(AVUTIL_INCLUDE_DIR libavutil/avutil.h
  PATHS
  ${LIBJAMI_CONTRIB_DIR}/native/ffmpeg
  ${LIBJAMI_CONTRIB_DIR}/apple-darwin/include/
  ${LIBJAMI_CONTRIB_DIR}/build/ffmpeg/Build/win32/x64/include)
include_directories(${AVUTIL_INCLUDE_DIR})
if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} -dumpmachine
    OUTPUT_STRIP_TRAILING_WHITESPACE
    OUTPUT_VARIABLE CC_MACHINE)
else()
  set(CC_MACHINE "")
endif()
find_library(AVUTIL_LIBRARY avutil
  HINTS
  ${LIBJAMI_CONTRIB_DIR}/${CC_MACHINE}/lib
  ${LIBJAMI_CONTRIB_DIR}/apple-darwin/lib)

if(ENABLE_LIBWRAP)
  list(APPEND LIBCLIENT_HEADERS directrenderer.h)
  list(APPEND LIBCLIENT_SOURCES directrenderer.cpp)
else()
  list(APPEND LIBCLIENT_HEADERS shmrenderer.h)
  list(APPEND LIBCLIENT_SOURCES shmrenderer.cpp)

  # Build DBus API
  if(DEFINED RING_XML_INTERFACES_DIR)
    set(dbus_xml_introspecs_path ${RING_XML_INTERFACES_DIR})
  elseif(DEFINED LIBJAMI_XML_INTERFACES_DIR)
    set(dbus_xml_introspecs_path ${LIBJAMI_XML_INTERFACES_DIR})
  elseif(EXISTS "${DAEMON_DIR}/bin/dbus")
    set(dbus_xml_introspecs_path ${DAEMON_DIR}/bin/dbus)
  else()
    set(dbus_xml_introspecs_path
      ${CMAKE_INSTALL_PREFIX}/share/dbus-1/interfaces)
  endif()
  message(STATUS "Using Jami (Ring) DBus-XML interfaces in \
${dbus_xml_introspecs_path}")

  set(presencemanager_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.PresenceManager.xml)
  set(dbus_metatype_path "dbus/metatypes.h")
  set_source_files_properties(
    ${presencemanager_xml}
    PROPERTIES
    CLASSNAME PresenceManagerInterface
    INCLUDE ${dbus_metatype_path})

  set(configurationmanager_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.ConfigurationManager.xml)
  set_source_files_properties(
    ${configurationmanager_xml}
    PROPERTIES
    CLASSNAME ConfigurationManagerInterface
    INCLUDE ${dbus_metatype_path})

  set(callmanager_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.CallManager.xml)
  set_source_files_properties(
    ${callmanager_xml}
    PROPERTIES
    CLASSNAME CallManagerInterface
    INCLUDE ${dbus_metatype_path})

  set(video_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.VideoManager.xml)
  set_source_files_properties(
    ${video_xml}
    PROPERTIES
    CLASSNAME VideoManagerInterface
    INCLUDE ${dbus_metatype_path})

  set(plugin_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.PluginManagerInterface.xml)
  set_source_files_properties(
    ${plugin_xml}
    PROPERTIES
    CLASSNAME PluginManagerInterface
    INCLUDE ${dbus_metatype_path})

  set(instance_xml
    ${dbus_xml_introspecs_path}/cx.ring.Ring.Instance.xml)
  set_source_files_properties(
    ${instance_xml}
    PROPERTIES
    CLASSNAME InstanceManagerInterface
    INCLUDE ${dbus_metatype_path})

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${presencemanager_xml}
    presencemanager_dbus_interface)

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${configurationmanager_xml}
    configurationmanager_dbus_interface)

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${callmanager_xml}
    callmanager_dbus_interface)

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${video_xml}
    video_dbus_interface)

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${plugin_xml}
    plugin_dbus_interface)

  qt_add_dbus_interface(
    LIBCLIENT_SOURCES
    ${instance_xml}
    instance_dbus_interface)
endif()

# Manually wrap libjamiclient's private headers and interfaces.
set(LIBCLIENT_HEADERS_PRIVATE
  private/namedirectory_p.h
  private/smartInfoHub_p.h)

if(ENABLE_LIBWRAP AND (NOT ENABLE_TEST))
  list(APPEND LIBCLIENT_HEADERS_PRIVATE
    qtwrapper/callmanager_wrap.h
    qtwrapper/configurationmanager_wrap.h
    qtwrapper/instancemanager_wrap.h
    qtwrapper/presencemanager_wrap.h
    qtwrapper/videomanager_wrap.h
    qtwrapper/pluginmanager_wrap.h)
endif()

if(NOT ENABLE_TEST)
  qt_wrap_cpp(LIBCLIENT_HEADERS_MOC ${LIBCLIENT_HEADERS_PRIVATE})
endif()

foreach(MODULE ${QT_MODULES})
  list(APPEND QT_LIBS "Qt::${MODULE}")
endforeach()

set(LIBCLIENT_NAME "jamiclient")
set(LIBCLIENT_VERSION "1.0.0")
add_library(${LIBCLIENT_NAME} STATIC
  ${LIBCLIENT_SOURCES}
  ${LIBCLIENT_HEADERS_API}
  ${LIBCLIENT_HEADERS_MOC})

if(JAMICORE_AS_SUBDIR)
  # Define the project dependencies depending on the build type.
  if(ENABLE_LIBWRAP)
    add_dependencies(qtwrapper jami-core)
    add_dependencies(${LIBCLIENT_NAME} qtwrapper)
  else()
    add_dependencies(${LIBCLIENT_NAME} jami-core)
  endif()
endif()

foreach(QT_LIB ${QT_LIBS})
  target_link_libraries(${LIBCLIENT_NAME} ${QT_LIB})
endforeach()

if(NOT(APPLE OR MSVC))
  pkg_check_modules(XCB xcb IMPORTED_TARGET)
  target_link_libraries(${LIBCLIENT_NAME} PkgConfig::XCB)
endif()

if(ENABLE_LIBWRAP)
  target_link_libraries(${LIBCLIENT_NAME} qtwrapper ${LIBJAMI_LIB})
  if (NOT (CMAKE_CXX_COMPILER_ID MATCHES "MSVC"))
    target_link_libraries(${LIBCLIENT_NAME} ${AVUTIL_LIBRARY})
  endif()
endif()
if (NOT (CMAKE_CXX_COMPILER_ID MATCHES "MSVC"))
  target_link_libraries(${LIBCLIENT_NAME} -lpthread)
  if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    target_link_libraries(${LIBCLIENT_NAME} -lrt)
  endif()
endif()
set_target_properties(${LIBCLIENT_NAME}
  PROPERTIES VERSION ${LIBCLIENT_VERSION})
target_include_directories(${LIBCLIENT_NAME}
  PRIVATE ${AVUTIL_INCLUDE_DIR})

# Set these in the parent scope for use from the top-level
# CMakeLists.txt file.
set(LIBCLIENT_NAME ${LIBCLIENT_NAME} PARENT_SCOPE)
set(LIBCLIENT_VERSION ${LIBCLIENT_VERSION} PARENT_SCOPE)
