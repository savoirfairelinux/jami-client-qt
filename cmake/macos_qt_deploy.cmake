message("Qt deploying in dir " ${QML_SRC_DIR})
execute_process(COMMAND "${MAC_DEPLOY_QT_PATH}/macdeployqt"
                            ${EXE_NAME}
                            -qmldir=${QML_SRC_DIR})
if(${ENABLE_SPARKLE} MATCHES true)
    file(COPY ${SPARKLE_PATH} DESTINATION ${EXE_NAME}/Contents/Frameworks/)
endif()