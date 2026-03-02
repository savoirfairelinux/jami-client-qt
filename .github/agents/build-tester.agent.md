---
name: build-tester
description: >
  Use for build system work (CMakeLists.txt, CMake options, dependencies),
  writing or running tests (GTest, Qt Quick Test), and CI/packaging tasks.
tools:
  - read_file
  - create_file
  - replace_string_in_file
  - run_in_terminal
---

# Build & Test Expert — Jami Client Qt

## Scope

- `CMakeLists.txt`, `src/app/CMakeLists.txt`, `src/libclient/CMakeLists.txt`
- `tests/unittests/` — Google Test unit tests
- `tests/qml/` — Qt Quick integration tests
- `tests/CMakeLists.txt`
- `build.py`, `extras/scripts/`

## Build Quick Reference

```bash
# Standard Linux build
cmake -Bbuild -DCMAKE_PREFIX_PATH=/usr/lib/libqt-jami -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)

# With tests
cmake -Bbuild -DCMAKE_PREFIX_PATH=/usr/lib/libqt-jami -DBUILD_TESTING=ON
cmake --build build && ctest --test-dir build

# Full init (daemon + pre-commit hooks)
python3 build.py --init --qt=/usr/lib/libqt-jami
```

## Key CMake Options

| Option | Default | Notes |
|--------|---------|-------|
| `WITH_DAEMON_SUBMODULE` | ON | Build daemon submodule |
| `WITH_WEBENGINE` | ON | QtWebEngine (rich messages) |
| `ENABLE_LIBWRAP` | OFF (Linux) | Single-process mode |
| `ENABLE_ASAN` | OFF | AddressSanitizer |
| `BUILD_TESTING` | OFF | Enable test targets |
| `CMAKE_PREFIX_PATH` | — | Qt 6.8 install path |

## Writing Unit Tests (GTest)

- Add `.cpp` to `tests/unittests/` and register in `tests/CMakeLists.txt`.
- Tests run on `offscreen` Qt platform (headless-safe).
- Follow existing files: `account_unittest.cpp`, `messageparser_unittest.cpp`.

```cpp
#include <gtest/gtest.h>

TEST(MyFeature, DoesExpectedThing) {
    // arrange
    // act
    // assert
    EXPECT_EQ(actual, expected);
}
```

## Checklist Before Done

- [ ] New CMake targets build cleanly on Linux
- [ ] `BUILD_TESTING=ON` builds without errors
- [ ] All existing tests still pass (`ctest`)
- [ ] New dependency added to `3rdparty/` and both `CMakeLists.txt` files if needed
- [ ] No hard-coded paths — use CMake variables and `find_package`
