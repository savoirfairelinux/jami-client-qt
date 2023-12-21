# Copyright (C) 2020-2024 Savoir-faire Linux Inc.
#
# Author: Albert Babí <albert.babi@savoirfairelinux.com>
# Author: Amin Bandali <amin.bandali@savoirfairelinux.com>
# Author: Mingrui Zhang <mingrui.zhang@savoirfairelinux.com>
# Author: Andreas Traczyk <andreas.traczyk@savoirfairelinux.com>
# Author: Kateryna Kostiuk <kateryna.kostiuk@savoirfairelinux.com>
# Author: Sébastien Blin <sebastien.blin@savoirfairelinux.com>
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

if(APPLE)
  project(Jami)
else()
  project(jami)
endif()

option(WITH_DAEMON_SUBMODULE "Build with daemon submodule" ON)
option(JAMICORE_AS_SUBDIR "Build Jami-core as a subdir dependency" OFF)
option(ENABLE_TESTS "Build with tests" OFF)
option(WITH_WEBENGINE "Build with WebEngine" ON)
if(WITH_WEBENGINE)
  add_definitions(-DWITH_WEBENGINE)
endif()
option(ENABLE_LIBWRAP "Enable libwrap (single process mode)" ON)
if(NOT (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    OR ENABLE_LIBWRAP
    # because mocks use the same interface present in qtwrapper/
    OR ENABLE_TEST)
  set(ENABLE_LIBWRAP true)
endif()
option(ENABLE_ASAN "Enable address sanitization" OFF)
if(ENABLE_ASAN AND NOT MSVC)
  message(STATUS "Address sanitization enabled for client")
  # Add AddressSanitizer flags for both compiler and linker
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fno-omit-frame-pointer")
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()

# jami-core
if(NOT WITH_DAEMON_SUBMODULE)
  set(DAEMON_DIR ${PROJECT_SOURCE_DIR}/../daemon)
else()
  set(DAEMON_DIR ${PROJECT_SOURCE_DIR}/daemon)
endif()

# For now only MSVC is supported for building Jami-core within the
# client cmake.
if(JAMICORE_AS_SUBDIR)
  add_subdirectory(${DAEMON_DIR})
endif()

# init some variables for includes, libs, etc.
set(CLIENT_INCLUDE_DIRS, "")
set(CLIENT_LINK_DIRS, "")
set(CLIENT_LIBS, "")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT MSVC)
  set(CMAKE_CXX_FLAGS_DEBUG "-Og -ggdb")
endif()

# Helper function to add external content with patches and options.
# Note: options must be a list of key-value pairs, e.g. "QWINDOWKIT_BUILD_EXAMPLES ON"
function(add_fetch_content_with_patches target_name repo_url git_tag patch_files options)
  include(FetchContent)

  # Create a string for the patch command
  set(patch_cmd "")
  foreach(patch_file IN LISTS patch_files)
    list(APPEND patch_cmd git apply ${patch_file})
  endforeach()

  # Declare the external content
  FetchContent_Declare(
    ${target_name}
    GIT_REPOSITORY ${repo_url}
    GIT_TAG ${git_tag}
    PATCH_COMMAND ${patch_cmd}
    UPDATE_DISCONNECTED 1
  )

  # Apply options
  list(LENGTH options len)
  math(EXPR len "${len} - 1")
  foreach(idx RANGE 0 ${len} 2)
    list(GET options ${idx} key)
    math(EXPR next_idx "${idx} + 1")
    list(GET options ${next_idx} value)
    message("${key} = ${value}")
    # Forcing STRING here seems to work for both BOOL and STRING options.
    set(${key} ${value} CACHE STRING "${key}" FORCE)
  endforeach()

  # Make the content available
  FetchContent_MakeAvailable(${target_name})
endfunction()

set(QWINDOWKIT_OPTIONS
  QWINDOWKIT_BUILD_WIDGETS OFF
  QWINDOWKIT_INSTALL OFF
  QWINDOWKIT_BUILD_STATIC ON
  QWINDOWKIT_BUILD_EXAMPLES OFF
)

if(WIN32)
  list(APPEND QWINDOWKIT_OPTIONS QWINDOWKIT_ENABLE_WINDOWS_SYSTEM_BORDERS OFF)
  list(APPEND QWINDOWKIT_PATCHES
    ${PROJECT_SOURCE_DIR}/extras/patches/0002-workaround-right-margin.patch
  )
endif()

# qwindowkit (frameless window)
add_fetch_content_with_patches(
  qwindowkit
  "https://github.com/stdware/qwindowkit.git"
  main
  "${QWINDOWKIT_PATCHES}"
  "${QWINDOWKIT_OPTIONS}"
)

