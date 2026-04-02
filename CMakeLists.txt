# Copyright (C) 2020-2026 Savoir-faire Linux Inc.
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

cmake_minimum_required(VERSION 3.19)

if(APPLE)
  project(Jami)
else()
  project(jami)
endif()

set(CMAKE_SCRIPTS_DIR ${PROJECT_SOURCE_DIR}/extras/build/cmake)
include(${CMAKE_SCRIPTS_DIR}/extra_tools.cmake)

option(WITH_DAEMON_SUBMODULE "Build with daemon submodule" ON)
option(JAMICORE_AS_SUBDIR "Build Jami-core as a subdir dependency" ON)
option(WITH_WEBENGINE "Build with WebEngine" ON)
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

# Enable this option when building for production.
option(ENABLE_CRASHREPORTS "Enable crash reports" OFF)

# These values are exposed to QML and are better off being defined as values.
define_macro_with_value(WITH_WEBENGINE)
define_macro_with_value(APPSTORE)
define_macro_with_value(ENABLE_CRASHREPORTS)

# jami-core
if(NOT WITH_DAEMON_SUBMODULE)
  set(DAEMON_DIR ${PROJECT_SOURCE_DIR}/../daemon)
else()
  set(DAEMON_DIR ${PROJECT_SOURCE_DIR}/daemon)
endif()

if(JAMICORE_AS_SUBDIR)
  add_subdirectory(${DAEMON_DIR} EXCLUDE_FROM_ALL)
  set(LIBJAMI_LIB jami-core)
endif()

# init some variables for includes, libs, etc.
set(CLIENT_INCLUDE_DIRS, "")
set(CLIENT_LINK_DIRS, "")
set(CLIENT_LIBS, "")

include(${PROJECT_SOURCE_DIR}/extras/build/cmake/contrib_tools.cmake)
set(EXTRA_PATCHES_DIR ${PROJECT_SOURCE_DIR}/extras/patches)

list(APPEND QWINDOWKIT_OPTIONS
  QWINDOWKIT_BUILD_WIDGETS OFF
  QWINDOWKIT_INSTALL OFF
  QWINDOWKIT_BUILD_STATIC ON
  QWINDOWKIT_BUILD_QUICK ON
)

if(WIN32)
  # Beta config
  if(BETA)
    message(STATUS "Beta config enabled")
    add_definitions(-DBETA)
  endif()
  set(JAMI_OUTPUT_DIRECTORY_RELEASE ${PROJECT_SOURCE_DIR}/x64/${CMAKE_BUILD_TYPE})
endif()

if(WIN32)
  list(APPEND QWINDOWKIT_OPTIONS QWINDOWKIT_ENABLE_WINDOWS_SYSTEM_BORDERS OFF)
endif()

# qwindowkit (frameless window)
add_fetch_content(
  TARGET QWindowKit
  URL https://github.com/atraczyk/qwindowkit.git
  BRANCH fix-multiarch-libdir
  PATCHES ${QWINDOWKIT_PATCHES}
  OPTIONS ${QWINDOWKIT_OPTIONS}
)

list(APPEND CLIENT_LIBS QWindowKit::Quick)

# If ENABLE_CRASHREPORTS is enabled, we will use crashpad_cmake for now.
if(ENABLE_CRASHREPORTS)
  set(ENABLE_CRASHPAD ON)
  set(CRASH_REPORT_URL "http://localhost:8080/submit" CACHE STRING "URL for crash handler uploads")
endif()
add_definitions(-DCRASH_REPORT_URL="${CRASH_REPORT_URL}")

