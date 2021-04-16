if (EXISTS ${TIME_STAMP_FILE})
    message("No need for Qt deployment in dir " ${QML_SRC_DIR})
else()
    message("Qt deploying in dir " ${QML_SRC_DIR})
    execute_process(COMMAND "${WIN_DEPLOY_QT_PATH}/windeployqt.exe"
                            --verbose 1
                            --qmldir ${QML_SRC_DIR}
                            --release ${EXE_NAME})
endif()