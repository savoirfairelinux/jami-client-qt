find_package(Qt5 CONFIG REQUIRED QuickTest Test)

if(MSVC)
    # Download and unpack googletest at configure time
    configure_file(googletest/CMakeLists.txt.in googletest-download/CMakeLists.txt)
    execute_process(COMMAND ${CMAKE_COMMAND} -G "${CMAKE_GENERATOR}" .
                    RESULT_VARIABLE result
                    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download)
    if(result)
        message(FATAL_ERROR "CMake step for googletest failed: ${result}")
    endif()
        execute_process(COMMAND ${CMAKE_COMMAND} --build .
                        RESULT_VARIABLE result
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/googletest-download)
    if(result)
        message(FATAL_ERROR "Build step for googletest failed: ${result}")
    endif()

    # Prevent overriding the parent project's compiler/linker
    # settings on Windows
    set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

    # Add googletest directly to our build. This defines
    # the gtest and gtest_main targets.
    add_subdirectory(${CMAKE_CURRENT_BINARY_DIR}/googletest-src
                     ${CMAKE_CURRENT_BINARY_DIR}/googletest-build
                     EXCLUDE_FROM_ALL)

    option(gtest_disable_pthreads "Disable uses of pthreads in gtest." ON)
else()
    find_package(GTest REQUIRED)
endif()

enable_testing(true)
set(QMLTEST_LIBS ${QML_LIBS} Qt5::QuickTest)

set(TESTS_INCLUDES
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/tests/qml
    ${CMAKE_SOURCE_DIR}/tests/unittests)

# Common jami files
add_library(test_common_obj OBJECT ${COMMON_SOURCES} ${COMMON_HEADERS})
target_link_libraries(test_common_obj ${QMLTEST_LIBS})
target_compile_definitions(test_common_obj PRIVATE ENABLE_TESTS="ON")

if(MSVC)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                        ${CMAKE_SOURCE_DIR}/src
                        ${LRC_SRC_PATH}
                        ${DRING_SRC_PATH})

    # QML tests
    add_executable(qml_tests
                   ${CMAKE_SOURCE_DIR}/tests/qml/main.cpp
                   ${QML_RESOURCES}
                   ${QML_RESOURCES_QML}
                   $<TARGET_OBJECTS:test_common_obj>)

    target_link_libraries(qml_tests
                          ${QMLTEST_LIBS}
                          ${test_common_objects}
                          ${QTWRAPPER_LIB}
                          ${RINGCLIENT_STATIC_LIB}
                          ${QRENCODE_LIB}
                          ${GNUTLS_LIB}
                          ${DRING_LIB}
                          Shell32.lib
                          Ole32.lib
                          Advapi32.lib
                          Shlwapi.lib
                          User32.lib
                          Gdi32.lib
                          Crypt32.lib
                          Strmiids.lib)

    target_include_directories(qml_tests PUBLIC
                               ${TESTS_INCLUDES}
                               ${LRC_SRC_PATH}
                               ${DRING_SRC_PATH})

    target_compile_definitions(qml_tests PRIVATE ENABLE_TESTS="ON")

    add_test(NAME QmlTests COMMAND qml_tests -input ${PROJECT_SOURCE_DIR}/tests/qml/)

    # Unittests
    add_executable(unittests
                   ${CMAKE_SOURCE_DIR}/tests/unittests/main_unittests.cpp
                   ${CMAKE_SOURCE_DIR}/tests/unittests/dummy_unittest.cpp
                   ${QML_RESOURCES}
                   ${QML_RESOURCES_QML}
                   $<TARGET_OBJECTS:test_common_obj>)

    target_link_libraries(unittests
                          ${QMLTEST_LIBS}
                          ${test_common_objects}
                          ${QTWRAPPER_LIB}
                          ${RINGCLIENT_STATIC_LIB}
                          ${QRENCODE_LIB}
                          ${GNUTLS_LIB}
                          ${DRING_LIB}
                          Shell32.lib
                          Ole32.lib
                          Advapi32.lib
                          Shlwapi.lib
                          User32.lib
                          Gdi32.lib
                          Crypt32.lib
                          Strmiids.lib
                          gtest)

    target_include_directories(unittests PUBLIC
                               ${TESTS_INCLUDES}
                               ${LRC_SRC_PATH}
                               ${DRING_SRC_PATH})

    target_compile_definitions(unittests PRIVATE ENABLE_TESTS="ON")

    add_test(NAME UnitTests COMMAND unittests)
else()
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}
                        ${CMAKE_SOURCE_DIR}/src
                        ${LRC}/include/libringclient
                        ${LRC}/include)

    # QML tests
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

    target_compile_definitions(qml_tests PRIVATE ENABLE_TESTS="ON")

    add_test(NAME QmlTests COMMAND qml_tests -input ${PROJECT_SOURCE_DIR}/tests/qml/)

    # Unittests
    add_executable(unittests
                   ${CMAKE_SOURCE_DIR}/tests/unittests/main_unittests.cpp
                   ${CMAKE_SOURCE_DIR}/tests/unittests/dummy_unittest.cpp
                   ${QML_RESOURCES}
                   ${QML_RESOURCES_QML}
                   $<TARGET_OBJECTS:test_common_obj>)

    target_link_libraries(unittests
                          ${QMLTEST_LIBS}
                          ${test_common_objects}
                          ${ringclient}
                          ${qrencode}
                          gtest
                          pthread)

    target_include_directories(unittests PUBLIC
                               ${TESTS_INCLUDES}
                               ${LRC}/include/libringclient
                               ${LRC}/include)

    target_compile_definitions(unittests PRIVATE ENABLE_TESTS="ON")

    add_test(NAME UnitTests COMMAND unittests)
endif()