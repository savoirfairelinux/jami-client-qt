cmake_minimum_required(VERSION 3.19)

project(jami-modern)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 COMPONENTS Quick Core Gui Widgets REQUIRED)

set(MODERN_SOURCES
    main.cpp
    CoreService.cpp
    CoreService.h
    AccountListModel.cpp
    AccountListModel.h
    ConversationListModel.cpp
    ConversationListModel.h
    MessageListModel.cpp
    MessageListModel.h
)

set(MODERN_RESOURCES
    Main.qml
)

add_executable(jami-modern
    ${MODERN_SOURCES}
    ${MODERN_RESOURCES}
)

# Include paths for qtwrapper and dependencies
target_include_directories(jami-modern PRIVATE
    ${CMAKE_SOURCE_DIR}/src/libclient/qtwrapper
    ${CMAKE_SOURCE_DIR}/src/libclient
    ${CMAKE_SOURCE_DIR}/daemon/src/jami
)

# Qt6 resource handling
qt_add_resources(jami-modern "modern_resources"

    PREFIX "/"
    FILES
        Main.qml
)

target_link_libraries(jami-modern
    PRIVATE
    Qt6::Quick
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    jamiclient
    qtwrapper
    jamiclient
)
