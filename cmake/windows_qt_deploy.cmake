if (EXISTS ${TIME_STAMP_FILE})
    message("No need for Qt deploy")
else()
    message("Qt Deploying ...")
    execute_process(COMMAND "${WIN_DEPLOY_QT_PATH}/windeployqt.exe"
                            --verbose 1
                            --qmldir ${QML_SRC_DIR}
                            --release ${EXE_NAME})
endif()