# Crash-report client: crashpad
if(ENABLE_CRASHPAD)
  message(STATUS "Crashpad enabled for client")
  if(WIN32)
    set(CMAKE_OBJECT_PATH_MAX 256)
    add_definitions(-DNOMINMAX)
  endif()
  add_fetch_content(
    TARGET crashpad_cmake
    URL https://github.com/TheAssemblyArmada/crashpad-cmake.git
    BRANCH 80573adcc845071401c73c99eaec7fd9847d45fb
  )
  add_definitions(-DENABLE_CRASHPAD)
  if (WIN32)
    # This makes sure the console window doesn't show up when running the
    # crashpad_handler executable.
    set_target_properties(crashpad_handler PROPERTIES LINK_FLAGS "/SUBSYSTEM:WINDOWS")
    # Set the output directory for the crashpad_handler executable. On Windows,
    # we use either the Release or Beta directory depending on the BETA option
    # which is set above.
    set_target_properties(crashpad_handler PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${JAMI_OUTPUT_DIRECTORY_RELEASE}")
  endif()
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
if(NOT MSVC)
  string(APPEND CMAKE_CXX_FLAGS_DEBUG " -Og")
endif()

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# src
set(LIBCLIENT_SRC_DIR ${PROJECT_SOURCE_DIR}/src/libclient)
set(APP_SRC_DIR ${PROJECT_SOURCE_DIR}/src/app)
set(VERSION_INFO_DIR ${PROJECT_SOURCE_DIR}/src/version_info)
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
set(QT6_MINVER_MINOR 8)
if(QT6_VER AND QT6_PATH)
  find_package(QT NAMES Qt6 REQUIRED
    PATHS ${QT6_PATH} NO_DEFAULT_PATH)
else()
  message(STATUS "Looking for Qt 6 in ${CMAKE_PREFIX_PATH}")
  find_package(QT NAMES Qt6 REQUIRED)
endif()
if (${QT_VERSION_MINOR} GREATER_EQUAL ${QT6_MINVER_MINOR})
  message(STATUS "Found a suitable Qt version ${QT_VERSION}")
else()
  message(FATAL_ERROR "Qt 6.8 or higher is required. Found ${QT_VERSION}")
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
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/extras/build/cmake/modules)
if (NOT JAMICORE_AS_SUBDIR)
  find_package(LibJami REQUIRED)
  if(LIBJAMI_FOUND)
    include_directories(${LIBJAMI_INCLUDE_DIR})
  endif()
endif()

include(FindPython3)
find_package(Python3 3.6 REQUIRED COMPONENTS Interpreter)
set(PYTHON_EXEC ${Python3_EXECUTABLE})

# Versioning and build ID generation
set(VERSION_FILE ${CMAKE_CURRENT_BINARY_DIR}/version_info.cpp)
# Touch the file to ensure it exists at configure time as
# we add it to the target_sources below.
file(TOUCH ${VERSION_FILE})
add_custom_target(
  generate_version_info ALL
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMAND ${CMAKE_COMMAND}
  -DAPP_SOURCE_DIR=${CMAKE_SOURCE_DIR}
  -DAPP_BINARY_DIR=${CMAKE_CURRENT_BINARY_DIR}
  -DCORE_SOURCE_DIR=${DAEMON_DIR}
  -DCPP_INT_FILE=${VERSION_INFO_DIR}/version_info.cpp.in
  -DBUILD_VERSION=${BUILD_VERSION}
  -P ${CMAKE_SCRIPTS_DIR}/generate_version_info.cmake
)
list(APPEND CLIENT_INCLUDE_DIRS ${VERSION_INFO_DIR})

# Resource auto-gen
# QML and related code files
# Check files in the app's src directory and force a reconfigure if it
# changes.
# Only include WebEngine resources if specified.
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

# Find modules (QtCreator) under the root source dir.
list(APPEND QML_DIRS ${APP_SRC_DIR})
set(QML_IMPORT_PATH ${QML_DIRS}
  CACHE STRING "Qt Creator extra qml import paths" FORCE)

# library compatibility (boost, libnotify, etc.)
add_definitions(-DQT_NO_KEYWORDS)

set(COMMON_SOURCES
  ${VERSION_FILE}
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
  ${APP_SRC_DIR}/audioconfiglistmodel.cpp
  ${APP_SRC_DIR}/qmlregister.cpp
  ${APP_SRC_DIR}/utilsadapter.cpp
  ${APP_SRC_DIR}/moderatorlistmodel.cpp
  ${APP_SRC_DIR}/screensaver.cpp
  ${APP_SRC_DIR}/systemtray.cpp
  ${APP_SRC_DIR}/appsettingsmanager.cpp
  ${APP_SRC_DIR}/accountsettingsmanager.cpp
  ${APP_SRC_DIR}/lrcinstance.cpp
  ${APP_SRC_DIR}/selectablelistproxymodel.cpp
  ${APP_SRC_DIR}/conversationlistmodelbase.cpp
  ${APP_SRC_DIR}/conversationlistmodel.cpp
  ${APP_SRC_DIR}/searchresultslistmodel.cpp
  ${APP_SRC_DIR}/calloverlaymodel.cpp
  ${APP_SRC_DIR}/spellcheckdictionarylistmodel.cpp
  ${APP_SRC_DIR}/spellcheckadapter.cpp
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
  ${APP_SRC_DIR}/filedownloader.cpp
  ${APP_SRC_DIR}/pluginversionmanager.cpp
  ${APP_SRC_DIR}/connectioninfolistmodel.cpp
  ${APP_SRC_DIR}/conversationstatusmodel.cpp
  ${APP_SRC_DIR}/trackedmembersmodel.cpp
  ${APP_SRC_DIR}/pluginversionmanager.cpp
  ${APP_SRC_DIR}/linkdevicemodel.cpp
  ${APP_SRC_DIR}/qrcodescannermodel.cpp
  ${APP_SRC_DIR}/spellchecker.cpp)

