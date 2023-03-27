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

set(COMMON_TESTS_SOURCES
    ${QML_RESOURCES}
    ${QML_RESOURCES_QML}
    $<TARGET_OBJECTS:test_common_obj>)

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
else()
    set(PTHREAD_LIB pthread)
endif()

string(TOUPPER ${CMAKE_BUILD_TYPE} BUILD_TYPE)

set(QML_TESTS_SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/tests/qml/main.cpp
    ${TEST_QML_RESOURCES}
    ${SFPM_OBJECTS}
    ${COMMON_TESTS_SOURCES})

set(UNIT_TESTS_SOURCE_FILES
    ${CMAKE_SOURCE_DIR}/tests/unittests/main_unittest.cpp
    ${CMAKE_SOURCE_DIR}/tests/unittests/account_unittest.cpp
    ${CMAKE_SOURCE_DIR}/tests/unittests/contact_unittest.cpp
    ${CMAKE_SOURCE_DIR}/tests/unittests/globaltestenvironment.h
    ${COMMON_TESTS_SOURCES})

set(ALL_TESTS_LIBS
    ${QML_TEST_LIBS}
    gtest
    ${ringclient}
    ${qrencode}
    ${X11}
    ${LIBNM_LIBRARIES}
    ${LIBNOTIFY_LIBRARIES}
    ${LIBGDKPIXBUF_LIBRARIES}
    ${WINDOWS_LIBS})

set(ALL_TESTS_INCLUDES
    ${TESTS_INCLUDES}
    ${LRC}/include/libringclient
    ${LRC}/include
    ${LIBNM_INCLUDE_DIRS}
    ${LIBNOTIFY_INCLUDE_DIRS}
    ${LIBGDKPIXBUF_INCLUDE_DIRS}
    ${WINDOWS_INCLUDES})

function(setup_test TEST_NAME TEST_SOURCES TEST_ARGS)
    string(TOLOWER ${TEST_NAME} TEST_BINARY_NAME)
    add_executable(${TEST_BINARY_NAME} ${TEST_SOURCES})
    target_compile_definitions(${TEST_BINARY_NAME} PRIVATE ENABLE_TESTS="ON")
    target_link_libraries(${TEST_BINARY_NAME} ${ALL_TESTS_LIBS})
    target_include_directories(${TEST_BINARY_NAME} PUBLIC ${ALL_TESTS_INCLUDES})
    if(MSVC)
        set_target_properties(${TEST_BINARY_NAME} PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY_${BUILD_TYPE} ${OUTPUT_DIRECTORY})
    endif()
    add_test(NAME ${TEST_NAME} COMMAND ${TEST_BINARY_NAME} ${TEST_ARGS})
endfunction()

# QML tests
setup_test(Qml_Tests
    "${QML_TESTS_SOURCE_FILES}" "-input ${PROJECT_SOURCE_DIR}/tests/qml/ -mutejamid")

# Unit tests
setup_test(Unit_Tests
    "${UNIT_TESTS_SOURCE_FILES}" "")