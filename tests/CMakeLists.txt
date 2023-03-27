cmake_minimum_required(VERSION 3.16)

enable_testing(true)

set(QT_TESTING_MODULES
    ${QT_MODULES}
    QuickControls2
    QuickTest
    Test
    Widgets
)
find_package(Qt${QT_VERSION_MAJOR} CONFIG REQUIRED ${QT_TESTING_MODULES})
foreach(MODULE ${QT_TESTING_MODULES})
    list(APPEND QT_TEST_LIBS "Qt::${MODULE}")
endforeach()

if(MSVC)
    # Download and unpack googletest for windows
    include(FetchContent)
    FetchContent_Declare(
        googletest
        URL https://github.com/google/googletest/archive/refs/tags/release-1.11.0.zip
    )
    # for Windows: Prevent overriding the parent project's compiler/linker settings
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
else()
    find_package(GTest REQUIRED)
endif()

set(QML_TEST_LIBS ${QT_LIBS} ${LIBCLIENT_NAME} ${QT_TEST_LIBS})
set(TESTS_INCLUDES
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/tests/qml
    ${CMAKE_SOURCE_DIR}/tests/unittests)
set(TEST_QML_RESOURCES ${CMAKE_SOURCE_DIR}/tests/qml/resources.qrc)

# Common jami files
add_library(test_common_obj OBJECT ${COMMON_SOURCES} ${COMMON_HEADERS})
target_link_libraries(test_common_obj ${QML_TEST_LIBS})
target_compile_definitions(test_common_obj PRIVATE ENABLE_TESTS="ON")

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/src)

# QML tests
add_executable(qml_tests
               ${CMAKE_SOURCE_DIR}/tests/qml/main.cpp
               ${QML_RESOURCES}
               ${QML_RESOURCES_QML}
               ${TEST_QML_RESOURCES}
               ${SFPM_OBJECTS}
               $<TARGET_OBJECTS:test_common_obj>)

target_link_libraries(qml_tests
                      ${QML_TEST_LIBS}
                      ${test_common_objects})

target_compile_definitions(qml_tests PRIVATE ENABLE_TESTS="ON")

# Unittests
set(UNIT_TESTS_HEADER_FILES
    ${CMAKE_SOURCE_DIR}/tests/unittests/globaltestenvironment.h)

set(UNIT_TESTS_SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/tests/unittests/main_unittest.cpp
    ${CMAKE_SOURCE_DIR}/tests/unittests/account_unittest.cpp
    ${CMAKE_SOURCE_DIR}/tests/unittests/contact_unittest.cpp)

add_executable(unittests
               ${UNIT_TESTS_HEADER_FILES}
               ${UNIT_TESTS_SOURCE_FILES}
               ${QML_RESOURCES}
               ${QML_RESOURCES_QML}
               $<TARGET_OBJECTS:test_common_obj>)

target_link_libraries(unittests
                      ${QML_TEST_LIBS}
                      ${test_common_objects}
                      gtest)

target_compile_definitions(unittests PRIVATE ENABLE_TESTS="ON")

if(MSVC)
    list(APPEND WINDOWS_LIBS
        ${QTWRAPPER_LIB}
        ${RINGCLIENT_STATIC_LIB}
        ${QRENCODE_LIB}
        ${GNUTLS_LIB}
        ${DRING_LIB}
        ${WINDOWS_SYS_LIBS})

    list(APPEND WINDOWS_INCLUDES
        ${LRC_SRC_PATH}
        ${DRING_SRC_PATH})
endif()

include_directories(${LRC}/include/libringclient
                        ${LRC}/include
                        ${LIBNM_INCLUDE_DIRS}
                        ${LIBNOTIFY_INCLUDE_DIRS}
                        ${LIBGDKPIXBUF_INCLUDE_DIRS}
                        ${WINDOWS_INCLUDES})

# QML tests
target_link_libraries(qml_tests
                        ${ringclient}
                        ${qrencode}
                        ${X11}
                        ${LIBNM_LIBRARIES}
                        ${LIBNOTIFY_LIBRARIES}
                        ${LIBGDKPIXBUF_LIBRARIES}
                        ${WINDOWS_LIBS})

target_include_directories(qml_tests PUBLIC
                            ${TESTS_INCLUDES}
                            ${LRC}/include/libringclient
                            ${LRC}/include
                            ${WINDOWS_INCLUDES})

add_test(NAME QmlTests COMMAND qml_tests -input ${PROJECT_SOURCE_DIR}/tests/qml/)

if(MSVC)
    string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
    set_target_properties(qml_tests PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY_${BUILD_TYPE} ${OUTPUT_DIRECTORY})
else()
    set(PTHREAD_LIB pthread)
endif()

# Unittests
target_link_libraries(unittests
                        ${ringclient}
                        ${qrencode}
                        ${PTHREAD_LIB}
                        ${X11}
                        ${LIBNM_LIBRARIES}
                        ${LIBNOTIFY_LIBRARIES}
                        ${LIBGDKPIXBUF_LIBRARIES}
                        ${WINDOWS_LIBS})

target_include_directories(unittests PUBLIC
                            ${TESTS_INCLUDES}
                            ${LRC}/include/libringclient
                            ${LRC}/include
                            ${WINDOWS_INCLUDES})

add_test(NAME UnitTests COMMAND unittests)

if(MSVC)
    string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)
    set_target_properties(unittests PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY_${BUILD_TYPE} ${OUTPUT_DIRECTORY})
endif()