list(APPEND CLIENT_LIBS QWindowKit::Quick)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# src
set(LIBCLIENT_SRC_DIR ${PROJECT_SOURCE_DIR}/src/libclient)
set(APP_SRC_DIR ${PROJECT_SOURCE_DIR}/src/app)
# doc
set(DOC_DIR ${PROJECT_SOURCE_DIR}/doc)
# extras
set(EXTRAS_DIR ${PROJECT_SOURCE_DIR}/extras)
set(DATA_DIR ${EXTRAS_DIR}/data)
set(PACKAGING_DIR ${EXTRAS_DIR}/packaging)
set(SCRIPTS_DIR ${EXTRAS_DIR}/scripts)
# tests
set(TESTS_DIR ${PROJECT_SOURCE_DIR}/tests)

# Here we let find_package(<PackageName>...) try to find Qt 6,
# If it is found, find_package will succeed, and the CMake variable
# QT_VERSION_MAJOR will be defined 6.
set(QT6_MINVER_MINOR 5)
if(QT6_VER AND QT6_PATH)
  find_package(QT NAMES Qt6 REQUIRED
    PATHS ${QT6_PATH} NO_DEFAULT_PATH)
else()
  message(STATUS "Looking for Qt 6" ${CMAKE_PREFIX_PATH})
  find_package(QT NAMES Qt6 REQUIRED)
endif()
if (${QT_VERSION_MINOR} GREATER_EQUAL ${QT6_MINVER_MINOR})
  # Qt version is 6.5 or higher
  message(STATUS "Found a suitable Qt version ${QT_VERSION}")
else()
  message(FATAL_ERROR "Qt 6.5 or higher is required. Found ${QT_VERSION}")
endif()

# libjamiclient
add_subdirectory(${LIBCLIENT_SRC_DIR})

set(QT_MODULES
  Quick
  Network
  Svg
  Gui
  Qml
  QmlModels
  Sql
  Concurrent
  Core
  Core5Compat
  Multimedia
  Widgets
  Positioning)

if(WITH_WEBENGINE)
  list(APPEND QT_MODULES
    WebEngineCore
    WebEngineQuick
    WebChannel
    WebEngineWidgets)
endif()

set(CMAKE_CXX_FLAGS
  ${CMAKE_CXX_FLAGS} ${Qt6Widgets_EXECUTABLE_COMPILE_FLAGS})

# Add the auto-determined directories (those that are in the linker
# search path or contain linked libraries) outside the build tree to
# the RPATH.
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH true)

# # Augment the install RPATH for local (non-global) installs.
list(FIND CMAKE_PLATFORM_IMPLICIT_LINK_DIRECTORIES
  "${CMAKE_INSTALL_PREFIX}/lib"
  isSystemDir)
if("${isSystemDir}" STREQUAL "-1")
    set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_PREFIX}/lib")
endif()

if (WITH_DAEMON_SUBMODULE AND NOT EXISTS ${DAEMON_DIR}/src)
  message(FATAL_ERROR
    "Jami Daemon sources not found in ${DAEMON_DIR}/src.  If you \
cloned this repository via git, perhaps you did not initialize its \
submodules afterwards.  You can do so by running \"git submodule \
update --init\" in the repository.")
endif()
set(CMAKE_MODULE_PATH
  ${CMAKE_MODULE_PATH} "${EXTRAS_DIR}/build/cmake/modules")
find_package(LibJami REQUIRED)
if(LIBJAMI_FOUND)
  include_directories(${LIBJAMI_INCLUDE_DIRS})
endif()

include(FindPython3)
find_package(Python3 3.6 REQUIRED COMPONENTS Interpreter)
set(PYTHON_EXEC ${Python3_EXECUTABLE})

# Resource auto-gen
# QML and related code files
# Check files in the app's src directory and force a reconfigure if it
# changes.
# Only include webengine resources if specified.
if(WITH_WEBENGINE)
  set(GEN_QRC_ARGS "--with-webengine")
