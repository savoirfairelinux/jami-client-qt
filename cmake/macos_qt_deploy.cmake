
    message("Qt deploying in dir " ${QML_SRC_DIR})
    execute_process(COMMAND macdeployqt
                            ${EXE_NAME}
                            -qmldir=${QML_SRC_DIR})
