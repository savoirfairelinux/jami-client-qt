# Copyright (C) 2024-2025 Savoir-faire Linux Inc.
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

include(FetchContent)
include(CMakeParseArguments)

# Helper function to add external content with patches and options.
# Parameters:
#   TARGET: Name of the target to create
#   URL: URL of the git repository
#   BRANCH: Branch to checkout
#   PATCHES: List of patch files to apply
#   OPTIONS: List of options to set prior to calling FetchContent_MakeAvailable
function(add_fetch_content)
  # Parse function arguments
  set(oneValueArgs TARGET URL BRANCH)
  set(multiValueArgs PATCHES OPTIONS)
  cmake_parse_arguments(PARSE_ARGV 0 AFCWP "" "${oneValueArgs}" "${multiValueArgs}")

  # Create a string for the patch command
  set(patch_cmd "")
  # If patches is not empty, start the command with "git apply"
  if(NOT "${AFCWP_PATCHES}" STREQUAL "")
    set(patch_cmd git apply)
  endif()
  foreach(patch_file IN LISTS AFCWP_PATCHES)
    list(APPEND patch_cmd "${patch_file}")
  endforeach()

  # Declare the external content
  FetchContent_Declare(
    ${AFCWP_TARGET}
    GIT_REPOSITORY ${AFCWP_URL}
    GIT_TAG ${AFCWP_BRANCH}
    PATCH_COMMAND ${patch_cmd}
    UPDATE_DISCONNECTED 1
  )

  # Apply options
  list(LENGTH AFCWP_OPTIONS options_length)
  if(NOT ${options_length} EQUAL 0)
    math(EXPR max_idx "${options_length} - 1")
    foreach(idx RANGE 0 ${max_idx} 2)
      list(GET AFCWP_OPTIONS ${idx} key)
      math(EXPR value_idx "${idx} + 1")
      list(GET AFCWP_OPTIONS ${value_idx} value)
      set(${key} ${value} CACHE STRING "${key}" FORCE)
    endforeach()
  endif()

  # Make the content available
  FetchContent_MakeAvailable(${AFCWP_TARGET})
endfunction()

# Helper function to apply a git patch to a directory.
# Parameters:
#   PATCH_FILE: Path to the patch file
#   TARGET_DIR: Optional directory to apply the patch to (relative to source dir)
function(apply_git_patch)
  set(oneValueArgs PATCH_FILE TARGET_DIR)
  cmake_parse_arguments(AGP "" "${oneValueArgs}" "" ${ARGN})

  set(dir_arg "")
  if(AGP_TARGET_DIR)
    set(dir_arg --directory=${AGP_TARGET_DIR})
  endif()

  # Check if patch can be applied
  execute_process(
    COMMAND git apply --check ${dir_arg} ${AGP_PATCH_FILE}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    RESULT_VARIABLE check_result
    OUTPUT_QUIET ERROR_QUIET
  )

  # Apply if check passed
  if(check_result EQUAL 0)
    execute_process(
      COMMAND git apply ${dir_arg} ${AGP_PATCH_FILE}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      RESULT_VARIABLE apply_result
      OUTPUT_QUIET ERROR_QUIET
    )
    if(apply_result EQUAL 0)
      get_filename_component(patch_name ${AGP_PATCH_FILE} NAME)
      message(STATUS "Applied patch: ${patch_name}")
    else()
      message(WARNING "Failed to apply patch: ${patch_name}")
    endif()
  else()
    message(WARNING "Patch file ${AGP_PATCH_FILE} cannot be applied. May already be applied.")
  endif()
endfunction()