set(COMMON_HEADERS
  ${APP_SRC_DIR}/global.h
  ${APP_SRC_DIR}/avatarimageprovider.h
  ${APP_SRC_DIR}/networkmanager.h
  ${APP_SRC_DIR}/smartlistmodel.h
  ${APP_SRC_DIR}/appversionmanager.h
  ${APP_SRC_DIR}/utils.h
  ${APP_SRC_DIR}/bannedlistmodel.h
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
  ${APP_SRC_DIR}/audioconfiglistmodel.h
  ${APP_SRC_DIR}/qmlregister.h
  ${APP_SRC_DIR}/abstractlistmodelbase.h
  ${APP_SRC_DIR}/quickimageproviderbase.h
  ${APP_SRC_DIR}/qtutils.h
  ${APP_SRC_DIR}/utilsadapter.h
  ${APP_SRC_DIR}/moderatorlistmodel.h
  ${APP_SRC_DIR}/screensaver.h
  ${APP_SRC_DIR}/systemtray.h
  ${APP_SRC_DIR}/appsettingsmanager.h
  ${APP_SRC_DIR}/accountsettingsmanager.h
  ${APP_SRC_DIR}/lrcinstance.h
  ${APP_SRC_DIR}/selectablelistproxymodel.h
  ${APP_SRC_DIR}/conversationlistmodelbase.h
  ${APP_SRC_DIR}/conversationlistmodel.h
  ${APP_SRC_DIR}/searchresultslistmodel.h
  ${APP_SRC_DIR}/calloverlaymodel.h
  ${APP_SRC_DIR}/spellcheckdictionarylistmodel.h
  ${APP_SRC_DIR}/spellcheckadapter.h
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
  ${APP_SRC_DIR}/filedownloader.h
  ${APP_SRC_DIR}/pluginversionmanager.h
  ${APP_SRC_DIR}/connectioninfolistmodel.h
  ${APP_SRC_DIR}/conversationstatusmodel.h
  ${APP_SRC_DIR}/trackedmembersmodel.h
  ${APP_SRC_DIR}/pttlistener.h
  ${APP_SRC_DIR}/crashreportclient.h
  ${APP_SRC_DIR}/crashreporter.h
  ${APP_SRC_DIR}/linkdevicemodel.h
  ${APP_SRC_DIR}/qrcodescannermodel.h
  ${APP_SRC_DIR}/spellchecker.h
  ${APP_SRC_DIR}/accountsettingspropertymap.h
)

set(CONTRIB_DARWIN_FOLDER "")
if(APPLE)
  list(LENGTH CMAKE_OSX_ARCHITECTURES ARCH_LEN)
  if(ARCH_LEN EQUAL 1)
    # single-arch -> use <arch>-apple-darwin<ver>
    set(DARWIN_ARCH "${CMAKE_OSX_ARCHITECTURES}")
    set(CONTRIB_DARWIN_FOLDER "${DARWIN_ARCH}-apple-darwin${CMAKE_SYSTEM_VERSION}")
  else() # multi-arch -> use apple-darwin<ver>
    set(CONTRIB_DARWIN_FOLDER "apple-darwin${CMAKE_SYSTEM_VERSION}")
  endif()
endif()

# For libavutil/avframe.
set(LIBJAMI_CONTRIB_DIR "${DAEMON_DIR}/contrib")

find_package(Vulkan)
if(Vulkan_FOUND)
  add_definitions(-DHAS_VULKAN)
  include_directories(${Vulkan_INCLUDE_DIR})
endif()
# Define PREFER_VULKAN to prefer Vulkan over the default API
# on GNU/Linux and Windows. Metal is always preferred on macOS.

