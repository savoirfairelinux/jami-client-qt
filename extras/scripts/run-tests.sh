#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd "${script_dir}/../.." && pwd)
build_dir="${JAMI_TEST_BUILD_DIR:-${repo_dir}/.build-cqfd}"
jobs="${JAMI_TEST_JOBS:-$(nproc 2>/dev/null || echo 4)}"
test_regex="${JAMI_TEST_REGEX:-^(Qml_Tests|Unit_Tests)$}"
ctest_args=(${JAMI_CTEST_ARGS:--V})

if [[ -z "${JAMI_TEST_QPA_PLATFORM:-}" ]]; then
    if command -v xvfb-run >/dev/null 2>&1; then
        JAMI_TEST_QPA_PLATFORM=xcb
    else
        JAMI_TEST_QPA_PLATFORM=offscreen
    fi
fi

cmake_args=(
    -DBUILD_TESTING=ON
    -DJAMI_CQFD_BUILD=ON
    -DJAMI_TEST_QPA_PLATFORM="${JAMI_TEST_QPA_PLATFORM}"
)

export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH:-/usr/lib/libqt-jami}"
if locale -a 2>/dev/null | grep -qx "en_US.utf8"; then
    export LANG="${LANG:-en_US.UTF-8}"
    export LC_ALL="${LC_ALL:-en_US.UTF-8}"
else
    export LANG="${LANG:-C.UTF-8}"
    export LC_ALL="${LC_ALL:-C.UTF-8}"
fi
export QT_OPENGL="${QT_OPENGL:-software}"
export QSG_RHI_BACKEND="${QSG_RHI_BACKEND:-software}"
export QTWEBENGINE_CHROMIUM_FLAGS="${QTWEBENGINE_CHROMIUM_FLAGS:---disable-gpu --disable-software-rasterizer --disable-dev-shm-usage}"

if [[ -n "${CMAKE_PREFIX_PATH:-}" ]]; then
    cmake_args+=("-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}")
elif [[ -f "${repo_dir}/build/CMakeCache.txt" ]]; then
    qt_prefix=$(
        sed -n 's/^CMAKE_PREFIX_PATH:[^=]*=//p' "${repo_dir}/build/CMakeCache.txt" | head -n 1
    )
    if [[ -n "${qt_prefix}" ]]; then
        cmake_args+=("-DCMAKE_PREFIX_PATH=${qt_prefix}")
    fi
fi

echo "Jami test build directory: ${build_dir}"
echo "Jami CTest regex: ${test_regex}"

configure_stamp="${build_dir}/.jami-test-cmake-args"
configure_args=("${cmake_args[@]}")
printf -v configure_signature '%q ' "${configure_args[@]}"
if [[ "${JAMI_TEST_RECONFIGURE:-0}" == "1" \
        || ! -f "${build_dir}/CMakeCache.txt" \
        || ! -f "${configure_stamp}" \
        || "$(cat "${configure_stamp}")" != "${configure_signature}" ]]; then
    cmake -S "${repo_dir}" -B "${build_dir}" "${configure_args[@]}"
    printf '%s' "${configure_signature}" > "${configure_stamp}"
fi

build_targets=()
if [[ "${test_regex}" =~ Qml_Tests ]]; then
    build_targets+=(qml_tests)
fi
if [[ "${test_regex}" =~ Unit_Tests ]]; then
    build_targets+=(unit_tests)
fi
if [[ "${#build_targets[@]}" -eq 0 ]]; then
    build_targets=(qml_tests unit_tests)
fi

cmake --build "${build_dir}" --target "${build_targets[@]}" --parallel "${jobs}"

run_ctest() {
    local regex="$1"
    local ctest_cmd=(ctest --test-dir "${build_dir}" -R "${regex}" --output-on-failure "${ctest_args[@]}")
    if [[ "${JAMI_TEST_QPA_PLATFORM:-xcb}" == "xcb" ]] && command -v xvfb-run >/dev/null 2>&1; then
        ctest_cmd=(xvfb-run -a -s "-screen 0 1280x1024x24" "${ctest_cmd[@]}")
    fi
    if [[ -z "${DBUS_SYSTEM_BUS_ADDRESS:-}" ]] && command -v dbus-daemon >/dev/null 2>&1; then
        local system_bus_dir
        system_bus_dir="$(mktemp -d)"
        local system_bus_address
        system_bus_address="$(dbus-daemon --session --fork --print-address=1 \
            --address="unix:path=${system_bus_dir}/system_bus_socket")"
        trap 'rm -rf "${system_bus_dir}"' RETURN
        ctest_cmd=(env "DBUS_SYSTEM_BUS_ADDRESS=${system_bus_address}" "${ctest_cmd[@]}")
    fi
    if command -v dbus-run-session >/dev/null 2>&1; then
        dbus-run-session -- "${ctest_cmd[@]}"
    else
        "${ctest_cmd[@]}"
    fi
}

if [[ "${test_regex}" =~ Qml_Tests && "${test_regex}" =~ Unit_Tests ]]; then
    run_ctest "^Qml_Tests$"
    run_ctest "^Unit_Tests$"
else
    run_ctest "${test_regex}"
fi
