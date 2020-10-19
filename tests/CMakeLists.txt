find_package(Qt5 CONFIG REQUIRED QuickTest)

enable_testing(true)

set(QMLTEST_LIBS ${QML_LIBS} Qt5::QuickTest)

set(TESTS_INCLUDES
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/tests/qml)

include_directories(${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
    ${LRC}/include/libringclient
    ${LRC}/include)

add_library(test_common_obj OBJECT ${COMMON_SOURCES} ${COMMON_HEADERS})
target_link_libraries(test_common_obj ${QMLTEST_LIBS})

add_executable(qml_tests
    ${CMAKE_SOURCE_DIR}/tests/qml/main.cpp
    ${QML_RESOURCES}
    ${QML_RESOURCES_QML}
    $<TARGET_OBJECTS:test_common_obj>)

target_link_libraries(qml_tests
    ${QMLTEST_LIBS}
    ${test_common_objects}
    ${ringclient}
    ${qrencode})

target_include_directories(qml_tests PUBLIC
    ${TESTS_INCLUDES}
    ${LRC}/include/libringclient
    ${LRC}/include)

#set(QUICK_TEST_SOURCE_DIR ${PROJECT_SOURCE_DIR}/tests/qml)

add_test(NAME QmlTests COMMAND qml_tests -input ${PROJECT_SOURCE_DIR}/tests/qml/)