if(ENABLE_CRASHREPORTS)
  set(CRASHREPORT_CLIENT_DIR ${APP_SRC_DIR}/crashreportclients)
  if(ENABLE_CRASHPAD)
    list(APPEND CLIENT_LIBS crashpad_client)
    list(APPEND COMMON_SOURCES ${CRASHREPORT_CLIENT_DIR}/crashpad.cpp)
    list(APPEND COMMON_HEADERS ${CRASHREPORT_CLIENT_DIR}/crashpad.h)
  endif()
endif()

find_package(PkgConfig REQUIRED)

# hunspell
pkg_search_module(hunspell IMPORTED_TARGET hunspell)
if(hunspell_FOUND)
  message(STATUS "hunspell found")
  set(HUNSPELL_LIBRARIES PkgConfig::hunspell)
else()
  message(STATUS "hunspell not found - building hunspell")

  set(HUNSPELL_DIR ${PROJECT_SOURCE_DIR}/3rdparty/hunspell)

  # Build using the submodule and its CMakeLists.txt
  add_subdirectory(${HUNSPELL_DIR} hunspell_build EXCLUDE_FROM_ALL)

  set(HUNSPELL_INCLUDE_DIR ${HUNSPELL_DIR}/src)
  set(HUNSPELL_LIBRARIES hunspell::hunspell)
endif()

if(MSVC)
  # Enforce minimum SDK 10.0.26100.0
  set(MIN_WIN_SDK "10.0.26100.0")

  # Set minimum SDK version hint
  set(CMAKE_SYSTEM_VERSION "${MIN_WIN_SDK}" CACHE STRING "" FORCE)

  # After SDK selection, validate what CMake chose
  if (DEFINED CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION)
      if (CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION VERSION_LESS MIN_WIN_SDK)
          message(FATAL_ERROR
              "Windows SDK ${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION} is too old. "
              "Minimum required: ${MIN_WIN_SDK}")
      endif()
  endif()

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
    /MP /GS /W3 /Gy /Zc:__cplusplus /Zc:wchar_t /Zi /Gm- /O2 /Zc:inline /fp:precise)
  add_compile_options(/Gd /Oi /MD /FC /EHsc /nologo /sdl)

  # linker options
  add_link_options(
    "/IGNORE:4006,4049,4078,4098"
    "/FORCE:MULTIPLE"
    "/INCREMENTAL:NO"
    "/DEBUG"
    "/LTCG"
    "/NODEFAULTLIB:LIBCMT")

  # daemon
  set(JAMID_SRC_PATH ${DAEMON_DIR}/contrib/msvc/include)
  set(GNUTLS_LIB ${DAEMON_DIR}/contrib/msvc/lib/x64/libgnutls.lib)

  include_directories(
    ${JAMID_SRC_PATH}
    ${LIBCLIENT_SRC_DIR}
  )
elseif (NOT APPLE)
  list(APPEND COMMON_SOURCES
    ${APP_SRC_DIR}/xrectsel.c
    ${APP_SRC_DIR}/connectivitymonitor.cpp
    ${APP_SRC_DIR}/dbuserrorhandler.cpp
    ${APP_SRC_DIR}/appversionmanager.cpp
    ${APP_SRC_DIR}/screencastportal.cpp)
  list(APPEND COMMON_HEADERS
    ${APP_SRC_DIR}/xrectsel.h
    ${APP_SRC_DIR}/dbuserrorhandler.h
    ${APP_SRC_DIR}/screencastportal.h)
  list(APPEND QT_MODULES DBus)

  pkg_check_modules(GLIB REQUIRED glib-2.0)
  if(GLIB_FOUND)
    add_definitions(${GLIB_CFLAGS_OTHER})
  endif()

  pkg_check_modules(GIO REQUIRED gio-2.0)
  if(GIO_FOUND)
    add_definitions(${GIO_CFLAGS})
  endif()

  pkg_check_modules(GIOUNIX REQUIRED gio-unix-2.0)
  if(GIOUNIX_FOUND)
    add_definitions(${GIOUNIX_CFLAGS})
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

  include_directories(
    ${LIBCLIENT_SRC_DIR}
    ${LIBNM_INCLUDE_DIRS}
    ${LIBNOTIFY_INCLUDE_DIRS}
    ${LIBGDKPIXBUF_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS})

  set(JAMI_DATA_PREFIX "${CMAKE_INSTALL_PREFIX}/share")

  find_library(${LIBCLIENT_NAME} ${LIBCLIENT_NAME} NO_DEFAULT_PATH)
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