endif()
file(GLOB_RECURSE
  QML_FILES CONFIGURE_DEPENDS
  ${APP_SRC_DIR}/*)
execute_process(
  COMMAND
  ${PYTHON_EXEC} ${SCRIPTS_DIR}/gen_qml_qrc.py ${GEN_QRC_ARGS}
  WORKING_DIRECTORY ${APP_SRC_DIR})
set(QML_RESOURCES_QML ${APP_SRC_DIR}/qml.qrc)
# Image and misc. resources
# check files in the resources directory and force a reconfigure if it
# changes
file(GLOB_RECURSE
  RES_FILES CONFIGURE_DEPENDS
  ${PROJECT_SOURCE_DIR}/resources/*)
execute_process(
  COMMAND ${PYTHON_EXEC} ${SCRIPTS_DIR}/gen_resources_qrc.py ${GEN_QRC_ARGS}
  WORKING_DIRECTORY ${APP_SRC_DIR})
set(QML_RESOURCES ${APP_SRC_DIR}/resources.qrc)

# library compatibility (boost, libnotify, etc.)
add_definitions(-DQT_NO_KEYWORDS)

set(COMMON_SOURCES
  ${APP_SRC_DIR}/bannedlistmodel.cpp
  ${APP_SRC_DIR}/accountlistmodel.cpp
  ${APP_SRC_DIR}/networkmanager.cpp
  ${APP_SRC_DIR}/instancemanager.cpp
  ${APP_SRC_DIR}/main.cpp
  ${APP_SRC_DIR}/smartlistmodel.cpp
  ${APP_SRC_DIR}/utils.cpp
  ${APP_SRC_DIR}/mainapplication.cpp
  ${APP_SRC_DIR}/messagesadapter.cpp
  ${APP_SRC_DIR}/positionobject.cpp
  ${APP_SRC_DIR}/positionmanager.cpp
  ${APP_SRC_DIR}/accountadapter.cpp
  ${APP_SRC_DIR}/calladapter.cpp
  ${APP_SRC_DIR}/conversationsadapter.cpp
  ${APP_SRC_DIR}/avadapter.cpp
  ${APP_SRC_DIR}/contactadapter.cpp
  ${APP_SRC_DIR}/pluginadapter.cpp
  ${APP_SRC_DIR}/deviceitemlistmodel.cpp
  ${APP_SRC_DIR}/pluginlistmodel.cpp
  ${APP_SRC_DIR}/pluginstorelistmodel.cpp
  ${APP_SRC_DIR}/pluginhandlerlistmodel.cpp
  ${APP_SRC_DIR}/preferenceitemlistmodel.cpp
  ${APP_SRC_DIR}/mediacodeclistmodel.cpp
  ${APP_SRC_DIR}/currentaccounttomigrate.cpp
  ${APP_SRC_DIR}/audiodevicemodel.cpp
  ${APP_SRC_DIR}/pluginlistpreferencemodel.cpp
  ${APP_SRC_DIR}/audiomanagerlistmodel.cpp
  ${APP_SRC_DIR}/qmlregister.cpp
  ${APP_SRC_DIR}/utilsadapter.cpp
  ${APP_SRC_DIR}/moderatorlistmodel.cpp
  ${APP_SRC_DIR}/screensaver.cpp
  ${APP_SRC_DIR}/systemtray.cpp
  ${APP_SRC_DIR}/appsettingsmanager.cpp
  ${APP_SRC_DIR}/lrcinstance.cpp
  ${APP_SRC_DIR}/selectablelistproxymodel.cpp
  ${APP_SRC_DIR}/conversationlistmodelbase.cpp
  ${APP_SRC_DIR}/conversationlistmodel.cpp
  ${APP_SRC_DIR}/searchresultslistmodel.cpp
  ${APP_SRC_DIR}/calloverlaymodel.cpp
  ${APP_SRC_DIR}/filestosendlistmodel.cpp
  ${APP_SRC_DIR}/wizardviewstepmodel.cpp
  ${APP_SRC_DIR}/avatarregistry.cpp
  ${APP_SRC_DIR}/currentconversation.cpp
  ${APP_SRC_DIR}/currentconversationmembers.cpp
  ${APP_SRC_DIR}/currentaccount.cpp
  ${APP_SRC_DIR}/videodevices.cpp
  ${APP_SRC_DIR}/videoprovider.cpp
  ${APP_SRC_DIR}/callparticipantsmodel.cpp
  ${APP_SRC_DIR}/tipsmodel.cpp
  ${APP_SRC_DIR}/positioning.cpp
  ${APP_SRC_DIR}/currentcall.cpp
  ${APP_SRC_DIR}/messageparser.cpp
  ${APP_SRC_DIR}/previewengine.cpp
  ${APP_SRC_DIR}/imagedownloader.cpp
  ${APP_SRC_DIR}/pluginversionmanager.cpp
  ${APP_SRC_DIR}/connectioninfolistmodel.cpp
  ${APP_SRC_DIR}/pluginversionmanager.cpp)

set(COMMON_HEADERS
  ${APP_SRC_DIR}/avatarimageprovider.h
  ${APP_SRC_DIR}/networkmanager.h
  ${APP_SRC_DIR}/smartlistmodel.h
  ${APP_SRC_DIR}/appversionmanager.h
  ${APP_SRC_DIR}/utils.h
  ${APP_SRC_DIR}/bannedlistmodel.h
  ${APP_SRC_DIR}/version.h
  ${APP_SRC_DIR}/accountlistmodel.h
  ${APP_SRC_DIR}/instancemanager.h
  ${APP_SRC_DIR}/connectivitymonitor.h
  ${APP_SRC_DIR}/jamiavatartheme.h
  ${APP_SRC_DIR}/mainapplication.h
  ${APP_SRC_DIR}/qrimageprovider.h
  ${APP_SRC_DIR}/messagesadapter.h
  ${APP_SRC_DIR}/positionobject.h
  ${APP_SRC_DIR}/positionmanager.h
  ${APP_SRC_DIR}/accountadapter.h
  ${APP_SRC_DIR}/calladapter.h
  ${APP_SRC_DIR}/conversationsadapter.h
  ${APP_SRC_DIR}/qmladapterbase.h
  ${APP_SRC_DIR}/avadapter.h
  ${APP_SRC_DIR}/contactadapter.h
  ${APP_SRC_DIR}/pluginadapter.h
  ${APP_SRC_DIR}/deviceitemlistmodel.h
  ${APP_SRC_DIR}/pluginlistmodel.h
  ${APP_SRC_DIR}/pluginstorelistmodel.h
  ${APP_SRC_DIR}/pluginhandlerlistmodel.h
  ${APP_SRC_DIR}/preferenceitemlistmodel.h
  ${APP_SRC_DIR}/mediacodeclistmodel.h
  ${APP_SRC_DIR}/currentaccounttomigrate.h
  ${APP_SRC_DIR}/audiodevicemodel.h
  ${APP_SRC_DIR}/pluginlistpreferencemodel.h
  ${APP_SRC_DIR}/audiomanagerlistmodel.h
  ${APP_SRC_DIR}/qmlregister.h
  ${APP_SRC_DIR}/abstractlistmodelbase.h
  ${APP_SRC_DIR}/quickimageproviderbase.h
  ${APP_SRC_DIR}/qtutils.h
  ${APP_SRC_DIR}/utilsadapter.h
  ${APP_SRC_DIR}/moderatorlistmodel.h
  ${APP_SRC_DIR}/screensaver.h
  ${APP_SRC_DIR}/systemtray.h
  ${APP_SRC_DIR}/appsettingsmanager.h
  ${APP_SRC_DIR}/lrcinstance.h
  ${APP_SRC_DIR}/selectablelistproxymodel.h
  ${APP_SRC_DIR}/conversationlistmodelbase.h
  ${APP_SRC_DIR}/conversationlistmodel.h
  ${APP_SRC_DIR}/searchresultslistmodel.h
  ${APP_SRC_DIR}/calloverlaymodel.h
  ${APP_SRC_DIR}/filestosendlistmodel.h
  ${APP_SRC_DIR}/wizardviewstepmodel.h
  ${APP_SRC_DIR}/avatarregistry.h
  ${APP_SRC_DIR}/currentconversation.h
  ${APP_SRC_DIR}/currentconversationmembers.h
  ${APP_SRC_DIR}/currentaccount.h
  ${APP_SRC_DIR}/videodevices.h
  ${APP_SRC_DIR}/videoprovider.h
  ${APP_SRC_DIR}/callparticipantsmodel.h
  ${APP_SRC_DIR}/tipsmodel.h
  ${APP_SRC_DIR}/positioning.h
  ${APP_SRC_DIR}/currentcall.h
  ${APP_SRC_DIR}/messageparser.h
  ${APP_SRC_DIR}/htmlparser.h
  ${APP_SRC_DIR}/imagedownloader.h
  ${APP_SRC_DIR}/pluginversionmanager.h
  ${APP_SRC_DIR}/connectioninfolistmodel.h
  ${APP_SRC_DIR}/pttlistener.h)

# For libavutil/avframe.
set(LIBJAMI_CONTRIB_DIR "${DAEMON_DIR}/contrib")
find_path(AVUTIL_INCLUDE_DIR libavutil/avutil.h
  PATHS
  ${LIBJAMI_CONTRIB_DIR}/native/ffmpeg
  ${LIBJAMI_CONTRIB_DIR}/apple-darwin/include/
  ${LIBJAMI_CONTRIB_DIR}/build/ffmpeg/Build/win32/x64/include)
include_directories(${AVUTIL_INCLUDE_DIR})

find_package(Vulkan)
if(Vulkan_FOUND)
  add_definitions(-DHAS_VULKAN)
  include_directories(${Vulkan_INCLUDE_DIR})
endif()
# Define PREFER_VULKAN to prefer Vulkan over the default API
# on GNU/Linux and Windows. Metal is always preferred on macOS.

if(MSVC)
  set(WINDOWS_SYS_LIBS
    windowsapp.lib
    dwmapi.lib
    Shell32.lib
    Ole32.lib
    Advapi32.lib
    Shlwapi.lib
    User32.lib
    Gdi32.lib
    Crypt32.lib
    Strmiids.lib)

  list(APPEND COMMON_SOURCES
    ${APP_SRC_DIR}/connectivitymonitor.cpp
    ${APP_SRC_DIR}/appversionmanager.cpp)
  # preprocessor defines
  add_definitions(-DUNICODE -DQT_NO_DEBUG -DNDEBUG)

  # compiler options
  add_compile_options(
    /wd4068 /wd4099 /wd4189 /wd4267 /wd4577 /wd4467 /wd4715 /wd4828)
  add_compile_options(
    /MP /GS /W3 /Gy /Zc:wchar_t /Zi /Gm- /O2 /Zc:inline /fp:precise)
  add_compile_options(/Gd /Oi /MD /FC /EHsc /nologo /sdl)

  # linker options
  add_link_options(
    "/IGNORE:4006,4049,4078,4098"
    "/FORCE:MULTIPLE"
    "/INCREMENTAL:NO"
    "/DEBUG"
    "/LTCG"
    "/NODEFAULTLIB:LIBCMT")

  # client deps
  set(QRENCODE_DIR ${PROJECT_SOURCE_DIR}/3rdparty/qrencode-win32/qrencode-win32)
  file(GLOB_RECURSE QRENCODE_LIB ${QRENCODE_DIR}/qrcodelib.lib)
  file(GLOB_RECURSE QRENCODE_INCLUDE ${QRENCODE_DIR}/qrencode.h)
  get_filename_component(QRENCODE_INCLUDE_DIR ${QRENCODE_INCLUDE} DIRECTORY)

  # daemon
  set(JAMID_SRC_PATH ${DAEMON_DIR}/contrib/msvc/include)
  set(GNUTLS_LIB ${DAEMON_DIR}/contrib/msvc/lib/x64/libgnutls.lib)

  # Beta config
  if(BETA)
    message(STATUS "Beta config enabled")
    add_definitions(-DBETA)
    set(JAMI_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/x64/Beta)
  else()
    set(JAMI_OUTPUT_DIRECTORY_RELEASE
      ${PROJECT_SOURCE_DIR}/x64/Release)
  endif()

  include_directories(
    ${JAMID_SRC_PATH}
    ${LIBCLIENT_SRC_DIR}
    ${QRENCODE_INCLUDE_DIR})
elseif (NOT APPLE)
  list(APPEND COMMON_SOURCES
    ${APP_SRC_DIR}/xrectsel.c
    ${APP_SRC_DIR}/connectivitymonitor.cpp
    ${APP_SRC_DIR}/dbuserrorhandler.cpp
    ${APP_SRC_DIR}/appversionmanager.cpp)
  list(APPEND COMMON_HEADERS
    ${APP_SRC_DIR}/xrectsel.h
    ${APP_SRC_DIR}/dbuserrorhandler.h)
  list(APPEND QT_MODULES DBus)

  find_package(PkgConfig REQUIRED)

  pkg_check_modules(GLIB REQUIRED glib-2.0)
  if(GLIB_FOUND)
    add_definitions(${GLIB_CFLAGS_OTHER})
  endif()

  pkg_check_modules(GIO REQUIRED gio-2.0)
  if(GIO_FOUND)
    add_definitions(${GIO_CFLAGS})
  endif()

  pkg_check_modules(LIBNM libnm)
  if(LIBNM_FOUND)
    add_definitions(-DUSE_LIBNM)
  endif()

  pkg_check_modules(LIBNOTIFY libnotify>=0.7.6)
  if(LIBNOTIFY_FOUND)
    add_definitions(-DUSE_LIBNOTIFY)
    add_definitions(${LIBNOTIFY_CFLAGS})
    pkg_check_modules(LIBGDKPIXBUF gdk-pixbuf-2.0>=2.40.0)
    add_definitions(${LIBGDKPIXBUF_CFLAGS})
  endif()

  list(PREPEND CMAKE_PREFIX_PATH
    ${LIBJAMI_CONTRIB_DIR}/native/ffmpeg/libavutil)
  pkg_check_modules(LIBAVUTIL libavutil>=55.75.100)
  list(REMOVE_ITEM CMAKE_PREFIX_PATH
    ${LIBJAMI_CONTRIB_DIR}/native/ffmpeg/libavutil)

  include_directories(
    ${LIBCLIENT_SRC_DIR}
    ${LIBNM_INCLUDE_DIRS}
    ${LIBNOTIFY_INCLUDE_DIRS}
    ${LIBGDKPIXBUF_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
    ${LIBAVUTIL_INCLUDE_DIRS})

  set(JAMI_DATA_PREFIX "${CMAKE_INSTALL_PREFIX}/share")

  find_library(${LIBCLIENT_NAME} ${LIBCLIENT_NAME} NO_DEFAULT_PATH)
  find_library(qrencode qrencode)
  find_library(X11 X11)
else() # APPLE
  list(APPEND COMMON_SOURCES
    ${APP_SRC_DIR}/os/macos/appversionmanager.mm
    ${APP_SRC_DIR}/os/macos/connectivitymonitor.mm
    ${APP_SRC_DIR}/os/macos/macutils.mm)
  list(APPEND COMMON_HEADERS
    ${APP_SRC_DIR}/os/macos/macutils.h)
  include_directories(${LIBCLIENT_SRC_DIR})

  set(JAMI_DATA_PREFIX "${CMAKE_INSTALL_PREFIX}/share")

  find_library(SYSTEM_CONFIGURATUION SystemConfiguration)
  set(myApp_ICON
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/images/jami.icns)
  set_source_files_properties(
    ${myApp_ICON}
    PROPERTIES
    MACOSX_PACKAGE_LOCATION Resources)
  INCLUDE_DIRECTORIES(${PROJECT_SOURCE_DIR}/3rdparty/libqrencode/include)
  LINK_DIRECTORIES(${PROJECT_SOURCE_DIR}/3rdparty/libqrencode/lib)
  if(ENABLE_SPARKLE)
    message("Sparkle auto-update enabled")
    set(sparkle_dir "${PACKAGING_DIR}/update/sparkle")
    find_library(SPARKLE_FRAMEWORK
      NAMES Sparkle
      HINTS ${sparkle_dir})
    add_definitions(-DENABLE_SPARKLE)
    message("Sparkle is here:" ${SPARKLE_FRAMEWORK})
  endif()
  if(BETA)
    message(STATUS "Beta config enabled")
    add_definitions(-DBETA)
  endif()
endif()

# Qt find package
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

if (CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if (DEFINED ENV{XDG_SESSION_TYPE})
        if ($ENV{XDG_SESSION_TYPE} STREQUAL "x11")
            set(PTT_PLATFORM "x11")
            list(APPEND COMMON_HEADER ${APP_SRC_DIR}/platform/X11/xcbkeyboard.H)
        # TODO: add Wayland support
        endif ()
    endif ()
elseif (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(PTT_PLATFORM "windows")
elseif (CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set(PTT_PLATFORM "macos")
endif ()

if (NOT ${PTT_PLATFORM} STREQUAL "")
    message(STATUS "Platform: ${PTT_PLATFORM}")
    add_definitions(-DHAVE_GLOBAL_PTT)
    list(APPEND COMMON_SOURCES ${APP_SRC_DIR}/platform/${PTT_PLATFORM}/pttlistener.cpp)
else ()
    message(WARNING "Global push-to-talk not supported.")
    list(APPEND COMMON_SOURCES ${APP_SRC_DIR}/platform/local/pttlistener.cpp)
endif ()

# common includes
include_directories(
  ${PROJECT_SOURCE_DIR}
  ${APP_SRC_DIR})

if(ENABLE_LIBWRAP)
  list(APPEND COMMON_HEADERS
    ${LIBCLIENT_SRC_DIR}/qtwrapper/instancemanager_wrap.h)
endif()

# SFPM
set(BUILD_SFPM_PIC ON CACHE BOOL "enable -fPIC for SFPM" FORCE)
add_subdirectory(3rdparty/SortFilterProxyModel)
set(SFPM_OBJECTS $<TARGET_OBJECTS:SortFilterProxyModel>)

# md4c
set(BUILD_SHARED_LIBS OFF CACHE BOOL "Don't build shared md4c library" FORCE)
add_subdirectory(3rdparty/md4c EXCLUDE_FROM_ALL)
list(APPEND CLIENT_LINK_DIRS ${MD4C_BINARY_DIR}/src)
list(APPEND CLIENT_INCLUDE_DIRS ${MD4C_SOURCE_DIR}/src)
list(APPEND CLIENT_LIBS md4c-html)

# tidy-html5
set(BUILD_SHARED_LIB OFF CACHE BOOL "Don't build shared tidy library" FORCE)
set(SUPPORT_CONSOLE_APP OFF CACHE BOOL "Don't build tidy console app" FORCE)
add_subdirectory(3rdparty/tidy-html5 EXCLUDE_FROM_ALL)
list(APPEND CLIENT_LINK_DIRS ${tidy_BINARY_DIR}/Release)
list(APPEND CLIENT_INCLUDE_DIRS ${tidy_SOURCE_DIR}/include)
list(APPEND CLIENT_LIBS tidy-static)

# common executable sources
qt_add_executable(
  ${PROJECT_NAME}
  MANUAL_FINALIZATION
  ${APP_SRC_DIR}/main.cpp
  ${COMMON_HEADERS}
  ${COMMON_SOURCES}
  ${QML_RESOURCES}
  ${QML_RESOURCES_QML}
  ${SFPM_OBJECTS})

foreach(MODULE ${QT_MODULES})
  list(APPEND QT_LIBS "Qt::${MODULE}")
endforeach()

if(MSVC)
  # Makes it a GUI executable instead of a console application
  set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES
    WIN32_EXECUTABLE TRUE)

  list(APPEND CLIENT_LIBS
    ${LIBJAMI_LIB}
    ${GNUTLS_LIB}
    ${LIBCLIENT_NAME}
    ${QT_LIBS}
    ${QRENCODE_LIB}
    ${WINDOWS_SYS_LIBS})

  # specify output executable files
  set_target_properties(
    ${PROJECT_NAME}
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_RELEASE
    "${JAMI_OUTPUT_DIRECTORY_RELEASE}")

  # executable icon
  target_sources(${PROJECT_NAME} PRIVATE ${PACKAGING_DIR}/wix/ico.rc)

  # translations
  if(Qt${QT_VERSION_MAJOR}LinguistTools_FOUND)
    message("Releasing and copying translation files")
    file(MAKE_DIRECTORY
      "${JAMI_OUTPUT_DIRECTORY_RELEASE}/share/jami/translations/")
    file(GLOB TS_FILES ${PROJECT_SOURCE_DIR}/translations/*.ts)
    set_source_files_properties(
      ${TS_FILES}
      PROPERTIES
      OUTPUT_LOCATION
      "${JAMI_OUTPUT_DIRECTORY_RELEASE}/share/jami/translations")

    qt_add_translation(QM_FILES ${TS_FILES})
    target_sources(${PROJECT_NAME} PRIVATE ${QM_FILES})
  endif()

  # executable name
  set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "Jami")
elseif (NOT APPLE)
  list(APPEND CLIENT_LIBS
    ${QT_LIBS}
    ${LIBCLIENT_NAME}
    ${qrencode}
    ${X11}
    ${LIBNM_LIBRARIES}
    ${LIBNOTIFY_LIBRARIES}
    ${LIBGDKPIXBUF_LIBRARIES}
    ${GLIB_LIBRARIES}
    ${GIO_LIBRARIES})

  install(
    TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin)

  # Install .desktop in XDG desktop direcory so that it is recognized
  # by the system.
  install(
    FILES ${DATA_DIR}/jami.desktop
    DESTINATION ${JAMI_DATA_PREFIX}/applications)

  # Install .desktop in the jami data directory, so that it can be
  # copied to the autostart directory by the client.
  install(
    FILES ${DATA_DIR}/jami.desktop
    DESTINATION "${JAMI_DATA_PREFIX}/${PROJECT_NAME}"
    PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ) # 644

  # Adjust JAMI_DATA_PREFIX for snap package.
  #   (This must come after all 'install' commands that refer to
  #    JAMI_DATA_PREFIX; the following value is not meant to be used
  #    for any install destinations.)
  if(DEFINED ENV{SNAPCRAFT_PROJECT_NAME})
    set(JAMI_DATA_PREFIX
      "/snap/$ENV{SNAPCRAFT_PROJECT_NAME}/current/usr/share")
  endif()

  # (This must come after the above adjustment to JAMI_DATA_PREFIX.)
  target_compile_definitions(
    ${PROJECT_NAME}
    PRIVATE
    JAMI_INSTALL_PREFIX="${JAMI_DATA_PREFIX}")

  # Logos
  install(
    FILES resources/images/jami.svg
    DESTINATION
    ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)

  install(
    FILES resources/images/jami-48px.png
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/48x48/apps
    RENAME jami.png)

  install(
    FILES resources/images/jami-32px.xpm
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/pixmaps
    RENAME jami.xpm)

  install(
    FILES ${DATA_DIR}/jami.appdata.xml
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/metainfo)

  # man page
  install(
    FILES ${DOC_DIR}/jami.1
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/man/man1)

  # Add a target to generate API documentation using Doxygen and
  # graphviz-dot.
  find_package(Doxygen)
  find_program(dot "dot")
  if(Doxygen_FOUND AND dot)
    configure_file(
      ${DOC_DIR}/Doxyfile.in
      ${DOC_DIR}/Doxyfile
      @ONLY)
    add_custom_target(
      doc
      COMMAND
      ${DOXYGEN_EXECUTABLE} ${DOC_DIR}/Doxyfile
      WORKING_DIRECTORY ${DOC_DIR}
      COMMENT "Generating API documentation with Doxygen"
      VERBATIM)

    # Create doc/README.md symlink to README since Doxygen doesn't
    # understand file with no extension.
    add_custom_command(
      TARGET doc
      PRE_BUILD
      COMMAND
      ln -sf ${CMAKE_CURRENT_SOURCE_DIR}/README ${DOC_DIR}/README.md)
  endif()

  # translations
  if(Qt${QT_VERSION_MAJOR}LinguistTools_FOUND)
    message("Releasing and copying translation files")
    file(MAKE_DIRECTORY
      "${CMAKE_BINARY_DIR}/share/jami/translations/")
    file(GLOB TS_FILES ${PROJECT_SOURCE_DIR}/translations/*.ts)
    set_source_files_properties(
      ${TS_FILES}
      PROPERTIES
      OUTPUT_LOCATION "share/jami/translations")

    qt_add_translation(QM_FILES ${TS_FILES})
    add_custom_target(translations ALL DEPENDS ${QM_FILES})
    install(DIRECTORY "${CMAKE_BINARY_DIR}/share/jami/translations/"
      DESTINATION ${CMAKE_INSTALL_PREFIX}/share/jami/translations)
  endif()

  # uninstall rule
  configure_file(
    "${EXTRAS_DIR}/build/cmake/cmake_uninstall.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake"
    IMMEDIATE
    @ONLY)

  add_custom_target(
    uninstall
    COMMAND
    ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
else()
  set(resources
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/images/jami.icns)
  set(libs ${QT_LIBS} ${SYSTEM_CONFIGURATUION} qrencode ${LIBCLIENT_NAME})
  if(ENABLE_SPARKLE)
    set(resources ${resources} ${SPARKLE_FRAMEWORK})
    set(libs ${libs} ${SPARKLE_FRAMEWORK})
  endif(ENABLE_SPARKLE)
  target_sources(${PROJECT_NAME} PRIVATE ${resources})
  list(APPEND CLIENT_LIBS ${libs})

  file(GLOB CONTRIB ${LIBJAMI_CONTRIB_DIR}/apple-darwin/lib/*.a)
  list(APPEND CLIENT_LIBS ${CONTRIB})

  find_package(Iconv REQUIRED)
  list(APPEND CLIENT_LIBS Iconv::Iconv)
  list(APPEND CLIENT_LIBS
    "-framework AVFoundation"
    "-framework CoreAudio -framework CoreMedia -framework CoreVideo"
    "-framework VideoToolbox -framework AudioUnit -framework Carbon"
    "-framework Security"
      compression
      resolv
    )

  # translations
  if(Qt${QT_VERSION_MAJOR}LinguistTools_FOUND)
    set(APP_CONTAINER
      "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.app/Contents")
    file(GLOB TS_FILES ${PROJECT_SOURCE_DIR}/translations/*.ts)

    # Generate lproj folders.
    foreach(QM_FILE ${TS_FILES})
      # Extract language code from filename.
      get_filename_component(FILENAME ${QM_FILE} NAME_WE)
      string(REGEX REPLACE "^lrc_" "" LANG ${FILENAME})
      file(MAKE_DIRECTORY ${APP_CONTAINER}/Resources/${LANG}.lproj)
    endforeach()
    set_source_files_properties(
      ${TS_FILES}
      PROPERTIES OUTPUT_LOCATION
      "${APP_CONTAINER}/Resources/share/jami/translations")

    qt_add_translation(QM_FILES ${TS_FILES})
    target_sources(${PROJECT_NAME} PRIVATE ${QM_FILES})
  endif()

  set_target_properties(${PROJECT_NAME} PROPERTIES
          MACOSX_BUNDLE TRUE
          MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/resources/Info.plist"
          MACOSX_BUNDLE_EXECUTABLE_NAME "${PROJ_NAME}"
          MACOSX_BUNDLE_ICON_FILE "jami.icns"
          MACOSX_BUNDLE_GUI_IDENTIFIER "${BUNDLE_ID}"
          MACOSX_BUNDLE_SHORT_VERSION_STRING "${JAMI_VERSION}"
          MACOSX_BUNDLE_BUNDLE_VERSION "${JAMI_BUILD}"
          MACOSX_BUNDLE_COPYRIGHT "${PROJ_COPYRIGHT}")
      if(APPSTORE)
          message(STATUS "app store version")
          add_definitions(-DAPPSTORE)
          set_target_properties(${PROJECT_NAME} PROPERTIES
               XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/entitlements/appstore/Jami.entitlements")
      else()
          set_target_properties(${PROJECT_NAME} PROPERTIES
                SPARKLE_URL "${SPARKLE_URL}"
                SPARKLE_PUBLIC_KEY "${SPARKLE_PUBLIC_KEY}"
                XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/entitlements/Jami.entitlements"
                XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME TRUE)
      endif()
      if(DEPLOY)
          add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                             COMMAND ${CMAKE_COMMAND} -DQML_SRC_DIR=${SRC_DIR}
                             -DMAC_DEPLOY_QT_PATH=${CMAKE_PREFIX_PATH}/bin
                             -DEXE_NAME="${CMAKE_BINARY_DIR}/${PROJECT_NAME}.app"
                             -DSPARKLE_PATH=${SPARKLE_FRAMEWORK}
                             -DENABLE_SPARKLE=${ENABLE_SPARKLE}
                             -P ${EXTRAS_DIR}/build/cmake/macos_qt_deploy.cmake)
      endif()
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CLIENT_INCLUDE_DIRS})
target_link_directories(${PROJECT_NAME} PRIVATE ${CLIENT_LINK_DIRS})
target_link_libraries(${PROJECT_NAME} PRIVATE ${CLIENT_LIBS})

qt_import_qml_plugins(${PROJECT_NAME})
qt_finalize_executable(${PROJECT_NAME})

# tests
if(ENABLE_TESTS)
  message("Add Jami tests")
  add_subdirectory(${TESTS_DIR})
endif()
