cmake_minimum_required(VERSION 3.19)

project(jami-modern)

find_package(Qt6 COMPONENTS Quick Core Gui Widgets REQUIRED)

qt_add_executable(jami-modern
    main.cpp
)

qt_add_qml_module(jami-modern
    URI "Jami.Modern"
    VERSION 1.0
    SOURCES
        CoreService.cpp CoreService.h
        AccountListModel.cpp AccountListModel.h
        ConversationListModel.cpp ConversationListModel.h
        MessageListModel.cpp MessageListModel.h
    QML_FILES
        Main.qml
)

# Export compile commands for IDEs
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Include paths for qtwrapper and dependencies
target_include_directories(jami-modern PRIVATE
    ${CMAKE_SOURCE_DIR}/src/libclient/qtwrapper
    ${CMAKE_SOURCE_DIR}/src/libclient
    ${CMAKE_SOURCE_DIR}/daemon/src/jami
)

target_link_libraries(jami-modern
    PRIVATE
    Qt6::Quick
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    jamiclient
    qtwrapper
)
