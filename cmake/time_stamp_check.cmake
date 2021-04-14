execute_process(COMMAND git rev-parse HEAD
                OUTPUT_VARIABLE VERSION_PATCH)

# remove leading and trailing spaces
string(STRIP "${VERSION_PATCH}" VERSION_PATCH)

message("Checking time stamp ...")
if(EXISTS ${File_To_Check})
    file (STRINGS ${File_To_Check} VERSION_IN_FILE)
    if(NOT "${VERSION_IN_FILE}" STREQUAL "${VERSION_PATCH}")
        file (REMOVE "${File_To_Check}")
    endif()
endif()