find_package(Git QUIET REQUIRED)

message(STATUS "Generating version information...")

function(configure_version_string SOURCE_DIR VERSION_STRING_OUT)
  # Get short git SHA
  execute_process(
    COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
    WORKING_DIRECTORY "${SOURCE_DIR}"
    OUTPUT_VARIABLE _GIT_SHA
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  # Output the VERSION_STRING_OUT to the caller
  set(${VERSION_STRING_OUT} "${_GIT_SHA}" PARENT_SCOPE)
endfunction()

# These need to be set to the parent scripts values for configure_file to work,
# as it prepends CMAKE_CURRENT_SOURCE_DIR to the <input> and CMAKE_CURRENT_BINARY_DIR
# to <output>.
set(CMAKE_CURRENT_SOURCE_DIR ${APP_SOURCE_DIR})
set(CMAKE_CURRENT_BINARY_DIR ${APP_BINARY_DIR})

# Generate the version string for the application and core
configure_version_string(${APP_SOURCE_DIR} APP_VERSION_STRING)
configure_version_string(${CORE_SOURCE_DIR} CORE_VERSION_STRING)
set(BUILD_VERSION_STRING ${BUILD_VERSION})

# Get output file names with the .in extension removed
get_filename_component(VERSION_CPP_FILENAME ${CPP_INT_FILE} NAME_WE)
set(VERSION_CPP_FILE "${CMAKE_CURRENT_BINARY_DIR}/${VERSION_CPP_FILENAME}.cpp")

message(STATUS "infiles: ${CPP_INT_FILE}")
message(STATUS "outfiles: ${VERSION_CPP_FILE}")
configure_file(${CPP_INT_FILE} ${VERSION_CPP_FILE})
