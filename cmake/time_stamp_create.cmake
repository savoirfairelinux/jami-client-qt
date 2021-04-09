execute_process(COMMAND git rev-parse HEAD
                OUTPUT_VARIABLE VERSION_PATCH)
if (EXISTS ${File_To_Check})
    message("Keep the old time stamp")
else()
    message("Creating time stamp ...")
    file(WRITE ${File_To_Check} "${VERSION_PATCH}")
endif()