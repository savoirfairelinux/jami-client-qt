# Copyright (C) 2024 Savoir-faire Linux Inc.
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

# Function to define a macro with a specific value or default to 0 if not already set.
# This is useful to if within the code we don't want to use #ifdef but rather use the
# value of the macro.
function(define_macro_with_value MACRO_NAME)
  if(DEFINED ${MACRO_NAME})
    # Convert ON/OFF to 1/0
    if(${${MACRO_NAME}} STREQUAL "ON")
      set(MACRO_VALUE "1")
    elseif(${${MACRO_NAME}} STREQUAL "OFF")
      set(MACRO_VALUE "0")
    # If the macro is defined and its value is neither "ON" nor "OFF",
    # set MACRO_VALUE to the macro's current value
    else()
      set(MACRO_VALUE "${${MACRO_NAME}}")
    endif()
  else()
    set(MACRO_VALUE "0")
  endif()

  # Add the macro definition to the compiler command line
  add_definitions("-D${MACRO_NAME}=${MACRO_VALUE}")
endfunction()
