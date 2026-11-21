# Build instructions

There are essentially two ways to build `client-qt`:

- Use `build.py` script which will build all of Jami (daemon and client)
- Build only this client.

## Disclaimer

Because the client-qt is multi-platforms and supporting macOS, we need a recent version of Qt to do rendering with Metal and to use Qt's native SortFilterProxyModel. So, Qt 6.12 is necessary.
This version is generally not packaged on a lot of platforms, and to control available plugins and such, we have our own Qt packaged (available on https://jami.net on the distributions we support).
So, you will need to get Qt 6.12 first. For this, there is 3 methods:

### Qt from our repo (recommended)

If your distribution is supported, we provide a Qt package (libqt-jami) on our repo.
The files will be installed to `/usr/lib/libqt-jami` on Debian-like distributions. For RPM based distributions the files will be installed to `/usr/lib64/qt-jami`.

#### Install libqt-jami, Ubuntu based

To install libqt-jami on Ubuntu, execute these commands replacing `ubuntu_<VERSION>` by your distribution version. For example "ubuntu_22.04"

```bash
sudo apt install gnupg dirmngr ca-certificates curl --no-install-recommends
curl -s https://dl.jami.net/public-key.gpg | sudo tee /usr/share/keyrings/jami-archive-keyring.gpg > /dev/null
sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/jami-archive-keyring.gpg] https://dl.jami.net/nightly/ubuntu_<VERSION>/ jami main' > /etc/apt/sources.list.d/jami.list"
sudo apt-get update && sudo apt-get install libqt-jami
```

#### Install libqt-jami, Debian based

To install libqt-jami on Debian, execute these commands replacing `debian_<VERSION>` by your distribution version. For example "debian_12"

```bash
sudo apt install gnupg dirmngr ca-certificates curl --no-install-recommends
curl -s https://dl.jami.net/public-key.gpg | sudo tee /usr/share/keyrings/jami-archive-keyring.gpg > /dev/null
sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/jami-archive-keyring.gpg] https://dl.jami.net/nightly/debian_<VERSION>/ jami main' > /etc/apt/sources.list.d/jami.list"
sudo apt-get update && sudo apt-get install jami
```

#### Install jami-libqt, Fedora based

To install libqt-jami on Fedora, execute these commands replacing `fedora_<VERSION>` by your distribution version. For example "fedora_38"

```bash
sudo dnf config-manager --add-repo https://dl.jami.net/nightly/fedora_<VERSION>/jami-nightly.repo
sudo dnf update && sudo dnf install jami-libqt
```

### Qt from your distribution

If Qt 6.12 is available, you can use the packages from your distribution:

It should be (For now qt5 only is packaged by distributions, so names can change).

#### Dependencies, Debian based

```bash
sudo apt-get install cmake make doxygen g++ gettext libnotify-dev pandoc nasm \
                     libnotify-dev libnm-dev \
                     qt6-base-dev \
                     qtmultimedia5-dev libqt6svg6-dev qt6-webengine-dev \
                     qtdeclarative5-dev \
                     qtquickcontrols2-5-dev qml-module-qtquick2 qml-module-qtquick-controls \
                     qml-module-qtquick-controls2 qml-module-qtquick-dialogs \
                     qml-module-qtquick-layouts qml-module-qtquick-privatewidgets \
                     qml-module-qtquick-shapes qml-module-qtquick-window2 \
                     qml-module-qtquick-templates2 qml-module-qt-labs-platform \
                     qml-module-qtwebengine qml-module-qtwebchannel \
                     qml-module-qt-labs-qmlmodels
```

#### Dependencies, Fedora based

```bash
sudo dnf install qt6-qtsvg-devel qt6-qtwebengine-devel qt6-qtmultimedia-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel qt6-qtquickcontrols NetworkManager-libnm-devel
```

### Qt from sources

https://www.qt.io/product/qt6

## GNU/Linux

Then, you can build the project

### With build.py

The build.py Jami installer uses **python3 (minimum v3.6)**. If it's not installed,
please install it. Then run the following to initialize and update
the submodules to set them at the top of their latest commit (ideal
for getting the latest development versions; otherwise, you can use
`git submodule update --init` then checkout specific commits for each
submodule).

If you're a developer you need to install clang-format separately before initializing with the command
```bash
sudo apt install clang-format
```

```bash
./build.py --init [--qt=<path/to/qt> (this is required for qmlformatting to work)]
```

Then you will need to install dependencies:

- For GNU/Linux

```bash
sudo ./build.py --dependencies
```

Then, you can build daemon and the client using:

```bash
./build.py --install [--qt=<path/to/qt> (this needs to be the same as in the previous ./build.py --init)]
```

If you use a Qt version that is not system-wide installed, you need to
specify its path using the `--qt` flag, e.g.
`./build.py --install --qt=/home/<username>/Qt/6.12.0/gcc_64`.

Now you will have the daemon in `daemon/bin/dbus/jamid` and the client in
`build/jami`. You can now run Jami using:

```bash
./build/jami
```

Notes:

- `--global-install` to install client-qt globally under /usr/local
- `--prefix` to change the destination of the install.
+ For developers:
    + `--asan` add address sanitizer on the binary
    + `--debug` enable debug symbols
    + `--testing` will build the tests for both the daemon and client
    + `--no-libwrap` will build the DBUS version.

## Build only the client

In order to use the Qt Client it is necessary to have the Qt version 6.12 or higher. If your system does not have it you can install it [from sources or download the binary installer](https://www.qt.io/download).

## Build only this repository

Clone with common required submodule (platform specific submodules will be cloned during the configure step)

```bash
git clone https://review.jami.net/jami-client-qt
cd jami-client-qt
git submodule update --recursive --init
```

Use CMake to build

```bash
# In this repository
mkdir build
cd build
cmake ..
make -j
```

cmake can take some options:

e.g. (with Qt version from https://jami.net)

```
cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=../install -DCMAKE_PREFIX_PATH=/usr/lib/libqt-jami
```

After the build has finished, you are finally ready to launch jami in your build directory.

If you want to install it to the path provided by `CMAKE_INSTALL_PREFIX` you can run:

```bash
make install
```

## Building on native Windows

Only the 64-bit MSVC build is supported. A Windows build needs:

- Visual Studio 2022 or later with the C++ workload (MSVC x64 tools, ATL,
  Windows SDK)
- Qt 6.12 for MSVC 2022 x64, with Qt WebEngine, Qt 5 Compatibility, Qt HTTP
  Server, Qt Image Formats, Qt Multimedia, Qt Positioning, Qt Shader Tools,
  Qt WebChannel and Qt WebSockets
- CMake, Git, Python 3 and Rust (MSVC toolchain); the daemon's dependencies
  are built with vcpkg, which fetches its other tools itself
- the .NET SDK, only to build the MSI installer

`extras\scripts\install-deps-windows.ps1` installs whichever of these is
missing, with the same pinned versions as the container image below. It leaves
an existing Visual Studio, tool or Qt in place. Preview it, then run it (from
an elevated prompt if Visual Studio must be installed):

```powershell
.\extras\scripts\install-deps-windows.ps1 -WhatIf
.\extras\scripts\install-deps-windows.ps1
```

Qt is installed into `C:\Qt\6.12.0\msvc2022_64` (`-QtDir` to change it), and
the other tools under `%LOCALAPPDATA%\Jami\build-tools` (`-ToolsDir`). The
script prints any directory you need to add to `PATH`. `-Component` limits it
to `VisualStudio`, `Tools` or `Qt`. Installing Qt with the Qt online installer
instead works too.

Then, from a new non-elevated prompt:

```bash
    python build.py --init
    python build.py --install --qt <path-to-qt> (e.g. C:/Qt/6.12.0/msvc2022_64)
```

> **CMake** Note: The build script does not specify what CMake generator should be used. CMake may pick another one, for instance Ninja if it is installed. Set the `CMAKE_GENERATOR` environment variable to `Visual Studio 17 2022` or `Visual Studio 18 2026` to choose.

> **Qt** Note: If you omit the `--qt` option, the build script will try to find Qt in the default installation folder, and will take the latest version found.

`extras\scripts\build-windows.py` (called by `build.py --install`) does the
build; run it with `--help` for its options. Once the build has finished, you
can use the Visual Studio solution in the **build** folder
**(Configuration = Release, Platform = x64)**.

## Building in a Windows container

The container runs the same `build-windows.py`, in a Windows Server Core LTSC
2025 image that `install-deps-windows.ps1` sets up with Visual Studio 2026
Build Tools (MSVC v145), Windows SDK 10.0.26100.0 and Qt 6.12.0. Qt's
`msvc2022_64` kit is binary-compatible with MSVC 2026. The host only needs
Git and Docker with **Windows containers**, disk space for the image and the
dependency builds, and network access. If the `docker` command does not reach
the Windows engine, set `DOCKER_HOST`, for example to
`npipe:////./pipe/docker_engine_windows`.

Run from the client repository in PowerShell (a Git worktree is fine):

```powershell
.\extras\build\docker\build-client-qt-windows-msvc.ps1
```

Arguments after `--` are passed to `build-windows.py`, for example
`-- --tests` to also run the client tests. The container builds the committed
revision, its Git tags and pinned submodules, never the host's build tree, and
removes its dependency build trees as it goes (`--clean-deps`).

The deployed app is written to `build-artifacts\windows-msvc\Jami`; pass
`-ArtifactsDir <empty-directory>` for a different destination. Running that
app on another machine requires the x64 Visual C++ redistributable.

The container uses Hyper-V isolation, with `-Memory 16g` and all CPUs by
default; `-Isolation process` also works when the host can run LTSC 2025
images. Rebuilding the image removes the previous one unless it is in use.

To also build the unsigned MSI, review the WiX EULA (see
[Packaging On Native Windows](#packaging-on-native-windows)), then pass
`-AcceptWixEula -- pack --msi`. The MSI is written next to `Jami`.

### Build Module Individually

- Jami also supports building each module (daemon, jami) separately

**Daemon**

- See [daemon/BUILD.md](daemon/BUILD.md#how-to-compile-on-windows). The
  dependencies are built with vcpkg from `daemon/contrib/vcpkg`.

**Jami**

- Make sure that daemon is built first. Then,

```
    python extras\scripts\build-windows.py --init
    python extras\scripts\build-windows.py --qt <path-to-qt> (e.g. C:/Qt/6.12.0/msvc2022_64)
```

## Building On MacOS

**Set up**

- macOS minimum version 14.4
- install python3
- download xcode
- install Qt 6.12

Qt 6.12 can be installed via brew

```bash
brew install qt
```

or downloaded from [Qt (Open Source)](https://www.qt.io/download-open-source?hsCtaTracking=9f6a2170-a938-42df-a8e2-a9f0b1d6cdce%7C6cb0de4f-9bb5-4778-ab02-bfb62735f3e5)

Then, you can build the project

**Build with build.py**

```bash
./build.py --init
./build.py --dependencies
./build.py --install
```

If you use a Qt version that is installed in a different than standard location you need to specify its path

```bash
QT_ROOT_DIRECTORY=your_qt_directory ./build.py --install
```

Built client could be find in `build/Jami`

## Packaging On Native Windows

Install the .NET 8 SDK or later in addition to the Windows client build
prerequisites (`install-deps-windows.ps1` installs it). The installer project restores WiX 7.0.1 and its UI and Util
extensions from NuGet. No system WiX installation or Visual Studio extension
is needed.

WiX 7 refuses to build until its EULA is accepted. Review the
[WiX Open Source Maintenance Fee terms](https://docs.firegiant.com/wix/osmf/)
and satisfy any applicable sponsorship requirements first; the build scripts
never accept the EULA for you. Accept it either once per user on the build
machine:

```powershell
dotnet build JamiInstaller\JamiInstaller.wixproj -t:AcceptEula -p:EulaId=wix7
```

or per build, by passing `-p:AcceptEula=wix7` to `dotnet build` (for example
in a packaging job).

To build the client and package it, run:

```powershell
python extras\scripts\build-windows.py pack --msi
```

The script writes `JamiInstaller\bin\Release\en-us\jami-<git-version>.msi`.
To repackage an existing deployment in `x64\Release`, pass `--skip-build`
and `--skip-deploy` before `pack`. The script locates the app-local x64 CRT using
the active MSVC redistributable directory; set `VC_CRT_Dir` explicitly to
override it.

To build just the `.wixproj`, first deploy the client and set `VC_CRT_Dir`
to the x64 CRT directory containing `vcruntime140.dll`, then run:

```powershell
dotnet build JamiInstaller\JamiInstaller.wixproj -c Release --no-incremental -p:Platform=x64
```

This produces `jami.release.x64.msi` in the same output directory.

## Testing for Client-qt on Windows

- We currently use [GoogleTest](https://github.com/google/googletest) and [Qt Quick Test](https://doc.qt.io/qt-5/qtquicktest-index.html#introduction) in our product. To build and run tests, you could use the following command.

```
    python extras\scripts\build-windows.py --tests --qt <path-to-qt-bin-folder>
```

- Note that, for tests, the path of local storage files for jami will be changed based on following environment variables.

```
    %JAMI_DATA_HOME% = %TEMP% + '\\jami_test\\jami'
    %JAMI_CONFIG_HOME% = %TEMP% + '\\jami_test\\.config'
    %JAMI_CACHE_HOME% = %TEMP% + '\\jami_test\\.cache'
```

- These environment variables will be temporarily set when using build-windows.py to run tests.

## Troubleshooting

Build errors may occur if daemon dependencies have been updated since the last build, as the script may not fully detect or rebuild them in the correct order. For the same reason, you may also occasionally encounter linker errors.

To resolve this, clean and restart the installation to ensure a fresh rebuild of all components (delete all temporary files generated by the build process):

```bash
./build.py --clean
./build.py --install
```

## Debugging

Compile the client with `-DCMAKE_BUILD_TYPE=Debug`. Then, if you want to enable logging when running `jami`, launch it with `-d` or `--debug`.

To diagnose a crash, use GDB:

```sh
./build.py --install --debug
gdb -ex run --args ./jami --debug
```
