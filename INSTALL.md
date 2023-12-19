# Build instructions

There are essentially two ways to build `client-qt`:

- Use `build.py` script which will build all of Jami (daemon and client)
- Build only this client.

## Disclaimer

Because the client-qt is multi-platforms and supporting macOS, we need a recent version of Qt to do rendering with Metal. So, Qt 6.5 is necessary.
This version is generally not packaged on a lot of platforms, and to control available plugins and such, we have our own Qt packaged (available on https://jami.net on the distributions we support).
So, you will need to get Qt 6.5 first. For this, there is 3 methods:

### Qt from our repo (recommended)

If your distribution is supported, we provide a Qt package (libqt-jami) on our repo.
The files will be installed in `/usr/lib/libqt-jami`.

#### Install libqt-jami, Ubuntu based

To install libqt-jami on Ubuntu, execute these commands replacing `ubuntu_<VERSION>` by your distribution version. For example "ubuntu_22.04"

```bash
sudo apt install gnupg dirmngr ca-certificates curl --no-install-recommends
curl -s https://dl.jami.net/public-key.gpg | sudo tee /usr/share/keyrings/jami-archive-keyring.gpg > /dev/null
sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/jami-archive-keyring.gpg] https://dl.jami.net/nightly/ubuntu_<VERSION>/ jami main' > /etc/apt/sources.list.d/jami.list"
sudo apt-get update && sudo apt-get install libqt-jami
```

#### Install libqt-jami, Debian based

To install libqt-jami on Debian, execute these commands replacing `debian_<VERSION>` by your distribution version. For example "debian_11"

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

If Qt 6.5 is available, you can use the packages from your distribution:

It should be (For now qt5 only is packaged by distributions, so names can change).

#### Dependencies, Debian based

```bash
sudo apt-get install cmake make doxygen g++ gettext libnotify-dev pandoc nasm libqrencode-dev \
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
sudo dnf install qt6-qtsvg-devel qt6-qtwebengine-devel qt6-qtmultimedia-devel qt6-qtdeclarative-devel qt6-qtquickcontrols2-devel qt6-qtquickcontrols qrencode-devel NetworkManager-libnm-devel
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
./build.py --install
```

If you use a Qt version that is not system-wide installed, you need to
specify its path using the `--qt` flag, e.g.
`./build.py --install --qt=/home/<username>/Qt/6.5.1/gcc_64`.

Now you will have the daemon in `daemon/bin/dbus/jamid` and the client in
`build/jami`. You can now run Jami using:

```bash
./build/jami
```

Notes:

- `--global-install` to install client-qt globally under /usr/local
- `--prefix` to change the destination of the install.

## Build only the client

In order to use the Qt Client it is necessary to have the Qt version 6.5 or higher. If your system does not have it you can install it [from sources or download the binary installer](https://www.qt.io/download).

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

Only 64-bit MSVC build can be compiled.

**Setup Before Building:**

- Enable Virtualization in the BIOS

- Install WSL 2 and any package it might require during the Jami build process.

- Download [Qt (Open Source)](https://www.qt.io/download-open-source?hsCtaTracking=9f6a2170-a938-42df-a8e2-a9f0b1d6cdce%7C6cb0de4f-9bb5-4778-ab02-bfb62735f3e5)

- Using the online installer, install the following Qt 6.5.3 components:

  - Git 2.10.2
  - MSVC 2019 64-bit
  - Qt 5 Compatibility Module
  - Additional Libraries
    - Qt Multimedia
    - Qt Network Authorization
    - Qt WebChannel
    - Qt WebEngine
    - Qt WebSockets
    - Qt WebView

- Download [Visual Studio](https://visualstudio.microsoft.com/) (versions 2019 or 2022). _See the SDK notes below._

  |              | SDK          | Toolset                                             | MFC              |
  | ------------ | ------------ | --------------------------------------------------- | ---------------- |
  | Requirement: | 10.0.18362.0 | V142 (VisualStudio 2019) / V143 (VisualStudio 2022) | matching Toolset |

- Install Qt Vs Tools under extensions, and configure msvc2017*64 path under Qt Options. \_See the Qt notes below.*

  |                      | Qt Version |
  | -------------------- | ---------- |
  | Minimum requirement: | 6.6.1      |

- Install [Python3](https://www.python.org/downloads/) for Windows

- Using **Elevated Command Prompt**

```sh
    python build.py --dependencies
```

> Note:
>
> 1. This command will install **chocolatey** which may require you to restart the Command Prompt to be able to use it.
> 2. This command will install **msys2 (64 bit)** by using chocolatey command which may cause issues below: <br>
>    a. Choco may require you to restart the Command Prompt after finishing installing msys2. <br>
>    b. Only if you have already installed msys2 (64 bit) under the default installation folder, we will use the existing one.
> 3. This command will install **strawberry perl** by using chocolatey command which may fail if you have already installed it.
> 4. This command will install **cmake** by using chocolatey command which will not add cmake into PATH (environment variable). <br>
>
> The issue 1, 2(a), 3 can be solved by restarting the Command Prompt under Administrator right and re-run the command. <br>
> The issue 3 can be solved by uninstalling your current strawberry perl and re-run the command. <br>
> The issue 4 can be solved by adding the location of the cmake.exe into PATH. <br>

- Using a new **Non-Elevated Command Prompt**

```bash
    python build.py --install --qt <path-to-qt-bin-folder> (e.g. C:/Qt/6.5.3/msvc2019_64)
```

> **SDK** Note:
> Jami can be build with more recent Windows SDK than the one specified in the table above. However, if your have another version than SDK 10.0.18362.0 installed, you need to identify it according to the example below. And you still need to have the required version in addition to the one you chose.

```bash
    python build.py --install --qt <path-to-qt-bin-folder> --sdk <your-sdk-version>
```

> **Qt** Note: If you omit the `--qt` option, the build script will try to find Qt in the default installation folder, and will take the latest version found. If you have appropriate Qt and SDK versions installed, you won't need to specify any additional options.

Once the build has finished, you should then be able to use the Visual Studio Solution file in client-qt **build** folder **(Configuration = Release, Platform = x64)**

### Build Module Individually

- Jami also supports building each module (daemon, jami) separately

**Daemon**

- Make sure that dependencies is built by build.py
- On MSVC folder (daemon\MSVC):

```sh
    cmake -DCMAKE_CONFIGURATION_TYPES="ReleaseLib_win32" -DCMAKE_VS_PLATFORM_NAME="x64" -G "Visual Studio 17 2022" -A x64 -T '$(DefaultPlatformToolset)' ..
    python winmake.py -b daemon
```

- This will generate a `.lib` file in the path of daemon\MSVC\x64\ReleaseLib_win32\bin

> Note: each dependencies contrib for daemon can also be updated individually <br>
> For example:

```bash
    python winmake.py -b opendht
```

**Jami**

- Make sure that daemon is built first. Then,

```
    python extras\scripts\build-windows.py --init
    python extras\scripts\build-windows.py --qt <path-to-qt-bin-folder> (e.g. C:/Qt/6.5.3/msvc2019_64)
```

## Building On MacOS

**Set up**

- macOS minimum version 10.15
- install python3
- download xcode
- install Qt 6.5

Qt 6.5 can be installed via brew

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

- To be able to generate a msi package, first download and install [Wixtoolset](https://wixtoolset.org/releases/).
- In Visual Studio, download WiX Toolset Visual Studio Extension.
- Build client-qt project first, then the JamiInstaller project, msi package should be stored in JamiInstaller\bin\Release

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

## Debugging

Compile the client with with `-DCMAKE_BUILD_TYPE=Debug`.

Then, if you want to enable logging when running `jami`, launch it
with `-d` or `--debug`.