message(STATUS "Adding HUNSPELL_INCLUDE_DIR" ${HUNSPELL_INCLUDE_DIR})
list(APPEND CLIENT_INCLUDE_DIRS ${HUNSPELL_INCLUDE_DIR} ${CMAKE_BINARY_DIR}/include
${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/hunspell/src)

message(STATUS "Adding HUNSPELL_LIBRARIES" ${HUNSPELL_INCLUDE_DIR})
list(APPEND CLIENT_LIBS ${HUNSPELL_LIBRARIES})

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
  add_definitions(-DENABLE_LIBWRAP=true)
endif()

# SFPM
set(BUILD_SFPM_PIC ON CACHE BOOL "enable -fPIC for SFPM" FORCE)
add_subdirectory(3rdparty/SortFilterProxyModel)
set(SFPM_OBJECTS $<TARGET_OBJECTS:SortFilterProxyModel>)

# md4c
find_package(md4c)
if(md4c_FOUND)
  message(STATUS "Using system-provided md4c-html")
  list(APPEND CLIENT_LIBS md4c::md4c-html)
else()
  message("Using bundled md4c-html library")
  set(BUILD_MD2HTML_EXECUTABLE OFF CACHE BOOL "Don't build md2html executable" FORCE)
  set(BUILD_SHARED_LIBS OFF CACHE BOOL "Don't build shared md4c library" FORCE)
  add_subdirectory(3rdparty/md4c EXCLUDE_FROM_ALL)
  list(APPEND CLIENT_LINK_DIRS ${MD4C_BINARY_DIR}/src)
  list(APPEND CLIENT_INCLUDE_DIRS ${MD4C_SOURCE_DIR}/src)
  list(APPEND CLIENT_LIBS md4c-html)
endif()

# tidy-html5
pkg_check_modules(tidy IMPORTED_TARGET tidy)
if(tidy_FOUND)
  message(STATUS "Using system-provided tidy")
  list(APPEND CLIENT_LIBS PkgConfig::tidy)
else()
  message("Using bundled tidy library")
  set(BUILD_SHARED_LIB OFF CACHE BOOL "Don't build shared tidy library" FORCE)
  set(SUPPORT_CONSOLE_APP OFF CACHE BOOL "Don't build tidy console app" FORCE)
  add_subdirectory(3rdparty/tidy-html5 EXCLUDE_FROM_ALL)
  list(APPEND CLIENT_LINK_DIRS ${tidy_BINARY_DIR}/Release)
  list(APPEND CLIENT_INCLUDE_DIRS ${tidy_SOURCE_DIR}/include)
  list(APPEND CLIENT_LIBS tidy-static)
endif()

# ZXing-cpp configuration
pkg_check_modules(zxing IMPORTED_TARGET zxing)
if(zxing_FOUND)
  message(STATUS "Using system-provided ZXing-cpp")
  list(APPEND CLIENT_INCLUDE_DIRS ${zxing_INCLUDE_DIRS})
  list(APPEND CLIENT_LIBS PkgConfig::zxing)
else()
  set(ZXING_EXAMPLES OFF CACHE BOOL "")
  set(ZXING_BLACKBOX_TESTS OFF CACHE BOOL "")
  add_subdirectory(3rdparty/zxing-cpp EXCLUDE_FROM_ALL)
  list(APPEND CLIENT_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/3rdparty/zxing-cpp/core/src)
  list(APPEND CLIENT_LIBS ZXing)
endif()

# common executable sources
qt_add_executable(
  ${PROJECT_NAME}
  MANUAL_FINALIZATION
  ${APP_SRC_DIR}/main.cpp
  ${COMMON_HEADERS}
  ${COMMON_SOURCES}
  ${QML_RESOURCES}
  ${QML_RESOURCES_QML}
  ${SFPM_OBJECTS}
  src/app/spellcheckadapter.h src/app/spellcheckadapter.cpp)

#add_dependencies(${PROJECT_NAME} hunspell)

# Ensure the generated version file can be found.
add_dependencies(${PROJECT_NAME} generate_version_info)

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
    FILES ${DATA_DIR}/net.jami.Jami.desktop
    DESTINATION ${JAMI_DATA_PREFIX}/applications)

  # Install .desktop in the jami data directory, so that it can be
  # copied to the autostart directory by the client.
  install(
    FILES ${DATA_DIR}/net.jami.Jami.desktop
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

  target_compile_definitions(
    ${PROJECT_NAME}
    PRIVATE
    HUNSPELL_INSTALL_DIR="${HUNSPELL_DICT_DIR}")

  # Logos
  install(
    FILES resources/images/net.jami.Jami.svg
    DESTINATION
    ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/scalable/apps)

  install(
    FILES resources/images/net.jami.Jami-48px.png
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor/48x48/apps
    RENAME jami.png)

  install(
    FILES resources/images/jami-32px.xpm
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/pixmaps
    RENAME jami.xpm)

  # AppStream metadata
  #
  # MetaInfo file:
  install(
    FILES ${DATA_DIR}/net.jami.Jami.metainfo.xml
    DESTINATION ${CMAKE_INSTALL_PREFIX}/share/metainfo)
  # Catalog file:
  if(NOT DEFINED APPSTREAM_CATALOG_DIR)
    set(APPSTREAM_CATALOG_DIR /share/swcatalog/xml)
  endif()
  install(
    FILES ${DATA_DIR}/jami.xml
    DESTINATION ${CMAKE_INSTALL_PREFIX}${APPSTREAM_CATALOG_DIR})

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
  set(libs ${QT_LIBS} ${SYSTEM_CONFIGURATUION} ${LIBCLIENT_NAME})
  if(ENABLE_SPARKLE)
    set(resources ${resources} ${SPARKLE_FRAMEWORK})
    set(libs ${libs} ${SPARKLE_FRAMEWORK})
  endif(ENABLE_SPARKLE)
  target_sources(${PROJECT_NAME} PRIVATE ${resources})
  list(APPEND CLIENT_LIBS ${libs})

  file(GLOB CONTRIB ${LIBJAMI_CONTRIB_DIR}/${CONTRIB_DARWIN_FOLDER}/lib/*.a)
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

  set(APP_CONTAINER "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.app/Contents")

  # ringtones. Copy the entire directory to the app bundle.
  # daemon/ringtones -> Jami.app/Contents/Resources/ringtones
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${DAEMON_DIR}/ringtones
    ${APP_CONTAINER}/Resources/ringtones
  )

  # translations
  if(Qt${QT_VERSION_MAJOR}LinguistTools_FOUND)
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
    set_target_properties(${PROJECT_NAME} PROPERTIES
          XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/entitlements/appstore/Jami.entitlements")
  else()
    # Include container-migration.plist in the Resources directory of the app bundle
    set_source_files_properties("${CMAKE_CURRENT_SOURCE_DIR}/resources/container-migration.plist" PROPERTIES
      MACOSX_PACKAGE_LOCATION "Resources"
    )
    # Add container-migration.plist to the target
    target_sources(${PROJECT_NAME} PRIVATE
      "${CMAKE_CURRENT_SOURCE_DIR}/resources/container-migration.plist"
    )
    set_target_properties(${PROJECT_NAME} PROPERTIES
          SPARKLE_URL "${SPARKLE_URL}"
          SPARKLE_PUBLIC_KEY "${SPARKLE_PUBLIC_KEY}"
          XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${CMAKE_CURRENT_SOURCE_DIR}/resources/entitlements/Jami.entitlements"
          XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME TRUE)
  endif()
  if(DEPLOY)
    execute_process(COMMAND
      "${CMAKE_PREFIX_PATH}/bin/macdeployqt"
      "${CMAKE_BINARY_DIR}/${PROJECT_NAME}.app"
      -qmldir=${QML_SRC_DIR})
    if(${ENABLE_SPARKLE} MATCHES true)
      file(COPY ${SPARKLE_FRAMEWORK} DESTINATION ${EXE_NAME}/Contents/Frameworks/)
    endif()
  endif()
endif()

target_include_directories(${PROJECT_NAME} PRIVATE ${CLIENT_INCLUDE_DIRS})
target_link_directories(${PROJECT_NAME} PRIVATE ${CLIENT_LINK_DIRS})
target_link_libraries(${PROJECT_NAME} PRIVATE ${CLIENT_LIBS})

qt_import_qml_plugins(${PROJECT_NAME})
qt_finalize_executable(${PROJECT_NAME})

# tests
if(BUILD_TESTING)
  message("Add Jami tests")
  enable_testing()
  add_subdirectory(${TESTS_DIR})
endif()
